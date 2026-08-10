:- module(test_rules, []).

/** <module> Golden and mutation suites.

    The mutation suite is the highest-value one here. Each fixture is the
    lhr_classic golden with exactly one rule broken, and each test asserts that
    exactly the expected rule ids fire. That catches false negatives and rules
    that over-fire on legal itineraries at the same time, and it is what
    verifies the rules are independent of each other.
*/

:- use_module(library(plunit)).
:- use_module(support).
:- use_module('../src/geo').
:- use_module('../src/validate').
:- use_module('../src/annotate').
:- use_module('../src/pricing').
:- use_module('../data/limits').
:- use_module('../src/rules/r04_routing').

% --- golden itineraries ----------------------------------------------------

:- begin_tests(golden).

test(classic_rtw) :-
    fixture_rules(lhr_classic, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

% An Africa excursion never leaves TC2, so 4(b) is untouched; what carries it
% is 4(e)'s two-way Europe/Middle East allowance for travel to/from/via Africa.
test(africa_excursion_is_legal) :-
    fixture_rules(lhr_africa, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

% Likewise a South America excursion never leaves TC1.
test(south_america_excursion_is_legal) :-
    fixture_rules(lhr_south_america, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

test(swp_origin_transoceanic_surface_exception) :-
    fixture_rules(syd_surface, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

% Rule 6 applies only to TC1 origins, and this fixture meets its 10 days.
% Segment 5 is eastbound trans-Pacific: it arrives at an earlier clock time
% than it departed, which is a date line crossing, not a data error.
test(tc1_origin_meeting_the_minimum_stay) :-
    fixture_rules(jfk_tc1, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

test(date_line_crossing_is_not_an_input_error) :-
    fixture_report(jfk_tc1, _, report(_, Violations, _)),
    assertion(\+ memberchk(v(input_error, _, _, _, _), Violations)).

% 4(f) permits a second international departure from a USA origin only when one
% of the country's own international arrival-departure pairs is a transfer.
% Miami is that transfer here; mut_origin_country is the same routing with
% Miami as a stopover instead.
test(usa_origin_using_the_transfer_exception) :-
    fixture_rules(jfk_us_transfer, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

test(fare_basis_follows_continent_count) :-
    fixture_report(lhr_classic, _, report(_, _, Fare3)),
    assertion(Fare3.continents == 3),
    assertion(Fare3.basis == 'DONE3'),
    fixture_report(lhr_africa, _, report(_, _, Fare4)),
    assertion(Fare4.continents == 4),
    assertion(Fare4.basis == 'DONE4').

:- end_tests(golden).

% --- one broken rule at a time ---------------------------------------------

:- begin_tests(mutations).

test(duplicate_sector) :-
    fixture_rules(mut_dup_sector, V-Ids),
    assertion(V-Ids == invalid-[dup_sector]).

test(traffic_conference_cycle) :-
    fixture_rules(mut_tc_cycle, V-Ids),
    assertion(V-Ids == invalid-[tc_cycle]).

test(does_not_end_at_origin) :-
    fixture_rules(mut_end_at_origin, V-Ids),
    assertion(V-Ids == invalid-[end_at_origin]).

test(travels_via_the_origin) :-
    fixture_rules(mut_origin_revisited, V-Ids),
    assertion(V-Ids == invalid-[origin_revisited]).

test(free_segment_cap) :-
    fixture_rules(mut_free_segments, V-Ids),
    assertion(V-Ids == invalid-[free_segments]).

test(too_few_stopovers) :-
    fixture_rules(mut_min_stopovers, V-Ids),
    assertion(V-Ids == invalid-[min_stopovers]).

test(carrier_not_eligible) :-
    fixture_rules(mut_carrier, V-Ids),
    assertion(V-Ids == invalid-[carrier_not_eligible]).

test(two_transcontinental_us_flights) :-
    fixture_rules(mut_transcontinental, V-Ids),
    assertion(V-Ids == invalid-[transcontinental_us]).

% Two Africa excursions exhaust both the Europe/Middle East allowance and
% Africa's own, in both directions.
test(intercontinental_allowance) :-
    fixture_rules(mut_intercontinental, V-Ids),
    assertion(V-Ids == invalid-[intercont_arrivals, intercont_departures]).

% Backtracking within a continent is legal under 4(b); Hawaii is the one
% exception, so this fixture must fire and the golden fixtures must not.
test(hawaii_backtracking) :-
    fixture_rules(mut_hawaii_backtrack, V-Ids),
    assertion(V-Ids == invalid-[hawaii_backtrack]).

test(australian_city_pair_set) :-
    fixture_rules(mut_au_city_pair, V-Ids),
    assertion(V-Ids == invalid-[au_city_pair]).

% The same surface sector is legal in syd_surface, where the itinerary
% originates in the South West Pacific.
test(transoceanic_surface_without_the_exception) :-
    fixture_rules(mut_transoceanic_surface, V-Ids),
    assertion(V-Ids == invalid-[transoceanic_surface]).

test(minimum_stay_from_tc1) :-
    fixture_rules(mut_min_stay, V-Ids),
    assertion(V-Ids == invalid-[min_stay]).

test(codeshare_operator_not_permitted) :-
    fixture_rules(mut_codeshare, V-Ids),
    assertion(V-Ids == invalid-[codeshare_not_permitted]).

test(too_many_segments) :-
    fixture_rules(mut_seg_count_max, V-Ids),
    assertion(V-Ids == invalid-[seg_count_max]).

% Some rules cannot fire alone: two segments are below the minimum and are also
% necessarily short of continents, stopovers and a traffic-conference cycle.
% The assertion is still exact, it is just exact about a set.
test(too_few_segments) :-
    fixture_rules(mut_seg_count_min, V-Ids),
    assertion(V-Ids == invalid-[min_stopovers, seg_count_min,
                                tc_cycle, too_few_continents]).

test(fewer_than_three_continents) :-
    fixture_rules(mut_two_continents, V-Ids),
    assertion(V-Ids == invalid-[tc_cycle, too_few_continents]).

test(child_discount_eligibility) :-
    fixture_rules(mut_discounts, V-Ids),
    assertion(V-Ids == invalid-[child_age_out_of_range, unaccompanied_child]).

test(alaska_flight_limits) :-
    fixture_rules(mut_alaska, V-Ids),
    assertion(V-Ids == invalid-[alaska_flights]).

test(stopovers_in_the_continent_of_origin) :-
    fixture_rules(mut_origin_continent_stopovers, V-Ids),
    assertion(V-Ids == invalid-[origin_continent_stopovers]).

% The USA exception no longer applies once Miami is a stopover, so both
% directions of the 4(f) count go over.
test(origin_country_international_limits) :-
    fixture_rules(mut_origin_country, V-Ids),
    assertion(V-Ids == invalid-[origin_country_arrivals, origin_country_departures]).

test(infant_over_the_age_limit) :-
    fixture_rules(mut_infant_too_old, V-Ids),
    assertion(V-Ids == invalid-[infant_too_old]).

test(infant_from_a_russian_origin) :-
    fixture_rules(led_infant, V-Ids),
    assertion(V-Ids == invalid-[infant_russia_origin]).

test(mauritius_south_africa_exclusion) :-
    fixture_rules(mut_europe_both_ways, V-Ids),
    assertion(V-Ids == invalid-[europe_both_ways_excluded]).

test(twelve_month_maximum_stay) :-
    fixture_rules(mut_max_stay, V-Ids),
    assertion(V-Ids == invalid-[max_stay]).

test(cuba_with_a_us_carrier) :-
    fixture_rules(mut_cuba, V-Ids),
    assertion(V-Ids == invalid-[cuba_us_carrier]).

% A single Cuban stop appears as both an arrival and the next departure; it
% must still be reported once.
test(cuba_reported_once) :-
    fixture_report(mut_cuba, _, report(_, Violations, _)),
    assertion(Violations = [_]).

:- end_tests(mutations).

% --- warnings do not invalidate --------------------------------------------

:- begin_tests(warnings).

% 4(j) turns on who operates the flight. An absent operating carrier is not a
% pass and not a failure: the check simply did not run, and the report says so.
test(unknown_operator_warns_but_stays_valid) :-
    fixture_rules(mut_operator_unknown, V-Ids),
    assertion(V-Ids == valid-[operator_unknown]).

test(carrier_shorthand_suppresses_the_warning) :-
    fixture_rules(lhr_classic, valid-[]).

test(no_carrier_at_all_warns) :-
    fixture_rules(mut_no_carrier, V-Ids),
    assertion(V-Ids == valid-[marketing_carrier_missing]).

% QF marketed and JQ operated is permitted by 4(j) but constrains ticket stock
% under section 15, which is a property of the ticket rather than the routing.
test(jetstar_operated_qf_limits_ticket_stock) :-
    fixture_rules(syd_jetstar, V-Ids),
    assertion(V-Ids == valid-[jq_stock_conflict]).

test(infant_without_an_age_warns) :-
    fixture_rules(mut_infant_age_unstated, V-Ids),
    assertion(V-Ids == valid-[infant_age_unstated]).

% Priced as travel via Asia, so the fare basis counts a continent the itinerary
% never lands in. Surfacing that stops the count looking like an error.
test(swp_europe_nonstop_warns_and_counts_asia) :-
    fixture_rules(syd_via_asia, V-Ids),
    assertion(V-Ids == valid-[via_asia_counted]),
    fixture_report(syd_via_asia, _, report(_, _, Fare)),
    assertion(Fare.continents == 4),
    assertion(Fare.basis == 'LONE4').

:- end_tests(warnings).

% --- undecidable input -----------------------------------------------------

:- begin_tests(indeterminacy).

% The point of the `indeterminate` severity: an itinerary entered without
% times is never reported valid.
test(missing_times_are_not_valid) :-
    fixture_rules(mut_no_times, V-Ids),
    assertion(V == indeterminate),
    assertion(Ids == [max_stay, stopovers_undecidable]).

% Unresolvable references are violations inside the report, not request errors,
% so they render alongside the rule violations.
test(unknown_airport_and_gap_are_violations) :-
    fixture_report(mut_input_errors, V, report(_, Violations, _)),
    assertion(V == invalid),
    rule_ids(Violations, Ids),
    assertion(Ids == [input_error]),
    assertion(Violations = [_, _]).

:- end_tests(indeterminacy).

% --- rule internals --------------------------------------------------------

:- begin_tests(invariants).

% 4(a) + 4(b) + 4(c) reduce to this one property.
test(valid_traffic_conference_cycles) :-
    assertion(valid_tc_cycle([tc2, tc1, tc3, tc2])),   % westbound from Europe
    assertion(valid_tc_cycle([tc2, tc3, tc1, tc2])),   % eastbound from Europe
    assertion(valid_tc_cycle([tc1, tc2, tc3, tc1])),
    assertion(valid_tc_cycle([tc3, tc2, tc1, tc3])),
    assertion(\+ valid_tc_cycle([tc2, tc1, tc2])),     % never reaches TC3
    assertion(\+ valid_tc_cycle([tc2, tc1, tc3])),     % does not come home
    assertion(\+ valid_tc_cycle([tc2, tc1, tc3, tc1, tc2])).

% There is no "too many continents" rule because it could never fire: the fare
% table stops at six and the continent list has exactly six members. What that
% rule was reaching for is this -- the table must cover every count the
% geography can actually produce.
test(fare_table_covers_every_reachable_continent_count) :-
    aggregate_all(count, continent(_), Total),
    limit(max_continents, Total),
    limit(min_continents, Min),
    forall(( between(Min, Total, N), member(Cabin, [economy, business, first]) ),
           assertion(fare_basis(Cabin, N, _))).

test(collapse_removes_only_consecutive_duplicates) :-
    collapse([tc2, tc2, tc1, tc1, tc1, tc3, tc2], S),
    assertion(S == [tc2, tc1, tc3, tc2]).

% 4(e) is a continent-level rule; the Europe/Middle East allowance depends on
% whether the itinerary goes to, from or via Africa.
test(intercontinental_allowances) :-
    fixture_report(lhr_classic, _, _),
    fixture(lhr_classic, _),
    ann_of(lhr_classic, NoAfrica),
    ann_of(lhr_africa, WithAfrica),
    assertion(intercont_allowance(NoAfrica, north_america, 2)),
    assertion(intercont_allowance(NoAfrica, asia, 2)),
    assertion(intercont_allowance(NoAfrica, europe_middle_east, 1)),
    assertion(intercont_allowance(WithAfrica, europe_middle_east, 2)),
    assertion(intercont_allowance(NoAfrica, south_america, 1)).

% Section 0: a nonstop between the South West Pacific and Europe/Middle East is
% priced as travel via Asia, adding a continent the itinerary never lands in.
test(swp_europe_nonstop_counts_asia) :-
    Segments = [ _{ type: "flight", from: "SYD", to: "LHR", carrier: "QF" },
                 _{ type: "flight", from: "LHR", to: "JFK", carrier: "BA" },
                 _{ type: "flight", from: "JFK", to: "SYD", carrier: "QF" } ],
    dict_ann(_{ origin: "SYD", cabin: "economy", segments: Segments }, A),
    continent_count(A, Continents, N),
    assertion(memberchk(asia, Continents)),
    assertion(N == 4).

ann_of(Name, A) :-
    fixture(Name, Dict),
    dict_ann(Dict, A).

dict_ann(Dict, A) :-
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A).

:- end_tests(invariants).
