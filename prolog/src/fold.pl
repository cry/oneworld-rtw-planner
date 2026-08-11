:- module(fold, [fold_diacritics/2, fold_char/2]).

/** <module> Accent folding for search.

    Typeahead is matched on a folded copy of both sides, so `sao paulo` finds
    Sao Paulo and `zurich` finds Zurich. Someone looking up an airport is
    typing on whatever keyboard they have, and a city they cannot spell the
    accents of is exactly the one they need the search for.

    The table is explicit rather than derived from Unicode normalisation. NFD
    plus a combining-mark filter would cover most of it, but it comes from an
    optional package and it does not decompose the letters that are not an
    ASCII letter with a mark on top -- o-slash, ash, eth, thorn, dotless i,
    l-stroke. Those need a table anyway, so there is one table rather than a
    normalisation pass and a table of exceptions to it.

    test/test_geo.pl asserts that this covers every character in the generated
    airport table, so regenerating that table with a new letter in it fails the
    suite rather than quietly dropping a city out of reach of the search.
*/

:- encoding(utf8).

%! fold_diacritics(+Text, -Folded) is det.
%  Lower-cases and strips accents. Characters with no entry pass through, which
%  keeps the predicate total: an unfoldable letter simply matches itself.
fold_diacritics(Text, Folded) :-
    downcase_atom(Text, Lower),
    atom_codes(Lower, Codes),
    foldl(fold_code, Codes, Out, []),
    atom_codes(Folded, Out).

fold_code(Code, Out, Tail) :-
    (   fold_char(Code, Replacement)
    ->  downcase_atom(Replacement, Down),
        atom_codes(Down, Codes),
        append(Codes, Tail, Out)
    ;   Out = [Code|Tail]
    ).

%! fold_char(?Code, ?Ascii) is nondet.
%  101 letters: every non-ASCII character in the airport table,
%  plus the common European letters someone might type that it happens not
%  to contain.
fold_char(0'À, "A").
fold_char(0'Á, "A").
fold_char(0'Â, "A").
fold_char(0'Ã, "A").
fold_char(0'Ä, "A").
fold_char(0'Å, "A").
fold_char(0'Æ, "AE").
fold_char(0'Ç, "C").
fold_char(0'È, "E").
fold_char(0'É, "E").
fold_char(0'Ê, "E").
fold_char(0'Ë, "E").
fold_char(0'Ì, "I").
fold_char(0'Í, "I").
fold_char(0'Î, "I").
fold_char(0'Ï, "I").
fold_char(0'Ð, "D").
fold_char(0'Ñ, "N").
fold_char(0'Ò, "O").
fold_char(0'Ó, "O").
fold_char(0'Ô, "O").
fold_char(0'Õ, "O").
fold_char(0'Ö, "O").
fold_char(0'Ø, "O").
fold_char(0'Ù, "U").
fold_char(0'Ú, "U").
fold_char(0'Û, "U").
fold_char(0'Ü, "U").
fold_char(0'Ý, "Y").
fold_char(0'Þ, "TH").
fold_char(0'ß, "ss").
fold_char(0'à, "a").
fold_char(0'á, "a").
fold_char(0'â, "a").
fold_char(0'ã, "a").
fold_char(0'ä, "a").
fold_char(0'å, "a").
fold_char(0'æ, "ae").
fold_char(0'ç, "c").
fold_char(0'è, "e").
fold_char(0'é, "e").
fold_char(0'ê, "e").
fold_char(0'ë, "e").
fold_char(0'ì, "i").
fold_char(0'í, "i").
fold_char(0'î, "i").
fold_char(0'ï, "i").
fold_char(0'ð, "d").
fold_char(0'ñ, "n").
fold_char(0'ò, "o").
fold_char(0'ó, "o").
fold_char(0'ô, "o").
fold_char(0'õ, "o").
fold_char(0'ö, "o").
fold_char(0'ø, "o").
fold_char(0'ù, "u").
fold_char(0'ú, "u").
fold_char(0'û, "u").
fold_char(0'ü, "u").
fold_char(0'ý, "y").
fold_char(0'þ, "th").
fold_char(0'ÿ, "y").
fold_char(0'Ā, "A").
fold_char(0'ā, "a").
fold_char(0'Ă, "A").
fold_char(0'ă, "a").
fold_char(0'Č, "C").
fold_char(0'č, "c").
fold_char(0'Ę, "E").
fold_char(0'ę, "e").
fold_char(0'ě, "e").
fold_char(0'ğ, "g").
fold_char(0'ġ, "g").
fold_char(0'Ħ, "H").
fold_char(0'ħ, "h").
fold_char(0'ĩ, "i").
fold_char(0'Į, "I").
fold_char(0'į, "i").
fold_char(0'İ, "I").
fold_char(0'ı, "i").
fold_char(0'Ł, "L").
fold_char(0'ł, "l").
fold_char(0'ń, "n").
fold_char(0'Ō, "O").
fold_char(0'ō, "o").
fold_char(0'ŏ, "o").
fold_char(0'Œ, "OE").
fold_char(0'œ, "oe").
fold_char(0'Ş, "S").
fold_char(0'ş, "s").
fold_char(0'Š, "S").
fold_char(0'š, "s").
fold_char(0'Ū, "U").
fold_char(0'ū, "u").
fold_char(0'Ÿ, "Y").
fold_char(0'ź, "z").
fold_char(0'Ž, "Z").
fold_char(0'ž, "z").
fold_char(0'ș, "s").
fold_char(0'ț, "t").
fold_char(0'ế, "e").
