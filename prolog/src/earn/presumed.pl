:- module(earn_presumed, [presumed_classes/3, presumption/3]).

/** <module> The class an Explorer fare is sold in, when the itinerary did not say.

    An itinerary that names a cabin has said more than it looks like it has.
    Section 5(b) publishes, per carrier, the class an Explorer fare books into in
    each cabin, so "business on CX" is `D` (or `I` on an IONE3 fare) and not a
    question. Every earning table is read against a class; without this, an
    itinerary that gave a cabin and no class was unpriceable in both programmes,
    which is a worse answer than the one the tariff already contains.

    Three things about it are deliberate.

    *The applicable codes only.* 5(b)'s notes also permit a lower cabin's own
    code, `Y` on a First fare and `B` or `H` on a DONE Business fare -- but every
    one of those turns on what the *flight* offers, which an itinerary cannot
    show. Presuming one would be guessing at a seat map; presuming the applicable
    code is reading the fare.

    *Economy comes out as `L`, not `Y`.* `Y` is the conventional shorthand for an
    economy cabin and it is not what this fare books into: 5(b) puts an economy
    Explorer fare in `L` on every carrier that publishes a row. The difference is
    not cosmetic -- on Cathay metal `L` is the M,L,V group and `Y` is the top one,
    and on the Qantas table `L` is Discount Economy where `Y` is Flexible
    Economy, so presuming `Y` would overstate the earn by roughly double. Wrong
    high is the bad direction for an estimate.

    *It never reaches rule 5(b).* The rule checks the class that was booked, and
    a presumed class would let it report a pass it never checked. This is the
    earning side reading the tariff to fill a gap in an estimate, which is a
    different thing from a validator inventing evidence.
*/

:- use_module('../../data/booking_codes').
:- use_module(library(apply)).
:- use_module(library(yall)).

%! presumed_classes(+S, +Cabin, -Classes) is det.
%  Empty when the marketing carrier is unknown or 5(b) publishes no row for it,
%  which leaves the sector undecided rather than presumed.
presumed_classes(S, Cabin, Classes) :-
    Carrier = S.marketing,
    (   Carrier \== unknown,
        carrier_has_codes(Carrier)
    ->  explorer_classes(Carrier, S.from_country, S.to_country, Cabin, Classes)
    ;   Classes = []
    ).

%! presumption(+Cabin, +Classes, -Reason) is det.
%  What the register says in place of a class the traveller gave. It names the
%  codes rather than the conclusion, so a reader who knows the fare can see at
%  once whether the presumption is the one they would have made.
presumption(Cabin, Classes, Reason) :-
    maplist([C, U]>>upcase_atom(C, U), Classes, Upper),
    atomic_list_concat(Upper, ' or ', List),
    format(atom(Reason),
           'no class given; section 5(b) books ~w into ~w on this carrier',
           [Cabin, List]).
