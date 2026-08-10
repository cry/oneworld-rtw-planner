:- module(server, [server/1, stop_server/1]).

/** <module> HTTP front end.

    A second renderer over the same report/3 term the CLI prints, with no rule
    logic of its own.

    Concurrency: SWI's HTTP server is multithreaded, and everything below the
    report term is pure -- annotate/2 returns a term, no rule asserts anything,
    and the reference data is static and consulted at load. So no request state
    is shared and handlers need no locking. This is also why itineraries arrive
    as JSON rather than as Prolog fact files: consulting a fact file mutates
    the global database and could not be run concurrently.
*/

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_log)).
:- use_module(library(thread_pool)).
:- use_module(library(apply)).
:- use_module(library(time)).

:- use_module('src/geo').
:- use_module('src/validate').
:- use_module('src/io/json_in').
:- use_module('src/io/json_out').
:- use_module('data/limits').

% The bundled UI is served from this same origin, but CORS stays open so a UI
% under its own dev server can call the API too.
:- set_setting_default(http:cors, [*]).

% The UI is read into the program at load time rather than opened from disk on
% each request. Two reasons, both of which bit the first version:
%
%   * A path resolved with prolog_load_context/2 is fixed at *compile* time,
%     so a saved state or an image built anywhere but the deployment directory
%     served 404s for a file that was sitting right there.
%   * It removes the only filesystem access in the request path, so the
%     container can run read-only and the server needs no working directory.
%
% Failing here fails the build, which is where a missing UI file should be
% noticed.
:- dynamic ui_page/1.

:- prolog_load_context(directory, Dir),
   file_directory_name(Dir, Root),
   atomic_list_concat([Root, '/web/index.html'], Index),
   read_file_to_string(Index, HTML, [encoding(utf8)]),
   assertz(ui_page(HTML)).

% Access logging is off unless RTW_HTTP_LOG names a file. library(http/http_log)
% otherwise defaults to writing httpd.log into the working directory, which is
% not something merely loading this file should do.
:- initialization(configure_logging).

configure_logging :-
    (   getenv('RTW_HTTP_LOG', File), File \== ''
    ->  set_setting(http:logfile, File)
    ;   set_setting(http:logfile, '')
    ).

% Validation is the only expensive handler: it runs under a time limit and is
% quadratic in the segment count. Sharing the server's default five workers
% with it means five slow requests stop /api/health answering, and a load
% balancer then takes the instance out of service over something that is not an
% outage. Its own bounded pool keeps the cheap endpoints responsive, and a full
% queue is refused rather than accumulated -- SWI maps threads_in_pool/1 to a
% 503, which is the honest answer to "we are at capacity".
:- multifile thread_pool:create_pool/1.

thread_pool:create_pool(rtw_validate) :-
    limit(validate_workers, Workers),
    limit(validate_backlog, Backlog),
    thread_pool_create(rtw_validate, Workers, [backlog(Backlog)]).

:- http_handler(root(.),            home,     [method(get)]).
:- http_handler(root(api/health),   health,   [method(get)]).
:- http_handler(root(api/ruleset),  ruleset,  [method(get)]).
:- http_handler(root(api/airports), airports, [method(get)]).
:- http_handler(root(api/validate), validate_endpoint,
                [method(post), methods([post, options]), spawn(rtw_validate)]).

%! server(+Port) is det.
server(Port) :-
    http_server(http_dispatch, [port(Port)]).

%! stop_server(+Port) is det.
stop_server(Port) :-
    http_stop_server(Port, []).

% --- endpoints -------------------------------------------------------------

% A single self-contained page. It talks to the endpoints below and hardcodes
% no rule data -- limits and the ruleset version come from /api/ruleset.
home(_Request) :-
    ui_page(HTML),
    format('Content-type: text/html; charset=UTF-8~n~n'),
    write(HTML).

health(_Request) :-
    cors_enable,
    ruleset_version(V),
    reply_json_dict(_{ status: ok, rulesetVersion: V }).

ruleset(_Request) :-
    cors_enable,
    ruleset_json(Dict),
    reply_json_dict(Dict).

