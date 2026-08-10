:- module(r08_stopovers, []).

/** <module> Rule 8 -- stopovers.

    "Minimum 2 stopovers required. Maximum 2 stopovers permitted in the
    continent of origin."

    This rule depends entirely on the stopover classification in annotate.pl,
    which is why an itinerary with no timestamps produces `indeterminate` here
    rather than passing.
*/

:- use_module('../geo').
:- use_module('../annotate').
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
           '~w connection(s) have no ground time (after segment(s) ~w), so stopovers could not be counted and rule 8 could not be decided.',
           [Count, Segs]).

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
