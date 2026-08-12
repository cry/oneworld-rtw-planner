:- module(earn_cx, []).

/** <module> Asia Miles, as a kernel plugin.

    This programme is the interface's audit. It was written second, deliberately
    against a kernel built around Qantas, to find out what that kernel had
    assumed. It forced exactly one change -- ranges -- and that change is
    recorded in PLANS/05 rather than absorbed quietly. It has since been rebuilt
    against a far larger capture without forcing a second one, which is the
    stronger result of the two.

    *Two earning models inside one programme.* Cathay's own flights earn fixed
    Status Points per distance zone and Asia Miles at exactly a hundred times the
    points. Every one of its 25 partners earns fixed Status Points per zone and
    Asia Miles as a *percentage of the distance flown* -- and off a band set with
    one more boundary in it, at 3,700 miles, which Cathay's own table does not
    have. Reading a partner against Cathay's bands returns a plausible number
    from the wrong row on every sector between 2,751 and 5,000 miles, so the
    scheme travels on the airline and is an argument to every zone fact rather
    than an assumption anywhere.

    That is also the reason accrual/5 returns an expression rather than a number:
    `fixed(70)` and `pct(125)` reach the reader down one path. It is not a
    hypothetical about a third programme; it is two halves of the second one.

    *The marketing carrier picks the table, and the operator picks the card.* A
    QF flight number flown on an Emirates aircraft reads the QF rows. But a CX
    flight number is priced twice over: on Cathay metal Economy splits into Flex,
    Essential and Light, and on a partner's metal it earns the Codeshare card
    instead -- which is numerically identical to Economy Light in every band, and
    which Premium Economy, Business and First do not have at all. So a codeshare
    in a premium cabin is unknown here rather than quietly priced off the
    Cathay-operated figure, and a Cathay flight number with no operator named
    cannot be answered at all.

    *Three ways to have no answer, and none of them is a zero.* A class in no fare
    group is refused outright and never priced off a neighbouring class, because
    within one cabin the rates differ by up to three times -- Japan Airlines'
    Business group B is 125% and its group G is 70%. A distance band nobody
    sampled carries no Status Points rate at all, so the kernel reports it
    undecided beside a mileage figure that is known, and the zone label says which
    airline was sampled where. And two fare groups exist in their carriers'
    definitions with no rate at any distance and no percentage either, which is
    said in those terms. Against all three, nine carriers earn a real, measured
    zero -- they are exactly the non-oneworld partners -- printed as the 0 it is.

    *The fare group is the unit, not the booking class.* Every class in a group
    earns identically, and the membership comes from each carrier's published fare
    groups rather than from the sampling. That matters because the earlier capture
    derived it from the calculator's one representative class per group, and the
    representative is sometimes not a member of the group it names: it invented
    classes and dropped real ones on two airlines. Two of them also price the same
    class differently by whether the sector stays inside one country, so
    (airline, cabin, class) is not a key -- see prefer_scope/3.

    *The bucket stayed opaque, and the basis did the work.* American is the one
    airline whose mile percentage varies: 150% where both airports are in the
    same country and 125% otherwise. That is a fact about the sector rather than
    about the fare, and it reached the accrual as part of the route basis without
    widening the protocol -- which is what the resolvers-take-the-segment rule in
    the kernel was for.

    The one thing this programme did force, and still does. Cathay lists the same
    economy booking classes -- Y,B,H,K, then M,L,V, then S,N,Q,O -- under Flex,
    Essential *and* Light, with different earn against each. A ticket in K on an
    ultra-short sector earns 25 Status Points as Flex, 15 as Essential and 10 as
    Light. So the class does not imply the card and there is nothing to derive
    one from: an itinerary that gives a class and no `fareFamily` has genuinely
    bought one of three things. Refusing to answer would be useless and picking
    one would be a guess wearing the same clothes as an answer, so the bucket
    comes back as `one_of/2` and the kernel prices every candidate and reports
    the spread.

    That is confined to Cathay's own Economy, and to part of it. Y is full-fare
    and therefore the flexible fare whatever the grid lists it under -- the one
    place in either programme where a fact that is not on the page decides an
    answer, which is why it is a predicate of its own, cx_class_settled/3,
    carrying its reason into the register. B, H and K are not settled that way
    and stay a range. Everywhere else -- every other Cathay cabin, and every
    partner in every cabin -- a class picks its card out on its own.
*/

