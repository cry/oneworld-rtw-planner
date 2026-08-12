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
    P.segments = [Row|_].

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

:- end_tests(earn_qff).

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
    sector("QF", "D", "AKL", "LAX", Row),
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
