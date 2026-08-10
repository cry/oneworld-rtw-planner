:- module(r04_routing, [valid_tc_cycle/1, intercont_allowance/3]).

/** <module> Rule 4 -- flight application and routings.

    Every clause below succeeds when the rule is *broken*. See src/validate.pl
    for why.
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../carriers').
:- use_module('../phrasing').
:- use_module('../../data/limits').
:- use_module('../../data/transcon').
:- use_module('../../data/au_pairs').
:- use_module(library(aggregate)).

:- multifile validate:violation/2.
:- multifile validate:check/2.

% ===========================================================================
% 4(a) + 4(b) + 4(c): the traffic-conference cycle
% ===========================================================================
%
% "Travel must be via the Atlantic and Pacific Oceans and only one crossing of
% each ocean is permitted" (4a), "travel must be in a continuous forward
% direction between TC1 - TC2 - TC3" (4b), and "must terminate at the same
% point" (4c) are not three independent facts about a round-the-world
% itinerary. Together they force the collapsed traffic-conference sequence to
% be exactly a 3-cycle: [T0,T1,T2,T0] where [T0,T1,T2] is a rotation of
% [tc1,tc2,tc3] or of its reverse.
%
% Checking that one property catches every 4(a)/4(b) failure at once, and
% yields a message that names the actual defect instead of reporting an ocean
% crossing count. Backtracking *within* a continent, which 4(b) explicitly
% permits, disappears in the collapse and is never seen here.

validate:violation(A, v(tc_cycle, '4(a),4(b)', error, Msg,
                        [segments([1]), sequence(Seq), crossings(Crossings)])) :-
    Seq = A.tcs,
    Seq \== [],
    \+ memberchk(unknown, Seq),
    \+ valid_tc_cycle(Seq),
    crossings(A, Crossings),
    tc_defect(Seq, Defect),
    format(atom(Msg),
           'Traffic-conference routing ~w ~w; a round-the-world itinerary must run TC1-TC2-TC3 in one continuous direction and come back to where it started.',
           [Seq, Defect]).

%! valid_tc_cycle(?Seq) is nondet.
valid_tc_cycle(Seq) :-
    member(Base, [[tc1, tc2, tc3], [tc3, tc2, tc1]]),
    rotation(Base, [First|Rest]),
    append([First|Rest], [First], Seq).

rotation(L, R) :-
    append(Front, Back, L),
    append(Back, Front, R).

tc_defect(Seq, 'does not return to the traffic conference it started in') :-
    Seq = [First|_], last(Seq, Last), First \== Last, !.
tc_defect(Seq, 'does not reach all three traffic conferences') :-
    sort(Seq, Distinct), length(Distinct, N), N < 3, !.
tc_defect(_, 'reverses direction or crosses an ocean twice').

crossings(A, [atlantic(NA), pacific(NP)]) :-
    aggregate_all(count, ( ann_seg(A, S), S.ocean == atlantic ), NA),
    aggregate_all(count, ( ann_seg(A, S), S.ocean == pacific ), NP).

validate:check(A, chk(tc_cycle, '4(a),4(b)', 'Traffic-conference cycle', Detail,
                      [tc_cycle])) :-
    Seq = A.tcs,
    Seq \== [],
    atomic_list_concat(Seq, ' → ', Path),
    crossings(A, [atlantic(NA), pacific(NP)]),
    quantity(NA, 'Atlantic crossing', Atlantic),
    quantity(NP, 'Pacific crossing', Pacific),
    format(atom(Detail), '~w; ~w, ~w.', [Path, Atlantic, Pacific]).

% ---------------------------------------------------------------------------
% 4(b) exception: no backtracking between Hawaii and other points in North
% America. Backtracking within a continent is otherwise permitted, so this is
% specifically a there-and-back pair.

validate:violation(A, v(hawaii_backtrack, '4(b)', error, Msg,
                        [segments([Lo, Hi]), pair(UF-UT)])) :-
    hawaii_hop(A, I, F1, T1, outbound),
    hawaii_hop(A, J, _, _, inbound),
    Lo is min(I, J),
    Hi is max(I, J),
    iata(F1, UF), iata(T1, UT),
    format(atom(Msg),
           'Segments ~w and ~w backtrack between Hawaii and the North American mainland, which 4(b) does not permit.',
           [Lo, Hi]).

hawaii_hop(A, N, From, To, Direction) :-
    ann_seg(A, S),
    S.type == flight,
    N = S.n, From = S.from, To = S.to,
    S.from_cont == north_america,
    S.to_cont == north_america,
    (   is_hawaii(From), \+ is_hawaii(To) -> Direction = outbound
    ;   is_hawaii(To), \+ is_hawaii(From) -> Direction = inbound
    ).

validate:check(A, Check) :-
    findall(N, hawaii_hop(A, N, _, _, _), Hops),
    (   Hops == []
    ->  Check = chk_na(hawaii_backtrack, '4(b)', 'Hawaii backtracking',
                       'No sector runs between Hawaii and the North American mainland.')
    ;   length(Hops, N),
        quantity(N, 'sector', Count),
        segments_phrase(Hops, Where),
        format(atom(Detail),
               '~w between Hawaii and the North American mainland (~w); a there-and-back pair is not permitted.',
               [Count, Where]),
        Check = chk(hawaii_backtrack, '4(b)', 'Hawaii backtracking', Detail,
                    [hawaii_backtrack])
    ).

% ---------------------------------------------------------------------------
% 4(c): travel must terminate at the point of origin, unless the gap between
% the finishing point and the origin is one of the seven permitted
% origin-destination surface relations.

validate:violation(A, v(end_at_origin, '4(c)', error, Msg,
                        [segments([N]), pair(UE-UO)])) :-
    A.segments \== [],
    last(A.segments, Last),
    N = Last.n,
    End = Last.to,
    Origin = A.origin,
    End \== Origin,
    airport_known(End), airport_known(Origin),
    \+ permitted_od_surface(End, Origin, _),
    iata(End, UE), iata(Origin, UO),
    format(atom(Msg),
           'Itinerary finishes at ~w but originated at ~w, and ~w-~w is not one of the permitted origin-destination surface sectors.',
           [UE, UO, UE, UO]).

%! permitted_od_surface(+A, +B, -Description) is nondet.
%  The 4(c) list, direction-independent.
permitted_od_surface(X, Y, 'within the country of origin') :-
    same_country(X, Y).
permitted_od_surface(X, Y, 'within the Middle East') :-
    airport_zone(X, middle_east), airport_zone(Y, middle_east).
permitted_od_surface(X, Y, 'between the United States and Canada') :-
    country_pair(X, Y, 'US', 'CA').
permitted_od_surface(X, Y, 'between Hong Kong and China') :-
    country_pair(X, Y, 'HK', 'CN').
permitted_od_surface(X, Y, 'between Malaysia and Singapore') :-
    country_pair(X, Y, 'MY', 'SG').
permitted_od_surface(X, Y, 'within Africa') :-
    airport_continent(X, africa), airport_continent(Y, africa).
permitted_od_surface(X, Y, 'between the Maldives and Sri Lanka or India') :-
    airport_country(X, CX), airport_country(Y, CY),
    (   CX == 'MV', memberchk(CY, ['LK', 'IN'])
    ;   CY == 'MV', memberchk(CX, ['LK', 'IN'])
    ).

country_pair(X, Y, C1, C2) :-
    airport_country(X, CX), airport_country(Y, CY),
    ( CX == C1, CY == C2 ; CX == C2, CY == C1 ), !.

validate:check(A, chk(end_at_origin, '4(c)', 'Terminates at origin', Detail, [end_at_origin])) :-
    A.segments \== [],
    last(A.segments, Last),
    End = Last.to,
    Origin = A.origin,
    iata(End, UE), iata(Origin, UO),
    (   End == Origin
    ->  format(atom(Detail), 'Finishes at ~w, the point of origin.', [UE])
    ;   permitted_od_surface(End, Origin, Description)
    ->  format(atom(Detail),
               'Finishes at ~w rather than ~w; ~w-~w is a permitted origin-destination surface sector, ~w.',
               [UE, UO, UE, UO, Description])
    ;   format(atom(Detail),
               'Finishes at ~w rather than at the point of origin, ~w.', [UE, UO])
    ).

% ---------------------------------------------------------------------------
% 4(d): travel may not be via the point of origin.

validate:violation(A, v(origin_revisited, '4(d)', error, Msg,
                        [segments([N]), airport(U)])) :-
    Origin = A.origin,
    Origin \== unknown,
    ann_point(A, P),
    P.airport == Origin,
    N = P.after,
    iata(Origin, U),
    format(atom(Msg),
           'The journey passes back through its point of origin (~w) after segment ~w; 4(d) does not permit travel via the origin.',
           [U, N]).

validate:check(A, chk(origin_revisited, '4(d)', 'Origin not revisited', Detail,
                      [origin_revisited])) :-
    A.origin \== unknown,
    iata(A.origin, U),
    length(A.points, N),
    quantity(N, 'intermediate point', Count),
    aggregate_all(count, ( ann_point(A, P), P.airport == A.origin ), Revisits),
    (   Revisits == 0
    ->  format(atom(Detail), '~w, none of them ~w.', [Count, U])
    ;   format(atom(Detail), '~w, ~w of them ~w.', [Count, Revisits, U])
    ).

% ===========================================================================
% 4(e): intercontinental departures and arrivals per continent
% ===========================================================================
%
% This is a *continent*-level rule, whereas 4(b) above is a *traffic
% conference*-level rule, and the difference is what makes legal side-trips
% legal. TC1 is {North America, South America} and TC2 is {Europe/Middle East,
% Africa}, so a South America excursion never leaves TC1 and an Africa
% excursion never leaves TC2 -- neither can break the forward-direction rule.
% What bounds them instead is the allowance below. Encoding these two rules at
% the same level makes every legal excursion look like a violation.

validate:violation(A, v(intercont_departures, '4(e)', error, Msg,
                        [continent(Cont), count(N), max(Max)])) :-
    continent(Cont),
    intercont_count(A, Cont, from_cont, N),
    intercont_allowance(A, Cont, Max),
    N > Max,
    format(atom(Msg),
           '~w intercontinental departures from ~w; 4(e) permits ~w.',
           [N, Cont, Max]).

validate:violation(A, v(intercont_arrivals, '4(e)', error, Msg,
                        [continent(Cont), count(N), max(Max)])) :-
    continent(Cont),
    intercont_count(A, Cont, to_cont, N),
    intercont_allowance(A, Cont, Max),
    N > Max,
    format(atom(Msg),
           '~w intercontinental arrivals into ~w; 4(e) permits ~w.',
           [N, Cont, Max]).

intercont_count(A, Cont, Key, N) :-
    aggregate_all(count,
                  ( ann_seg(A, S),
                    get_dict(Key, S, Cont),
                    S.intercontinental == true ),
                  N).

%! intercont_allowance(+A, +Continent, -Max) is det.
%  "Two permitted in North America. Two permitted in Asia. Two permitted in
%  Europe/Middle East for travel to/from/via Africa."
intercont_allowance(A, Cont, Max) :-
    (   memberchk(Cont, [north_america, asia])
    ->  limit(max_intercont_relaxed, Max)
    ;   Cont == europe_middle_east, ann_visits(A, africa)
    ->  limit(max_intercont_relaxed, Max)
    ;   limit(max_intercont_per_continent, Max)
    ).

% "If travel is to/from Europe in both directions, itinerary may not include
% Mauritius/South Africa." The two-way Europe allowance is only in play when it
% is actually used.
validate:violation(A, v(europe_both_ways_excluded, '4(e)', error, Msg,
                        [airport(U), country(Country)])) :-
    intercont_count(A, europe_middle_east, from_cont, D),
    intercont_count(A, europe_middle_east, to_cont, R),
    % Deterministic on purpose: a cut here would prune every violation/2
    % clause that follows, since they are all clauses of one predicate.
    ( D > 1 -> true ; R > 1 ),
    ann_airport(A, Airport),
    airport_country(Airport, Country),
    memberchk(Country, ['MU', 'ZA']),
    iata(Airport, U),
    format(atom(Msg),
           'Travel is to and from Europe in both directions, so the itinerary may not include Mauritius or South Africa (~w).',
           [U]).

% One line per continent the itinerary actually enters or leaves. Listing all
% six would bury the two that carry the constraint under four zeroes.
validate:check(A, chk(intercontinental, '4(e)', 'Intercontinental sectors', Detail,
                      [intercont_departures, intercont_arrivals,
                       europe_both_ways_excluded])) :-
    findall(Part, intercont_summary(A, Part), Parts),
    (   Parts == []
    ->  Detail = 'No sector leaves the continent it starts in.'
    ;   atomic_list_concat(Parts, '; ', Body),
        format(atom(Detail), '~w.', [Body])
    ).

intercont_summary(A, Part) :-
    continent(Cont),
    memberchk(Cont, A.visited),
    intercont_count(A, Cont, from_cont, Out),
    intercont_count(A, Cont, to_cont, In),
    ( Out > 0 -> true ; In > 0 ),
    intercont_allowance(A, Cont, Max),
    format(atom(Part), '~w: ~w out, ~w in, max ~w', [Cont, Out, In, Max]).

% ===========================================================================
% 4(f): international departures and arrivals from the country of origin
% ===========================================================================

validate:violation(A, v(origin_country_departures, '4(f)', error, Msg,
                        [country(Country), count(N), max(Max)])) :-
    origin_country(A, Country),
    intl_country_count(A, Country, from_country, N),
    origin_country_allowance(A, Country, Max),
    N > Max,
    format(atom(Msg),
           '~w international departures from the country of origin (~w); 4(f) permits ~w.',
           [N, Country, Max]).

validate:violation(A, v(origin_country_arrivals, '4(f)', error, Msg,
                        [country(Country), count(N), max(Max)])) :-
    origin_country(A, Country),
    intl_country_count(A, Country, to_country, N),
    origin_country_allowance(A, Country, Max),
    N > Max,
    format(atom(Msg),
           '~w international arrivals into the country of origin (~w); 4(f) permits ~w.',
           [N, Country, Max]).

origin_country(A, Country) :-
    A.origin \== unknown,
    airport_country(A.origin, Country).

intl_country_count(A, Country, Key, N) :-
    aggregate_all(count,
                  ( ann_seg(A, S),
                    get_dict(Key, S, Country),
                    S.international == true ),
                  N).

% "EXCEPTION: Two permitted for origin USA when one arrival-departure is a
% transfer without stopover."
%
% The transfer has to be one of the country's own international
% arrival-departure pairs. Accepting any US transfer anywhere would let a purely
% domestic connection -- a change of plane at ORD in the middle of the journey
% -- buy the second international departure, which is not what the exception
% says.
origin_country_allowance(A, 'US', Max) :-
    origin_country_transfer(A, 'US'), !,
    limit(max_intl_dep_origin_country_usa, Max).
origin_country_allowance(_, _, Max) :-
    limit(max_intl_dep_origin_country, Max).

origin_country_transfer(A, Country) :-
    ann_point(A, P),
    P.kind == transfer,
    airport_country(P.airport, Country),
    N = P.after,
    arriving_segment(A, N, In),
    In.international == true,
    onward_segment(A, N, Out),
    Out.international == true,
    !.

arriving_segment(A, N, S) :-
    ann_seg(A, S),
    S.n == N.

validate:check(A, chk(origin_country_traffic, '4(f)',
                      'Origin-country international sectors', Detail,
                      [origin_country_departures, origin_country_arrivals])) :-
    origin_country(A, Country),
    Country \== unknown,
    intl_country_count(A, Country, from_country, Out),
    intl_country_count(A, Country, to_country, In),
    origin_country_allowance(A, Country, Max),
    (   Max > 1
    ->  Note = ' (the 4(f) exception for a USA origin with an international transfer)'
    ;   Note = ''
    ),
    quantity(Out, 'international departure', Departures),
    quantity(In, 'arrival', Arrivals),
    format(atom(Detail),
           '~w from ~w and ~w into it, of ~w each permitted~w.',
           [Departures, Country, Arrivals, Max, Note]).

% "No more than 4 international transfers from the one country permitted."
%
% No fixture reaches this: five international transfers in one country needs
% enough re-entries to breach 4(h)'s per-continent free segment cap first, so
% the itinerary is rejected before this rule can fire. It is implemented anyway
% because the rule text states it and a future edition may raise the caps --
% but it is untested, and worth knowing that.
validate:violation(A, v(intl_transfers_per_country, '4(f)', error, Msg,
                        [country(Country), count(N), max(Max)])) :-
    transfer_country(A, Country),
    aggregate_all(count, international_transfer(A, Country, _), N),
    limit(max_intl_transfers_per_country, Max),
    N > Max,
    format(atom(Msg),
           '~w international transfers in ~w; 4(f) permits no more than ~w from any one country.',
           [N, Country, Max]).

transfer_country(A, Country) :-
    findall(C, ( international_transfer(A, C, _) ), Cs),
    sort(Cs, Set),
    member(Country, Set).

international_transfer(A, Country, N) :-
    ann_point(A, P),
    P.kind == transfer,
    N = P.after,
    airport_country(P.airport, Country),
    Country \== unknown,
    onward_segment(A, N, Next),
    Next.international == true.

onward_segment(A, N, Next) :-
    M is N + 1,
    ann_seg(A, Next),
    Next.n == M.

validate:check(A, chk(transfers_per_country, '4(f)',
                      'International transfers per country', Detail,
                      [intl_transfers_per_country])) :-
    limit(max_intl_transfers_per_country, Max),
    findall(N-Country,
            ( transfer_country(A, Country),
              aggregate_all(count, international_transfer(A, Country, _), N) ),
            Counts),
    (   Counts == []
    ->  format(atom(Detail),
               'No international transfer; 4(f) permits ~w in any one country.', [Max])
    ;   sort(0, @>=, Counts, [Most-Where|_]),
        quantity(Most, 'international transfer', Count),
        format(atom(Detail),
               'At most ~w in any one country (~w), of ~w permitted.',
               [Count, Where, Max])
    ).

% ===========================================================================
% 4(g): surface sectors
% ===========================================================================
%
% "Transoceanic surface sectors between TC1-TC2 and TC1-TC3 are not permitted.
% EXCEPTION: For travel originating in the South West Pacific, one transoceanic
% surface sector between TC1-TC2 or TC1-TC3 is permitted."

validate:violation(A, v(transoceanic_surface, '4(g)', error, Msg,
                        [segments(Segs), count(N), max(Max)])) :-
    findall(Num, transoceanic_surface(A, Num), Segs),
    length(Segs, N),
    transoceanic_surface_allowance(A, Max),
    N > Max,
    format(atom(Msg),
           '~w transoceanic surface sector(s) (segment(s) ~w); 4(g) permits ~w for this itinerary.',
           [N, Segs, Max]).

transoceanic_surface(A, N) :-
    ann_seg(A, S),
    S.type == surface,
    memberchk(S.ocean, [atlantic, pacific]),
    N = S.n.

transoceanic_surface_allowance(A, Max) :-
    (   origin_continent(A, south_west_pacific)
    ->  limit(max_transoceanic_surface_swp, Max)
    ;   limit(max_transoceanic_surface, Max)
    ).

validate:check(A, chk(transoceanic_surface, '4(g)', 'Transoceanic surface sectors',
                      Detail, [transoceanic_surface])) :-
    findall(N, transoceanic_surface(A, N), Segs),
    length(Segs, Count),
    transoceanic_surface_allowance(A, Max),
    (   origin_continent(A, south_west_pacific)
    ->  Because = ', the allowance for travel originating in the South West Pacific'
    ;   Because = ''
    ),
    (   Segs == []
    ->  format(atom(Detail), 'None; 4(g) permits ~w~w.', [Max, Because])
    ;   segments_phrase(Segs, Where),
        quantity(Count, 'sector', Quantity),
        format(atom(Detail), '~w across the Atlantic or Pacific (~w), of ~w permitted~w.',
               [Quantity, Where, Max, Because])
    ).

origin_continent(A, Cont) :-
    A.origin \== unknown,
    airport_continent(A.origin, Cont).

% ===========================================================================
% 4(h): segment counts
% ===========================================================================

validate:violation(A, v(seg_count_max, '4(h)', error, Msg, [count(N), max(Max)])) :-
    ann_segment_count(A, N),
    limit(max_segments, Max),
    N > Max,
    format(atom(Msg),
           'Itinerary has ~w segments; the maximum is ~w, and surface sectors count toward it.',
           [N, Max]).

validate:violation(A, v(seg_count_min, '4(h)', error, Msg, [count(N), min(Min)])) :-
    ann_segment_count(A, N),
    limit(min_segments, Min),
    N < Min,
    format(atom(Msg), 'Itinerary has ~w segments; the minimum is ~w.', [N, Min]).

validate:violation(A, v(free_segments, '4(h)', error, Msg,
                        [continent(Cont), count(N), max(Max), segments(Segs)])) :-
    continent(Cont),
    free_segments(Cont, Max),
    findall(Num, intra_continental_flight(A, Cont, Num), Segs),
    length(Segs, N),
    N > Max,
    format(atom(Msg),
           '~w flight segments within ~w; 4(h) allows ~w free segments there.',
           [N, Cont, Max]).

intra_continental_flight(A, Cont, N) :-
    ann_seg(A, S),
    S.type == flight,
    S.from_cont == Cont,
    S.to_cont == Cont,
    N = S.n.

validate:check(A, chk(segment_count, '4(h)', 'Segment count', Detail,
                      [seg_count_max, seg_count_min])) :-
    ann_segment_count(A, N),
    limit(min_segments, Min),
    limit(max_segments, Max),
    quantity(N, 'segment', Count),
    format(atom(Detail),
           '~w, of a minimum ~w and a maximum ~w; surface sectors count toward the maximum.',
           [Count, Min, Max]).

validate:check(A, chk(free_segments, '4(h)', 'Free segments per continent', Detail,
                      [free_segments])) :-
    findall(Part, free_segment_summary(A, Part), Parts),
    (   Parts == []
    ->  Detail = 'No flight begins and ends in the same continent.'
    ;   atomic_list_concat(Parts, '; ', Body),
        format(atom(Detail), '~w.', [Body])
    ).

free_segment_summary(A, Part) :-
    continent(Cont),
    free_segments(Cont, Max),
    aggregate_all(count, intra_continental_flight(A, Cont, _), N),
    N > 0,
    format(atom(Part), '~w: ~w of ~w', [Cont, N, Max]).

% ===========================================================================
% 4(i): the same city pair may not be flown twice in the same direction
% ===========================================================================
%
% Two goals and a nondeterministic search that finds every offending pair.

validate:violation(A, v(dup_sector, '4(i)', error, Msg,
                        [segments([I, J]), pair(UF-UT)])) :-
    ann_flight(A, I, From, To),
    ann_flight(A, J, From, To),
    I < J,
    iata(From, UF), iata(To, UT),
    format(atom(Msg),
           'Sector ~w-~w flown twice in the same direction (segments ~w and ~w).',
           [UF, UT, I, J]).

validate:check(A, chk(dup_sector, '4(i)', 'Repeated sectors', Detail,
                      [dup_sector])) :-
    findall(From-To, ann_flight(A, _, From, To), Flown),
    Flown \== [],
    length(Flown, N),
    sort(Flown, Distinct),
    length(Distinct, D),
    Repeats is N - D,
    quantity(N, 'flight sector', Count),
    (   Repeats == 0
    ->  format(atom(Detail), '~w, each city pair flown once in that direction.', [Count])
    ;   quantity(Repeats, 'sector', Repeated),
        format(atom(Detail), '~w over ~w distinct city pairs, so ~w repeat a direction.',
               [Count, D, Repeated])
    ).

% ===========================================================================
% 4(j): carriers, affiliates and codeshares
% ===========================================================================

validate:violation(A, v(carrier_not_eligible, '4(j)', error, Msg,
                        [segments([N]), carrier(U)])) :-
    ann_seg(A, S),
    S.type == flight,
    Mkt = S.marketing,
    Mkt \== unknown,
    \+ eligible_carrier(Mkt),
    N = S.n,
    iata(Mkt, U),
    format(atom(Msg),
           'Segment ~w is marketed by ~w, which is not one of the carriers this fare applies on.',
           [N, U]).

validate:violation(A, v(codeshare_not_permitted, '4(j)', error, Msg,
                        [segments([N]), carrier(UM), operator(UO)])) :-
    ann_seg(A, S),
    S.type == flight,
    Mkt = S.marketing, Op = S.operating,
    Mkt \== unknown, Op \== unknown,
    eligible_carrier(Mkt),
    \+ permitted_operator(Mkt, Op),
    N = S.n,
    iata(Mkt, UM), iata(Op, UO),
    format(atom(Msg),
           'Segment ~w is marketed by ~w but operated by ~w, which 4(j) does not permit.',
           [N, UM, UO]).

% Carrier eligibility cannot be decided without knowing who actually operates
% the flight, so an absent operating carrier is a warning, not a pass.
validate:violation(A, v(operator_unknown, '4(j)', warning, Msg, [segments([N])])) :-
    ann_seg(A, S),
    S.type == flight,
    S.marketing \== unknown,
    S.operating == unknown,
    N = S.n,
    format(atom(Msg),
           'Segment ~w does not state an operating carrier, so its codeshare eligibility under 4(j) was not checked.',
           [N]).

% Aggregated rather than one warning per segment: a routing given without
% carriers at all would otherwise bury its real violations under a warning for
% every sector, and "no carriers were given" is one fact, not sixteen.
validate:violation(A, v(marketing_carrier_missing, '4(j)', warning, Msg, [segments(Ns)])) :-
    findall(N, ( ann_seg(A, S), S.type == flight, S.marketing == unknown, N = S.n ), Ns),
    Ns \== [],
    length(Ns, Count),
    (   Count == 1
    ->  format(atom(Msg),
               'Segment ~w does not state a carrier, so 4(j) was not checked for it.', [Ns])
    ;   format(atom(Msg),
               '~w segments (~w) do not state a carrier, so 4(j) was not checked for them.',
               [Count, Ns])
    ).

validate:check(A, chk(carriers, '4(j)', 'Carriers and codeshares', Detail,
                      [carrier_not_eligible, codeshare_not_permitted,
                       operator_unknown, marketing_carrier_missing])) :-
    aggregate_all(count, ( ann_seg(A, S), S.type == flight ), Flights),
    Flights > 0,
    carrier_set(A, marketing, Marketing),
    carrier_set(A, operating, Operating),
    quantity(Flights, 'flight segment', Count),
    (   Marketing == []
    ->  format(atom(Detail), '~w, none of them naming a carrier.', [Count])
    ;   listed(Marketing, Marketed),
        (   Operating == []
        ->  format(atom(Detail), '~w marketed by ~w; no operating carrier is stated.',
                   [Count, Marketed])
        ;   listed(Operating, Operated),
            format(atom(Detail), '~w marketed by ~w, operated by ~w.',
                   [Count, Marketed, Operated])
        )
    ).

carrier_set(A, Key, Codes) :-
    findall(U,
            ( ann_seg(A, S), S.type == flight,
              get_dict(Key, S, Code), Code \== unknown,
              iata(Code, U) ),
            All),
    sort(All, Codes).

% ===========================================================================
% 4(k): transcontinental USA and Alaska
% ===========================================================================

validate:violation(A, v(transcontinental_us, '4(k)', error, Msg,
                        [segments(Segs), count(N), max(Max)])) :-
    findall(Num, transcontinental_flight(A, Num), Segs),
    length(Segs, N),
    limit(max_transcontinental_us, Max),
    N > Max,
    format(atom(Msg),
           '~w transcontinental USA flights (segments ~w); 4(k) permits ~w.',
           [N, Segs, Max]).

transcontinental_flight(A, N) :-
    ann_seg(A, S),
    S.type == flight,
    is_transcontinental_us(S.from, S.to),
    N = S.n.

validate:violation(A, v(alaska_flights, '4(k)', error, Msg,
                        [direction(Dir), segments(Segs), count(N), max(Max)])) :-
    member(Dir-Max0, [to-max_flights_to_alaska, from-max_flights_from_alaska]),
    limit(Max0, Max),
    findall(Num, alaska_flight(A, Dir, Num), Segs),
    length(Segs, N),
    N > Max,
    format(atom(Msg),
           '~w flights ~w the State of Alaska (segments ~w); 4(k) permits ~w.',
           [N, Dir, Segs, Max]).

alaska_flight(A, to, N) :-
    ann_seg(A, S), S.type == flight,
    is_alaska(S.to), \+ is_alaska(S.from),
    N = S.n.
alaska_flight(A, from, N) :-
    ann_seg(A, S), S.type == flight,
    is_alaska(S.from), \+ is_alaska(S.to),
    N = S.n.

% 4(k) and 4(l) below are geography-specific, so they are declared not
% applicable rather than passed when the itinerary never goes near them. A
% clean pass on "transcontinental USA" for a journey that never lands in the
% USA is a truth that reads as coverage.
validate:check(A, Check) :-
    limit(max_transcontinental_us, Max),
    findall(N, transcontinental_flight(A, N), Segs),
    (   Segs == [], \+ touches_country(A, 'US')
    ->  Check = chk_na(transcontinental_us, '4(k)', 'Transcontinental USA',
                       'The itinerary does not touch the United States.')
    ;   Segs == []
    ->  format(atom(Detail),
               'No flight crosses the USA between the 4(k) state columns; ~w is permitted.',
               [Max]),
        Check = chk(transcontinental_us, '4(k)', 'Transcontinental USA', Detail,
                    [transcontinental_us])
    ;   length(Segs, N),
        quantity(N, 'transcontinental USA flight', Count),
        segments_phrase(Segs, Where),
        format(atom(Detail), '~w (~w), of ~w permitted.', [Count, Where, Max]),
        Check = chk(transcontinental_us, '4(k)', 'Transcontinental USA', Detail,
                    [transcontinental_us])
    ).

validate:check(A, Check) :-
    limit(max_flights_to_alaska, MaxTo),
    limit(max_flights_from_alaska, MaxFrom),
    findall(N, alaska_flight(A, to, N), To),
    findall(N, alaska_flight(A, from, N), From),
    (   \+ touches_alaska(A)
    ->  Check = chk_na(alaska_flights, '4(k)', 'Flights to and from Alaska',
                       'The itinerary does not touch the State of Alaska.')
    ;   length(To, NTo), length(From, NFrom),
        format(atom(Detail), '~w in, ~w out, of ~w in and ~w out permitted.',
               [NTo, NFrom, MaxTo, MaxFrom]),
        Check = chk(alaska_flights, '4(k)', 'Flights to and from Alaska', Detail,
                    [alaska_flights])
    ).

touches_country(A, Country) :-
    ann_airport(A, Airport),
    airport_country(Airport, Country),
    !.

touches_alaska(A) :-
    ann_airport(A, Airport),
    is_alaska(Airport),
    !.

% ===========================================================================
% 4(l): Australian city pairs
% ===========================================================================

validate:violation(A, v(au_city_pair, '4(l)', error, Msg,
                        [set(Set), segments(Segs), count(N), max(Max)])) :-
    au_pair_set(Set, _),
    findall(Num, au_restricted_flight(A, Set, Num), Segs),
    length(Segs, N),
    limit(max_au_city_pair_flights, Max),
    N > Max,
    upcase_atom(Set, U),
    format(atom(Msg),
           '~w flights within Australia in the ~w city-pair set (segments ~w); 4(l) permits ~w.',
           [N, U, Segs, Max]).

au_restricted_flight(A, Set, N) :-
    ann_seg(A, S),
    S.type == flight,
    au_restricted_pair(S.from-S.to, Set),
    N = S.n.

validate:check(A, Check) :-
    limit(max_au_city_pair_flights, Max),
    findall(Set-N, ( au_pair_set(Set, _), au_restricted_flight(A, Set, N) ), Flown),
    (   Flown == [], \+ domestic_australian_flight(A, _)
    ->  Check = chk_na(au_city_pair, '4(l)', 'Australian city pairs',
                       'The itinerary has no flight within Australia.')
    ;   findall(Part, au_set_summary(A, Part), Parts),
        (   Parts == []
        ->  format(atom(Detail),
                   'No flight falls in a 4(l) restricted city-pair set; ~w per set is permitted.',
                   [Max])
        ;   atomic_list_concat(Parts, '; ', Body),
            format(atom(Detail), '~w, of ~w per set permitted.', [Body, Max])
        ),
        Check = chk(au_city_pair, '4(l)', 'Australian city pairs', Detail,
                    [au_city_pair])
    ).

au_set_summary(A, Part) :-
    au_pair_set(Set, _),
    aggregate_all(count, au_restricted_flight(A, Set, _), N),
    N > 0,
    upcase_atom(Set, U),
    format(atom(Part), '~w ~w', [U, N]).

domestic_australian_flight(A, N) :-
    ann_seg(A, S),
    S.type == flight,
    S.from_country == 'AU',
    S.to_country == 'AU',
    N = S.n.