:- use_module('../geo').
:- use_module(presumed).
:- use_module('../../data/earn/cx/airlines').
:- use_module('../../data/earn/cx/buckets').
:- use_module('../../data/earn/cx/zones').
:- use_module('../../data/earn/cx/table_cx').
:- use_module('../../data/earn/cx/source').
:- use_module(library(apply)).
:- use_module(library(lists)).

:- multifile earn_kernel:earn_program/3.
:- multifile earn_kernel:currency/4.
:- multifile earn_kernel:eligible/4.
:- multifile earn_kernel:fare_bucket/5.
:- multifile earn_kernel:route_basis/5.
:- multifile earn_kernel:route_basis_edges/3.
:- multifile earn_kernel:accrual/5.
:- multifile earn_kernel:program_source/3.
:- multifile earn_kernel:program_note/2.
:- multifile earn_kernel:term_label/2.
:- multifile earn_kernel:fare_family/2.

earn_kernel:earn_program(cx, 'Cathay', cx).

% What a caller may put in `fareFamily`. Served from /api/programs so a page can
% offer the choice without knowing a programme's name. Codeshare is a card and
% not one of these: it is settled by who operates the flight rather than by what
% was bought.
earn_kernel:fare_family(cx, Family) :- cx_family(Family, _).

% Two currencies, and on Cathay's own metal they come out of one number -- every
% Cathay row has Asia Miles at exactly a hundred times Status Points. No partner
% row does, which was the error in the first version of this capture and is the
% reason the relationship is a Cathay rule here rather than a checksum over the
% whole table. They stay separate because they are two things a member holds and
% only one of them is what a membership tier is measured in.
earn_kernel:currency(cx, asia_miles, 'Asia Miles',
                     [ rounding(nearest), scope(per_segment), bonus_applies(true) ]).
earn_kernel:currency(cx, status_points, 'Status Points',
                     [ rounding(nearest), scope(per_segment), bonus_applies(false) ]).

% --- eligibility -----------------------------------------------------------

% Asia Miles publishes earning for 26 airlines and nothing outside them earns at
% all, which is `ineligible` -- a fact about the ticket -- rather than a gap in
% this table. The one thing that cannot be settled is a Cathay flight number
% whose operator is not named: Cathay's own card and its codeshare card are
% different rates, and in three cabins out of four the codeshare card does not
% exist.
earn_kernel:eligible(cx, S, _A, Outcome) :-
    Marketing = S.marketing,
    (   Marketing == unknown
    ->  Outcome = indeterminate('No marketing carrier, so there is no earning table to read this segment against.')
    ;   \+ cx_airline(Marketing, _, _)
    ->  iata(Marketing, U),
        format(atom(Why),
               'Asia Miles publishes no earning for ~w, which is neither Cathay nor one of its 25 partners.',
               [U]),
        Outcome = ineligible(Why)
    ;   Marketing == cx,
        S.operating == unknown
    ->  Outcome = indeterminate('A Cathay flight number earns one rate on Cathay metal and another on a partner\'s, and the operating carrier is not given.')
    ;   Outcome = eligible
    ).

% --- which card -------------------------------------------------------------

%! metal(+S, -Metal) is det.
%  Which set of cards this segment reads against. Only a Cathay flight number has
%  two, and eligible/4 has already refused the case where the operator is unknown.
metal(S, Metal) :-
    (   S.marketing == cx, S.operating \== cx
    ->  Metal = codeshare
    ;   Metal = own
    ).

earn_kernel:fare_bucket(cx, S, A, Bucket, Basis) :-
    Airline = S.marketing,
    cx_airline(Airline, _, _),
    metal(S, Metal),
    Family = S.fare_family,
    (   Family \== unknown,
        \+ cx_family(Family, _)
    ->  findall(F, cx_family(F, _), Known),
        atomic_list_concat(Known, ', ', List),
        format(atom(Why), 'Cathay has no fare family called ~w. It publishes ~w.', [Family, List]),
        Bucket = indeterminate(Why),
        Basis = null
    ;   Class = S.booking_class,
        Class \== unknown
    ->  candidates(Airline, Metal, S, A.cabin, Family, Class, Cards),
        resolve(Airline, Metal, Family, Class, Cards, Bucket, Basis)
    ;   % No class given, so the fare's own is used -- see src/earn/presumed.pl.
        presumed_classes(S, A, Presumed),
        Presumed \== [],
        presumption(A, Presumed, Why)
    ->  findall(Card,
                ( member(C, Presumed), candidates(Airline, Metal, S, A.cabin, Family, C, Cs), member(Card, Cs) ),
                Cards0),
        sort(Cards0, Cards),
        resolve_presumed(Cards, Why, Bucket, Basis)
    ;   Bucket = indeterminate('The class this segment is sold in is not given, and no 5(b) row says what this fare books into on this carrier.'),
        Basis = null
    ).

