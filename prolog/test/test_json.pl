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

% A bug in a rule must not describe the validator's internals to an
% unauthenticated caller: that is the hazard library(http/http_error) exists to
% warn about, and it is invisible until something actually throws. The mapping
% is checked rather than the wiring, which the 400 cases above already cover.
test(an_internal_error_does_not_leak_the_term) :-
    Secret = error(existence_error(procedure, some_internal_predicate/3), _),
    server:error_reply(Secret, Status, Dict),
    assertion(Status == 500),
    assertion(Dict.error == internal_error),
    assertion(\+ sub_atom(Dict.message, _, _, _, 'some_internal_predicate')),
    assertion(\+ sub_atom(Dict.message, _, _, _, 'existence_error')).

% The cases that describe the caller's own request back to them stay verbatim;
% only the fallback is opaque.
test(client_errors_keep_their_message) :-
    server:error_reply(input_error('Missing "segments" or "route".'), S1, D1),
    assertion(S1 == 400),
    assertion(D1.message == 'Missing "segments" or "route".'),
    server:error_reply(time_limit_exceeded, S2, _),
    assertion(S2 == 503),
    server:error_reply(request_too_large(200000, 131072), S3, _),
    assertion(S3 == 413).

% Served from memory, so it cannot depend on the working directory or on a
% path baked in at compile time -- see the note in server.pl.
test(the_ui_is_served_without_touching_the_filesystem) :-
    url('/', Url),
    setup_call_cleanup(
        http_open(Url, In, [status_code(Code)]),
        read_string(In, _, Body),
        close(In)),
    assertion(Code == 200),
    assertion(sub_string(Body, _, _, _, "oneworld Explorer validator")).

% The page is three files now, and a stylesheet that 404s is a UI that renders
% as unstyled markup rather than one that fails loudly. Content types are
% asserted too: a stylesheet served as text/plain is ignored by every browser.
test(the_page_assets_are_served) :-
    forall(member(Path-Type, [ '/app.css' - "text/css",
                               '/app.js'  - "text/javascript",
                               '/map.js'  - "text/javascript" ]),
           ( url(Path, Url),
             setup_call_cleanup(
                 http_open(Url, In, [ status_code(Code),
                                      header(content_type, CT) ]),
                 read_string(In, _, Body),
                 close(In)),
             assertion(Code == 200),
             assertion(sub_string(CT, _, _, _, Type)),
             string_length(Body, Len),
             assertion(Len > 0)
           )).

% Composing a routing is a separate endpoint rather than a flag on validate,
% because it runs no rules and answers a different question.
test(the_routing_endpoint_composes) :-
    fixture(lhr_classic, Body),
    url('/api/routing', Url),
    setup_call_cleanup(
        http_open(Url, In, [ method(post), post(json(Body)), status_code(Code),
                             request_header('Accept'='application/json') ]),
        json_read_dict(In, D, [value_string_as(atom)]),
        close(In)),
    assertion(Code == 200),
    assertion(D.route == 'LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR').

% Refusing is the interesting half: the reply has to name the segments rather
% than invent a classification for them.
test(the_routing_endpoint_refuses_an_undecidable_itinerary) :-
    fixture(mut_no_times, Body),
    url('/api/routing', Url),
    setup_call_cleanup(
        http_open(Url, In, [method(post), post(json(Body)), status_code(Code)]),
        json_read_dict(In, D, [value_string_as(atom)]),
        close(In)),
    assertion(Code == 400),
    assertion(D.error == invalid_request),
    assertion(sub_atom(D.message, _, _, _, '1, 2, 3, 4, 5, 6')).

% RTW_DEV_ASSETS trades the whole point of reading the page into the program for
% not having to restart while editing it, so the two must not be confusable: dev
% replies are uncacheable, and production ones are not.
test(assets_are_cacheable_unless_dev_mode_is_on) :-
    assertion(\+ server:dev_assets),
    server:cache_control('text/css', Css),
    server:cache_control('font/woff2', Font),
    assertion(Css == 'no-cache'),
    assertion(Font == 'public, max-age=31536000, immutable'),
    setup_call_cleanup(
        assertz(server:dev_assets),
        ( server:cache_control('text/css', DevCss),
          server:cache_control('font/woff2', DevFont),
          assertion(DevCss == 'no-store'),
          assertion(DevFont == 'no-store')
        ),
        retract(server:dev_assets)).

% The one route that writes bytes rather than text. An encoding applied on the
% way out corrupts a woff2 without any error being raised, and the only symptom
% is a browser silently falling back to a system font -- so the reply is compared
% against the bytes the server holds.
test(a_font_arrives_byte_for_byte) :-
    Path = '/fonts/archivo-latin-var.woff2',
    server:asset(Path, _, Expected),
    url(Path, Url),
    setup_call_cleanup(
        http_open(Url, In, [status_code(Code)]),
        ( set_stream(In, encoding(octet)),
          read_string(In, _, Body) ),
        close(In)),
    assertion(Code == 200),
    string_codes(Body, Got),
    assertion(Got == Expected),
    % woff2 files begin with the signature 'wOF2'.
    assertion(append(`wOF2`, _, Got)).

% The font handler has a prefix, so it sees every path under /fonts/. It resolves
% nothing from disk: anything not in the table is absent, which is what keeps
% ../../etc/passwd from being a question worth asking.
test(an_unknown_asset_is_a_404) :-
    forall(member(P, ['/fonts/nothing.woff2', '/fonts/../server.pl']),
           ( url(P, Url),
             catch(setup_call_cleanup(
                       http_open(Url, In, [status_code(C)]),
                       read_string(In, _, _),
                       close(In)),
                   _, C = 404),
             assertion(C == 404)
           )).

:- end_tests(http).
