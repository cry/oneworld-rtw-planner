:- module(annotate,
          [ annotate/2,
            ann_seg/2,
            ann_flight/4,
            ann_point/2,
            ann_visits/2,
            ann_segment_count/2,
            ann_airport/2,
            collapse/2
          ]).

/** <module> The derived-facts pass.

    annotate/2 runs once, before any rule, and decorates the raw itinerary with
    everything the rules need: continents, traffic conferences, ocean
    crossings, and the stopover/transfer classification of every intermediate
    point. Without it roughly twenty-five rules would each re-derive the same
    geography; with it, most rule bodies stay two or three goals long.

    It is eager and pure -- it returns a term, asserts nothing, and tables
    nothing -- which is what makes the validator safe to call concurrently from
    HTTP worker threads.
*/

:- use_module(geo).
:- use_module(itinerary).
:- use_module('../data/limits').

%! annotate(+Itin, -A) is det.
annotate(Itin, A) :-
    maplist(annotate_segment, Itin.segments, Segs),
    points(Segs, Points),
    continent_sequence(Segs, Continents),
    tc_sequence(Segs, TCs),
    visited_set(Segs, Visited),
    A = ann{ origin: Itin.origin,
             cabin: Itin.cabin,
             passengers: Itin.passengers,
             input_errors: Itin.errors,
             segments: Segs,
             points: Points,
             continents: Continents,
             tcs: TCs,
             visited: Visited }.

% --- per segment -----------------------------------------------------------

annotate_segment(S, A) :-
    From = S.from, To = S.to,
    geo_of(From, FC, FR, FCont, FZone, FTc),
    geo_of(To,   TC, TR, TCont, TZone, TTc),
    (   ocean_of(FTc, TTc, Ocean) -> true ; Ocean = unknown ),
    intercontinental(FCont, TCont, Inter),
    international(FC, TC, From, To, Intl),
    A = aseg{ n: S.n, type: S.type, from: From, to: To,
              marketing: S.marketing, operating: S.operating, flight: S.flight,
              dep: S.dep, arr: S.arr,
              from_country: FC, to_country: TC,
              from_region: FR,  to_region: TR,
              from_cont: FCont, to_cont: TCont,
              from_zone: FZone, to_zone: TZone,
              from_tc: FTc,     to_tc: TTc,
              intercontinental: Inter,
              international: Intl,
              ocean: Ocean }.

% An unresolvable airport yields `unknown` fields rather than a failure, so an
% itinerary with one bad code still gets validated everywhere else. Every rule
% that reads a geography field requires it to be bound to a real value.
geo_of(A, Country, Region, Cont, Zone, TC) :-
    (   airport_known(A)
    ->  airport_country(A, Country),
        airport_region(A, Region),
        airport_continent(A, Cont),
        (   airport_zone(A, Zone) -> true ; Zone = none ),
        (   airport_tc(A, TC) -> true ; TC = unknown )
    ;   Country = unknown, Region = unknown, Cont = unknown,
        Zone = unknown, TC = unknown
    ).

ocean_of(FTc, TTc, Ocean) :-
    FTc \== unknown, TTc \== unknown,
    (   tc_ocean(FTc, TTc) -> ocean_name(FTc, TTc, Ocean) ; Ocean = none ).

tc_ocean(F, T) :- ocean_name(F, T, _).
ocean_name(tc1, tc2, atlantic).
ocean_name(tc2, tc1, atlantic).
ocean_name(tc1, tc3, pacific).
ocean_name(tc3, tc1, pacific).

intercontinental(F, T, unknown) :- ( F == unknown ; T == unknown ), !.
intercontinental(F, F, false) :- !.
intercontinental(_, _, true).

% 4(f) NOTE: travel between the USA and Canada is not counted as international.
international(FC, TC, _, _, unknown) :- ( FC == unknown ; TC == unknown ), !.
international(C, C, _, _, false) :- !.
international(_, _, From, To, false) :- domestic_us_canada(From, To), !.
international(_, _, _, _, true).

% --- intermediate points ---------------------------------------------------

% A point exists between each consecutive pair of segments. The origin (before
% segment 1) and the final return (after segment N) are not intermediate
% points and can never be stopovers.
points(Segs, Points) :-
    findall(P, point(Segs, P), Points).

