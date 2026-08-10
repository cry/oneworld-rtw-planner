% load.pl -- entry point.
%
%   swipl prolog/load.pl                    interactive session
%   swipl -g run_tests -t halt prolog/load.pl
%
% Deliberately not a module: use_module/1 from a non-module file imports into
% `user`, so an interactive session has every exported predicate in scope.
%
% All paths are relative to this file, so the loader works from any working
% directory without a file_search_path alias.

:- use_module('data/limits').
:- use_module('data/countries').
:- use_module('data/overrides').
:- use_module('data/transcon').
:- use_module('data/au_pairs').
:- use_module('data/surcharges').

:- use_module('src/geo').
:- use_module('src/carriers').
:- use_module('src/itinerary').
:- use_module('src/annotate').
:- use_module('src/pricing').
:- use_module('src/validate').
:- use_module('src/explain').

:- use_module('src/io/json_in').
:- use_module('src/io/json_out').

% Rule modules export nothing. Loading them is what registers their clauses of
% validate:violation/2; there is no other registry.
:- use_module('src/rules/r00_continents').
:- use_module('src/rules/r04_routing').
:- use_module('src/rules/r06_min_stay').
:- use_module('src/rules/r07_max_stay').
:- use_module('src/rules/r08_stopovers').
:- use_module('src/rules/r15_sales').
:- use_module('src/rules/r19_discounts').

% Rule 9 (transfers) has nothing mechanically checkable: "unlimited
% online/interline transfers permitted between [the eligible carriers]" is a
% permission, and the carriers themselves are checked by 4(j).

% Test suites are loaded only when tests are actually run, so a server process
% does not carry plunit or the fixture corpus.
:- if(current_prolog_flag(rtw_tests, true)).
:- use_module(library(plunit)).
:- ensure_loaded('test/test_geo').
:- ensure_loaded('test/test_annotate').
:- ensure_loaded('test/test_rules').
:- ensure_loaded('test/test_json').
:- endif.
