:- module(itinerary,
          [ build_itinerary/6,
            itinerary_mode/1,
            stop_kind/1,
            dt_stamp/2,
            dt_iso/2,
            dt_days_between/3,
            dt_minutes_between/3,
            dt_months_between/3
          ]).

/** <module> Raw segment list -> canonical itinerary term.

    Two kinds of input problem are handled differently on purpose:

      * Malformed input (not an object, unparseable date) throws from the
        reader in io/json_in.pl and becomes an HTTP 400.
      * Well-formed but unresolvable input (unknown IATA code, a gap between
        consecutive segments, arrival before departure) becomes an ordinary
        `error` violation carried in the itinerary's `errors` field, so the UI
        renders it inline next to the rule violations.

    Times are local, and no timezone database is needed anywhere. Ground time
    is the gap between an arrival and the next departure *at the same
    airport*, so subtracting two local timestamps is correct. Rules 6 and 7
    compare timestamps at different airports but only at day and month
    granularity. Stamps below are therefore computed at a fixed zero UTC
    offset, which makes the arithmetic deterministic without pretending to
    know a real offset.
*/

:- use_module(geo).
:- use_module('../data/limits').

%! itinerary_mode(?Mode) is nondet.
%
%  `full` means the itinerary carries a calendar: connections are classified
%  from timestamps and rules 6 and 7 apply. `routing` means it does not --
%  the route and the declared stop kinds are all there is, so rules 6 and 7
%  have nothing to measure and are reported as not checked rather than as
%  undecidable. See validate.pl for why that distinction is not a silent pass.
itinerary_mode(full).
itinerary_mode(routing).

%! stop_kind(?Kind) is nondet.
%  What a traveller can declare about an intermediate point, independently of
%  any timestamps. `transfer` is the `X/` of fare-construction notation.
stop_kind(transfer).
stop_kind(stopover).

%! build_itinerary(+Origin, +Cabin, +Passengers, +Mode, +RawSegs, -Itin) is det.
%
%  Origin may be `unknown`, in which case it is taken from the first segment.
%  RawSegs is a list of rseg(N, Type, From, To, Marketing, Operating, Flight,
%  Dep, Arr, Stop); every field except Type/From/To may be `unknown`. Stop
%  declares the kind of the intermediate point at that segment's *arrival*.
build_itinerary(Origin0, Cabin, Passengers, Mode, RawSegs, Itin) :-
    number_segments(RawSegs, 1, Segs, NumErrs),
    resolve_origin(Origin0, Segs, Origin, OriginErrs),
    maplist(segment_errors, Segs, SegErrsL),
    continuity_errors(Segs, ContErrs),
    append([NumErrs, OriginErrs, ContErrs | SegErrsL], Errors0),
    sort(Errors0, Errors),
    Itin = itin{ origin: Origin,
                 cabin: Cabin,
                 passengers: Passengers,
                 mode: Mode,
                 segments: Segs,
                 errors: Errors }.

% Position in the list is authoritative. A supplied `n` that disagrees is
% reported rather than silently honoured, because a renumbered itinerary would
% make every later violation cite the wrong segment.
number_segments([], _, [], []).
number_segments([R|Rs], I, [S|Ss], Errs) :-
    R = rseg(N, Type, From0, To0, Mkt, Op, Flt, Dep, Arr, Stop),
    place(From0, From),
    place(To0, To),
    S = seg{ n: I, type: Type, from: From, to: To,
             marketing: Mkt, operating: Op, flight: Flt,
             dep: Dep, arr: Arr, stop: Stop },
    (   ( N == unknown ; N == I )
    ->  Errs = Errs1
    ;   format(atom(M),
               'Segment listed in position ~w carries number ~w; segments must be numbered consecutively from 1.',
               [I, N]),
        Errs = [v(input_error, input, error, M, [segments([I]), given(N)])|Errs1]
    ),
    I1 is I + 1,
    number_segments(Rs, I1, Ss, Errs1).

% A metropolitan city code stands for its representative airport everywhere
% downstream, so `NYC` and `JFK` are one place to 4(i) and to the geography.
place(Given, Place) :-
    downcase_atom(Given, Lower),
    resolve_place(Lower, Place).

