:- module(earn_presumed, [presumed_classes/3, presumption/3]).

/** <module> The class an Explorer fare is sold in, when the itinerary did not say.

    An itinerary that names a cabin has said more than it looks like it has.
    Section 5(b) publishes, per carrier, the class an Explorer fare books into in
    each cabin, so "business on CX" is `D` and not a question. Every earning
    table is read against a class; without this, an itinerary written as a
    routing was unpriceable in both programmes, which is a worse answer than the
    one the tariff already contains.

    Four things about it are deliberate.

    *The applicable codes only.* 5(b)'s notes also permit a lower cabin's own
    code, `Y` on a First fare and `B` or `H` on a DONE Business fare -- but every
    one of those turns on what the *flight* offers, which an itinerary cannot
    show. Presuming one would be guessing at a seat map; presuming the applicable
    code is reading the fare.

    *The fare basis narrows it further, and has to.* 5(b) publishes two business
    columns, headed "Business — DONE*" and "Business — IONE3". Those are fare
    bases and not cabins: a DONE4 fare books into the DONE column, and the IONE3
    column describes a fare this itinerary is not. Asking for the cabin's columns
    instead returns both codes -- `D` and `I` on most carriers -- and on Qantas'
    own earning table those two sit in *different* categories, Business and
    Discount Business. The result was a sector reported undecided over an
    ambiguity the fare basis printed at the top of the same report had already
    settled. So the basis picks the column, and only where the itinerary has no
    published basis at all does the cabin's wider projection stand in.

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
    different thing from a validator inventing evidence. The rule keeps the
    cabin's projection for the same reason: a ticket presented in either business
    column is booked in a code 5(b) names, whatever basis this validator reports.
*/

:- use_module('../../data/booking_codes').
:- use_module('../../data/limits').
:- use_module('../pricing').
:- use_module('../phrasing').
:- use_module(library(apply)).
:- use_module(library(yall)).

%! presumed_classes(+S, +A, -Classes) is det.
%  Empty when the marketing carrier is unknown or 5(b) publishes no row for it,
%  which leaves the sector undecided rather than presumed.
presumed_classes(S, A, Classes) :-
    Carrier = S.marketing,
    (   Carrier \== unknown,
        carrier_has_codes(Carrier)
    ->  (   reported_basis(A, Basis),
            basis_classes(Carrier, S.from_country, S.to_country, Basis, Codes)
        ->  Classes = Codes
        ;   explorer_classes(Carrier, S.from_country, S.to_country, A.cabin, Classes)
        )
    ;   Classes = []
    ).

%! reported_basis(+A, -Basis) is semidet.
%  The fare basis this report prints, and fails where there is none -- fewer
%  than three continents has no published basis, and rule 0 raises that as an
%  error rather than this quietly presuming a column.
reported_basis(A, Basis) :-
    continent_count(A, _, N),
    fare_basis(A.cabin, N, Basis).

%! presumption(+A, +Classes, -Reason) is det.
%  What the register says in place of a class the traveller gave. It names the
%  codes and the fare they were read off rather than the conclusion, so a reader
%  who knows the fare can see at once whether the presumption is the one they
%  would have made.
presumption(A, Classes, Reason) :-
    maplist([C, U]>>upcase_atom(C, U), Classes, Upper),
    atomic_list_concat(Upper, ' or ', List),
    (   reported_basis(A, Basis)
    ->  article(Basis, lower, Fare),
        format(atom(Reason),
               'no class given; section 5(b) books ~w fare into ~w on this carrier',
               [Fare, List])
    ;   format(atom(Reason),
               'no class given; section 5(b) books ~w into ~w on this carrier',
               [A.cabin, List])
    ).
