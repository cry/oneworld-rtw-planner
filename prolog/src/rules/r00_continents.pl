:- module(r00_continents, []).

/** <module> Section 0 -- continent count and fare basis.

    Mostly informational, with one hard constraint: the fare basis table starts
    at three continents, so an itinerary touching fewer than three has no
    published fare and cannot be a oneworld Explorer at all.
*/

:- use_module('../annotate').
:- use_module('../pricing').
:- use_module('../../data/limits').

:- multifile validate:violation/2.

validate:violation(A, v(too_few_continents, '0', error, Msg,
                        [count(N), min(Min), continents(Cs)])) :-
    continent_count(A, Cs, N),
    limit(min_continents, Min),
    N < Min,
    format(atom(Msg),
           'Itinerary visits ~w continent(s) (~w); the fare requires at least ~w.',
           [N, Cs, Min]).

validate:violation(A, v(too_many_continents, '0', error, Msg,
                        [count(N), max(Max), continents(Cs)])) :-
    continent_count(A, Cs, N),
    limit(max_continents, Max),
    N > Max,
    format(atom(Msg),
           'Itinerary visits ~w continents (~w); the fare table stops at ~w.',
           [N, Cs, Max]).

% Section 0: a nonstop or surface sector between the South West Pacific and
% Europe/Middle East is priced as travel via Asia, which adds a continent the
% itinerary never lands in. Surfacing this stops the continent count looking
% like an error to the user.
validate:violation(A, v(via_asia_counted, '0', warning, Msg, [segments([N])])) :-
    via_asia_sector(A, N),
    format(atom(Msg),
           'Segment ~w runs directly between the South West Pacific and Europe/Middle East, which is priced as travel via Asia; Asia is counted as a continent for the fare basis.',
           [N]).
