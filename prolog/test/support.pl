:- module(test_support,
          [ fixture/2, fixture_report/3, fixture_rules/2, fixture_not_checked/2,
            rule_ids/2 ]).

/** <module> Shared fixture loading for the plunit suites.
*/

:- use_module(library(json)).
:- use_module('../src/io/json_in').
:- use_module('../src/validate').

fixture_file(Name, File) :-
    module_property(test_support, file(Here)),
    file_directory_name(Here, Dir),
    atomic_list_concat([Dir, '/fixtures/', Name, '.json'], File).

%! fixture(+Name, -Dict) is det.
fixture(Name, Dict) :-
    fixture_file(Name, File),
    setup_call_cleanup(
        open(File, read, S, [encoding(utf8)]),
        json_read_dict(S, Dict, [end_of_file(error)]),
        close(S)).

%! fixture_report(+Name, -Verdict, -Report) is det.
fixture_report(Name, Verdict, Report) :-
    fixture(Name, Dict),
    itinerary_from_json(Dict, Itin),
    validate(Itin, Report),
    Report = report(Verdict, _, _, _).

%! fixture_rules(+Name, -Verdict-RuleIds) is det.
%  The sorted set of rule ids that fired. Mutation tests assert on this set
%  rather than on the violation count, so a rule that fires twice for the same
%  reason still reads as one rule having fired.
fixture_rules(Name, Verdict-Ids) :-
    fixture_report(Name, Verdict, report(_, Violations, _, _)),
    rule_ids(Violations, Ids).

%! fixture_not_checked(+Name, -RuleIds) is det.
%  The rules the fixture's input mode put out of reach, in report order.
fixture_not_checked(Name, Ids) :-
    fixture_report(Name, _, report(_, _, _, NotChecked)),
    findall(R, member(nc(R, _, _), NotChecked), Ids).

rule_ids(Violations, Ids) :-
    findall(R, member(v(R, _, _, _, _), Violations), Rs),
    sort(Rs, Ids).