%! candidates(+Airline, +Metal, +S, +Cabin, +Family, +Class, -Cards) is det.
candidates(Airline, Metal, S, Cabin, Family, Class, Cards) :-
    findall(fare(Airline, RowCabin, Brand, Group, Scope),
            (   cx_class(Airline, RowCabin, Brand, Group, Scope, Class),
                metal_brand(Metal, Brand),
                brand_allowed(Airline, Metal, RowCabin, Family, Class, Brand)
            ),
            Cards0),
    sort(Cards0, Cards1),
    reach(S, Reach),
    include(scope_allows(Reach), Cards1, Usable),
    prefer_cabin(Cabin, Usable, Cards2),
    prefer_scope(Reach, Cards2, Cards).

% Two airlines file the same class in two fare groups and price them apart by
% whether the sector stays inside one country: Japan Airlines' Economy Y is
% group F at 100% internationally and group H at 50% at home, and its First F is
% 150% or 125% the same way. Every other airline files `all` and only, so this
% does nothing at all for 24 of the 26.
%
% Scope narrows in two places, either side of the cabin, and the order is what
% makes both right. A card scoped to the other reach is never a candidate --
% a domestic-only group must not price an international sector -- so that filter
% runs first. The *preference* for an exactly-scoped card over an `all` one runs
% last, after the cabin: Japan Airlines files J in Business at 125% and again in
% its domestic Economy group, and a domestic business ticket in J is a business
% ticket. Preferring the scope first read it as economy.
prefer_scope(Reach, Cards, Kept) :-
    include(in_scope(Reach), Cards, Exact),
    Exact \== [],
    !,
    Kept = Exact.
prefer_scope(_, Cards, Cards).

scope_allows(_, fare(_, _, _, _, all)) :- !.
scope_allows(Reach, fare(_, _, _, _, Reach)).

in_scope(Reach, fare(_, _, _, _, Reach)).

% Cathay's Codeshare card is not available to its own metal, and its own three
% Economy cards are not available to a partner's.
metal_brand(codeshare, codeshare) :- !.
metal_brand(codeshare, _) :- !, fail.
metal_brand(own, Brand) :- Brand \== codeshare.

% Two things can narrow the brand, and both are only meaningful where there is
% more than one brand to narrow between -- Cathay's own Economy, and nowhere
% else. A partner has no fare brands at all, so a family left set in a picker is
% quietly irrelevant there rather than an error, and Y meaning "the flexible
% fare" is a statement about a choice a partner never offers.
brand_allowed(Airline, Metal, Cabin, Family, Class, Brand) :-
    (   \+ branded(Airline, Metal, Cabin)
    ->  true
    ;   Family \== unknown
    ->  cx_family(Family, Brand)
    ;   cx_class_settled(Class, Settled, _)
    ->  Brand == Settled
    ;   true
    ).

branded(Airline, Metal, Cabin) :-
    findall(B, ( cx_row(Airline, Cabin, B, _, _), metal_brand(Metal, B) ), Brands0),
    sort(Brands0, Brands),
    Brands = [_, _|_].

% A class can sit in two cabins on the same airline -- Japan Airlines files A in
% First and again in Economy -- and the cabin the fare was sold in tells them
% apart. Only where it does: a Cathay ticket in W on a Business fare is a
% Premium Economy seat and there is no Business card listing W, so the filter
% that would empty the set is not applied. The cabin narrows an answer here and
% never removes the only one.
prefer_cabin(Cabin, Cards, Matching) :-
    include(in_cabin(Cabin), Cards, Matching),
    Matching \== [],
    !.
prefer_cabin(_, Cards, Cards).

in_cabin(Cabin, fare(_, Cabin, _, _, _)).

