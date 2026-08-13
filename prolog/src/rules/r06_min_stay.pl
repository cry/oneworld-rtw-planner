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
:- use_module('../phrasing').
:- use_module('../../data/limits').

:- multifile validate:violation/2.
:- multifile validate:not_checked/2.

% A routing-only itinerary carries no calendar, so there is nothing to measure
% ten days against. Named in the report rather than reported as undecidable:
% see the registry note in validate.pl.
%
% Guarded on the same span the rule itself measures: a rule that does not reach
% this itinerary at all is not a rule the input mode failed to answer, and
% naming it here while the register calls it not applicable would have the one
% report saying both.
validate:not_checked(A, nc(min_stay, '6',
                           'Travel originates in TC1, so a 10-day minimum stay applies, but a routing-only itinerary carries no dates to measure it against.')) :-
    A.mode == routing,
    tc1_origin(A),
    measurable_span(A, _, _).

validate:violation(A, v(min_stay, '6', error, Msg,
                        [segments([F, L]), days(Days), min(Min)])) :-
    tc1_origin(A),
    measurable_span(A, First, Last),
    F = First.n, L = Last.n,
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
    A.mode == full,
    tc1_origin(A),
    measurable_span(A, First, Last),
    F = First.n, L = Last.n,
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

%! measurable_span(+A, -First, -Last) is semidet.
%  The two sectors rule 6 measures between. It needs two *distinct* ones -- the
%  rule is a gap between a first and a last -- so an itinerary with fewer than
%  two international sectors gives the rule nothing to measure rather than
%  something it is missing the dates for. Shared with the check below so the two
%  cannot disagree about which itineraries the rule reaches.
measurable_span(A, First, Last) :-
    first_last_international(A, First, Last),
    First.n \== Last.n.

:- multifile validate:check/2.

validate:check(A, Check) :-
    limit(min_stay_days_tc1, Min),
    (   \+ tc1_origin(A)
    ->  Check = chk_na(min_stay, '6', 'Minimum stay',
                       'The journey does not start in TC1. The minimum stay does not apply.')
    %  Distinguished from the branch below on purpose. Both leave the rule
    %  unmeasured, but only one of them is the traveller's to fix, and reporting
    %  "no dates" over a fully dated itinerary sends them to look at a field that
    %  is already filled in.
    ;   \+ measurable_span(A, _, _)
    ->  Check = chk_na(min_stay, '6', 'Minimum stay',
                       'The journey has fewer than two international sectors, so there is no gap between a first and a last one for the minimum stay to apply to.')
    ;   measurable_span(A, First, Last),
        F = First.n, L = Last.n,
        dt_days_between(First.dep, Last.dep, Days0)
    ->  Days is truncate(Days0),
        quantity(Days, 'day', Elapsed),
        format(atom(Detail),
               '~w pass between the first international flight (segment ~w) and the last (segment ~w). The journey needs at least ~w.',
               [Elapsed, F, L, Min]),
        Check = chk(min_stay, '6', 'Minimum stay', Detail, [min_stay])
    ;   quantity(Min, 'day', Required),
        format(atom(Detail),
               'The journey starts in TC1, so ~w must pass between the first international flight and the last. The journey has no dates for them.',
               [Required]),
        Check = chk(min_stay, '6', 'Minimum stay', Detail, [min_stay])
    ).
