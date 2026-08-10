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
    length(Violations, N),
    verdict_headline(Verdict, Head),
    (   N =:= 0
    ->  format(S, '~w~n', [Head])
    ;   plural(N, 'violation', Word),
        format(S, '~w — ~d ~w~n', [Head, N, Word])
    ),
    forall(member(V, Violations), violation_line(V, S)),
    fare_line(Fare, S).

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