% Nothing lists this class. Which of the three reasons it is matters to the
% reader, and only the first is anything they can act on.
resolve(_, codeshare, _, Class, [], indeterminate(Why), null) :-
    !,
    upcase_atom(Class, U),
    findall(Label, ( cx_codeshare_brand(Cabin, _), cx_cabin_label(Cabin, Label) ), Cabins),
    atomic_list_concat(Cabins, ', ', List),
    format(atom(Why),
           'A Cathay flight number on a partner aircraft earns the Codeshare card, which Cathay publishes for ~w only. Class ~w is not on it.',
           [List, U]).
% A class this airline prices only on the other kind of sector -- Japan
% Transocean files most of its Economy classes domestically and nothing else, so
% an international sector in one of them has a class the table knows and a rate it
% does not give. Named apart from the class it has never heard of, because they
% are different facts and only one of them is about this sector.
resolve(Airline, _, _, Class, [], indeterminate(Why), null) :-
    cx_class(Airline, _, _, _, Scope, Class),
    Scope \== all,
    !,
    upcase_atom(Class, U),
    cx_airline(Airline, Name, _),
    format(atom(Why),
           'Asia Miles prices class ~w on ~w only on ~w sectors, and this one is not.',
           [U, Name, Scope]).
% A class in no fare group at all. The class lists come from each carrier's
% published fare groups rather than from the sampling, so this is a fact about
% the table and not a hole in it -- and the sector stays undecided rather than
% borrowing a rate from a neighbouring class, because within one cabin the
% multipliers differ by up to three times. Japan Airlines' Business group B is
% 125% and its group G is 70%, so a substitution here would be a wrong answer
% dressed as a right one.
resolve(Airline, _, Family, Class, [], indeterminate(Why), null) :-
    !,
    upcase_atom(Class, U),
    cx_airline(Airline, Name, _),
    (   Family \== unknown
    ->  format(atom(Why), 'Cathay lists no earning for class ~w on a ~w fare.', [U, Family])
    ;   format(atom(Why),
               'Class ~w is in no ~w fare group Asia Miles publishes, so this sector cannot be priced. Rates differ by up to three times within one cabin, so no neighbouring class is used in its place.',
               [U, Name])
    ).
% A card the carrier defines and the sampling never reached: it has no rate at any
% distance and no percentage either. Two of them, and answering here rather than
% letting the accrual fail is what stops it reading as a route the table does not
% cover, which is a different problem with a different fix.
resolve(_, _, _, _, [Card], indeterminate(Why), null) :-
    cx_unpriced(Card, Note),
    !,
    earn_kernel:term_label(Card, Label),
    format(atom(Why), 'Asia Miles publishes the ~w card and no rate for it. ~w', [Label, Note]).
% How the card was settled travels with the answer, because "declared", "the
% operator decided it" and "there was only one it could be" are different degrees
% of confidence, and the register is where a reader checks which they were given.
resolve(Airline, Metal, Declared, Class, [Card], Card, Basis) :-
    !,
    Card = fare(_, Cabin, Brand, _, _),
    (   Metal == codeshare
    ->  Basis = 'a Cathay flight number on a partner aircraft'
    ;   Declared \== unknown, cx_family(Declared, Brand)
    ->  Basis = 'fare family declared'
    ;   branded(Airline, Metal, Cabin),
        cx_class_settled(Class, _, Reason)
    ->  Basis = Reason
    ;   Basis = 'the only card listing this class'
    ).
% More than one card lists this class and the input did not say which was bought.
% The kernel prices every candidate and reports the spread; naming the cards here
% is what lets the register say why the answer is a range.
resolve(_, _, _, Class, Cards, one_of(Cards, Why), null) :-
    card_brands(Cards, List),
    upcase_atom(Class, U),
    format(atom(Why),
           'Cathay lists class ~w under more than one fare brand (~w) with different earn against each, and no fareFamily was given. The figures span all of them.',
           [U, List]).

card_brands(Cards, List) :-
    findall(Label,
            ( member(fare(_, _, Brand, _, _), Cards), cx_brand_label(Brand, Label) ),
            Labels0),
    sort(Labels0, Labels),
    atomic_list_concat(Labels, ', ', List).

resolve_presumed([], Why, indeterminate(Reason), null) :-
    !,
    format(atom(Reason), 'Asia Miles lists no earning for the class this fare books into (~w).', [Why]).
resolve_presumed([Card], Why, Card, Why) :- !.
resolve_presumed(Cards, Why, one_of(Cards, Reason), null) :-
    format(atom(Reason),
           'The figures span every card this class could have been sold under: ~w.', [Why]).

