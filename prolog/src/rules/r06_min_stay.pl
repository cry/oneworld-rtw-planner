:- module(r06_min_stay, []).

/** <module> Rule 6 -- minimum stay.

    "All fares originating in TC1: travel on the last international sector must
    commence no earlier than 10 days after commencement of the first
    international sector."

    No cut may appear in a violation/2 clause body: they are all clauses of one
    predicate, so a cut would prune the rules that follow.
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../itinerary').
:- use_module('../../data/limits').

:- multifile validate:violation/2.

validate:violation(A, v(min_stay, '6', error, Msg,
                        [segments([F, L]), days(Days), min(Min)])) :-
    tc1_origin(A),
    first_last_international(A, First, Last),
    F = First.n, L = Last.n,
    F \== L,
    dt_days_between(First.dep, Last.dep, Days0),
    Days is truncate(Days0),
    limit(min_stay_days_tc1, Min),
    Days < Min,
    format(atom(Msg),
           'Travel originates in TC1, so the last international sector (segment ~w) may not commence earlier than ~w days after the first (segment ~w); the gap is ~w days.',
           [L, Min, F, Days]).

% Timestamps are what this rule is about, so their absence is reported rather
% than passed over.
validate:violation(A, v(min_stay, '6', indeterminate, Msg, [segments([F, L])])) :-
    tc1_origin(A),
    first_last_international(A, First, Last),
    F = First.n, L = Last.n,
    F \== L,
    \+ dt_days_between(First.dep, Last.dep, _),
    format(atom(Msg),
           'Travel originates in TC1, but segments ~w and ~w lack departure times, so the 10-day minimum stay could not be checked.',
           [F, L]).

tc1_origin(A) :-
    A.origin \== unknown,
    airport_tc(A.origin, tc1).

first_last_international(A, First, Last) :-
    findall(S, ( ann_seg(A, S), S.international == true ), Intl),
    Intl \== [],
    Intl = [First|_],
    last(Intl, Last).
