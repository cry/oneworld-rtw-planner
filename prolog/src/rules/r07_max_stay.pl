:- module(r07_max_stay, []).

/** <module> Rule 7 -- maximum stay.

    "Return travel from the last stopover point must commence no later than 12
    months after departure."
*/

:- use_module('../annotate').
:- use_module('../itinerary').
:- use_module('../../data/limits').

:- multifile validate:violation/2.
:- multifile validate:not_checked/2.

validate:not_checked(A, nc(max_stay, '7',
                           'Return travel from the last stopover must commence within 12 months of departure, but a routing-only itinerary carries no dates to measure it against.')) :-
    A.mode == routing.

validate:violation(A, v(max_stay, '7', error, Msg,
                        [segments([1, N]), months(Months), max(Max)])) :-
    departure(A, Dep),
    last_stopover_departure(A, N, Onward),
    dt_months_between(Dep, Onward, Months),
    limit(max_stay_months, Max),
    Months > Max,
    format(atom(Msg),
           'Return travel from the last stopover commences ~w months after departure (segment ~w); the maximum is ~w.',
           [Months, N, Max]).

validate:violation(A, v(max_stay, '7', indeterminate, Msg, [])) :-
    A.mode == full,
    \+ departure(A, _),
    A.segments \== [],
    format(atom(Msg),
           'No departure time was given, so the 12-month maximum stay could not be checked.', []).

departure(A, Dep) :-
    A.segments = [First|_],
    Dep = First.dep,
    Dep \== unknown.

% The onward flight from the final stopover is the sector whose departure the
% 12 months is measured to.
last_stopover_departure(A, N, Dep) :-
    findall(P, ( ann_point(A, P), P.kind == stopover ), Stops),
    Stops \== [],
    last(Stops, Last),
    N0 = Last.after,
    N is N0 + 1,
    ann_seg(A, S),
    S.n == N,
    Dep = S.dep,
    Dep \== unknown.
