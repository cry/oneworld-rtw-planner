% daemon.pl -- production entry point.
%
%   swipl prolog/daemon.pl --no-fork --port=8080 --workers=16
%
% library(http/http_unix_daemon) supplies the whole daemon CLI (--port, --ip,
% --user, --group, --workers, --pidfile, --fork, --syslog, --https and the
% certificate options) and, more importantly, the signal handling: SIGINT and
% SIGTERM shut the server down without abandoning requests in flight, SIGHUP
% reloads, SIGUSR1 reopens log files. `cli.pl serve` has none of that -- it
% parks the main thread on a message that never arrives, so a SIGTERM kills
% mid-request work. Use cli.pl for development and this file to deploy.
%
% Under a supervisor that wants a foreground process -- systemd Type=simple,
% or Docker, where this is PID 1 -- pass --no-fork. Only the parent needs to be
% root, and only to bind a privileged port; --user drops privileges afterwards.
%
% Loading order follows the library's own documented example: the daemon
% library first, then the application. There is no entry point declared here
% because http_unix_daemon already declares initialization(http_daemon, main);
% redeclaring it would run the server twice.

:- use_module(library(http/http_unix_daemon)).

:- ensure_loaded('load').

% server.pl is what registers the http_handler/3 directives. The daemon starts
% http_dispatch/1 itself, so server:server/1 is deliberately not called here.
:- use_module('server').