resolve_origin(unknown, [S|_], Origin, []) :- !, Origin = S.from.
resolve_origin(unknown, [], unknown, []) :- !.
resolve_origin(Given0, Segs, Origin, Errs) :-
    place(Given0, Origin),
    (   Segs = [S|_], S.from \== Origin
    ->  iata(Origin, UO), iata(S.from, UF),
        format(atom(M),
               'Declared origin ~w does not match the departure point of segment 1 (~w).',
               [UO, UF]),
        Errs = [v(input_error, input, error, M, [segments([1]), pair(UO-UF)])]
    ;   Errs = []
    ).

segment_errors(S, Errs) :-
    findall(E, segment_error(S, E), Errs).

segment_error(S, v(input_error, input, error, M, [segments([N]), airport(U)])) :-
    N = S.n,
    (   A = S.from ; A = S.to ),
    \+ airport_known(A),
    iata(A, U),
    format(atom(M), 'Segment ~w references ~w, which is not a known airport with scheduled service.',
           [N, U]).
% These are local wall-clock times, so an eastbound trans-Pacific sector
% legitimately arrives at an earlier clock time than it departed: NRT 17:00
% arrives LAX 10:00 on the same calendar day. Only a regression wider than the
% whole span of world time zones (UTC+14 to UTC-12) can be a data error rather
% than a date line crossing.
segment_error(S, v(input_error, input, error, M, [segments([N]), hours(Hours)])) :-
    N = S.n,
    dt_minutes_between(S.dep, S.arr, Minutes),
    limit(max_local_time_regression_hours, Max),
    Limit is -Max * 60,
    Minutes < Limit,
    Hours is truncate(-Minutes / 60),
    format(atom(M),
           'Segment ~w arrives ~w hours before it departs, which no time zone difference explains.',
           [N, Hours]).
segment_error(S, v(input_error, input, error, M, [segments([N]), airport(U)])) :-
    N = S.n,
    A = S.from,
    A == S.to,
    iata(A, U),
    format(atom(M), 'Segment ~w departs from and arrives at the same point (~w).', [N, U]).

% The journey must be a single connected chain; a surface sector between two
% airports is itself a segment (4(h) counts them), so a gap is always an error.
continuity_errors(Segs, Errs) :-
    findall(E, continuity_error(Segs, E), Errs).

continuity_error(Segs, v(input_error, input, error, M, [segments([I, J]), pair(UT-UF)])) :-
    append(_, [A, B|_], Segs),
    To = A.to, From = B.from,
    To \== From,
    I = A.n, J = B.n,
    iata(To, UT), iata(From, UF),
    format(atom(M),
           'Segment ~w arrives at ~w but segment ~w departs from ~w; the journey must be continuous (add a surface sector).',
           [I, UT, J, UF]).

% --- time helpers ----------------------------------------------------------

%! dt_stamp(+Dt, -Stamp) is semidet.
%  Fails for `unknown`, which is what propagates missing-timestamp handling
%  into the `indeterminate` severity rather than into a silent pass.
dt_stamp(dt(Y, Mo, D, H, Mi), Stamp) :-
    date_time_stamp(date(Y, Mo, D, H, Mi, 0.0, 0, -, -), Stamp).

%! dt_iso(+Dt, -Atom) is det.
dt_iso(unknown, unknown) :- !.
dt_iso(dt(Y, Mo, D, H, Mi), A) :-
    format(atom(A), '~|~`0t~d~4+-~|~`0t~d~2+-~|~`0t~d~2+T~|~`0t~d~2+:~|~`0t~d~2+',
           [Y, Mo, D, H, Mi]).

%! dt_minutes_between(+From, +To, -Minutes) is semidet.
dt_minutes_between(From, To, Minutes) :-
    dt_stamp(From, A),
    dt_stamp(To, B),
    Minutes is (B - A) / 60.

%! dt_days_between(+From, +To, -Days) is semidet.
dt_days_between(From, To, Days) :-
    dt_minutes_between(From, To, M),
    Days is M / 1440.

%! dt_months_between(+From, +To, -Months) is semidet.
%  Calendar months, not 30-day units: rule 7's "12 months" is a calendar
%  period, so 1 Sep 2026 -> 1 Sep 2027 is exactly 12 and legal.
dt_months_between(dt(Y1, M1, D1, H1, Mi1), dt(Y2, M2, D2, H2, Mi2), Months) :-
    Whole is (Y2 - Y1) * 12 + (M2 - M1),
    (   [D2, H2, Mi2] @< [D1, H1, Mi1]   % day-of-month has not come round yet
    ->  Months is Whole - 1
    ;   Months = Whole
    ).
