:- module(test_json, []).

/** <module> Serialization and HTTP round trip.

    The service and the CLI are two renderers over one report/3 term. These
    tests are what stop the two drifting apart: the JSON body must carry the
    same verdict and the same rule ids the text renderer prints.
*/

:- use_module(library(plunit)).
:- use_module(library(http/http_open)).
:- use_module(library(http/json)).
:- use_module(support).
:- use_module('../src/io/json_in').
:- use_module('../src/io/json_out').
:- use_module('../src/validate').
:- use_module('../server').
:- use_module('../data/limits').

:- begin_tests(json_in).

test(carrier_shorthand_fills_both_fields) :-
    itinerary_from_json(
        _{ origin: "LHR", segments: [ _{ from: "LHR", to: "JFK", carrier: "BA" } ] },
        Itin),
    Itin.segments = [S],
    assertion(S.marketing == ba),
    assertion(S.operating == ba).

test(codes_are_folded_but_flight_numbers_are_not) :-
    itinerary_from_json(
        _{ segments: [ _{ from: "lhr", to: "JFK", carrier: "ba", flight: "BA117" } ] },
        Itin),
    Itin.segments = [S],
    assertion(S.from == lhr),
    assertion(S.to == jfk),
    assertion(S.flight == 'BA117').

test(origin_defaults_to_first_departure) :-
    itinerary_from_json(_{ segments: [ _{ from: "SYD", to: "HKG" } ] }, Itin),
    assertion(Itin.origin == syd).

% Zone designators are discarded rather than applied: these are local
% wall-clock times, and honouring an offset would corrupt ground times.
test(iso_times_with_and_without_zone) :-
    forall(member(T, ["2026-09-01T10:25", "2026-09-01 10:25:00",
                      "2026-09-01T10:25:00Z", "2026-09-01T10:25-05:00"]),
           ( parse_dt(T, Dt), assertion(Dt == dt(2026, 9, 1, 10, 25)) )).

test(date_only_is_midnight) :-
    parse_dt("2026-09-01", Dt),
    assertion(Dt == dt(2026, 9, 1, 0, 0)).

test(malformed_input_throws, [throws(input_error(_))]) :-
    itinerary_from_json(_{ segments: [ _{ from: "LHR" } ] }, _).

test(bad_cabin_throws, [throws(input_error(_))]) :-
    itinerary_from_json(_{ cabin: "premium", segments: [ _{from:"LHR", to:"JFK"} ] }, _).

test(unparseable_date_throws, [throws(input_error(_))]) :-
    itinerary_from_json(_{ segments: [ _{from:"LHR", to:"JFK", dep:"next tuesday"} ] }, _).

% Several rules are quadratic in the segment count, so the reader caps the
% input well above the 16 the fare permits and far below anything expensive.
test(segment_cap_throws, [throws(input_error(_))]) :-
    limit(max_input_segments, Max),
    Over is Max + 1,
    length(Segs, Over),
    maplist(=(_{ from: "LHR", to: "JFK" }), Segs),
    itinerary_from_json(_{ segments: Segs }, _).

:- end_tests(json_in).

:- begin_tests(json_out).

test(report_carries_verdict_and_rules) :-
    fixture(mut_dup_sector, Dict),
    itinerary_from_json(Dict, Itin),
    validate(Itin, Report),
    report_json(Report, Json),
    assertion(Json.verdict == invalid),
    assertion(Json.rulesetVersion == '27FEB26'),
    Json.violations = [V],
    assertion(V.rule == dup_sector),
    assertion(V.citation == '4(i)'),
    assertion(V.evidence.segments == [4, 6]),
    assertion(V.evidence.pair == 'NRT-HKG').

test(annotations_describe_the_route) :-
    fixture(lhr_classic, Dict),
    itinerary_from_json(Dict, Itin),
    validate_annotated(Itin, _, A),
    annotations_json(A, Ann),
    assertion(Ann.trafficConferenceSequence == [tc2, tc1, tc3, tc2]),
    Ann.segments = [First|_],
    assertion(First.from == 'LHR'),
    assertion(First.ocean == atlantic),
    assertion(is_dict(First.fromCoords)),
    Ann.points = [P1|_],
    assertion(P1.kind == stopover).

