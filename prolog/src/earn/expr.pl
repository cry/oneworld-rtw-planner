:- module(earn_expr, [eval/4, rounding/2, expr_shape/1]).

/** <module> Accrual expressions.

    A programme's accrual table binds a rate rather than a number, so that a
    table of fixed integers and a table of "a percentage of flown miles" reach
    the reader down one path instead of two. Cathay needs both *inside one
    programme* -- its own metal earns from a table and its partners earn a
    share of the miles flown -- so this is not a hypothetical about a third
    programme; it is the second one.

        fixed(N)          N, whatever the distance
        pct(P)            P per cent of the distance flown
        max(A, B)         the larger of two rates, which is how a
        min(A, B)         minimum or a cap is written
        sum([A, B, ...])  several rates added
        none              this row earns nothing of this currency, which is a
                          different thing from earning zero of it and a
                          different thing again from not being priced at all

    `none` is the one worth dwelling on. A Qantas region row can publish points
    and a dash under Status Credits, meaning the carrier serving that pair earns
    no status currency at all. Writing that as 0 would make it add correctly and
    read wrongly: a total of "0 Status Credits" over a journey of such sectors
    is true, and a reader is owed the reason.

    Nothing here knows about a programme, a carrier or a currency -- only about
    a rate, a distance and a rounding rule.
*/

%! rounding(?Name, ?Goal) is nondet.
%  How a currency's amounts come off a fraction. Declared per currency by the
%  programme, because the programmes disagree: a percentage accrual has to land
%  on an integer and which way it lands is the airline's choice, not ours.
rounding(nearest, round).
rounding(down,    floor).
rounding(up,      ceiling).

%! expr_shape(?Shape) is nondet.
%  The name of every form eval/4 accepts. Exported so the conformance harness
%  can assert a programme's tables contain nothing else -- a typo in a rate
%  would otherwise fail at the first request that reached that row rather than
%  at the build.
expr_shape(fixed).
expr_shape(pct).
expr_shape(max).
expr_shape(min).
expr_shape(sum).
expr_shape(none).

%! eval(+Expr, +Miles, +Rounding, -Amount) is semidet.
%  Amount is a non-negative integer, or `none`.
%
%  Rounding is applied once, at the end, rather than at each step: rounding the
%  arms of a max/2 separately and then comparing them can pick the smaller of
%  the two true values, and a sum of rounded parts is not the rounded sum.
eval(Expr, Miles, Rounding, Amount) :-
    (   raw(Expr, Miles, Raw)
    ->  (   Raw == none
        ->  Amount = none
        ;   apply_rounding(Rounding, Raw, Amount)
        )
    ;   throw(error(type_error(accrual_expression, Expr), _))
    ).

raw(none, _, none) :- !.
raw(fixed(N), _, N) :- number(N), !.
raw(pct(P), Miles, Raw) :- number(P), !, Raw is Miles * P / 100.
raw(max(A, B), Miles, Raw) :- !, combine(max, A, B, Miles, Raw).
raw(min(A, B), Miles, Raw) :- !, combine(min, A, B, Miles, Raw).
raw(sum(Es), Miles, Raw) :-
    is_list(Es),
    !,
    sum_raw(Es, Miles, 0, Raw).

% Written out rather than folded with a lambda: yall copies its goal and would
% rename the Miles the arms have to be evaluated against.
sum_raw([], _, Acc, Acc).
sum_raw([E|T], Miles, Acc0, Raw) :-
    raw(E, Miles, R),
    ( R == none -> Acc = Acc0 ; Acc is Acc0 + R ),
    sum_raw(T, Miles, Acc, Raw).

% A `none` arm is not a zero to compare against: the larger of "nothing" and a
% rate is that rate, and the smaller of them is still that rate rather than
% nothing, because a row that prices one arm has priced the pair.
combine(How, A, B, Miles, Raw) :-
    raw(A, Miles, RA),
    raw(B, Miles, RB),
    (   RA == none -> Raw = RB
    ;   RB == none -> Raw = RA
    ;   Goal =.. [How, RA, RB],
        Raw is Goal
    ).

apply_rounding(Name, Raw, Amount) :-
    (   rounding(Name, Goal)
    ->  true
    ;   throw(error(domain_error(rounding, Name), _))
    ),
    Term =.. [Goal, Raw],
    Amount0 is Term,
    Amount is max(0, Amount0).
