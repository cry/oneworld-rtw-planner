:- module(earn_kernel,
          [ earn/3,
            earn_program/3,
            currency/4,
            eligible/4,
            fare_bucket/4,
            route_basis/5,
            route_basis_edges/3,
            accrual/5,
            bonus/5,
            program_source/3,
            program_note/2,
            currency_option/3,
            known_program/1
          ]).

/** <module> What a routing earns: sequencing, totals and the earn register.

    Nothing in this file names a programme. A programme is a module supplying
    multifile clauses of the protocol below, and the kernel decides only the
    order they are asked in, what an unanswered question means, and how the
    answers add up.

    That is the whole design. Qantas and Cathay disagree at nearly every join --
    region pairs against distance zones, an earn category against a cabin and a
    fare family, fixed integers against a share of the miles flown, a tier bonus
    on one currency and not the other -- so the thing they share is the pipeline
    and not the lookup. If a table lookup were the interface, Cathay would be a
    special case in it and a third programme would be a rewrite.

    The protocol:

        earn_program(Id, DisplayName, ProvenanceKey)
        currency(Id, CurrencyKey, DisplayName, Opts)
        eligible(Id, Segment, Annotated, Outcome)
        fare_bucket(Id, Segment, Bucket, Basis)
        route_basis(Id, From, To, Distance, Basis)
        accrual(Id, Bucket, Basis, Carrier, Rates)
        bonus(Id, Tier, CurrencyKey, BaseAmount, BonusAmount)
        program_source(Id, Table, Source)
        program_note(Id, Note)

    Four properties hold it together, and all four have to be preserved.

    *A bucket is opaque.* Qantas binds category(business); Cathay binds
    bucket(business, flex). The kernel only ever hands a bucket back to the same
    programme's accrual/5, so a programme whose bucket comes from somewhere this
    file has never heard of needs no change here.

    *route_basis/5 takes airports, not just a distance.* Cathay's Short-Type 2
    zone is 751 to 2,750 miles *to or from* one of six countries, which distance
    alone cannot decide. With the endpoints in the signature, Qantas' region pair
    and its mileage-band fallback become two clauses of one predicate instead of
    two mechanisms.

    *An accrual returns an expression, not a number.* See src/earn/expr.pl:
    fixed rates and proportional ones then share one path, which Cathay needs
    within a single programme.

    *A currency declares its own rules.* "Status Points take no tier bonus" is
    bonus_applies(false) in the programme's data, never a conditional here.

    Undecidability propagates rather than collapsing. A segment the programme
    cannot price does not earn zero -- it earns `indeterminate`, the journey
    total is marked a lower bound, and every renderer has to say so. That is the
    same standard the validator holds itself to, and the reason it matters more
    here is that a number is so much easier to believe than a verdict.
*/

:- use_module('../annotate').
:- use_module('../geo').
:- use_module(distance).
:- use_module(expr).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(aggregate)).

:- multifile earn_program/3.
:- multifile currency/4.
:- multifile eligible/4.
:- multifile fare_bucket/4.
:- multifile route_basis/5.
:- multifile accrual/5.
:- multifile bonus/5.
:- multifile program_source/3.
:- multifile program_note/2.

:- discontiguous earn_program/3.

%! known_program(?Id) is nondet.
known_program(Id) :- earn_program(Id, _, _).

%! currency_option(+Id, +Key, ?Option) is nondet.
currency_option(Id, Key, Option) :-
    currency(Id, Key, _, Opts),
    memberchk(Option, Opts).

% --- the top level ---------------------------------------------------------

%! earn(+A, +Ids, -Report) is det.
%  A is the annotated itinerary; Ids are the programmes asked for, in the order
%  they were asked for. Every programme is answered over the same annotation,
%  which is what makes asking for two of them at once the same computation as
%  asking for each separately -- a property the suite asserts, and the only
%  reason "where should I credit this ticket?" is a question this can answer.
earn(A, Ids, earn{ programs: Programs, segments: SegmentCount }) :-
    ann_segment_count(A, SegmentCount),
    maplist(program_report(A), Ids, Programs).

program_report(A, Id, Report) :-
    (   earn_program(Id, Name, _)
    ->  true
    ;   format(atom(M), 'There is no "~w" earning programme.', [Id]),
        throw(input_error(M))
    ),
    findall(cur{ key: Key, name: CName, bonusApplies: Bonus },
            ( currency(Id, Key, CName, Opts),
              ( memberchk(bonus_applies(true), Opts) -> Bonus = true ; Bonus = false ) ),
            Currencies),
    findall(S, ann_seg(A, S), Segs),
    maplist(segment_row(Id, A), Segs, Rows),
    findall(Key, member(cur{ key: Key, name: _, bonusApplies: _ }, Currencies), Keys),
    maplist(total_for(Rows), Keys, Totals),
    findall(src{ table: Table, url: Url, fetched: Fetched },
            ( program_source(Id, Table, source(Url, Fetched)) ),
            Sources),
    findall(Note, program_note(Id, Note), Notes),
    Report = program{ id: Id, name: Name,
                      currencies: Currencies,
                      segments: Rows,
                      totals: Totals,
                      sources: Sources,
                      notes: Notes }.

