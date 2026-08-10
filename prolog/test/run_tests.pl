% run_tests.pl -- test entry point.
%
%   swipl -g run_tests -t halt prolog/test/run_tests.pl
%
% Separate from prolog/load.pl so that a server process carries neither plunit
% nor the fixture corpus.

:- ensure_loaded('../load').

:- use_module(library(plunit)).
:- use_module(test_geo).
:- use_module(test_rules).
:- use_module(test_route).
:- use_module(test_json).
