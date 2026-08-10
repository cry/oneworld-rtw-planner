:- module(test_route, []).

/** <module> Routing strings, declared stop kinds and routing mode.

    Three things are asserted here, in descending value:

    1. A routing string and a segment array describing the same journey must
       produce the same verdict. That is what makes the routing form a genuine
       second front end rather than a separate, weaker validator.
    2. Declaring stop kinds must decide rule 8 on its own, with no timestamps
       anywhere -- otherwise routing mode would report `indeterminate` for
       every itinerary and be useless.
    3. Routing mode must not quietly pass the rules it cannot check. Rules 6
       and 7 have to appear in the report's not-checked list.
*/

:- use_module(library(plunit)).
:- use_module(support).
:- use_module('../src/io/route_in').
:- use_module('../src/io/json_in').
:- use_module('../src/io/json_out').
:- use_module('../src/annotate').
:- use_module('../src/validate').
:- use_module('../data/cities').
:- use_module('../src/geo').

% --- the grammar -----------------------------------------------------------

:- begin_tests(route_parsing).

test(x_prefix_marks_a_transfer_and_bare_codes_are_stopovers) :-
    route_segments('LHR-X/JFK-LAX-LHR', Segs),
    assertion(Segs = [ rseg(1, flight, lhr, jfk, _, _, _, _, _, transfer),
                       rseg(2, flight, jfk, lax, _, _, _, _, _, stopover),
                       rseg(3, flight, lax, lhr, _, _, _, _, _, unknown) ]).

% Fare construction is written in city codes. The parser passes codes through
% untouched -- resolution belongs to itinerary.pl, so that a city code posted
% in a `segments` array resolves the same way; see the city_codes suite below.
test(city_codes_pass_through_the_parser_unresolved) :-
    route_segments('NYC-X/LON-SIN', Segs),
    assertion(Segs = [ rseg(1, _, nyc, lon, _, _, _, _, _, transfer),
                       rseg(2, _, lon, sin, _, _, _, _, _, unknown) ]).

% The prefix is only read on a four-character token, so a three-letter code
% beginning with X is a place, not a transfer at a two-letter one.
test(three_letter_codes_starting_with_x_are_places) :-
    route_segments('HKG-XIY-PEK', Segs),
    assertion(Segs = [ rseg(1, _, hkg, xiy, _, _, _, _, _, stopover),
                       rseg(2, _, xiy, pek, _, _, _, _, _, unknown) ]).

test(bare_x_prefix_is_accepted_as_well_as_x_slash) :-
    route_segments('LHR-XJFK-LHR', A),
    route_segments('LHR-X/JFK-LHR', B),
    assertion(A == B).

test(double_slash_makes_a_surface_sector) :-
    route_segments('BKK//SIN-LHR', Segs),
    assertion(Segs = [ rseg(1, surface, bkk, sin, _, _, _, _, _, _),
                       rseg(2, flight,  sin, lhr, _, _, _, _, _, _) ]).

test(surface_sector_may_be_spaced_out) :-
    route_segments('BKK//SIN', A),
    route_segments('BKK-//-SIN', B),
    assertion(A == B).

% Two characters is an airline designator and three is a place, so the two
% never need separating by anything but position.
test(two_letter_tokens_are_the_carrier_of_the_following_leg) :-
    route_segments('LHR-BA-X/JFK-AA-LAX', Segs),
    assertion(Segs = [ rseg(1, _, lhr, jfk, ba, ba, _, _, _, _),
                       rseg(2, _, jfk, lax, aa, aa, _, _, _, _) ]).

test(whitespace_and_commas_separate_like_dashes) :-
    route_segments('LON BA JFK, AA X/DFW', A),
    route_segments('LON-BA-JFK-AA-X/DFW', B),
    assertion(A == B).

test(case_is_irrelevant) :-
    route_segments('lhr-x/jfk-lhr', A),
    route_segments('LHR-X/JFK-LHR', B),
    assertion(A == B).

test(unreadable_token_is_reported_with_the_token) :-
    catch(route_segments('LHR-X/JFKK-LHR', _), input_error(M), true),
    assertion(sub_atom(M, _, _, _, 'X/JFKK')).

test(a_single_point_is_not_a_route) :-
    catch(route_segments('LHR', _), input_error(_), Caught = yes),
    assertion(Caught == yes).

