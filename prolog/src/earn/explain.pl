:- module(earn_explain, [explain_earn/2, explain_earn/3, amount_text/2]).

/** <module> Earn report -> human-readable text.

    One of two renderers over the term src/earn/kernel.pl produces;
    src/io/earn_out.pl is the other. Neither decides anything.

    The register below is the check register's counterpart, and it exists for
    the same reason. A total on its own is a claim a reader cannot audit, and
    here the claim is worse than in the validator: a number carries an air of
    having been calculated, and this one was looked up in a table that has no
    version, no clause numbers and no notice period. So every line says which
    category it resolved, how, which route basis priced it, and how far the
    sector was measured to be -- and the fetch date of the table follows the
    totals rather than being buried somewhere a reader will not look.
*/

:- use_module('../phrasing').
:- use_module(kernel).
:- use_module(library(apply)).
:- use_module(library(lists)).

%! explain_earn(+Report, +Stream) is det.
explain_earn(Report, S) :- explain_earn(Report, S, []).

%! explain_earn(+Report, +Stream, +Options) is det.
%  Options: `rows(false)` prints the totals and the provenance without the
%  per-segment register. On by default, unlike the validator's register, because
%  a total nobody can trace is the failure mode this whole feature has to avoid.
explain_earn(Report, S, Opts) :-
    forall(member(Program, Report.programs), program_lines(Program, S, Opts)).

program_lines(Program, S, Opts) :-
    format(S, '~w~n', [Program.name]),
    totals_line(Program, S),
    (   memberchk(rows(false), Opts)
    ->  true
    ;   forall(member(Row, Program.segments), row_line(Program, Row, S))
    ),
    forall(member(Note, Program.notes), format(S, '  ~w~n', [Note])),
    forall(member(Source, Program.sources),
           format(S, '  ~w table read ~w from ~w~n',
                  [Source.table, Source.fetched, Source.url])).

% A lower bound is said in the same breath as the number, never in a footnote.
% The whole point of carrying undecidability this far is lost if the total can
% be read off the line above the caveat.
totals_line(Program, S) :-
    findall(Text, ( member(Total, Program.totals), total_text(Program, Total, Text) ), Texts),
    listed(Texts, Line),
    format(S, '  ~w~n', [Line]).

total_text(Program, Total, Text) :-
    currency_name(Program, Total.currency, Name),
    amount_text(Total.amount, Amount),
    (   Total.lowerBound == true
    ->  quantity(Total.unpriced, 'sector', Unpriced),
        format(atom(Text), '~w ~w or more (~w unpriced)', [Amount, Name, Unpriced])
    ;   format(atom(Text), '~w ~w', [Amount, Name])
    ).

% Two lines: what it earned, then what that was read off. One line cannot hold
% both -- a resolved category, a route basis and a measured distance run past
% any column stop a sixteen-segment journey would keep -- and the amount is what
% the reader came for, so it goes first and the provenance sits under it.
row_line(Program, Row, S) :-
    outcome_word(Row.outcome, Word),
    row_amounts(Program, Row, Amounts),
    row_detail(Row, Detail),
    format(S, '  [~w]~t~7| ~w-~w~t~19| ~w~t~30| ~w~n',
           [Row.segment, Row.from, Row.to, Word, Amounts]),
    format(S, '~t~30| ~w~n', [Detail]).

outcome_word(ok,            'ok').
outcome_word(indeterminate, 'undecided').
outcome_word(not_applicable, 'n/a').

% What was resolved and from what. A reader checking a number against the
% airline's own table needs the row, not the answer.
row_detail(Row, Detail) :-
    (   Row.outcome \== ok
    ->  Detail = Row.reason
    ;   distance_text(Row, Miles),
        (   Row.bucketBasis == null
        ->  format(atom(Head), '~w · ~w · ~w', [Row.bucket, Row.basis, Miles])
        ;   format(atom(Head), '~w (~w) · ~w · ~w',
                   [Row.bucket, Row.bucketBasis, Row.basis, Miles])
        ),
        (   Row.assumption == null
        ->  Detail = Head
        ;   format(atom(Detail), '~w~n~t~30| ~w', [Head, Row.assumption])
        )
    ).

% The measured distance travels with the band it selected, and a distance close
% enough to an edge to be in doubt says so here rather than in a note nobody
% reads -- see the tolerance in src/earn/distance.pl.
distance_text(Row, Text) :-
    (   Row.nearBoundary == null
    ->  format(atom(Text), '~D mi', [Row.distance])
    ;   format(atom(Text), '~D mi — within 1.5% of the ~D-mile edge',
               [Row.distance, Row.nearBoundary])
    ).

row_amounts(_, Row, 'nothing') :-
    Row.amounts == [],
    !.
row_amounts(Program, Row, Text) :-
    findall(T, ( member(Amt, Row.amounts), amount_pair(Program, Amt, T) ), Ts),
    listed(Ts, Text).

amount_pair(Program, Amt, Text) :-
    currency_name(Program, Amt.currency, Name),
    amount_text(Amt.value, Value),
    format(atom(Text), '~w ~w', [Value, Name]).

%! amount_text(+Value, -Text) is det.
%  `none` and `indeterminate` are both rendered as words rather than as 0,
%  because the difference between "this row earns nothing of this" and "nobody
%  said" is the difference a zero would destroy.
amount_text(none, 'no') :- !.
amount_text(indeterminate, 'an unknown number of') :- !.
% A range is written with both ends and never with a midpoint: no combination
% of the traveller's actual fares can produce the middle of it.
amount_text(range(Low, High), Text) :- !,
    format(atom(Text), '~D to ~D', [Low, High]).
amount_text(N, Text) :- format(atom(Text), '~D', [N]).

currency_name(Program, Key, Name) :-
    (   member(Cur, Program.currencies), Cur.key == Key
    ->  Name = Cur.name
    ;   Name = Key
    ).
