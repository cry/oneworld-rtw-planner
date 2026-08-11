:- module(r08_stopovers, []).

/** <module> Rule 8 -- stopovers.

    "Minimum 2 stopovers required. Maximum 2 stopovers permitted in the
    continent of origin."

    This rule depends entirely on the stopover classification in annotate.pl,
    which is why an itinerary with neither timestamps nor declared stop kinds
    produces `indeterminate` here rather than passing.
*/

:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../itinerary').
:- use_module('../phrasing').
:- use_module('../../data/limits').
:- use_module(library(aggregate)).

:- multifile validate:violation/2.
:- multifile validate:check/2.

validate:violation(A, v(min_stopovers, '8', error, Msg, [count(N), min(Min)])) :-
    \+ any_indeterminate_point(A),
    stopover_count(A, N),
    limit(min_stopovers, Min),
    N < Min,
    quantity(N, 'stopover', Count),
    format(atom(Msg),
           'The journey has ~w. It needs at least ~w.', [Count, Min]).

validate:violation(A, v(origin_continent_stopovers, '8', error, Msg,
                        [continent(Cont), count(N), max(Max), airports(Airports)])) :-
    origin_continent(A, Cont),
    % The dict access must sit inside the goal, not in the findall template:
    % functional notation is hoisted out of a template, where P is still free.
    findall(Airport,
            ( ann_point(A, P), P.kind == stopover, P.continent == Cont,
              iata(P.airport, Airport) ),
            Airports),
    length(Airports, N),
    limit(max_stopovers_origin_continent, Max),
    N > Max,
    continent_name(Cont, Where),
    quantity(N, 'stopover', Count),
    listed_and(Airports, List),
    format(atom(Msg),
           'The journey has ~w in the continent it began in, ~w (~w). The limit is ~w.',
           [Count, Where, List, Max]).

% An itinerary entered without timestamps must not be reported clean.
validate:violation(A, v(stopovers_undecidable, '8', indeterminate, Msg,
                        [segments(Segs)])) :-
    findall(N, ( ann_point(A, P), P.kind == indeterminate, N = P.after ), Segs),
    Segs \== [],
    length(Segs, Count),
    quantity(Count, 'connection', Unclassified),
    segments_phrase(Segs, Where),
    agree(Count, 'It has', 'They have', Have),
    format(atom(Msg),
           '~w could not be read (after ~w). ~w no ground time and no declared stop kind, so the stopovers could not be counted.',
           [Unclassified, Where, Have]).

% A declared stop kind is taken as authoritative -- the traveller knows what
% was booked -- but where it contradicts the ground time or a surface sector,
% resolving that silently would hide the fact that the stopover count depends
% on which one is believed. So the disagreement is reported and the itinerary
% is left valid, since neither source is wrong on its face.
%
% Which one won is read off the point rather than assumed: a declaration beats
% the clock but does not beat a surface sector, so naming the declared kind
% unconditionally states the opposite of what happened on exactly the sectors
% where the passenger arranged their own travel. And the kind that won is the
% number the 2-stopover minimum and the origin-continent cap are counted from,
% so it is the one fact this message owes the reader.
validate:violation(A, v(stop_kind_conflict, '8', warning, Msg,
                        [segments([N]), airport(Airport),
                         declared(D), derived(Derived), used(Used)])) :-
    ann_point(A, P),
    D = P.declared,
    stop_kind(D),
    Derived = P.derived,
    stop_kind(Derived),
    D \== Derived,
    N = P.after,
    Used = P.kind,
    iata(P.airport, Airport),
    conflict_reason(P, Reason),
    (   Used == D
    ->  Which = 'the declared'
    ;   Which = 'the derived'
    ),
    format(atom(Msg),
           '~w (after segment ~w) is declared a ~w but ~w; ~w ~w is used.',
           [Airport, N, D, Reason, Which, Used]).

conflict_reason(P, Reason) :-
    (   P.surface == true
    ->  Reason = 'adjoins a surface sector, which breaks the flown journey at the passenger\'s own expense (4(g))'
    ;   Hours is round(P.ground_minutes / 6) / 10.0,
        format(atom(Reason), 'the ~w hours on the ground make it a ~w', [Hours, P.derived])
    ).

stopover_count(A, N) :-
    aggregate_all(count, ( ann_point(A, P), P.kind == stopover ), N).

% If any connection could not be classified, the stopover total is a lower
% bound, so the "too few stopovers" error is withheld and the indeterminate
% violation below carries the report instead.
any_indeterminate_point(A) :-
    ann_point(A, P),
    P.kind == indeterminate,
    !.

origin_continent(A, Cont) :-
    A.origin \== unknown,
    airport_continent(A.origin, Cont).

% The unclassified count travels with the stopover count rather than in a check
% of its own: a stopover total with four connections unread is a lower bound,
% and reading the two numbers apart is what makes it look like a total.
validate:check(A, chk(min_stopovers, '8', 'Stopovers', Detail,
                      [min_stopovers, stopovers_undecidable, stop_kind_conflict])) :-
    stopover_count(A, N),
    limit(min_stopovers, Min),
    aggregate_all(count, ( ann_point(A, P), P.kind == indeterminate ), Unread),
    quantity(N, 'stopover', Count),
    (   Unread == 0
    ->  format(atom(Detail), 'The journey has ~w. It needs at least ~w.', [Count, Min])
    ;   quantity(Unread, 'connection', Unclassified),
        format(atom(Detail),
               'The journey has ~w. It needs at least ~w. ~w could not be read, so the real number may be higher.',
               [Count, Min, Unclassified])
    ).

validate:check(A, chk(origin_continent_stopovers, '8',
                      'Stopovers in the origin continent', Detail,
                      [origin_continent_stopovers])) :-
    origin_continent(A, Cont),
    aggregate_all(count,
                  ( ann_point(A, P), P.kind == stopover, P.continent == Cont ),
                  N),
    limit(max_stopovers_origin_continent, Max),
    continent_name(Cont, Where),
    quantity(N, 'stopover', Count),
    format(atom(Detail),
           'The journey has ~w in the continent it began in, ~w. The limit is ~w.',
           [Count, Where, Max]).
