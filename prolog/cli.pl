#!/usr/bin/env swipl
% cli.pl -- command line front end.
%
%   swipl prolog/cli.pl -- validate <itinerary.json> [--json]
%   swipl prolog/cli.pl -- route <routing> [--cabin business] [--json]
%   swipl prolog/cli.pl -- serve [--port 8080] [--dev]
%
% All three subcommands render the same report/4 term; the first two use the
% text renderer in src/explain.pl and the service uses src/io/json_out.pl.

:- initialization(main, main).

:- ensure_loaded('load').
:- use_module('server').
:- use_module(library(json)).
:- use_module(library(main)).

% halt/1 unwinds through catch/3, so the exit code is carried out as a value
% and the process is halted exactly once, outside the recovery goal.
main(Argv) :-
    catch(run(Argv, Code), Error, fatal(Error, Code)),
    halt(Code).

run([validate, File|Opts], Code) :- !, cmd_validate(File, Opts, Code).
run([route, Route|Opts], Code)   :- !, cmd_route(Route, Opts, Code).
run([serve|Opts], Code)          :- !, cmd_serve(Opts, Code).
run(_, 2) :-
    route_help(Help),
    format(user_error,
           'usage: swipl prolog/cli.pl -- validate <itinerary.json> [--json]~n', []),
    format(user_error,
           '       swipl prolog/cli.pl -- route <routing> [--cabin economy|business|first] [--json]~n', []),
    format(user_error,
           '       swipl prolog/cli.pl -- serve [--port 8080] [--dev]~n~n', []),
    format(user_error, '~w~n', [Help]).

% --- validate --------------------------------------------------------------

cmd_validate(File, Opts, Code) :-
    read_json_file(File, Dict),
    report_for(Dict, Opts, Code).

% --- route -----------------------------------------------------------------

% The routing form goes through the same JSON reader rather than a second path
% into the validator, so `route` and a posted {"route": ...} cannot drift.
cmd_route(Route, Opts, Code) :-
    (   append(_, ['--cabin', Cabin|_], Opts)
    ->  Dict = _{ route: Route, cabin: Cabin }
    ;   Dict = _{ route: Route }
    ),
    report_for(Dict, Opts, Code).

report_for(Dict, Opts, Code) :-
    itinerary_from_json(Dict, Itin),
    validate_annotated(Itin, Report, A),
    (   memberchk('--json', Opts)
    ->  annotations_json(A, Ann),
        report_json(Report, _{ annotations: Ann }, Json),
        json_write_dict(current_output, Json, [width(96)]),
        nl
    ;   explain(Report)
    ),
    Report = report(Verdict, _, _, _),
    exit_code(Verdict, Code).

exit_code(valid, 0).
exit_code(indeterminate, 1).
exit_code(invalid, 1).

read_json_file(File, Dict) :-
    (   exists_file(File)
    ->  setup_call_cleanup(
            open(File, read, S, [encoding(utf8)]),
            json_read_dict(S, Dict, [end_of_file(error)]),
            close(S))
    ;   format(atom(M), 'No such file: ~w', [File]),
        throw(input_error(M))
    ).

% --- serve -----------------------------------------------------------------

% --dev sets the same environment variable the daemon reads, so there is one
% switch rather than two ways to say it. It must be set before server.pl's
% initialization goal has run -- which it has by the time main/1 is called, so
% the flag is re-applied here explicitly.
cmd_serve(Opts, 0) :-
    (   append(_, ['--port', PortAtom|_], Opts),
        atom_number(PortAtom, Port)
    ->  true
    ;   Port = 8080
    ),
    (   memberchk('--dev', Opts)
    ->  setenv('RTW_DEV_ASSETS', '1'),
        server:configure_dev_assets
    ;   true
    ),
    server(Port),
    format(user_error, 'oneworld Explorer validator listening on http://localhost:~w~n', [Port]),
    thread_get_message(_).   % park forever; Ctrl-C stops the process

% --- errors ----------------------------------------------------------------

fatal(input_error(M), 2) :- !,
    format(user_error, 'input error: ~w~n', [M]).
fatal(E, 3) :-
    print_message(error, E).
