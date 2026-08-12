:- module(earn_registry, [earn_programs/1, resolve_programs/2]).

/** <module> Which earning programmes are loaded.

    The one file that names them. Each programme is otherwise self-contained --
    its resolvers under src/earn/, its tables under data/earn/<id>/, its
    fixtures under test/earn/<id>/ -- so removing a programme is deleting those
    three directories and the one line below, and everything else still builds
    and passes. The conformance harness runs over whatever this list holds.
*/

:- use_module(library(lists)).
:- use_module(library(apply)).

:- use_module(kernel).
:- use_module(qff).

%! earn_programs(-Ids) is det.
%  Every registered programme, in a stable order.
earn_programs(Ids) :-
    findall(Id, known_program(Id), Ids0),
    sort(Ids0, Ids).

%! resolve_programs(+Asked, -Ids) is det.
%  What a caller asked for, checked against what is registered. An empty ask
%  means all of them, which is the useful default: "where should I credit this
%  ticket?" is the question having more than one programme is for.
resolve_programs([], Ids) :-
    !,
    earn_programs(Ids).
resolve_programs(Asked, Ids) :-
    earn_programs(Known),
    findall(Id, ( member(Id, Asked), \+ memberchk(Id, Known) ), Unknown),
    (   Unknown == []
    ->  true
    ;   atomic_list_concat(Unknown, ', ', Bad),
        atomic_list_concat(Known, ', ', Good),
        format(atom(M), 'No earning programme called ~w. Registered: ~w.', [Bad, Good]),
        throw(input_error(M))
    ),
    % De-duplicated, but in the order asked for: a caller comparing two
    % programmes put them in the order they want to read them in.
    once_each(Asked, Ids).

% Keeps the first occurrence of each and drops the rest.
once_each([], []).
once_each([H|T], [H|R]) :-
    exclude(==(H), T, Rest),
    once_each(Rest, R).
