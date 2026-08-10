:- module(explain, [explain/2, explain/1, verdict_headline/2]).

/** <module> Report term -> human-readable text.

    One of two renderers over report/3; io/json_out.pl is the other. Neither
    contains rule logic, which is what keeps the CLI and the HTTP service
    saying the same thing.
*/

:- use_module('../data/limits').
:- use_module(validate).

%! explain(+Report) is det.
explain(Report) :- explain(Report, current_output).

%! explain(+Report, +Stream) is det.
explain(report(Verdict, Violations, Fare), S) :-
    verdict_headline(Verdict, Head),
    (   tally(Violations, Tally), Tally \== ''
    ->  format(S, '~w — ~w~n', [Head, Tally])
    ;   format(S, '~w~n', [Head])
    ),
    forall(member(V, Violations), violation_line(V, S)),
    fare_line(Fare, S).

% Counted by severity rather than lumped together: a report carrying only
% warnings is still valid, and calling those "violations" misreads it.
tally(Violations, Tally) :-
    findall(Part,
            ( severity_rank(Severity, _),
              aggregate_all(count, member(v(_, _, Severity, _, _), Violations), N),
              N > 0,
              severity_noun(Severity, Noun),
              plural(N, Noun, Word),
              format(atom(Part), '~d ~w', [N, Word])
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
    ;   plural(N, 'continent', Word),
        format(S, 'Fare basis: ~w (~d ~w, ~w)~n', [Fare.basis, N, Word, Cabin])
    ),
    upgrade_line(Fare, S).

upgrade_line(Fare, S) :-
    Usd = Fare.premium_economy_upgrade_usd,
    (   Fare.cabin == economy, Usd > 0
    ->  format(S, 'Premium economy upgrade (section 12, all segments): USD ~d~n', [Usd])
    ;   true
    ).

plural(1, Word, Word) :- !.
plural(_, Word, Plural) :- atom_concat(Word, s, Plural).
