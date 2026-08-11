:- module(explain, [explain/3, explain/2, explain/1, verdict_headline/2]).

/** <module> Report term -> human-readable text.

    One of two renderers over report/5; io/json_out.pl is the other. Neither
    contains rule logic, which is what keeps the CLI and the HTTP service
    saying the same thing.
*/

:- use_module('../data/limits').
:- use_module(phrasing).
:- use_module(validate).

%! explain(+Report) is det.
explain(Report) :- explain(Report, current_output, []).

%! explain(+Report, +Stream) is det.
explain(Report, S) :- explain(Report, S, []).

%! explain(+Report, +Stream, +Options) is det.
%  Options: `checks(true)` lists every rule that was measured, not just the
%  ones that failed. Off by default because the list is four times the length
%  of the verdict it supports, and on demand because "no rule was broken" is
%  otherwise a claim the reader cannot audit.
explain(report(Verdict, Violations, Fare, NotChecked, Checks), S, Opts) :-
    verdict_headline(Verdict, Head),
    (   tally(Violations, Tally), Tally \== ''
    ->  format(S, '~w — ~w~n', [Head, Tally])
    ;   format(S, '~w~n', [Head])
    ),
    forall(member(V, Violations), violation_line(V, S)),
    not_checked_lines(NotChecked, S),
    check_lines(Checks, Violations, S, Opts),
    fare_line(Fare, S).

% --- the check register ----------------------------------------------------

% Empty means the input did not parse; see the note in validate.pl. Saying so
% is the point, since the alternative is a report that silently drops a section.
check_lines([], Violations, S, _) :-
    !,
    (   memberchk(v(input_error, _, _, _, _), Violations)
    ->  format(S, 'Checks — none run; the input errors above must be fixed first.~n', [])
    ;   true
    ).
check_lines(Checks, _, S, Opts) :-
    check_tally(Checks, Tally),
    (   memberchk(checks(true), Opts)
    ->  format(S, 'Checks — ~w:~n', [Tally]),
        forall(member(C, Checks), check_line(C, S))
    ;   format(S, 'Checks — ~w. Re-run with --checks to list them.~n', [Tally])
    ).

check_line(check(_, Citation, Label, Outcome, Detail), S) :-
    outcome_word(Outcome, Word),
    format(S, '  [~w]~t~14| ~w~t~24| ~w~t~62| ~w~n', [Citation, Word, Label, Detail]).

check_tally(Checks, Tally) :-
    findall(Part,
            ( outcome_word(Outcome, Word),
              aggregate_all(count, member(check(_, _, _, Outcome, _), Checks), N),
              N > 0,
              format(atom(Part), '~d ~w', [N, Word])
            ),
            Parts),
    atomic_list_concat(Parts, ', ', Tally).

% Order matters: check_tally/2 reports in this order, worst first, so the one
% exception among twenty passes is the first thing in the line.
outcome_word(fail,           'failed').
outcome_word(indeterminate,  'undecided').
outcome_word(warning,        'flagged').
outcome_word(pass,           'ok').
outcome_word(not_checked,    'not run').
outcome_word(not_applicable, 'n/a').

% A verdict that leaves rules unchecked says so on its own line. Printing the
% headline alone would read as a clean bill of health for rules that never ran.
not_checked_lines([], _) :- !.
not_checked_lines(NCs, S) :-
    length(NCs, N),
    quantity(N, 'rule', Count),
    format(S, 'Not checked — ~w this input cannot answer:~n', [Count]),
    forall(member(nc(_, Citation, Reason), NCs),
           format(S, '  [~w]~t~14| ~w~n', [Citation, Reason])).

% Counted by severity rather than lumped together: a report carrying only
% warnings is still valid, and calling those "violations" misreads it.
tally(Violations, Tally) :-
    findall(Part,
            ( severity_rank(Severity, _),
              aggregate_all(count, member(v(_, _, Severity, _, _), Violations), N),
              N > 0,
              severity_noun(Severity, Noun),
              quantity(N, Noun, Part)
            ),
            Parts),
    atomic_list_concat(Parts, ', ', Tally).

severity_noun(error,         'error').
severity_noun(indeterminate, 'undecidable check').
severity_noun(warning,       'warning').

verdict_headline(valid,         'VALID').
verdict_headline(invalid,       'INVALID').
verdict_headline(indeterminate, 'INDETERMINATE').

violation_line(v(_Rule, Citation, Severity, Message, _Evidence), S) :-
    format(S, '  [~w]~t~14| ~w~t~30| ~w~n', [Citation, Severity, Message]).

fare_line(Fare, S) :-
    N = Fare.continents,
    Cabin = Fare.cabin,
    (   Fare.basis == none
    ->  format(S, 'Fare basis: none published for ~d continents in ~w.~n', [N, Cabin])
    ;   quantity(N, 'continent', Count),
        format(S, 'Fare basis: ~w (~w, ~w)~n', [Fare.basis, Count, Cabin])
    ),
    upgrade_line(Fare, S).

upgrade_line(Fare, S) :-
    Usd = Fare.premium_economy_upgrade_usd,
    (   Fare.cabin == economy, Usd > 0
    ->  format(S, 'Premium economy upgrade (section 12, all segments): USD ~d~n', [Usd])
    ;   true
    ).