% The card as the table publishes it: the brand it is filed under and the classes
% that share it. Either alone would be ambiguous -- Qantas files Economy twice,
% once for Y and once for everything below it -- and the pair is what a reader
% checks the number against.
earn_kernel:term_label(fare(Airline, Cabin, Brand, Group, Scope), Label) :-
    cx_brand_label(Brand, B),
    cx_group_label(Airline, Cabin, Group, Scope, G),
    format(atom(Label), '~w (~w)', [B, G]).
earn_kernel:term_label(zone(_, _, _, Label), Label).

% --- which zone -------------------------------------------------------------

% Three things a distance alone cannot decide, all of them here rather than in
% the accrual, because each is a fact about the sector: which scheme's bands to
% read, whether Cathay's 751-to-2,750 band is the standard card or the enhanced
% one, and -- for American alone -- whether both airports are in the same
% country.
earn_kernel:route_basis(cx, S, _A, Miles, Basis) :-
    Airline = S.marketing,
    cx_airline(Airline, Name, Scheme),
    reach(S, Reach),
    (   Scheme == cx,
        cx_override(S.from, S.to, Position, Note)
    ->  zone_label(Scheme, Position, Airline, Name, Label0),
        format(atom(Label), '~w — a published exception to the distance rule (~w)', [Label0, Note]),
        Basis = zone(Scheme, Position, Reach, Label)
    ;   zone_for(Scheme, S, Miles, Position)
    ->  zone_label(Scheme, Position, Airline, Name, Label),
        Basis = zone(Scheme, Position, Reach, Label)
    ;   format(atom(Why), 'No Asia Miles distance zone covers ~w miles.', [Miles]),
        Basis = indeterminate(Why)
    ).

zone_for(Scheme, S, Miles, Position) :-
    findall(P-Region,
            ( cx_zone(Scheme, P, Low, High, Region), in_zone(Miles, Low, High) ),
            Zones),
    (   Zones = [Position-_]
    ->  true
    ;   % The overlapping Cathay pair. The enhanced card is the qualified one and
        % the standard card is the residue, which is how the rule is written:
        % either endpoint in one of seven countries, and otherwise not.
        (   memberchk(P-enhanced, Zones), enhanced_sector(S)
        ->  Position = P
        ;   memberchk(Position-standard, Zones)
        )
    ),
    !.

in_zone(Miles, Low, High) :-
    Miles >= Low,
    ( High == inf -> true ; Miles =< High ).

enhanced_sector(S) :-
    ( Airport = S.from ; Airport = S.to ),
    airport_country(Airport, Country),
    cx_enhanced_country(Country),
    !.

% Whether both airports are in the same country. One row in the whole table turns
% on it -- American's Business card, at 150% against 125% -- and "domestic" there
% means the same country rather than inside the USA, so a New Zealand domestic
% sector on an AA flight number is domestic.
reach(S, Reach) :-
    (   airport_country(S.from, C),
        airport_country(S.to, C)
    ->  Reach = domestic
    ;   Reach = international
    ).

% What the sampling behind this table actually saw. A zone an airline was never
% sampled in is said so on the sector, because the alternative is a reader
% assuming a measured zero or a complete table -- and for the nine carriers that
% earn a real zero everywhere, an inferred zero and a measured one look identical
% on the page.
zone_label(Scheme, Position, Airline, Name, Label) :-
    cx_zone_label(Scheme, Position, Published),
    (   cx_coverage(Airline, Zones, Summary, _),
        \+ memberchk(Position, Zones)
    ->  format(atom(Label), '~w — ~w was sampled in ~w, so this band was never observed',
               [Published, Name, Summary])
    ;   Label = Published
    ).

earn_kernel:route_basis_edges(cx, zone(Scheme, _, _, _), Edges) :-
    cx_zone_edges(Scheme, Edges).

% Reach is `any` on every card but American's Business one, so it is tried and
% then fallen back on rather than written into all 942 rows.
earn_kernel:accrual(cx, Card, zone(_, Position, Reach, _), _Carrier, Rates) :-
    (   cx_rate(Card, Position, Reach, Found)
    ->  Rates = Found
    ;   cx_rate(Card, Position, any, Rates)
    ).

% --- provenance -------------------------------------------------------------

earn_kernel:program_source(cx, Table, Source) :- cx_source(Table, Source).
earn_kernel:program_note(cx, Note) :- cx_note(Note).
