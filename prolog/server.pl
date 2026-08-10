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

% web/ sits beside prolog/ at the repository root.
:- prolog_load_context(directory, Dir),
   file_directory_name(Dir, Root),
   (   user:file_search_path(rtw_root, Root)
   ->  true
   ;   asserta(user:file_search_path(rtw_root, Root))
   ).

:- http_handler(root(.),            home,     [method(get)]).
:- http_handler(root(api/health),   health,   [method(get)]).
:- http_handler(root(api/ruleset),  ruleset,  [method(get)]).
:- http_handler(root(api/airports), airports, [method(get)]).
:- http_handler(root(api/validate), validate_endpoint,
                [method(post), methods([post, options])]).

%! server(+Port) is det.
server(Port) :-
    http_server(http_dispatch, [port(Port)]).

%! stop_server(+Port) is det.
stop_server(Port) :-
    http_stop_server(Port, []).

% --- endpoints -------------------------------------------------------------

% A single self-contained page. It talks to the endpoints below and hardcodes
% no rule data -- limits and the ruleset version come from /api/ruleset.
home(Request) :-
    http_reply_file(rtw_root('web/index.html'), [unsafe(false)], Request).

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
    ;   catch(validate_request(Request), Error, reply_error(Error))
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
reply_error(input_error(Message)) :- !,
    reply_json_dict(_{ error: 'invalid_request', message: Message }, [status(400)]).
reply_error(request_too_large(Length, Max)) :- !,
    format(atom(M), 'Request body is ~d bytes; the maximum is ~d.', [Length, Max]),
    reply_json_dict(_{ error: 'request_too_large', message: M }, [status(413)]).
reply_error(time_limit_exceeded) :- !,
    reply_json_dict(_{ error: 'timeout',
                       message: 'Validation exceeded its time limit.' },
                    [status(503)]).
reply_error(http_reply(_) ) :- !,
    reply_json_dict(_{ error: 'invalid_request',
                       message: 'Request body must be JSON.' }, [status(400)]).
reply_error(Error) :-
    message_to_atom(Error, Text),
    reply_json_dict(_{ error: 'internal_error', message: Text }, [status(500)]).

% The raw term, not a rendered message: this path only fires on a bug, and the
% term is what a developer needs. It is also logged server-side by SWI.
message_to_atom(Error, Text) :-
    term_to_atom(Error, Text).
