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
:- use_module('../src/io/route_out').
:- use_module('../src/io/json_in').
:- use_module('../src/io/json_out').
:- use_module('../src/annotate').
:- use_module('../src/validate').
:- use_module('../data/cities').
:- use_module('../src/carriers').
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
    validate(Itin, report(Verdict, Violations, _, _, _)),
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
    assertion(P.kind == stopover),
    % And the warning has to say the derived kind won. It used to say "the
    % declared transfer is used" here, which is the opposite of the number rule
    % 8's minimum and origin-continent cap were then counted from.
    validate:violation(A, v(stop_kind_conflict, _, _, Msg, Evidence)),
    assertion(memberchk(used(stopover), Evidence)),
    assertion(sub_atom(Msg, _, _, _, 'the derived stopover is used')).

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

% --- writing a routing back out --------------------------------------------

% The reason io/route_out.pl is Prolog and not JavaScript: with both directions
% here, "a routing survives the round trip" is a property the suite can assert
% rather than a claim in a comment.
:- begin_tests(route_composition).

route_of(Dict, Route) :-
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A),
    annotated_route(A, Route).

test(a_routing_survives_the_round_trip) :-
    forall(member(R, ['LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR',
                      'LHR-BA-X/JFK-AA-X/LAX-JL-X/NRT-CX-X/HKG-CX-X/BKK-QR-X/DOH-QR-LHR',
                      'LHR-JFK-LAX-NRT-HKG-BKK-DOH-LHR']),
           ( route_of(_{ route: R }, Out),
             assertion(Out == R) )).

% A surface sector replaces both the separator and the carrier, so it has to
% come back out that way and not as a dash.
test(a_surface_sector_round_trips_as_a_double_slash) :-
    route_of(_{ route: 'SYD-QF-X/HKG-QR-DOH-QR-LHR-BA-JFK-AA-LAX//SYD' }, Out),
    assertion(Out == 'SYD-QF-X/HKG-QR-DOH-QR-LHR-BA-JFK-AA-LAX//SYD').

% City codes resolve to airports on the way in and stay resolved on the way out.
% That is canonicalisation rather than loss: both name the same journey, and the
% test pins it so the behaviour is a decision rather than a surprise.
test(city_codes_come_back_as_airports) :-
    route_of(_{ route: 'LON-BA-NYC-AA-X/DFW-AA-LAX-QF-SYD//MEL-QF-X/SIN-BA-LON' }, Out),
    assertion(Out == 'LHR-BA-JFK-AA-X/DFW-AA-LAX-QF-SYD//MEL-QF-X/SIN-BA-LHR').

% The point of the feature: a dated itinerary, whose stops were worked out from
% the clock rather than declared, still writes down as a routing -- and that
% routing must reach the same verdict as the itinerary it came from.
test(a_dated_itinerary_composes_and_agrees) :-
    fixture(lhr_classic, Dict),
    route_of(Dict, Route),
    assertion(Route == 'LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR'),
    itinerary_from_json(Dict, Dated),
    validate(Dated, report(V1, _, _, _, _)),
    itinerary_from_json(_{ route: Route, cabin: "business" }, Composed),
    validate(Composed, report(V2, _, _, _, _)),
    assertion(V1 == valid),
    assertion(V2 == V1).

% A routing has no notation for "we do not know what this point is". Writing a
% bare code would say stopover, which would change the itinerary and its
% verdict, so composition fails and names the segments instead.
test(an_undecidable_point_refuses_to_compose) :-
    fixture(mut_no_times, Dict),
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A),
    assertion(\+ annotated_route(A, _)),
    route_undecidable(A, Segments),
    assertion(Segments == [1, 2, 3, 4, 5, 6]).

% Every report carries the routing, so an API client gets it without a second
% request -- and null, not a guess, when it cannot be written.
test(the_report_carries_the_routing) :-
    fixture(lhr_classic, Dict),
    itinerary_from_json(Dict, Itin),
    validate_annotated(Itin, _, A),
    annotations_json(A, Ann),
    assertion(Ann.routing == 'LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR'),

    fixture(mut_no_times, Bad),
    itinerary_from_json(Bad, BadItin),
    validate_annotated(BadItin, _, BadA),
    annotations_json(BadA, BadAnn),
    assertion(BadAnn.routing == null).

:- end_tests(route_composition).

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

