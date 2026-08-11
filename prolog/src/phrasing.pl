:- module(phrasing, [plural/3, agree/4, quantity/3,
                     listed/2, listed_and/2, segments_phrase/2]).

/** <module> The small amount of English every rule module needs.

    Rule messages and check details are written by the rules themselves, next
    to the arithmetic they describe, so the same few phrases were being
    rewritten in each file -- and the count and the noun were being formatted
    apart often enough that "1 international departures" reached the report
    more than once. They live here instead. Nothing in this module knows
    anything about the fare.

    The rule of thumb: if a message needs a number and a noun together, it
    wants quantity/3, not plural/3 and its own format string.
*/

%! plural(+N, +Word, -Form) is det.
%  Regular -s only. Anything else is agree/4's job.
plural(1, Word, Word) :- !.
plural(_, Word, Plural) :- atom_concat(Word, s, Plural).

%! agree(+N, +Singular, +Plural, -Form) is det.
%  Agreement that adding an -s cannot do: is/are, it/them, this/these. Written
%  as a pair rather than inferred, because the alternative is a table of
%  English irregulars that this program has no reason to own.
agree(1, Singular, _, Singular) :- !.
agree(_, _, Plural, Plural).

%! quantity(+N, +Word, -Atom) is det.
%  "1 stopover", "3 stopovers". The count and the noun are formatted together
%  precisely so they cannot disagree.
quantity(N, Word, Atom) :-
    plural(N, Word, Form),
    format(atom(Atom), '~w ~w', [N, Form]).

%! listed(+Items, -Atom) is det.
%  A comma-separated list, or `none` for an empty one. Rendering `[]` in a
%  sentence reads as a missing value rather than as an empty set.
listed([], none) :- !.
listed(Items, Atom) :- atomic_list_concat(Items, ', ', Atom).

%! listed_and(+Items, -Atom) is det.
%  The same list as an English one: "A", "A and B", "A, B and C". Prose wants
%  this; a field of comma-separated values wants listed/2.
listed_and([], none) :- !.
listed_and([One], One) :- !.
listed_and(Items, Atom) :-
    append(Front, [Last], Items),
    atomic_list_concat(Front, ', ', Head),
    format(atom(Atom), '~w and ~w', [Head, Last]).

%! segments_phrase(+Numbers, -Atom) is det.
%  "segment 4", "segments 4 and 9".
segments_phrase(Ns, Atom) :-
    length(Ns, Count),
    plural(Count, 'segment', Word),
    listed_and(Ns, List),
    format(atom(Atom), '~w ~w', [Word, List]).
