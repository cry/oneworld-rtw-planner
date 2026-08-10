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
:- use_module('../../data/limits').
:- use_module(library(aggregate)).

:- multifile validate:violation/2.

validate:violation(A, v(min_stopovers, '8', error, Msg, [count(N), min(Min)])) :-
    \+ any_indeterminate_point(A),
    stopover_count(A, N),
    limit(min_stopovers, Min),
    N < Min,
    plural_word(N, 'stopover', Word),
    format(atom(Msg),
           'Itinerary has ~w ~w; a minimum of ~w is required.', [N, Word, Min]).

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
    format(atom(Msg),
           '~w stopovers in the continent of origin (~w: ~w); a maximum of ~w is permitted.',
           [N, Cont, Airports, Max]).

% An itinerary entered without timestamps must not be reported clean.
validate:violation(A, v(stopovers_undecidable, '8', indeterminate, Msg,
                        [segments(Segs)])) :-
    findall(N, ( ann_point(A, P), P.kind == indeterminate, N = P.after ), Segs),
    Segs \== [],
    length(Segs, Count),
    format(atom(Msg),
           '~w connection(s) are unclassified (after segment(s) ~w): no ground time and no declared stop kind, so stopovers could not be counted and rule 8 could not be decided.',
           [Count, Segs]).

% A declared stop kind is taken as authoritative -- the traveller knows what
% was booked -- but where it contradicts the ground time or a surface sector,
% resolving that silently would hide the fact that the stopover count depends
% on which one is believed. So the disagreement is reported and the itinerary
% is left valid, since neither source is wrong on its face.
validate:violation(A, v(stop_kind_conflict, '8', warning, Msg,
                        [segments([N]), airport(Airport),
                         declared(D), derived(Derived)])) :-
    ann_point(A, P),
    D = P.declared,
    stop_kind(D),
    Derived = P.derived,
    stop_kind(Derived),
    D \== Derived,
    N = P.after,
    iata(P.airport, Airport),
    conflict_reason(P, Reason),
    format(atom(Msg),
           '~w (after segment ~w) is declared a ~w but ~w; the declared ~w is used.',
           [Airport, N, D, Reason, D]).

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

plural_word(1, W, W) :- !.
plural_word(_, W, P) :- atom_concat(W, s, P).