% The table has to run backwards too. 4(i) is written in city pairs and 4(c)
% and 4(d) in points, so an airport that belongs to a metropolitan area has to
% be findable from the airport.
test(a_metro_airport_knows_its_city) :-
    assertion(city_of(lgw, lon)),
    assertion(city_of(lhr, lon)),
    assertion(city_of(ewr, nyc)),
    assertion(\+ city_of(man, _)),
    assertion(same_place(lhr, lgw)),
    assertion(\+ same_place(lhr, man)).

% Every member has to resolve, for the same reason the representatives do.
test(every_metro_airport_resolves) :-
    findall(A, ( city_airports(_, As), member(A, As), \+ airport_known(A) ), Bad),
    assertion(Bad == []).

% No airport may sit in two metropolitan areas, or city_of/2's commit picks one
% arbitrarily and 4(i) starts depending on clause order.
test(no_airport_belongs_to_two_cities) :-
    findall(A-Cs,
            ( city_airports(_, As), member(A, As),
              findall(C, ( city_airports(C, Members), memberchk(A, Members) ), Cs),
              Cs = [_, _|_] ),
            Overlaps),
    assertion(Overlaps == []).

% 4(i) says "the same city pairs/sectors". LHR-JFK out and LGW-JFK back repeats
% a city pair without repeating a three-letter code.
test(one_city_pair_flown_twice_from_different_airports) :-
    routed_rules('LHR-BA-JFK-AA-LAX-QF-SYD-QF-SIN-BA-LGW-BA-JFK-AA-ORD-BA-LHR', _-Ids),
    assertion(memberchk(dup_sector, Ids)).

% 4(d) is about the point of origin, and a second London airport is that point.
test(a_stop_at_another_airport_of_the_origin_city_is_via_the_origin) :-
    routed_rules('LHR-BA-JFK-BA-LGW-BA-NRT-JL-LHR', _-Ids),
    assertion(memberchk(origin_revisited, Ids)).

% ...and finishing at one is finishing at the origin, not an OD surface sector.
test(finishing_at_another_airport_of_the_origin_city_is_finishing_at_home) :-
    routed_rules('LHR-BA-JFK-AA-LAX-QF-SYD-QF-X/SIN-BA-LGW', V-Ids),
    assertion(V-Ids == valid-[]).

:- end_tests(city_codes).

% --- carriers that look like places ----------------------------------------

:- begin_tests(carrier_codes).

% HAC is Hokkaido Air System in the 4(j) affiliate table and Hachijojima in the
% airport table. The notation cannot say which is meant, so a routing reads it
% as the place -- the far likelier thing to write down.
test(a_three_letter_code_that_is_an_airport_stays_an_airport) :-
    route_segments('HND-HAC-OKD', Segs),
    assertion(Segs = [_, _]),
    Segs = [First|_],
    arg(3, First, From), arg(4, First, To),
    assertion(From == hnd),
    assertion(To == hac).

% A three-letter designator that collides with nothing is still a carrier, so
% the grammar is not simply capped at two characters.
test(a_three_letter_carrier_that_is_not_a_place_is_a_carrier) :-
    assertion(( carrier_code(hac), place_code_known(hac) )),
    findall(C, ( carrier_code(C), atom_length(C, 3), \+ place_code_known(C) ), Free),
    forall(member(C, Free), assertion(\+ place_code_known(C))).

% The round trip is the property this notation exists to have. Composing HAC
% would emit a string that parses back to a journey via Hachijojima, so it is
% refused and named instead.
test(an_ambiguous_carrier_is_refused_rather_than_composed) :-
    itinerary_from_json(
        _{ origin: "HND",
           segments: [ _{ from: "HND", to: "OKD", carrier: "HAC", stop: "stopover" },
                       _{ from: "OKD", to: "HND", carrier: "JL" } ] },
        Itin),
    annotate(Itin, A),
    assertion(\+ annotated_route(A, _)),
    route_ambiguous_carrier(A, Segments),
    assertion(Segments == [1]),
    % and it is not confused with the other reason a routing cannot be written
    route_undecidable(A, Undecided),
    assertion(Undecided == []).

:- end_tests(carrier_codes).

routed_rules(Route, Verdict-Ids) :-
    itinerary_from_json(_{ route: Route }, Itin),
    validate(Itin, report(Verdict, Violations, _, _, _)),
    rule_ids(Violations, Ids).

routed_not_checked(Route, Ids) :-
    itinerary_from_json(_{ route: Route }, Itin),
    validate(Itin, report(_, _, _, NotChecked, _)),
    findall(R, member(nc(R, _, _), NotChecked), Ids).

ann_of(Name, A) :-
    fixture(Name, Dict),
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A).