test(missing_times_serialize_as_null) :-
    fixture(mut_no_times, Dict),
    itinerary_from_json(Dict, Itin),
    validate_annotated(Itin, _, A),
    annotations_json(A, Ann),
    Ann.segments = [First|_],
    assertion(First.dep == null),
    Ann.points = [P1|_],
    assertion(P1.groundHours == null).

test(ruleset_is_self_describing) :-
    ruleset_json(R),
    assertion(R.limits.max_segments == 16),
    assertion(R.freeSegments.north_america == 6),
    assertion(R.version == '27FEB26'),
    length(R.carriers, NC),
    assertion(NC == 16).

:- end_tests(json_out).

:- begin_tests(http, [setup(start), cleanup(stop)]).

test_port(8763).

start :- test_port(P), server(P).
stop  :- test_port(P), stop_server(P).

url(Path, Url) :-
    test_port(P),
    format(atom(Url), 'http://localhost:~w~w', [P, Path]).

get_json(Path, Dict) :-
    url(Path, Url),
    setup_call_cleanup(
        http_open(Url, In, [request_header('Accept'='application/json')]),
        json_read_dict(In, Dict, [value_string_as(atom)]),
        close(In)).

post_fixture(Name, Dict) :-
    fixture(Name, Body),
    url('/api/validate', Url),
    setup_call_cleanup(
        http_open(Url, In, [ method(post), post(json(Body)),
                             request_header('Accept'='application/json'),
                             status_code(_) ]),
        json_read_dict(In, Dict, [value_string_as(atom)]),
        close(In)).

test(health) :-
    get_json('/api/health', D),
    assertion(D.status == ok).

test(ruleset) :-
    get_json('/api/ruleset', D),
    assertion(D.version == '27FEB26').

test(airport_search) :-
    get_json('/api/airports?q=lhr&limit=3', D),
    D.results = [First|_],
    assertion(First.iata == 'LHR'),
    assertion(First.continent == europe_middle_east).

% The whole point of standing the service up early: the body must say exactly
% what the CLI's report term says.
test(validate_matches_the_report_term) :-
    forall(member(Name, [lhr_classic, mut_dup_sector, mut_no_times]),
           ( fixture_rules(Name, Verdict-Ids),
             post_fixture(Name, D),
             assertion(D.verdict == Verdict),
             findall(R, ( member(V, D.violations), R = V.rule ), Rs0),
             sort(Rs0, Rs),
             assertion(Rs == Ids)
           )).

post_json(Body, Code, Dict) :-
    url('/api/validate', Url),
    setup_call_cleanup(
        http_open(Url, In, [ method(post), post(json(Body)), status_code(Code) ]),
        json_read_dict(In, Dict, [value_string_as(atom)]),
        close(In)).

test(malformed_body_is_a_400) :-
    post_json(_{ segments: [ _{ from: "LHR" } ] }, Code, D),
    assertion(Code == 400),
    assertion(D.error == invalid_request).

% Bounded work per request: the declared length is refused before the body is
% read, and the segment cap refuses a small body that would still be expensive.
% The body is refused on its declared length, before it is read -- which is the
% point, since reading it is the cost being avoided. A client that writes the
% whole body before reading the response may therefore see the connection go
% away instead of the 413; both outcomes mean refused, and the test accepts
% either. curl and other streaming clients do receive the 413.
test(oversized_body_is_refused) :-
    limit(max_request_bytes, Max),
    Count is Max // 20,
    length(Segs, Count),
    maplist(=(_{ from: "LHR", to: "JFK", carrier: "BA" }), Segs),
    catch(( post_json(_{ segments: Segs }, Code, D),
            assertion(Code == 413),
            assertion(D.error == request_too_large)
          ),
          error(socket_error(_, _), _),
          true).

test(too_many_segments_is_a_400) :-
    limit(max_input_segments, Max),
    Over is Max + 1,
    length(Segs, Over),
    maplist(=(_{ from: "LHR", to: "JFK" }), Segs),
    post_json(_{ segments: Segs }, Code, D),
    assertion(Code == 400),
    assertion(D.error == invalid_request).

:- end_tests(http).