airports(Request) :-
    cors_enable,
    http_parameters(Request,
                    [ q(Q, [default('')]),
                      limit(Limit, [integer, default(20)])
                    ]),
    Capped is max(1, min(Limit, 100)),
    (   Q == ''
    ->  Results = []
    ;   airport_search(Q, Capped, Codes),
        maplist(airport_json, Codes, Results)
    ),
    reply_json_dict(_{ query: Q, results: Results }).

validate_endpoint(Request) :-
    cors_enable,
    (   memberchk(method(options), Request)
    ->  reply_json_dict(_{}, [status(200)])
    ;   catch_with_backtrace(validate_request(Request), Error,
                             reply_error(Error, Request))
    ).

validate_request(Request) :-
    check_body_size(Request),
    http_read_json_dict(Request, Dict, [value_string_as(string)]),
    % The report is built under a time limit and replied outside it, so a
    % timeout can never leave a half-written response on the wire.
    limit(request_time_limit_seconds, Seconds),
    call_with_time_limit(Seconds, build_report(Dict, Json)),
    reply_json_dict(Json).

build_report(Dict, Json) :-
    itinerary_from_json(Dict, Itin),
    validate_annotated(Itin, Report, A),
    annotations_json(A, Annotations),
    report_json(Report, _{ annotations: Annotations }, Json).

% Refuse an oversized body before reading it rather than after. The declared
% length is what SWI will read, so checking it here is the cheap guard; the
% segment cap in io/json_in.pl is the one that bounds the actual work.
check_body_size(Request) :-
    limit(max_request_bytes, Max),
    (   memberchk(content_length(Length), Request),
        Length > Max
    ->  throw(request_too_large(Length, Max))
    ;   true
    ).

% Malformed input is a 400 with a structured body; anything else is a bug in a
% rule and is reported as a 500 rather than being swallowed into a verdict.
%
% The four cases below describe the caller's own request back to them, which is
% information they already have. The fallback deliberately does not: see
% log_internal_error/2.
%
% The mapping is kept separate from the writing so that what the client is
% told can be tested without an HTTP context; test_json.pl asserts that the
% fallback body carries nothing from the exception term.
% The status is decided once and then asked about. Calling error_reply/3 a
% second time with 500 bound would match the catch-all clause for *every*
% exception, and log each malformed request as an internal failure.
reply_error(Error, Request) :-
    error_reply(Error, Status, Dict),
    (   Status == 500
    ->  log_internal_error(Error, Request)
    ;   true
    ),
    reply_json_dict(Dict, [status(Status)]).

%! error_reply(+Error, -Status, -Dict) is det.
error_reply(input_error(Message), 400,
            _{ error: 'invalid_request', message: Message }) :- !.
error_reply(request_too_large(Length, Max), 413,
            _{ error: 'request_too_large', message: M }) :- !,
    format(atom(M), 'Request body is ~d bytes; the maximum is ~d.', [Length, Max]).
error_reply(time_limit_exceeded, 503,
            _{ error: 'timeout',
               message: 'Validation exceeded its time limit.' }) :- !.
error_reply(http_reply(_), 400,
            _{ error: 'invalid_request',
               message: 'Request body must be JSON.' }) :- !.
error_reply(_, 500,
            _{ error: 'internal_error',
               message: 'The validator failed on this request. The failure has been logged.' }).

% Logged in full server-side, opaque to the client. This path only fires on a
% bug, and the raw term plus its backtrace is exactly what a developer needs --
% but it is also a description of the validator's internals, and handing that
% to an unauthenticated caller is the hazard library(http/http_error) exists to
% warn about. stderr is the right destination: systemd and Docker both collect
% it, and neither needs a log file managed inside the container.
% The term is printed by us rather than left to print_message/2, which renders
% anything without a message clause as "Unknown message". Standard errors are
% then printed a second time so their backtrace -- collected by
% catch_with_backtrace/3 -- is rendered too.
log_internal_error(Error, Request) :-
    (   memberchk(path(Path), Request) -> true ; Path = unknown ),
    print_message(error, rtw_request_failed(Path, Error)),
    (   Error = error(_, _)
    ->  print_message(error, Error)
    ;   true
    ).

:- multifile prolog:message//1.

prolog:message(rtw_request_failed(Path, Error)) -->
    [ 'Unhandled error while serving ~w; replying 500: ~p'-[Path, Error] ].