test(two_carriers_for_one_leg_is_reported) :-
    catch(route_segments('LHR-BA-AA-JFK', _), input_error(_), Caught = yes),
    assertion(Caught == yes).

:- end_tests(route_parsing).

% --- the two front ends must agree -----------------------------------------

:- begin_tests(routing_mode).

% The headline claim. route_classic is lhr_classic written as a routing, and
% stops_declared is the same journey again as segments with declared stops and
% no times. All three must reach the same verdict.
test(routing_string_agrees_with_the_dated_itinerary) :-
    fixture_rules(lhr_classic, Dated),
    fixture_rules(route_classic, Routed),
    fixture_rules(stops_declared, Declared),
    assertion(Dated == valid-[]),
    assertion(Routed == valid-[]),
    assertion(Declared == valid-[]).

% Rule 8 is decided from the declarations alone: no timestamp is involved, so
% marking every point X/ has to produce the too-few-stopovers error rather
% than the undecidable one.
test(declared_stops_decide_rule_8_without_any_times) :-
    fixture_rules(route_all_transfers, Verdict-Ids),
    assertion(Verdict == invalid),
    assertion(Ids == [min_stopovers]).

test(surface_sector_parses_and_prices_the_same_way) :-
    fixture_rules(route_surface, Verdict-Ids),
    assertion(Verdict-Ids == valid-[]).

% Routing mode must not turn "cannot be checked" into "checked and passed".
test(rules_needing_a_calendar_are_named_as_not_checked) :-
    fixture_not_checked(route_classic, Ids),
    assertion(Ids == [max_stay]),
    fixture_not_checked(lhr_classic, None),
    assertion(None == []).

% Rule 6 applies only to TC1 origins, so it is out of reach only when it would
% otherwise have applied -- listing it for a London origin would be noise.
test(rule_6_is_named_only_when_the_origin_is_in_tc1) :-
    routed_not_checked('LHR-BA-JFK-AA-LAX-QF-SYD-QF-X/SIN-BA-LHR', Europe),
    assertion(Europe == [max_stay]),
    routed_not_checked('JFK-AA-LHR-BA-BKK-QF-SYD-QF-LAX-AA-JFK', Tc1),
    assertion(Tc1 == [min_stay, max_stay]).

% The severities stay distinct: a *full* itinerary missing its times is
% indeterminate, because the data those rules need was simply left out.
test(routing_mode_is_not_the_same_as_missing_data) :-
    fixture_rules(mut_no_times, Verdict-Ids),
    assertion(Verdict == indeterminate),
    assertion(memberchk(stopovers_undecidable, Ids)).

% A point with neither a time nor a declaration is still undecidable; routing
% mode relaxes which rules apply, not the standard of evidence for rule 8.
test(undeclared_points_in_routing_mode_are_still_undecidable) :-
    itinerary_from_json(
        _{ mode: "routing",
           segments: [ _{ from: "LHR", to: "JFK" }, _{ from: "JFK", to: "LHR" } ] },
        Itin),
    validate(Itin, report(Verdict, Violations, _, _)),
    rule_ids(Violations, Ids),
    assertion(Verdict == invalid),          % also too short, below the 4(h) minimum
    assertion(memberchk(stopovers_undecidable, Ids)).

:- end_tests(routing_mode).

% --- declarations against the clock ----------------------------------------

:- begin_tests(declared_stops).

test(a_declaration_overrides_the_ground_time) :-
    ann_of(mut_stop_conflict, A),
    once(( ann_point(A, P), P.after == 1 )),
    assertion(P.declared == transfer),
    assertion(P.derived == stopover),
    assertion(P.kind == transfer).

% Reported, not resolved in silence: which source is believed changes the
% stopover count, and hiding that would hide why rule 8 came out as it did.
test(a_disagreement_is_reported_as_a_warning) :-
    fixture_rules(mut_stop_conflict, Verdict-Ids),
    assertion(Verdict == valid),
    assertion(Ids == [stop_kind_conflict]).

% 4(g) surface travel is at the passenger's own expense and breaks the flown
% journey whatever it is called, so here the declaration loses.
test(a_surface_sector_outranks_a_declared_transfer) :-
    itinerary_from_json(
        _{ mode: "routing",
           segments: [ _{ from: "LHR", to: "BKK", carrier: "BA", stop: "transfer" },
                       _{ from: "BKK", to: "SIN", type: "surface" },
                       _{ from: "SIN", to: "LHR", carrier: "BA" } ] },
        Itin),
    annotate(Itin, A),
    once(( ann_point(A, P), P.after == 1 )),
    assertion(P.declared == transfer),
    assertion(P.kind == stopover).

