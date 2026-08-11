:- module(transcon,
          [ transcon_column/2,
            alaska_region/1,
            transcontinental_pair/2
          ]).

/** <module> 4(k) transcontinental US definition.

    Kept separate from the continent tables on purpose: this is a third
    taxonomy (US states in two columns) that has nothing to do with the
    section 0 continent list, and folding them together is an easy bug.
    Matched on iso_region, which is why the generated airport table carries it.

    Neither column lists Hawaii, and this table does not add it. That is a
    decision, not an oversight. Experienced bookers do apply 4(k) to Hawaii --
    the advice "you have already used your transcontinental flight on LAX-NYC,
    so fly NYC-DFW-HNL rather than NYC-HNL" only follows if HNL is Column A,
    since routing via Texas defeats it and Texas is in neither column. But
    4(k)'s own sentence is a closed definition ("travel between a State in
    Column A and a State in Column B"), the rule gives Alaska a separate
    sentence rather than a column, and it gives Hawaii a separate sentence too
    -- in 4(b), where backtracking to Hawaii is barred outright. A place the
    rule handles in its own clause is not obviously also a column entry.

    If this is revisited, note that Alaska is the control: it must stay out of
    both columns, so ANC-PHL is not transcontinental. Adding Hawaii by
    loosening the table would sweep Alaska in with it.
*/

%! transcon_column(?IsoRegion, ?Column) is nondet.
transcon_column('US-AZ', a).
transcon_column('US-CA', a).
transcon_column('US-NV', a).
transcon_column('US-OR', a).
transcon_column('US-WA', a).

transcon_column('US-CT', b).
transcon_column('US-FL', b).
transcon_column('US-GA', b).
transcon_column('US-IN', b).
transcon_column('US-MD', b).
transcon_column('US-MA', b).
transcon_column('US-NJ', b).
transcon_column('US-NY', b).
transcon_column('US-NC', b).
transcon_column('US-OH', b).
transcon_column('US-PA', b).
transcon_column('US-MI', b).
transcon_column('US-SC', b).
transcon_column('US-TN', b).
transcon_column('US-VA', b).
transcon_column('US-DC', b).
transcon_column('US-KY', b).

%! transcontinental_pair(+FromRegion, +ToRegion) is semidet.
%  Direction-independent: a flight between a Column A state and a Column B
%  state is transcontinental whichever way it is flown.
transcontinental_pair(From, To) :-
    transcon_column(From, X),
    transcon_column(To, Y),
    X \== Y,
    !.

%! alaska_region(?IsoRegion) is nondet.
%  4(k): one flight to and one flight from the State of Alaska.
alaska_region('US-AK').