% --- one segment -----------------------------------------------------------

% The order below is the whole of the kernel's opinion about earning, and each
% step is here because leaving it out would produce a number rather than a
% question.
segment_row(Id, A, S, Row) :-
    (   S.type == surface
    ->  outcome_row(S, not_applicable,
                    'A surface sector is not flown, so it earns nothing.', [], Row)
    ;   eligibility(Id, S, A, Eligibility),
        (   Eligibility = ineligible(Why)
        ->  outcome_row(S, not_applicable, Why, [], Row)
        ;   Eligibility = indeterminate(Why)
        ->  outcome_row(S, indeterminate, Why, [], Row)
        ;   priced_row(Id, A, S, Row)
        )
    ).

% A programme that declares no eligibility rule earns on everything it can
% price. Saying so here rather than requiring a clause keeps the smallest
% possible programme small.
eligibility(Id, S, A, Outcome) :-
    (   eligible(Id, S, A, Out)
    ->  Outcome = Out
    ;   Outcome = eligible
    ).

priced_row(Id, A, S, Row) :-
    From = S.from, To = S.to,
    (   sector_distance(From, To, Miles)
    ->  bucket_step(Id, A, S, Miles, Row)
    ;   iata(From, UF), iata(To, UT),
        format(atom(Why),
               'No coordinates for ~w or ~w, so the distance this earn depends on cannot be measured.',
               [UF, UT]),
        outcome_row(S, indeterminate, Why, [], Row)
    ).

bucket_step(Id, A, S, Miles, Row) :-
    (   fare_bucket(Id, S, Bucket, BucketBasis)
    ->  (   Bucket = indeterminate(Why)
        ->  outcome_row(S, indeterminate, Why, [distance(Miles)], Row)
        ;   basis_step(Id, A, S, Miles, Bucket, BucketBasis, Row)
        )
    ;   outcome_row(S, indeterminate,
                    'This programme publishes no earning category for the class this segment is sold in.',
                    [distance(Miles)], Row)
    ).

basis_step(Id, A, S, Miles, Bucket, BucketBasis, Row) :-
    (   route_basis(Id, S.from, S.to, Miles, Basis)
    ->  (   Basis = indeterminate(Why)
        ->  outcome_row(S, indeterminate, Why,
                        [distance(Miles), bucket(Bucket, BucketBasis)], Row)
        ;   accrual_step(Id, A, S, Miles, Bucket, BucketBasis, Basis, Row)
        )
    ;   outcome_row(S, indeterminate,
                    'This programme has no route basis for this pair of airports.',
                    [distance(Miles), bucket(Bucket, BucketBasis)], Row)
    ).

accrual_step(Id, A, S, Miles, Bucket, BucketBasis, Basis, Row) :-
    Carrier = S.marketing,
    (   accrual(Id, Bucket, Basis, Carrier, Rates)
    ->  amounts(Id, A, Miles, Rates, Amounts),
        near_boundary_flag(Id, Basis, Miles, Flag),
        outcome_row(S, ok, null,
                    [distance(Miles), bucket(Bucket, BucketBasis), basis(Basis),
                     near_boundary(Flag), amounts(Amounts)],
                    Row)
    ;   outcome_row(S, indeterminate,
                    'This programme has no published rate for that category on that route.',
                    [distance(Miles), bucket(Bucket, BucketBasis), basis(Basis)], Row)
    ).

% A distance within a whisker of a band or zone edge is where a great circle
% stops being a good enough stand-in for the airline's own mileage -- see
% src/earn/distance.pl.
%
% The edges are asked for *per basis*, not per programme, because a programme
% can price one sector off a distance and the next off a pair of endpoints. A
% basis that never looked at the distance has no edge to be near, and flagging
% it would tell the reader to go and check a number that decided nothing.
near_boundary_flag(Id, Basis, Miles, Flag) :-
    (   route_basis_edges(Id, Basis, Edges),
        near_boundary(Miles, Edges, Edge)
    ->  Flag = Edge
    ;   Flag = null
    ).

:- multifile route_basis_edges/3.

% --- amounts ---------------------------------------------------------------

