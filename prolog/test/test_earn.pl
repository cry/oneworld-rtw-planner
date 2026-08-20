:- module(test_earn, []).

/** <module> Qantas Frequent Flyer earning, against hand-computed values.

    Conformance in test/earn/conformance.pl asserts the shape of a programme.
    This asserts the numbers, which is the part conformance cannot: every
    expected value below was read out of the published table by hand and the
    row it came from is named in the comment above it.

    The mutation tests are the same idea as the rule suite's -- change exactly
    one field and assert exactly one thing moves. A category table is a large
    flat mapping and the way it goes wrong is a letter landing in the wrong
    column, which a total would absorb and a per-segment assertion catches.
*/

:- use_module(library(plunit)).
:- use_module('../src/earn/kernel').
:- use_module('../src/earn/registry').
:- use_module('../src/earn/distance').
:- use_module('../src/annotate').
:- use_module('../src/io/json_in').
:- use_module('../src/io/earn_out').
:- use_module('../data/earn/cx/table_cx').
:- use_module('../data/earn/cx/buckets').
:- use_module('../data/earn/cx/zones').
:- use_module('../data/earn/cx/airlines').
:- use_module('../data/booking_codes').
:- use_module(library(lists)).

sector(Carrier, Class, From, To, Row) :-
    itinerary_from_json(
        _{ cabin: "business", mode: "routing",
           segments: [ _{ from: From, to: To, carrier: Carrier,
                          bookingClass: Class, stop: "stopover" },
                       _{ from: To, to: From, carrier: Carrier,
                          bookingClass: Class } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    !.

classless(Carrier, From, To, Cabin, Row) :-
    itinerary_from_json(
        _{ cabin: Cabin, mode: "routing",
           segments: [ _{ carrier: Carrier, from: From, to: To, stop: "stopover" },
                       _{ carrier: Carrier, from: To, to: From } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    !.

tiered(Carrier, From, To, Tier, Row) :-
    itinerary_from_json(
        _{ cabin: "business", mode: "routing",
           members: _{ qff: _{ tier: Tier } },
           segments: [ _{ carrier: Carrier, bookingClass: "D", from: From, to: To, stop: "stopover" },
                       _{ carrier: Carrier, bookingClass: "D", from: To, to: From } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    !.

amount(Row, Currency, Value) :-
    once(( member(Amt, Row.amounts), Amt.currency == Currency )),
    Value = Amt.value.

:- begin_tests(earn_qff).

% Partner earning table, "All other flights", row "2,501 to 3,500 miles",
% column Business: 4,000 Qantas Points and 100 Status Credits. D is BA's
% business class in the earn-category table.
test(a_business_sector_earns_the_published_band_rate) :-
    sector("BA", "D", "LHR", "JFK", Row),
    assertion(Row.outcome == ok),
    assertion(Row.bucket == 'Business'),
    assertion(Row.basis == '2,501 to 3,500 miles'),
    amount(Row, points, Points),
    amount(Row, status_credits, Credits),
    assertion(Points == 4000),
    assertion(Credits == 100).

% The same sector in M, which BA files under Discount Economy. Same band, same
% distance, one column left: 800 points and 25 Status Credits.
test(one_changed_class_moves_exactly_one_column) :-
    sector("BA", "D", "LHR", "JFK", Business),
    sector("BA", "M", "LHR", "JFK", Discount),
    assertion(Discount.basis == Business.basis),
    assertion(Discount.distance == Business.distance),
    assertion(Discount.bucket == 'Discount Economy'),
    amount(Discount, points, Points),
    amount(Discount, status_credits, Credits),
    assertion(Points == 800),
    assertion(Credits == 25).

% A class no carrier files anywhere is undecided, not zero, and the message
% names the carrier and the class so the reader can go and look.
test(an_unlisted_class_is_undecided) :-
    sector("BA", "Z", "LHR", "JFK", Row),
    assertion(Row.outcome == indeterminate),
    assertion(Row.amounts == []),
    assertion(sub_atom(Row.reason, _, _, _, 'BA')),
    assertion(sub_atom(Row.reason, _, _, _, 'Z')).

% Japan Airlines publishes a within-Japan row and does not fill it in. That is
% an earn the table cannot state, so it reaches the reader as undecided in the
% table's own words -- not as an absence of earn.
test(an_unfilled_row_carries_the_tables_own_words) :-
    sector("JL", "D", "HND", "ITM", Row),
    assertion(Row.outcome == indeterminate),
    assertion(sub_atom(Row.reason, _, _, _, 'Japan Airlines')).

% Malaysia Airlines files A under Business on its long-haul markets and under
% First everywhere else, and which applies needs the region tables phase 2
% adds. Naming both is a smaller claim than picking one.
test(a_route_dependent_category_is_undecided_until_phase_2) :-
    sector("MH", "A", "KUL", "LHR", Row),
    assertion(Row.outcome == indeterminate),
    assertion(sub_atom(Row.reason, _, _, _, 'Business or First')).

% Fiji Airways files a within-Fiji row that the endpoints alone decide, so it
% needs no region table and is decided now. Only Flexible Economy is published
% for it, so Y earns and D does not.
test(an_endpoint_scoped_row_is_decided_now) :-
    sector("FJ", "Y", "SUV", "NAN", Yes),
    assertion(Yes.outcome == ok),
    assertion(Yes.bucket == 'Flexible Economy'),
    assertion(Yes.bucketBasis == 'flights within Fiji'),
    sector("FJ", "D", "SUV", "NAN", No),
    assertion(No.outcome == indeterminate).

% A codeshare flown outside oneworld earns nothing at all, and that is `n/a`
% rather than undecided: the operator is known and the answer is no.
test(a_non_oneworld_operator_earns_nothing) :-
    itinerary_from_json(
        _{ cabin: "business", mode: "routing",
           segments: [ _{ from: "LHR", to: "JFK", marketingCarrier: "BA",
                          operatingCarrier: "AF", bookingClass: "D", stop: "stopover" },
                       _{ from: "JFK", to: "LHR", carrier: "BA", bookingClass: "D" } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    assertion(Row.outcome == not_applicable),
    assertion(sub_atom(Row.reason, _, _, _, 'outside oneworld')).

% Partner earning table, group "Between East Coast USA/Canada and …", row "West
% Coast USA/Canada", column Business: 3,125 Qantas Points and 100 Status
% Credits. The named pair takes precedence over the mileage band the same sector
% would otherwise fall in, which prices it at 2,500 and 80.
test(a_named_region_pair_beats_the_mileage_band) :-
    sector("AA", "D", "JFK", "LAX", Row),
    assertion(Row.outcome == ok),
    assertion(Row.basis == 'East Coast USA/Canada and West Coast USA/Canada'),
    amount(Row, points, Points),
    amount(Row, status_credits, Credits),
    assertion(Points == 3125),
    assertion(Credits == 100).

% "Between X and Y" is symmetric, and the table publishes each pair once.
test(a_region_pair_reads_the_same_both_ways) :-
    sector("AA", "D", "JFK", "LAX", Out),
    sector("AA", "D", "LAX", "JFK", Back),
    amount(Out, points, P1), amount(Back, points, P2),
    assertion(P1 == P2),
    assertion(Out.basis == Back.basis).

% A region is a set of *places*, matched on place_key/2, so a region naming New
% York covers Newark -- which is what the published table means by a city, and
% the same folding 4(i) and 4(c) are written in.
test(a_region_naming_a_city_covers_its_airports) :-
    sector("AA", "D", "EWR", "LAX", Row),
    assertion(Row.basis == 'East Coast USA/Canada and West Coast USA/Canada').

% Intra-USA Short Haul is a region group that is itself banded on distance --
% the reason route_basis/5 hands back an opaque basis rather than "a region
% pair, else a band". LAX-SFO is 338 miles: "Up to 400 miles", Business 400
% points and 40 Status Credits.
test(a_region_group_can_itself_be_banded) :-
    sector("AA", "D", "LAX", "SFO", Row),
    assertion(Row.outcome == ok),
    assertion(Row.basis == 'Intra-USA Short Haul, 1 to 400 miles'),
    amount(Row, points, Points),
    amount(Row, status_credits, Credits),
    assertion(Points == 400),
    assertion(Credits == 40).

% ...and above its top band it falls through to the global table, because the
% published group has no row for a longer intra-USA sector. BOS-MIA is 1,260
% miles: "751 to 1,500 miles", Business 1,375 points and 60 Status Credits.
test(a_longer_intra_usa_sector_falls_through_to_the_bands) :-
    sector("AA", "D", "BOS", "MIA", Row),
    assertion(Row.basis == '751 to 1,500 miles'),
    amount(Row, points, Points),
    assertion(Points == 1375).

% Qantas publishes ten categories for its own flights where every partner
% publishes six, splitting business and premium economy into discount, standard
% and flexible grades. A QF-marketed sector is priced off Qantas' own table and
% keeps all ten, so the grades are distinguishable rather than collapsed.
test(qantas_keeps_its_own_ten_categories) :-
    forall(member(Class-Bucket, ["I"-'Discount Business', "D"-'Business',
                                 "C"-'Flexible Business', "J"-'Flexible Business',
                                 "T"-'Discount Premium Economy',
                                 "R"-'Premium Economy',
                                 "W"-'Flexible Premium Economy',
                                 "A"-'First', "F"-'First']),
           (   sector("QF", Class, "SYD", "LAX", Row),
               assertion(Row.outcome == ok),
               assertion(Row.bucket == Bucket)
           )).

% The same ground, one sold by Qantas and one by a partner, is read off two
% different tables and earns two different numbers. Which table applies is
% decided by who sold the ticket, which is why route_basis/5 is handed the
% segment.
test(who_sold_it_decides_which_table_prices_it) :-
    sector("QF", "D", "SYD", "LAX", Own),
    sector("AA", "D", "SYD", "LAX", Partner),
    assertion(Own.distance == Partner.distance),
    amount(Own, points, OwnPoints),
    amount(Partner, points, PartnerPoints),
    assertion(OwnPoints == 14625),
    assertion(PartnerPoints == 13500),
    assertion(sub_atom(Own.basis, _, _, _, 'Adelaide')),
    assertion(sub_atom(Partner.basis, _, _, _, 'Sydney')).

% Qantas' own table bands Australian domestic sectors on distance. Short is
% 0-750 miles, Business 1,750 points and 40 Status Credits.
test(a_domestic_australian_sector_is_banded) :-
    sector("QF", "D", "SYD", "MEL", Row),
    assertion(Row.outcome == ok),
    assertion(sub_atom(Row.basis, _, _, _, 'Domestic Australia short')),
    amount(Row, points, Points),
    amount(Row, status_credits, Credits),
    assertion(Points == 1750),
    assertion(Credits == 40).

% An itinerary that names a cabin has said more than it looks like it has:
% section 5(b) publishes the class an Explorer fare books into, so a sector with
% no class is priced off the fare's own class rather than being refused.
test(a_missing_class_is_taken_from_the_fare) :-
    forall(member(Cabin-Bucket, ["economy"-'Discount Economy',
                                 "business"-'Business',
                                 "first"-'First']),
           (   classless("BA", "LHR", "JFK", Cabin, Row),
               assertion(Row.outcome == ok),
               assertion(Row.bucket == Bucket),
               assertion(sub_atom(Row.bucketBasis, _, _, _, 'section 5(b)'))
           )).

% Economy comes out as L, which is what 5(b) says an economy Explorer fare books
% into -- not Y, which is the conventional shorthand for the cabin and a
% different, much better-earning class. On the Qantas table L is Discount
% Economy and Y is Flexible Economy, so the difference is roughly double.
test(economy_is_presumed_as_l_not_y) :-
    classless("BA", "LHR", "JFK", "economy", Presumed),
    sector("BA", "L", "LHR", "JFK", Stated),
    amount(Presumed, points, P1),
    amount(Stated, points, P2),
    assertion(P1 == P2),
    sector("BA", "Y", "LHR", "JFK", Flexible),
    amount(Flexible, points, P3),
    assertion(P3 > P1).

% ...and the *fare basis* picks which business column, which the cabin cannot.
% 5(b) heads its two business columns "Business — DONE*" and "Business — IONE3",
% and those are fare bases rather than cabins: a DONE4 fare books into D, and the
% IONE3 column describes a fare this itinerary is not. Asking for the cabin's
% columns returned D and I, which on Qantas' own table are Business and Discount
% Business -- so every classless QF business sector came back undecided over an
% ambiguity the fare basis at the top of the same report had already settled.
test(a_business_fare_is_presumed_from_its_basis_not_its_cabin) :-
    itinerary_from_json(
        _{ route: "LON-BA-NYC-AA-X/DFW-AA-LAX-QF-SYD//MEL-QF-X/SIN-BA-LON",
           cabin: "business" },
        Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    Report.programs = [P],
    % Every flown sector prices, and the total is not a lower bound.
    forall(( member(Row, P.segments), Row.type == flight ),
           assertion(Row.outcome == ok)),
    forall(member(Total, P.totals), assertion(Total.lowerBound == false)),
    % The two QF-marketed ones are what used to fail, and the register names the
    % fare it read the class off rather than only the cabin.
    member(Row4, P.segments), Row4.segment == 4, !,
    assertion(Row4.bucket == 'Business'),
    assertion(sub_atom(Row4.bucketBasis, _, _, _, 'a DONE4 fare into D')).

% Economy and First are untouched by that, because 5(b) publishes one column for
% each: LONE4 names the Economy column and AONE4 the First one, which are the
% same columns the cabin was already reaching.
test(the_other_cabins_read_the_same_column_either_way) :-
    forall(member(Cabin-Basis-Code, ["economy"-'LONE4'-'L', "first"-'AONE4'-'A']),
           (   priced_route("LON-BA-NYC-AA-X/DFW-AA-LAX-QF-SYD//MEL-QF-X/SIN-BA-LON",
                            Cabin, 4, Row),
               assertion(Row.outcome == ok),
               format(atom(Phrase), '~w fare into ~w on this carrier', [Basis, Code]),
               assertion(sub_atom(Row.bucketBasis, _, _, _, Phrase))
           )).

% A journey with fewer than three continents has no published fare basis at all
% -- rule 0 raises that as an error -- so there is nothing to narrow the column
% with and the cabin's wider projection stands in. Named rather than left to be
% discovered, because it is the one input where the two projections still differ.
test(a_fare_with_no_published_basis_falls_back_to_the_cabin) :-
    classless("QF", "SYD", "LAX", "business", Row),
    assertion(Row.outcome == ok),
    assertion(sub_atom(Row.assumption, _, _, _, 'books business into D or I')),
    % ...which is exactly the input the safety net exists for: D and I earn in
    % two categories on Qantas' own table, so the answer is the spread rather
    % than the refusal this used to be.
    amount(Row, points, Points),
    assertion(Points = range(_, _)).

priced_route(Route, Cabin, N, Row) :-
    itinerary_from_json(_{ route: Route, cabin: Cabin }, Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    Report.programs = [P],
    member(Row, P.segments),
    Row.segment == N,
    !.

% Where one column still leaves two categories, the answer is the spread and not
% a refusal. Malaysia files A in both Business and First, so a classless First
% fare on MH books into a code that earns two ways -- and pricing both is the
% same posture the Cathay resolver takes over a class listed under three fare
% brands, down the same kernel path.
test(a_code_that_earns_two_ways_gives_the_spread) :-
    classless("MH", "KUL", "LHR", "first", Row),
    assertion(Row.outcome == ok),
    assertion(Row.bucket == 'Business or First'),
    amount(Row, points, Points),
    assertion(Points = range(_, _)),
    Points = range(Low, High),
    assertion(Low < High),
    assertion(sub_atom(Row.assumption, _, _, _, 'the figures span both')).

% Qantas pays its status bonus on Qantas-marketed sectors and not on partner
% ones, so the same journey carries a bonus on one sector and none on the next.
% That is why bonus/6 is handed the segment and not only the tier.
test(the_status_bonus_is_a_qantas_flight_benefit) :-
    tiered("QF", "SYD", "LAX", gold, Own),
    tiered("QF", "SYD", "LAX", bronze, OwnBase),
    amount(Own, points, OwnPoints),
    amount(OwnBase, points, BasePoints),
    assertion(OwnPoints =:= round(BasePoints * 1.75)),
    once(( member(A, Own.amounts), A.currency == points )),
    assertion(A.bonus > 0),
    % The same tier over a partner-marketed sector gets nothing: the bonus is a
    % benefit of flying Qantas, not of holding the card.
    tiered("AA", "SYD", "LAX", gold, Partner),
    once(( member(B, Partner.amounts), B.currency == points )),
    assertion(B.bonus == 0),
    assertion(Partner.outcome == ok).

% Status Credits declare bonus_applies(false), so no tier reaches them. It is
% the currency's own flag rather than anything the kernel or the tier table
% decides.
test(status_credits_take_no_tier_bonus) :-
    forall(member(Tier, [bronze, silver, gold, platinum, platinum_one]),
           (   tiered("QF", "SYD", "LAX", Tier, Row),
               once(( member(A, Row.amounts), A.currency == status_credits )),
               assertion(A.bonus == 0)
           )),
    tiered("QF", "SYD", "LAX", bronze, Base),
    tiered("QF", "SYD", "LAX", platinum, Top),
    amount(Base, points, BasePoints),
    amount(Top, points, TopPoints),
    assertion(TopPoints =:= BasePoints * 2).

% A tier nobody publishes is a caller error, not a silent base rate: a member
% who typed it and got the base rate back could not tell that from having no
% status at all.
test(an_unpublished_tier_is_refused, [throws(input_error(_))]) :-
    tiered("QF", "SYD", "LAX", platinum1, _).

:- end_tests(earn_qff).

% --- Asia Miles --------------------------------------------------------------
%
% Every expected value below is a cell of asia-miles-lookup.csv, named in the
% comment above it, and the five worked examples from the parsing guide are here
% under their own letters. The guide states the property a correct parser has:
% reproduce all five, refuse a Cathay-numbered Business ticket on partner metal,
% and report an unsampled band as unobserved rather than as a number.

cx_sector(Class, From, To, Cabin, Row) :-
    cx_sector('CX', Class, From, To, Cabin, Row).

cx_sector(Carrier, Class, From, To, Cabin, Row) :-
    itinerary_from_json(
        _{ cabin: Cabin, mode: "routing",
           segments: [ _{ carrier: Carrier, bookingClass: Class, from: From, to: To, stop: "stopover" },
                       _{ carrier: Carrier, bookingClass: Class, from: To, to: From } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [cx], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    !.

cx_family_sector(Class, Family, From, To, Cabin, Row) :-
    itinerary_from_json(
        _{ cabin: Cabin, mode: "routing",
           segments: [ _{ carrier: "CX", bookingClass: Class, fareFamily: Family,
                          from: From, to: To, stop: "stopover" },
                       _{ carrier: "CX", bookingClass: Class, fareFamily: Family,
                          from: To, to: From } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [cx], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    !.

% A Cathay flight number and a named operator, which is what tells its own metal
% from a partner's -- and the one thing this programme cannot answer without.
cx_metal_sector(Class, Operator, From, To, Cabin, Row) :-
    itinerary_from_json(
        _{ cabin: Cabin, mode: "routing",
           segments: [ _{ marketingCarrier: "CX", operatingCarrier: Operator,
                          bookingClass: Class, from: From, to: To, stop: "stopover" },
                       _{ marketingCarrier: "CX", operatingCarrier: Operator,
                          bookingClass: Class, from: To, to: From } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [cx], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    !.

:- begin_tests(earn_cx).

% --- the two models ---------------------------------------------------------

% Worked example B. CX / Economy / B H K Y / Economy Flex is 25;30;35;48;70;90,
% and HKG-CDG is zone 5. Cathay's own metal earns a fixed number of miles at
% exactly a hundred times the points.
test(cathay_metal_earns_a_fixed_amount) :-
    cx_family_sector("K", "flex", "HKG", "CDG", "economy", Row),
    assertion(Row.outcome == ok),
    assertion(Row.bucket == 'Economy Flex (Y B H K)'),
    assertion(Row.bucketBasis == 'fare family declared'),
    assertion(sub_atom(Row.basis, _, _, _, 'Zone 5')),
    amount(Row, status_points, Points),
    amount(Row, asia_miles, Miles),
    assertion(Points == 70),
    assertion(Miles == 7000).

% Worked example A, and the difference the whole rewrite turns on. A partner
% earns banded points and Asia Miles as a percentage of the distance flown, so
% the x100 relationship that holds over every Cathay row is false here: QF /
% Business / C D I J is 15;25;45;60;75;85 and HKG-SYD is zone 4, which is 60
% points and 125% of the distance rather than 6,000 miles.
test(a_partner_earns_a_share_of_the_distance) :-
    cx_sector('QF', "J", "HKG", "SYD", "business", Row),
    assertion(Row.outcome == ok),
    assertion(Row.bucket == 'Business (J C D I)'),
    amount(Row, status_points, Points),
    amount(Row, asia_miles, Miles),
    assertion(Points == 60),
    Expected is round(Row.distance * 125 / 100),
    assertion(Miles == Expected),
    assertion(Miles =\= Points * 100),
    % The guide's own figures, against our great circle rather than Cathay's
    % published sector mileage. Within a mile or two, which is the agreement the
    % capture measured over 745 pairs.
    assertion(abs(Row.distance - 4592) < 20),
    assertion(abs(Miles - 5740) < 30).

% The extra boundary. Partners band at 3,700 miles and Cathay does not, so a
% sector between 2,751 and 5,000 falls in zone 3 on a partner and zone 4 on
% Cathay -- the mistake the capture warns about, and the reason the scheme is an
% argument to every zone fact.
test(only_partners_have_a_3700_mile_boundary) :-
    cx_sector('BA', "J", "LHR", "JFK", "business", Partner),
    cx_sector("J", "HKG", "SYD", "business", Cathay),
    assertion(Partner.distance > 2750), assertion(Partner.distance < 3700),
    assertion(Cathay.distance > 2750), assertion(Cathay.distance < 5000),
    assertion(sub_atom(Partner.basis, _, _, _, 'Zone 3 (2,751-3,700 miles)')),
    assertion(sub_atom(Cathay.basis, _, _, _, 'Zone 4 (2,751-5,000 miles)')).

% --- the Cathay region split -------------------------------------------------

% The zone a distance alone cannot decide, and the reason route_basis/5 takes the
% endpoints. HKG-NRT is 1,841 miles and HKG-SIN is 1,594 -- the same 751-to-2,750
% band -- but Japan is one of the seven countries on the enhanced card and
% Singapore is not, so the same fare earns 35 points on one and 30 on the other.
test(the_same_band_splits_on_the_endpoints) :-
    cx_family_sector("K", "flex", "HKG", "NRT", "economy", Enhanced),
    cx_family_sector("K", "flex", "HKG", "SIN", "economy", Standard),
    assertion(sub_atom(Enhanced.basis, _, _, _, 'enhanced region')),
    assertion(\+ sub_atom(Standard.basis, _, _, _, 'enhanced')),
    amount(Enhanced, status_points, PE),
    amount(Standard, status_points, PS),
    assertion(PE == 35),
    assertion(PS == 30).

% Kazakhstan is on the enhanced list and is still missing from the six-country
% list on Cathay's own change notice, so the disagreement is asserted here rather
% than left to the generator's count. The calculator pays the enhanced card:
% HKG-ALA is 2,554 miles and returns 35 rather than the standard card's 30.
test(kazakhstan_is_on_the_enhanced_card) :-
    cx_family_sector("K", "flex", "HKG", "ALA", "economy", Row),
    assertion(sub_atom(Row.basis, _, _, _, 'enhanced region')),
    amount(Row, status_points, Points),
    assertion(Points == 35).

% A city pair whose card is not the one its distance predicts. Cathay publishes
% no reason for any of the four, so the override is applied before the distance
% is looked at and the register says it is an exception rather than explaining it.
test(an_override_beats_the_distance) :-
    cx_family_sector("Y", "flex", "HKG", "CZX", "economy", Row),
    assertion(Row.distance > 750),
    assertion(sub_atom(Row.basis, _, _, _, 'Zone 1')),
    assertion(sub_atom(Row.basis, _, _, _, 'exception to the distance rule')),
    amount(Row, status_points, Points),
    assertion(Points == 25).

% The same rule pulling the other way, and by four positions rather than one.
% Almaty-Astana is 591 miles, which predicts Zone 1, and Cathay pays the
% 5,001-7,500 card for it. Nothing about the sector explains that, which is why
% it is a written-down exception and why the figure is pinned here: the zone was
% recorded as 4 until the calculator was re-read on 2026-08-19.
%
% Astana is NQZ, and Cathay's capture still calls it TSE. The generator maps the
% retired code onto the one data/generated/airports.pl carries, because
% kernel.pl resolves coordinates *before* it consults a city pair -- so an
% override written under a code the geography does not know cannot fire at all,
% and the sector reads as undecided rather than as the exception it is. This
% test is the guard on that translation as much as on the zone.
test(an_override_can_raise_the_zone_as_well_as_lower_it) :-
    cx_family_sector("K", "flex", "ALA", "NQZ", "economy", Row),
    assertion(Row.outcome == ok),
    assertion(Row.distance < 750),
    assertion(sub_atom(Row.basis, _, _, _, 'Zone 5')),
    assertion(sub_atom(Row.basis, _, _, _, 'exception to the distance rule')),
    amount(Row, status_points, Points),
    assertion(Points == 70).

% --- who operates the flight -------------------------------------------------

% Worked example C. A Cathay flight number on partner metal earns the Codeshare
% card, which is numerically Economy Light in every band -- 40 points on zone 5
% rather than the 70 the same ticket earns on Cathay's own aircraft.
test(a_codeshare_earns_the_codeshare_card) :-
    cx_metal_sector("K", "BA", "HKG", "CDG", "economy", Codeshare),
    cx_metal_sector("K", "CX", "HKG", "CDG", "economy", Own),
    assertion(Codeshare.bucket == 'Codeshare (Y B H K)'),
    assertion(Codeshare.bucketBasis == 'a Cathay flight number on a partner aircraft'),
    amount(Codeshare, status_points, PC),
    assertion(PC == 40),
    % ...and the operator is the only thing that changed. Y is settled as Flex on
    % Cathay's own metal and there is no such choice on the codeshare card.
    amount(Own, status_points, PO),
    assertion(PO == range(40, 70)),
    assertion(PC \== PO).

% Cathay publishes a codeshare rate for Economy and for nothing else, so the
% premium cabins are unknown rather than quietly priced off the Cathay-operated
% figure. This is one of the three things the guide says a correct parser must do.
test(a_premium_codeshare_is_unknown_not_the_cathay_rate) :-
    cx_metal_sector("J", "BA", "HKG", "CDG", "business", Row),
    assertion(Row.outcome == indeterminate),
    assertion(Row.amounts == []),
    assertion(sub_atom(Row.reason, _, _, _, 'Codeshare card')),
    assertion(sub_atom(Row.reason, _, _, _, 'Economy only')).

% ...and a Cathay flight number with no operator named cannot be answered at all,
% because those two rates are what it is between.
test(a_cathay_flight_number_needs_its_operator) :-
    itinerary_from_json(
        _{ cabin: "economy", mode: "routing",
           segments: [ _{ marketingCarrier: "CX", bookingClass: "K", from: "HKG", to: "CDG", stop: "stopover" },
                       _{ carrier: "CX", bookingClass: "K", from: "CDG", to: "HKG" } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [cx], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    assertion(Row.outcome == indeterminate),
    assertion(Row.amounts == []),
    assertion(sub_atom(Row.reason, _, _, _, 'operating carrier is not given')).

% The marketing carrier picks the table and the operator does not, everywhere
% except Cathay's own flight numbers. A QF ticket flown by anyone reads the QF
% rows.
test(a_partner_reads_its_own_rows_whoever_flies_it) :-
    itinerary_from_json(
        _{ cabin: "business", mode: "routing",
           segments: [ _{ marketingCarrier: "QF", operatingCarrier: "EK",
                          bookingClass: "J", from: "HKG", to: "SYD", stop: "stopover" },
                       _{ carrier: "QF", bookingClass: "J", from: "SYD", to: "HKG" } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [cx], Report),
    Report.programs = [P],
    P.segments = [Row|_],
    assertion(Row.outcome == ok),
    amount(Row, status_points, Points),
    assertion(Points == 60).

% --- what is not observed, and what is a real zero ---------------------------

% Worked example D. Nine carriers earn Asia Miles and no Status Points at all,
% and they are exactly the non-oneworld partners. LH / Business / C D J Z is
% 0;0;0;0;0;0, which is a measured zero and prints as one.
test(a_zero_point_carrier_earns_a_real_zero) :-
    cx_sector('LH', "C", "FRA", "JFK", "business", Row),
    assertion(Row.outcome == ok),
    amount(Row, status_points, Points),
    assertion(Points == 0),
    amount(Row, asia_miles, Miles),
    Expected is round(Row.distance * 125 / 100),
    assertion(Miles == Expected).

% ...and a band nobody sampled is not that. American was sampled in zones 1-2 and
% 4-6, so its zone 3 cells are `?` in the capture, and a `?` reaches the reader as
% undecided rather than as a zero that would add correctly and read wrongly. The
% miles are still known, because they come off the distance rather than the band.
test(an_unsampled_band_is_undecided_not_zero) :-
    cx_sector('AA', "J", "LHR", "JFK", "business", Row),
    assertion(Row.outcome == ok),
    assertion(sub_atom(Row.basis, _, _, _, 'Zone 3')),
    assertion(sub_atom(Row.basis, _, _, _, 'never observed')),
    amount(Row, status_points, Points),
    assertion(Points == indeterminate),
    amount(Row, asia_miles, Miles),
    assertion(integer(Miles)),
    assertion(Miles > 0).

% The two are told apart on the page as well as in the term. Air New Zealand
% earns a real zero everywhere and was sampled only in zone 5, so its zone 1
% figure is an inferred zero -- and the band says so, which is the difference
% between a zero a reader can rely on and one nobody measured.
test(an_inferred_zero_says_it_was_never_sampled) :-
    cx_sector('NZ', "B", "AKL", "CHC", "economy", Inferred),
    cx_sector('NZ', "B", "AKL", "SIN", "economy", Observed),
    amount(Inferred, status_points, PI),
    amount(Observed, status_points, PO),
    assertion(PI == 0),
    assertion(PO == 0),
    assertion(sub_atom(Inferred.basis, _, _, _, 'never observed')),
    assertion(\+ sub_atom(Observed.basis, _, _, _, 'never observed')).

% --- fare brands --------------------------------------------------------------

% The one thing this programme forces on the kernel. Cathay lists Y,B,H,K under
% Flex (70), Essential (60) and Light (40) on zone 5, and the class cannot tell
% them apart -- so the answer is the spread and the register says why.
test(an_undeclared_brand_gives_the_spread) :-
    cx_sector("K", "HKG", "CDG", "economy", Row),
    assertion(Row.outcome == ok),
    amount(Row, status_points, Points),
    assertion(Points == range(40, 70)),
    amount(Row, asia_miles, Miles),
    assertion(Miles == range(4000, 7000)),
    assertion(sub_atom(Row.assumption, _, _, _, 'more than one fare brand')).

% Y is full-fare economy, so it is the flexible fare whatever the grid lists it
% under. It is the one place in either programme where a fact that is not on the
% page decides an answer, so the register carries the reason rather than claiming
% the table settled it.
test(full_fare_economy_is_settled_as_flex) :-
    cx_sector("Y", "HKG", "CDG", "economy", Row),
    assertion(Row.outcome == ok),
    assertion(Row.bucket == 'Economy Flex (Y B H K)'),
    assertion(sub_atom(Row.bucketBasis, _, _, _, 'full-fare economy')),
    assertion(Row.assumption == null),
    amount(Row, status_points, Points),
    assertion(Points == 70).

% ...and only where there is a brand to settle. British Airways files one Economy
% card for B, H and Y, so Y there is not a statement about flexibility and the
% register must not pretend it decided anything.
test(the_settled_class_is_a_cathay_fact_only) :-
    cx_sector('BA', "Y", "HKG", "BKK", "economy", Row),
    assertion(Row.bucket == 'Economy (Y B H)'),
    assertion(Row.bucketBasis == 'the only card listing this class').

% Fare brands are Cathay's own Economy and nowhere else, so a family left set in
% a picker changes nothing on a card that has no brand axis. It is quietly
% irrelevant rather than an error: saying so on every sector it did not decide
% would be noise about a field that decided nothing.
test(a_brand_only_applies_where_there_is_one) :-
    cx_family_sector("D", "light", "HKG", "CDG", "business", Declared),
    cx_sector("D", "HKG", "CDG", "business", Plain),
    assertion(Declared.outcome == ok),
    assertion(Declared.bucket == 'Business (D P I)'),
    amount(Declared, status_points, PD),
    amount(Plain, status_points, PP),
    assertion(PD == 100),
    assertion(PD == PP).

% A family the programme does not publish is refused rather than ignored, which
% is the same call check_tier/2 makes about a tier: a caller who mistyped it and
% got the base answer back could not tell that from having declared nothing.
test(an_unpublished_fare_brand_is_refused) :-
    cx_family_sector("K", "premium", "HKG", "CDG", "economy", Row),
    assertion(Row.outcome == indeterminate),
    assertion(sub_atom(Row.reason, _, _, _, 'no fare family called premium')).

% Outside Economy a class picks its card out on its own, so no range arises. The
% two Business cards are the C,J one and the D,I,P one, which the old capture read
% as two fare families and this one does not name at all.
test(a_premium_cabin_class_picks_its_own_card) :-
    forall(member(Class-Cabin-Card-Points,
                  ["J"-"business"-'Business (J C)'-130,
                   "D"-"business"-'Business (D P I)'-100,
                   "F"-"first"-'First (F A)'-160,
                   "W"-"business"-'Premium Economy (W R)'-80,
                   "E"-"business"-'Premium Economy (E)'-65]),
           (   cx_sector(Class, "HKG", "CDG", Cabin, Row),
               assertion(Row.outcome == ok),
               assertion(Row.bucket == Card),
               assertion(Row.assumption == null),
               amount(Row, status_points, P),
               assertion(P == Points)
           )).

% A class can sit in two cabins on one airline -- Japan Airlines files J in
% Business at 125% and again in its domestic Economy group at 50% -- and the cabin
% the fare was sold in is what tells them apart. The cabin narrows an answer here
% and never removes the only one: a Cathay ticket in W on a Business fare is still
% a Premium Economy seat, which the case above asserts.
test(a_class_in_two_cabins_is_settled_by_the_cabin) :-
    cx_sector('JL', "J", "HND", "CTS", "business", Business),
    cx_sector('JL', "J", "HND", "CTS", "economy", Economy),
    assertion(Business.bucket == 'Business (J C D I)'),
    assertion(Economy.bucket == 'Economy (J Y)'),
    amount(Business, asia_miles, MB),
    amount(Economy, asia_miles, ME),
    assertion(MB > 2.4 * ME).

% --- fare groups and scope ---------------------------------------------------

% Worked example A2, and the reason the class lists were rebuilt. Earning is
% priced per *fare group*, and D sits in Japan Airlines' Business group B with J,
% C and I at 125%. The previous capture derived class lists from the API's one
% representative class per group and recorded D as absent, which was an artefact
% of that method rather than a fact about the airline.
test(a_fare_group_prices_every_class_in_it) :-
    forall(member(Class, ["J", "C", "D", "I"]),
           (   cx_sector('JL', Class, "LAX", "NRT", "business", Row),
               assertion(Row.outcome == ok),
               assertion(Row.bucket == 'Business (J C D I)'),
               amount(Row, status_points, P),
               assertion(P == 75),
               amount(Row, asia_miles, M),
               assertion(abs(M - 6798) < 20)
           )).

% ...and the group beside it in the same cabin earns a third as much, which is
% why a class the table does not name is never priced off its neighbour.
test(two_groups_in_one_cabin_can_differ_threefold) :-
    cx_sector('JL', "D", "LAX", "NRT", "business", Full),
    cx_sector('JL', "X", "LAX", "NRT", "business", Discount),
    assertion(Discount.bucket == 'Business (X)'),
    amount(Full, status_points, PF),
    amount(Discount, status_points, PD),
    assertion(PF == 75),
    assertion(PD == 25),
    amount(Full, asia_miles, MF),
    amount(Discount, asia_miles, MD),
    assertion(MF > 1.7 * MD).

% Two airlines price the same class differently by whether the sector stays inside
% one country, so (airline, cabin, class) is not a key for them. Y is Japan
% Airlines' Economy group F at 100% abroad and its group H at 50% at home.
test(scope_splits_a_class_on_two_airlines) :-
    cx_sector('JL', "Y", "NRT", "LHR", "economy", Abroad),
    cx_sector('JL', "Y", "HND", "CTS", "economy", Home),
    assertion(Abroad.bucket == 'Economy (Y)'),
    assertion(Home.bucket == 'Economy (J Y)'),
    amount(Abroad, asia_miles, MA),
    amount(Home, asia_miles, MH),
    assertion(MA =:= Abroad.distance),
    assertion(MH =:= round(Home.distance / 2)),
    % First goes the same way: group A at 150% abroad, group B at 125% at home.
    cx_sector('JL', "F", "NRT", "LHR", "first", FirstAbroad),
    cx_sector('JL', "F", "HND", "CTS", "first", FirstHome),
    assertion(FirstAbroad.bucket == 'First (F A)'),
    assertion(FirstHome.bucket == 'First (F)').

% A card scoped to the other kind of sector is not a candidate at all. Japan
% Transocean files most of its Economy classes domestically and nowhere else, so
% an international sector in one of them is a class the table knows and a rate it
% does not give -- which is a different fact from a class it has never heard of,
% and says so.
test(a_domestic_only_card_does_not_price_an_international_sector) :-
    cx_sector('NU', "K", "OKA", "TPE", "economy", Row),
    assertion(Row.outcome == indeterminate),
    assertion(sub_atom(Row.reason, _, _, _, 'only on domestic sectors')).

% A class in no fare group at all. The lists come from each carrier's published
% fare groups rather than from sampling, so this is a fact about the table --
% and the sector stays undecided rather than borrowing the rate of a class beside
% it, which the case above shows can be three times wrong.
test(a_class_in_no_fare_group_is_refused_not_substituted) :-
    cx_sector('BA', "X", "LHR", "JFK", "economy", Row),
    assertion(Row.outcome == indeterminate),
    assertion(Row.amounts == []),
    assertion(sub_atom(Row.reason, _, _, _, 'in no British Airways fare group')),
    assertion(sub_atom(Row.reason, _, _, _, 'no neighbouring class is used')).

% Two fare groups exist in the carriers' own definitions and were never sampled
% at all, so they have no rate at any distance and no percentage either. The card
% is real and the answer is not, which is worth saying in those terms rather than
% letting it read as a route the table does not cover.
test(a_card_with_no_rate_anywhere_says_so) :-
    cx_sector('OS', "T", "VIE", "FRA", "economy", Row),
    assertion(Row.outcome == indeterminate),
    assertion(sub_atom(Row.reason, _, _, _, 'Economy (T L) card and no rate for it')).

% --- American's one conditional row ------------------------------------------

% The only percentage in the table that varies, and it varies on the sector
% rather than on the fare -- which is why it reaches the accrual as part of the
% route basis and needed no change to the kernel's protocol. Domestic means both
% airports in the same country, not inside the USA.
test(american_business_is_150_percent_at_home_and_125_abroad) :-
    cx_sector('AA', "J", "JFK", "LAX", "business", Domestic),
    cx_sector('AA', "J", "LHR", "JFK", "business", International),
    amount(Domestic, asia_miles, MD),
    amount(International, asia_miles, MI),
    ExpectedD is round(Domestic.distance * 150 / 100),
    ExpectedI is round(International.distance * 125 / 100),
    assertion(MD == ExpectedD),
    assertion(MI == ExpectedI).

% --- what is outside the programme -------------------------------------------

% Emirates is not one of the 26, and a sector on it earns no Asia Miles at all.
% That is `n/a` -- a fact about the ticket -- and not the undecided a missing
% table would give, which is the distinction the old Cathay-only implementation
% could not make and reported every partner as.
test(an_airline_outside_the_programme_earns_nothing) :-
    cx_sector('EK', "J", "DXB", "LHR", "business", Row),
    assertion(Row.outcome == not_applicable),
    assertion(Row.amounts == []),
    assertion(sub_atom(Row.reason, _, _, _, 'neither Cathay nor one of its 25 partners')).

% --- the tables themselves ---------------------------------------------------

% Asia Miles is exactly a hundred times Status Points on every Cathay row, and on
% no partner row. Asserting both halves is the point: the first version of this
% capture stated the relationship as a general invariant and recommended it as a
% parser checksum, which was wrong, and a table that quietly grew a fixed partner
% rate would otherwise look right.
test(the_x100_rule_is_cathays_and_only_cathays) :-
    findall(Card-Zone,
            (   cx_table:cx_rate(Card, Zone, _, Rates),
                Card = fare(cx, _, _, _, _),
                memberchk(rate(status_points, fixed(_)), Rates),
                \+ memberchk(rate(asia_miles, fixed(_)), Rates)
            ),
            NotFixed),
    assertion(NotFixed == []),
    findall(Card-Zone,
            (   cx_table:cx_rate(Card, Zone, _, Rates),
                Card = fare(cx, _, _, _, _),
                memberchk(rate(status_points, fixed(Points)), Rates),
                memberchk(rate(asia_miles, fixed(Miles)), Rates),
                Miles =\= Points * 100
            ),
            Broken),
    assertion(Broken == []),
    findall(Card,
            (   cx_table:cx_rate(Card, _, _, Rates),
                Card \= fare(cx, _, _, _, _),
                memberchk(rate(asia_miles, fixed(_)), Rates)
            ),
            PartnerFixed),
    assertion(PartnerFixed == []).

% Which carriers cannot price an Explorer fare at all, held as an exact list.
%
% Section 5(b) publishes the class this fare books into per carrier, so those are
% the codes this repository actually asks for. Malaysia files neither I nor L in
% any fare group, so a Malaysian sector on an IONE3 business fare or on any
% economy fare cannot be priced -- and that is now a fact about the table rather
% than a gap in the sampling, because the class lists come from each carrier's
% published fare groups.
%
% It was three carriers until the lists were rebuilt: Japan Airlines and Japan
% Transocean appeared to be missing D and L, which turned out to be an artefact of
% deriving class lists from one representative class per group.
%
% Asserted exactly, both ways: a second carrier appearing is a regression in the
% capture, and this one disappearing means Malaysia's groups grew and the list
% should lose its last line.
test(one_carrier_cannot_price_an_explorer_fare) :-
    findall(Airline-Missing,
            (   cx_airlines:cx_airline(Airline, _, _),
                booking_codes:carrier_has_codes(Airline),
                findall(Code,
                        (   booking_codes:booking_column(Column),
                            booking_codes:booking_code(Airline, _, Column, Code),
                            \+ cx_buckets:cx_class(Airline, _, _, _, _, Code)
                        ),
                        Missing0),
                sort(Missing0, Missing),
                Missing \== []
            ),
            Gaps0),
    sort(Gaps0, Gaps),
    assertion(Gaps == [mh-[i, l]]).

% Every card the class table can reach has a rate in every zone of its own
% scheme, unless it is one of the two the capture says was never sampled at all.
% A card with no row and no such note is a transcription error that would surface
% as an undecided sector the reader would take for their own fault.
test(every_card_prices_every_zone_of_its_scheme) :-
    findall(Card-Zone,
            (   cx_buckets:cx_row(Airline, Cabin, Brand, Group, Scope),
                Card = fare(Airline, Cabin, Brand, Group, Scope),
                \+ cx_table:cx_unpriced(Card, _),
                cx_airlines:cx_airline(Airline, _, Scheme),
                cx_zones:cx_zone(Scheme, Zone, _, _, _),
                \+ cx_table:cx_rate(Card, Zone, _, _)
            ),
            Missing),
    assertion(Missing == []),
    % ...and the two that have none say why, rather than being absent silently.
    findall(C, cx_table:cx_unpriced(C, _), Unpriced),
    assertion(length(Unpriced, 2)).

:- end_tests(earn_cx).

% --- distance ---------------------------------------------------------------

:- begin_tests(earn_distance).

% Great-circle distances against published figures for four well-known pairs,
% to 1%. Tighter than that would be asserting the airport table's coordinates
% rather than the arithmetic; looser would not catch a radius in the wrong unit,
% which is the mistake this is really guarding.
test(known_city_pairs) :-
    forall(member(From-To-Expected,
                  [ lhr-jfk-3451, jfk-lax-2475, hkg-lhr-5990, syd-lax-7488 ]),
           (   sector_distance(From, To, Miles),
               Slack is Expected * 0.01,
               assertion(abs(Miles - Expected) =< Slack)
           )).

test(distance_is_symmetric) :-
    sector_distance(lhr, syd, A),
    sector_distance(syd, lhr, B),
    assertion(A == B).

% A sector within 1.5% of a band edge is flagged, because that is exactly where
% a great circle stops standing in for the airline's own mileage. LHR-YYZ
% measures 3,546 miles against a 3,500-mile edge.
test(a_sector_near_a_band_edge_is_flagged) :-
    sector("BA", "D", "LHR", "YYZ", Row),
    assertion(Row.outcome == ok),
    assertion(Row.nearBoundary == 3500).

test(a_sector_well_inside_a_band_is_not_flagged) :-
    sector("BA", "D", "LHR", "JFK", Row),
    assertion(Row.nearBoundary == null).

% A region pair never looked at the distance, so there is no edge for it to be
% near and flagging it would send the reader to check a number that decided
% nothing. AKL-LAX is 6,516 miles against a 6,500-mile band edge it does not use.
test(a_region_pair_is_never_flagged_for_a_band_edge) :-
    sector("AA", "D", "AKL", "LAX", Row),
    assertion(Row.outcome == ok),
    assertion(sub_atom(Row.basis, _, _, _, 'New Zealand')),
    assertion(Row.nearBoundary == null).

:- end_tests(earn_distance).

% --- the reply --------------------------------------------------------------

:- begin_tests(earn_json).

% `none` and `indeterminate` must never reach a client as a number. Both become
% null, and `known` says which -- a 0 in a points column is a claim, and it is
% the wrong one in both cases.
test(an_undecided_amount_is_null_and_says_why) :-
    itinerary_from_json(
        _{ cabin: "business", mode: "routing",
           segments: [ _{ from: "LHR", to: "JFK", marketingCarrier: "BA",
                          bookingClass: "D", stop: "stopover" },
                       _{ from: "JFK", to: "LHR", carrier: "BA", bookingClass: "D" } ] },
        Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    earn_json(Report, Json),
    Json.programs = [P],
    P.segments = [Row|_],
    assertion(Row.outcome == indeterminate),
    once(member(Total, P.totals)),
    assertion(Total.lowerBound == true),
    assertion(Total.unpricedSegments > 0).

test(a_priced_amount_carries_its_base_and_bonus) :-
    sector("BA", "D", "LHR", "JFK", _),
    itinerary_from_json(
        _{ cabin: "business", mode: "routing",
           segments: [ _{ from: "LHR", to: "JFK", carrier: "BA", bookingClass: "D", stop: "stopover"},
                       _{ from: "JFK", to: "LHR", carrier: "BA", bookingClass: "D"} ] },
        Itin),
    annotate(Itin, A),
    earn(A, [qff], Report),
    earn_json(Report, Json),
    Json.programs = [P],
    P.segments = [Row|_],
    once(( member(Amt, Row.amounts), Amt.currency == points )),
    assertion(Amt.known == known),
    assertion(Amt.value == 4000),
    assertion(Amt.base == 4000),
    assertion(Amt.bonus == 0).

% The page hardcodes no programme, for the same reason it hardcodes no rule.
test(programs_describe_themselves) :-
    programs_json(Dict),
    Dict.programs = [_|_],
    forall(member(P, Dict.programs),
           (   assertion(P.currencies \== []),
               assertion(P.sources \== []),
               assertion(P.notes \== [])
           )).

test(an_unknown_programme_is_refused, [throws(input_error(_))]) :-
    resolve_programs([qff, nonesuch], _).

test(no_programmes_asked_for_means_all_of_them) :-
    resolve_programs([], All),
    earn_programs(Registered),
    assertion(All == Registered).

:- end_tests(earn_json).
