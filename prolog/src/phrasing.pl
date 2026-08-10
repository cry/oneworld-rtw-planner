:- module(phrasing, [plural/3, quantity/3, listed/2, segments_phrase/2]).

/** <module> The small amount of English every rule module needs.

    Rule messages and check details are written by the rules themselves, next
    to the arithmetic they describe, so the same three phrases were being
    rewritten in each file. They live here instead. Nothing in this module
    knows anything about the fare.
*/

%! plural(+N, +Word, -Form) is det.
plural(1, Word, Word) :- !.
plural(_, Word, Plural) :- atom_concat(Word, s, Plural).

%! quantity(+N, +Word, -Atom) is det.
%  "1 stopover", "3 stopovers".
quantity(N, Word, Atom) :-
    plural(N, Word, Form),
    format(atom(Atom), '~w ~w', [N, Form]).

%! listed(+Items, -Atom) is det.
%  A comma-separated list, or `none` for an empty one. Rendering `[]` in a
%  sentence reads as a missing value rather than as an empty set.
listed([], none) :- !.
listed(Items, Atom) :- atomic_list_concat(Items, ', ', Atom).

%! segments_phrase(+Numbers, -Atom) is det.
%  "segment 4", "segments 4, 9".
segments_phrase(Ns, Atom) :-
    length(Ns, Count),
    plural(Count, 'segment', Word),
    listed(Ns, List),
    format(atom(Atom), '~w ~w', [Word, List]).