test(layover_and_connection_are_accepted_for_transfer) :-
    forall(member(Word, ["layover", "connection", "transit", "transfer"]),
           ( itinerary_from_json(
                 _{ segments: [ _{ from: "LHR", to: "JFK", stop: Word },
                                _{ from: "JFK", to: "LHR" } ] },
                 I),
             I.segments = [S|_],
             assertion(S.stop == transfer) )).

test(an_unknown_stop_word_is_rejected_rather_than_ignored) :-
    catch(itinerary_from_json(
              _{ segments: [ _{ from: "LHR", to: "JFK", stop: "overnight" } ] }, _),
          input_error(_), Caught = yes),
    assertion(Caught == yes).

% Silently discarding the times would make rules 6 and 7 look unanswerable
% when the data to answer them was supplied.
test(times_supplied_in_routing_mode_are_refused) :-
    catch(itinerary_from_json(
              _{ mode: "routing",
                 segments: [ _{ from: "LHR", to: "JFK", dep: "2026-09-01T10:00" },
                             _{ from: "JFK", to: "LHR" } ] }, _),
          input_error(_), Caught = yes),
    assertion(Caught == yes).

test(route_and_segments_together_are_refused) :-
    catch(itinerary_from_json(
              _{ route: "LHR-JFK-LHR", segments: [ _{ from: "LHR", to: "JFK" } ] }, _),
          input_error(_), Caught = yes),
    assertion(Caught == yes).

:- end_tests(declared_stops).

% --- serialization ---------------------------------------------------------

:- begin_tests(routing_json).

% A client that renders `verdict` without `notChecked` would claim coverage the
% report does not give, so the field has to be there to be rendered.
test(not_checked_rules_reach_the_json) :-
    fixture(route_classic, Dict),
    itinerary_from_json(Dict, Itin),
    validate(Itin, Report),
    report_json(Report, Json),
    assertion(Json.notChecked = [NC]),
    Json.notChecked = [NC],
    assertion(NC.rule == max_stay),
    assertion(NC.citation == '7').

% Both classifications travel with the point, not just the winner, so a client
% can show which source decided it.
test(points_carry_both_the_declared_and_the_derived_kind) :-
    ann_of(mut_stop_conflict, A),
    annotations_json(A, Json),
    Json.points = [P|_],
    assertion(P.declaredKind == transfer),
    assertion(P.derivedKind == stopover),
    assertion(P.kind == transfer),
    assertion(P.surfaceAdjacent == false).

test(mode_travels_with_the_annotations) :-
    ann_of(route_classic, A),
    annotations_json(A, Json),
    assertion(Json.mode == routing).

:- end_tests(routing_json).

% --- the city table --------------------------------------------------------

:- begin_tests(city_codes).

% A regenerated airport table that drops one of these must fail here rather
% than turn a city code into "not a known airport" at runtime.
test(every_city_code_resolves_to_a_known_airport) :-
    findall(C, ( city_code(C, A), \+ airport_known(A) ), Bad),
    assertion(Bad == []).

test(every_city_code_has_a_name) :-
    findall(C, ( city_code(C, _), \+ city_name(C, _) ), Unnamed),
    assertion(Unnamed == []).

% Aliasing rather than inventing a new kind of place is what makes this hold,
% and it is what lets 4(i) see NYC-LON and JFK-LHR as one sector. It applies to
% both front ends, because both resolve in itinerary.pl.
test(a_city_code_is_the_same_place_as_its_airport) :-
    itinerary_from_json(_{ route: "NYC-LON" }, FromRoute),
    FromRoute.segments = [R],
    assertion(R.from == jfk),
    assertion(R.to == lhr),
    itinerary_from_json(_{ segments: [ _{ from: "NYC", to: "LON" } ] }, FromSegments),
    FromSegments.segments = [S],
    assertion(S.from == jfk),
    assertion(S.to == lhr).

:- end_tests(city_codes).

routed_not_checked(Route, Ids) :-
    itinerary_from_json(_{ route: Route }, Itin),
    validate(Itin, report(_, _, _, NotChecked)),
    findall(R, member(nc(R, _, _), NotChecked), Ids).

ann_of(Name, A) :-
    fixture(Name, Dict),
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A).
