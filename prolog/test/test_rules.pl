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
:- use_module('../src/carriers').
:- use_module('../src/itinerary').
:- use_module('../src/io/json_in').
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

% 4(e)'s Mauritius/South Africa sentence turns on the two Africa gateways, not
% on a count of arrivals into Europe. This journey has a second Europe arrival
% -- Hong Kong to Paris -- that has nothing to do with the Africa excursion,
% and the excursion itself goes in through Doha, so the sentence does not bite.
test(one_gulf_gateway_clears_the_africa_exclusion) :-
    fixture_rules(osl_africa_gulf_gateway, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

% Four international transfers at one Gulf hub: 4(f)'s cap exactly, with 4(e)
% and 4(h) also on their limits. The Africa legs are intercontinental, so they
% cost nothing against the Europe/Middle East free-segment allowance -- which
% is what lets a real itinerary get this far up 4(f) at all.
test(four_transfers_in_one_country_is_the_limit) :-
    fixture_rules(doh_transfers, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

% Rule 6 applies only to TC1 origins, and this fixture meets its 10 days.
% Segment 5 is eastbound trans-Pacific: it arrives at an earlier clock time
% than it departed, which is a date line crossing, not a data error.
test(tc1_origin_meeting_the_minimum_stay) :-
    fixture_rules(jfk_tc1, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

test(date_line_crossing_is_not_an_input_error) :-
    fixture_report(jfk_tc1, _, report(_, Violations, _, _, _)),
    assertion(\+ memberchk(v(input_error, _, _, _, _), Violations)).

% 4(f) permits a second international departure from a USA origin only when one
% of the country's own international arrival-departure pairs is a transfer.
% Miami is that transfer here; mut_origin_country is the same routing with
% Miami as a stopover instead.
test(usa_origin_using_the_transfer_exception) :-
    fixture_rules(jfk_us_transfer, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

test(fare_basis_follows_continent_count) :-
    fixture_report(lhr_classic, _, report(_, _, Fare3, _, _)),
    assertion(Fare3.continents == 3),
    assertion(Fare3.basis == 'DONE3'),
    fixture_report(lhr_africa, _, report(_, _, Fare4, _, _)),
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

% 4(k) names two columns of states and Alaska is in neither, so a flight
% between Anchorage and the east coast is not transcontinental. Pinned because
% Alaska and Hawaii both sit outside the columns, and the loosest way to bring
% Hawaii in would drag Alaska with it. Alaska's own limit is one flight each
% way, which this journey keeps.
test(alaska_is_in_neither_column) :-
    routed_report('LHR-JFK-ANC-PHL-LAX-NRT-HKG-LHR', _, report(Verdict, _, _, _, _)),
    assertion(Verdict == valid).

% The same limits on a booked itinerary: one transcontinental flight, one
% flight into Alaska and one out, and four points visited twice without
% tripping 4(i) or 4(d).
test(booked_alaska_round_trip) :-
    fixture_rules(hnd_alaska, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]),
    fixture_check(hnd_alaska, transcontinental_us,
                  check(_, _, _, Transcon, _)),
    assertion(Transcon == pass),
    fixture_check(hnd_alaska, alaska_flights, check(_, _, _, Alaska, _)),
    assertion(Alaska == pass).

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

% Surfacing the return leg does not make the pair legal. Checking flights alone
% passes this, which is how it went unnoticed.
test(hawaii_backtracking_by_surface) :-
    fixture_rules(mut_hawaii_surface, V-Ids),
    assertion(V-Ids == invalid-[hawaii_backtrack]).

% 4(f)'s transfer cap cannot be broken alone: a fifth transfer costs either a
% fifth pair of intra-continental legs or a third intercontinental crossing, so
% 4(h) or 4(e) always comes with it. It does fire, though -- the driver
% enumerates every violation rather than stopping at the first.
test(international_transfers_from_one_country) :-
    fixture_rules(mut_intl_transfers, V-Ids),
    assertion(V-Ids == invalid-[free_segments, intl_transfers_per_country]).

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

% The infant is stated as 1, which is also the age rule 19's own trigger cannot
% tell apart from an infant who turns 2 mid-journey, so the warning rides along.
test(infant_from_a_russian_origin) :-
    fixture_rules(led_infant, V-Ids),
    assertion(V-Ids == invalid-[infant_russia_origin, infant_turns_two]).

test(mauritius_south_africa_exclusion) :-
    fixture_rules(mut_europe_both_ways, V-Ids),
    assertion(V-Ids == invalid-[europe_both_ways_excluded]).

% The same journey with the outbound crossing at Doha instead of Paris. The
% exclusion names the Europe zone, not the Europe/Middle East continent, so one
% token decides this and nothing else about the two itineraries differs.
test(africa_via_the_gulf_is_not_excluded) :-
    fixture_rules(mut_europe_both_ways_gulf, V-Ids),
    assertion(V-Ids == valid-[]).

test(twelve_month_maximum_stay) :-
    fixture_rules(mut_max_stay, V-Ids),
    assertion(V-Ids == invalid-[max_stay]).

% The boundary the whole-month count could not see. Departing 1 Sep 2026 and
% returning 20 Sep 2027 is nineteen days late and twelve *whole* months, so a
% truncating comparison reads it as exactly at the limit; anything short of a
% thirteenth completed month ran valid.
test(maximum_stay_is_measured_from_the_anniversary_not_whole_months) :-
    fixture_rules(mut_max_stay_days, V-Ids),
    assertion(V-Ids == invalid-[max_stay]).

% The other side of the same boundary, so the fix cannot be "always fire".
test(returning_inside_the_anniversary_is_valid) :-
    itinerary_from_json(
        _{ segments: [ _{ from: "LHR", to: "JFK", carrier: "BA",
                          dep: "2026-09-01T10:25", arr: "2026-09-01T13:30",
                          stop: "stopover" },
                       _{ from: "JFK", to: "LHR", carrier: "BA",
                          dep: "2027-09-01T09:00", arr: "2027-09-01T21:00" } ] },
        Itin),
    validate(Itin, report(_, Violations, _, _, _)),
    rule_ids(Violations, Ids),
    assertion(\+ memberchk(max_stay, Ids)).

% 4(j)'s last clause: "Ground transportation services operated by/for BA/QF may
% not be included as part of the oneworld Explorer." A surface sector normally
% names no carrier at all -- route_surface is the golden that does not -- and
% naming one is what makes it a ground service sold with the ticket. The
% stop_kind_conflict alongside it is the SIN transfer that the surface sector
% turns into a stopover, which is rule 8 reporting correctly.
test(ground_transport_carried_by_ba) :-
    itinerary_from_json(_{ route: "LHR-BA-JFK-AA-LAX-QF-SYD-QF-X/SIN-BA//LGW" }, Itin),
    validate(Itin, report(V, Violations, _, _, _)),
    rule_ids(Violations, Ids),
    assertion(V == invalid),
    assertion(Ids == [ground_transport, stop_kind_conflict]).

test(cuba_with_a_us_carrier) :-
    fixture_rules(mut_cuba, V-Ids),
    assertion(V-Ids == invalid-[cuba_us_carrier]).

% A single Cuban stop appears as both an arrival and the next departure; it
% must still be reported once.
test(cuba_reported_once) :-
    fixture_report(mut_cuba, _, report(_, Violations, _, _, _)),
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

% Rule 19's actual trigger is an infant reaching 2 *during* the journey, and the
% input carries an age rather than a date of birth. Stating 1 used to silence
% the rule entirely -- including from the page's own adult+infant preset, which
% sends exactly this.
test(an_infant_who_may_turn_two_en_route_warns) :-
    fixture_rules(mut_infant_turns_two, V-Ids),
    assertion(V-Ids == valid-[infant_turns_two]).

% Priced as travel via Asia, so the fare basis counts a continent the itinerary
% never lands in. Surfacing that stops the count looking like an error.
test(swp_europe_nonstop_warns_and_counts_asia) :-
    fixture_rules(syd_via_asia, V-Ids),
    assertion(V-Ids == valid-[via_asia_counted]),
    fixture_report(syd_via_asia, _, report(_, _, Fare, _, _)),
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

% Rule 7 measures to one instant: the departure of the onward flight from the
% last stopover. When only that instant is missing the rule used to fail
% silently and read as satisfied, because its indeterminate clause only covered
% a missing *first* departure.
test(an_untimed_return_leg_is_undecided_not_satisfied) :-
    fixture_rules(mut_untimed_return, V-Ids),
    assertion(V-Ids == indeterminate-[max_stay]).

% Rule 15 needs a carrier the way rule 7 needs a date. Left blank, the check
% used to read "it does not use American or Alaska", which is a clean pass on a
% question nobody answered -- and the sector that puts most itineraries into
% Cuba is American. 4(j)'s own missing-carrier warning rides along, from the
% same two blanks.
test(cuba_without_carriers_is_undecided_not_clean) :-
    fixture_rules(mut_cuba_no_carrier, V-Ids),
    assertion(V-Ids == indeterminate-[cuba_us_carrier, marketing_carrier_missing]).

% ...and once a carrier is named the rule is settled, so the blank segments
% around it must not add an undecided verdict on top of the error.
test(a_named_carrier_settles_cuba_outright) :-
    fixture_rules(mut_cuba, V-Ids),
    assertion(V-Ids == invalid-[cuba_us_carrier]).

% Unresolvable references are violations inside the report, not request errors,
% so they render alongside the rule violations.
test(unknown_airport_and_gap_are_violations) :-
    fixture_report(mut_input_errors, V, report(_, Violations, _, _, _)),
    assertion(V == invalid),
    rule_ids(Violations, Ids),
    assertion(Ids == [input_error]),
    assertion(Violations = [_, _]).

:- end_tests(indeterminacy).

% --- the check register ----------------------------------------------------

:- begin_tests(checks).

% The load-bearing property. A rule that can fire without a check reporting
% what it measured makes the register a claim about coverage it does not have,
% and a new rule added without a check is exactly how that would happen.
test(every_rule_that_can_fire_is_measured) :-
    fixture_names(Names),
    findall(Name-Rule,
            ( member(Name, Names), uncovered_rule(Name, Rule) ),
            Gaps),
    assertion(Gaps == []).

uncovered_rule(Name, Rule) :-
    fixture(Name, Dict),
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A),
    findall(R, ( validate:check(A, C), covered_rule(C, R) ), Covered),
    validate:violation(A, v(Rule, _, _, _, _)),
    Rule \== input_error,
    \+ memberchk(Rule, Covered).

covered_rule(chk(_, _, _, _, Covers), Rule) :- member(Rule, Covers).

% What the section is for: the number and the cap it sits under, not "ok".
test(a_satisfied_cap_states_the_measurement) :-
    fixture_check(lhr_classic, segment_count, check(_, Citation, _, Outcome, Detail)),
    assertion(Citation == '4(h)'),
    assertion(Outcome == pass),
    assertion(sub_atom(Detail, _, _, _, '7 segments')),
    assertion(sub_atom(Detail, _, _, _, 'allows 3 to 16')).

% The outcome is derived from the violations, never stated by the check, so a
% breached cap cannot read as a pass.
test(a_breached_cap_reports_as_failed) :-
    fixture_check(mut_seg_count_max, segment_count, check(_, _, _, Outcome, _)),
    assertion(Outcome == fail).

% An unread connection makes the stopover total a lower bound. The check has to
% inherit that from rule 8's indeterminate violation rather than pass on the
% count it managed to reach.
test(an_unread_connection_leaves_the_stopover_check_undecided) :-
    fixture_check(mut_no_times, min_stopovers, check(_, _, _, Outcome, Detail)),
    assertion(Outcome == indeterminate),
    assertion(sub_atom(Detail, _, _, _, 'could not be read')).

% not_checked and not_applicable are different absences: one is a rule the
% input mode cannot answer, the other a rule the itinerary never engages.
test(a_rule_the_input_mode_cannot_answer_is_not_a_pass) :-
    fixture_check(route_classic, max_stay, check(_, _, _, Outcome, _)),
    assertion(Outcome == not_checked).

test(a_rule_the_geography_never_engages_is_not_a_pass) :-
    fixture_check(lhr_classic, au_city_pair, check(_, _, _, Outcome, _)),
    assertion(Outcome == not_applicable),
    fixture_check(mut_au_city_pair, au_city_pair, check(_, _, _, Fired, _)),
    assertion(Fired == fail).

% Measurements over an itinerary that did not parse describe a journey nobody
% submitted.
test(input_errors_withhold_the_register) :-
    fixture_checks(mut_input_errors, Checks),
    assertion(Checks == []).

test(checks_come_out_in_rule_order) :-
    fixture_checks(lhr_classic, Checks),
    findall(N,
            ( member(check(_, Citation, _, _, _), Checks),
              citation_key(Citation, N-_) ),
            Numbers),
    assertion(Numbers \== []),
    assertion(\+ ( append(_, [X, Y|_], Numbers), X > Y )).

:- end_tests(checks).

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

% Section 15 lists fifteen stocks against sixteen eligible carriers. The one it
% leaves out is NU, which may be flown under 4(j) but may not issue the ticket.
test(ticket_stock_is_every_eligible_carrier_but_nu) :-
    findall(C, eligible_carrier(C), Eligible0), sort(Eligible0, Eligible),
    findall(C, ticketing_stock(C), Stock0), sort(Stock0, Stock),
    subtract(Eligible, Stock, Excluded),
    assertion(Excluded == [nu]),
    length(Stock, N),
    assertion(N == 15).

% The gap between where a journey ends and where it began is detected, because
% 4(c) decides whether it is allowed at all and the count is worth explaining.
% It is not one of the segments 4(h) counts: taking the permission 4(c) grants
% would otherwise cost a flight, which no clause says it should.
test(the_origin_destination_gap_is_not_a_counted_segment) :-
    Out = [ _{ type: "flight", from: "LHR", to: "JFK", carrier: "BA" },
            _{ type: "flight", from: "JFK", to: "SYD", carrier: "QF" },
            _{ type: "flight", from: "SYD", to: "MAN", carrier: "QF" } ],
    dict_ann(_{ mode: "routing", origin: "LHR", segments: Out }, Gap),
    ann_segment_count(Gap, Counted),
    assertion(Counted == 3),
    assertion(od_surface_gap(Gap)).

% A sixteen-flight journey closed by a 4(c) open jaw is at the limit, not over
% it. The Cairo-to-Doha shape below is held and priced in the wild.
test(sixteen_flights_and_an_open_jaw_is_at_the_limit) :-
    routed_report('CAI-X/DOH-MAD-EZE-JFK-MEX-LAX-ANC-DFW-ICN-HKG-SIN-HND-BKK-X/HEL-CDG-DOH',
                  A, report(Verdict, _, _, _, _)),
    ann_segment_count(A, N),
    assertion(N == 16),
    assertion(od_surface_gap(A)),
    assertion(Verdict == valid).

% ...but two airports of one city are one point, so this journey has no gap.
test(a_second_airport_of_the_origin_city_is_not_a_gap) :-
    Home = [ _{ type: "flight", from: "LHR", to: "JFK", carrier: "BA" },
             _{ type: "flight", from: "JFK", to: "SYD", carrier: "QF" },
             _{ type: "flight", from: "SYD", to: "LGW", carrier: "QF" } ],
    dict_ann(_{ mode: "routing", origin: "LHR", segments: Home }, A),
    ann_segment_count(A, N),
    assertion(N == 3),
    assertion(\+ od_surface_gap(A)).

% Calendar arithmetic, including the two cases that make month addition awkward.
test(month_addition_clamps_to_the_end_of_a_short_month) :-
    dt_plus_months(dt(2026, 1, 31, 9, 0), 1, Feb),
    assertion(Feb == dt(2026, 2, 28, 9, 0)),
    dt_plus_months(dt(2028, 2, 29, 9, 0), 12, NonLeap),
    assertion(NonLeap == dt(2029, 2, 28, 9, 0)),
    dt_plus_months(dt(2026, 9, 1, 10, 25), 12, Anniversary),
    assertion(Anniversary == dt(2027, 9, 1, 10, 25)).

test(a_limit_is_past_the_anniversary_not_the_month_count) :-
    From = dt(2026, 9, 1, 10, 25),
    assertion(dt_beyond_months(From, dt(2027, 9, 20, 0, 0), 12)),
    assertion(dt_beyond_months(From, dt(2027, 9, 1, 10, 26), 12)),
    assertion(\+ dt_beyond_months(From, dt(2027, 9, 1, 10, 25), 12)),
    assertion(\+ dt_beyond_months(From, dt(2027, 8, 31, 23, 59), 12)),
    % The truncating count still reads all four as twelve whole months.
    forall(member(To, [dt(2027, 9, 20, 0, 0), dt(2027, 9, 1, 10, 26),
                       dt(2027, 9, 1, 10, 25)]),
           ( dt_months_between(From, To, M), assertion(M == 12) )).

ann_of(Name, A) :-
    fixture(Name, Dict),
    dict_ann(Dict, A).

dict_ann(Dict, A) :-
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A).

:- end_tests(invariants).

% File level, not inside a unit: plunit scopes a unit's clauses to its own
% module, and this is called from `mutations` as well as `invariants`.
routed_report(Route, A, Report) :-
    itinerary_from_json(_{ route: Route }, Itin),
    annotate(Itin, A),
    validate(Itin, Report).