point(Segs, Pt) :-
    append(_, [A, B|_], Segs),
    Airport = A.to,
    ground_minutes(A, B, Mins),
    classify(A, B, Airport, Mins, Kind),
    Pt = pt{ after: A.n, airport: Airport, continent: A.to_cont,
             ground_minutes: Mins, kind: Kind }.

ground_minutes(A, B, Mins) :-
    (   dt_minutes_between(A.arr, B.dep, M)
    ->  Mins = M
    ;   Mins = unknown
    ).

% Convention, since Rule 3015 never defines stopover-vs-transfer:
%
%   * A point adjacent to a surface sector is a stopover -- surface travel is
%     at the passenger's expense (4(g)) and breaks the flown journey.
%   * Otherwise more than 24 hours on the ground, or more than 4 hours where
%     both adjacent sectors are domestic within the USA/Canada.
%   * Missing timestamps give `indeterminate`, which propagates into rule 8 as
%     an `indeterminate` violation rather than a silent pass.
%
% Both thresholds live in data/limits.pl so they are auditable.
classify(A, B, _, _, stopover) :-
    ( A.type == surface ; B.type == surface ), !.
classify(_, _, _, unknown, indeterminate) :- !.
classify(A, B, Airport, Mins, Kind) :-
    threshold_hours(A, B, Airport, Hours),
    Limit is Hours * 60,
    ( Mins > Limit -> Kind = stopover ; Kind = transfer ).

threshold_hours(A, B, Airport, Hours) :-
    (   airport_country(Airport, C), memberchk(C, ['US', 'CA']),
        A.international == false,
        B.international == false
    ->  limit(stopover_hours_domestic_us_ca, Hours)
    ;   limit(stopover_hours_international, Hours)
    ).

% --- itinerary-level sequences ---------------------------------------------

continent_sequence(Segs, Seq) :-
    raw_sequence(Segs, from_cont, to_cont, Raw),
    collapse(Raw, Seq).

tc_sequence(Segs, Seq) :-
    raw_sequence(Segs, from_tc, to_tc, Raw),
    collapse(Raw, Seq).

raw_sequence([], _, _, []) :- !.
raw_sequence(Segs, FromKey, ToKey, Raw) :-
    findall(V, ( member(S, Segs), get_dict(FromKey, S, V) ), Froms),
    last(Segs, Last),
    get_dict(ToKey, Last, End),
    append(Froms, [End], Raw).

%! collapse(+List, -Collapsed) is det.
%  Removes consecutive duplicates. This is what turns a 12-segment itinerary
%  into the short traffic-conference cycle that 4(a)/4(b)/4(c) are checked
%  against.
collapse([], []).
collapse([X], [X]) :- !.
collapse([X, X|T], R) :- !, collapse([X|T], R).
collapse([X|T], [X|R]) :- collapse(T, R).

visited_set(Segs, Visited) :-
    findall(C, ( member(S, Segs),
                 ( C = S.from_cont ; C = S.to_cont ),
                 C \== unknown ),
            Cs),
    sort(Cs, Visited).

% --- accessors used by rule modules ----------------------------------------

ann_seg(A, S) :- member(S, A.segments).

%! ann_flight(+A, -N, -From, -To) is nondet.
%  Flight segments only; surface sectors are excluded because 4(i) and the
%  4(h) free-segment caps are about flights.
ann_flight(A, N, From, To) :-
    ann_seg(A, S),
    S.type == flight,
    N = S.n, From = S.from, To = S.to.

ann_point(A, P) :- member(P, A.points).

%! ann_airport(+A, -Airport) is nondet.
%  Each distinct point of the journey, once. Rules that ask "does the
%  itinerary include X" must use this rather than iterating segments, or a
%  single airport appearing as both an arrival and the next departure reports
%  its violation twice.
ann_airport(A, Airport) :-
    findall(P, ( ann_seg(A, S), ( P = S.from ; P = S.to ) ), Ps),
    sort(Ps, Distinct),
    member(Airport, Distinct).

ann_visits(A, C) :- memberchk(C, A.visited).

%! ann_segment_count(+A, -N) is det.
%  4(h) counts surface segments toward the maximum, so this is every segment.
ann_segment_count(A, N) :- length(A.segments, N).