% One amount per currency the programme declares, in the order it declares
% them, whether or not the rate row mentions it. A rate row that is silent about
% a declared currency has not priced it, and the difference between that and
% pricing it at nothing is exactly the difference this whole design exists to
% keep: `none` is published, `indeterminate` is missing.
amounts(Id, A, Miles, Rates, Amounts) :-
    findall(Amount,
            ( currency(Id, Key, _, Opts),
              amount_for(Id, A, Miles, Rates, Key, Opts, Amount) ),
            Amounts).

amount_for(Id, A, Miles, Rates, Key, Opts, amt{ currency: Key, value: Value,
                                                bonus: Bonus, tier: Tier }) :-
    (   memberchk(rounding(Rounding), Opts) -> true ; Rounding = nearest ),
    (   memberchk(rate(Key, Expr), Rates)
    ->  eval(Expr, Miles, Rounding, Base)
    ;   Base = indeterminate
    ),
    tier_bonus(Id, A, Key, Opts, Base, Tier, Bonus),
    (   number(Base), number(Bonus)
    ->  Value is Base + Bonus
    ;   Value = Base
    ).

% Phase 5 fills this in from the programmes' tier tables. Until a tier reaches
% the kernel there is no bonus to apply, and saying that here -- rather than
% leaving the field out -- is what stops a later reader mistaking a base-rate
% number for a member's actual earn.
tier_bonus(Id, A, Key, Opts, Base, Tier, Bonus) :-
    (   member_tier(A, Id, Tier0)
    ->  Tier = Tier0
    ;   Tier = null
    ),
    (   Tier \== null,
        memberchk(bonus_applies(true), Opts),
        number(Base),
        bonus(Id, Tier, Key, Base, B)
    ->  Bonus = B
    ;   Bonus = 0
    ).

% The annotated itinerary carries no member tier yet; see PLANS/05, phase 5.
member_tier(A, Id, Tier) :-
    get_dict(members, A, Members),
    get_dict(Id, Members, Tier).

% --- totals ----------------------------------------------------------------

% A total over a journey with an unpriced sector is a lower bound and is
% labelled one. Adding what could be priced and printing it as the answer is the
% single most misleading thing this report could do, because the number looks
% exactly like a complete one.
total_for(Rows, Key, tot{ currency: Key, amount: Amount,
                          lowerBound: Bound, unpriced: Unpriced }) :-
    findall(V, ( member(Row, Rows), row_amount(Row, Key, V) ), Values),
    include(number, Values, Numbers),
    sum_list(Numbers, Amount),
    aggregate_all(count, ( member(Row, Rows), Row.outcome == indeterminate ), Undecided),
    aggregate_all(count, member(indeterminate, Values), Missing),
    Unpriced is Undecided + Missing,
    ( Unpriced > 0 -> Bound = true ; Bound = false ).

row_amount(Row, Key, Value) :-
    get_dict(amounts, Row, Amounts),
    member(Amt, Amounts),
    Amt.currency == Key,
    Value = Amt.value.

% --- building a row --------------------------------------------------------

% Every row has the same keys whatever happened to it, so that a renderer never
% has to ask which shape it got and a JSON consumer never meets a missing field.
outcome_row(S, Outcome, Reason, Parts,
            row{ segment: N, from: From, to: To, type: Type,
                 carrier: Carrier, bookingClass: Class,
                 outcome: Outcome, reason: Reason,
                 distance: Distance,
                 bucket: Bucket, bucketBasis: BucketBasis,
                 basis: Basis,
                 nearBoundary: Near,
                 amounts: Amounts }) :-
    N = S.n,
    Type = S.type,
    iata(S.from, From),
    iata(S.to, To),
    iata(S.marketing, Carrier),
    upcase_or_null(S.booking_class, Class),
    part(distance, Parts, null, Distance),
    (   memberchk(bucket(B, BB), Parts)
    ->  bucket_text(B, Bucket), BucketBasis = BB
    ;   Bucket = null, BucketBasis = null
    ),
    (   memberchk(basis(Ba), Parts)
    ->  bucket_text(Ba, Basis)
    ;   Basis = null
    ),
    part(near_boundary, Parts, null, Near),
    part(amounts, Parts, [], Amounts).

part(Name, Parts, Default, Value) :-
    Template =.. [Name, V],
    (   memberchk(Template, Parts)
    ->  Value = V
    ;   Value = Default
    ).

% A bucket and a basis are the programme's own terms, and the kernel has no
% business interpreting them -- but it does have to write them down. So a
% programme may name its own, and one that does not gets term_to_atom, which is
% at least honest: it says exactly what was bound, which is what makes the
% register checkable against that programme's tables.
bucket_text(Term, Text) :-
    (   atom(Term) -> Text = Term
    ;   term_label(Term, Label) -> Text = Label
    ;   term_to_atom(Term, Text)
    ).

:- multifile term_label/2.

upcase_or_null(unknown, null) :- !.
upcase_or_null(A, U) :- upcase_atom(A, U).
