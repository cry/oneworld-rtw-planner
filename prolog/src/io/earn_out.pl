:- module(earn_out, [earn_json/2, programs_json/1]).

/** <module> Earn report -> JSON dict.

    The kernel already builds dicts, so this is nearly a pass-through. It exists
    for the one thing that is not: an amount can be `none` or `indeterminate`,
    and neither may reach a JSON consumer as a number.

    Both become `null`, with `known` saying which of the two it was. A client
    that renders `value` and ignores `known` prints a blank rather than a zero,
    which is the failure this shape is chosen to make impossible -- a `0` in a
    points column is a claim, and it is the wrong one in both cases.
*/

:- use_module('../earn/kernel').
:- use_module('../earn/registry').
:- use_module(library(apply)).
:- use_module(library(lists)).

%! earn_json(+Report, -Dict) is det.
earn_json(Report, _{ segments: Segments, programs: Programs }) :-
    Segments = Report.segments,
    maplist(program_json, Report.programs, Programs).

program_json(P, _{ id: Id, name: Name,
                   currencies: Currencies,
                   totals: Totals,
                   segments: Rows,
                   sources: Sources,
                   notes: Notes }) :-
    Id = P.id, Name = P.name,
    Currencies = P.currencies,
    Sources = P.sources,
    Notes = P.notes,
    maplist(total_json, P.totals, Totals),
    maplist(row_json, P.segments, Rows).

total_json(T, _{ currency: Key, amount: Amount,
                 lowerBound: Bound, unpricedSegments: Unpriced }) :-
    Key = T.currency, Amount = T.amount,
    Bound = T.lowerBound, Unpriced = T.unpriced.

row_json(R, _{ segment: N, from: From, to: To, type: Type,
               marketingCarrier: Carrier, bookingClass: Class,
               outcome: Outcome, reason: Reason,
               distanceMiles: Distance,
               bucket: Bucket, bucketBasis: BucketBasis,
               routeBasis: Basis,
               nearBoundaryMiles: Near,
               amounts: Amounts }) :-
    N = R.segment, From = R.from, To = R.to, Type = R.type,
    Carrier = R.carrier, Class = R.bookingClass,
    Outcome = R.outcome, Reason = R.reason,
    Distance = R.distance,
    Bucket = R.bucket, BucketBasis = R.bucketBasis,
    Basis = R.basis, Near = R.nearBoundary,
    maplist(amount_json, R.amounts, Amounts).

amount_json(A, _{ currency: Key, value: Value, known: Known,
                  base: Base, bonus: Bonus, tier: Tier }) :-
    Key = A.currency,
    Bonus = A.bonus, Tier = A.tier,
    known_value(A.value, Value, Known),
    (   number(Value)
    ->  Base is Value - Bonus
    ;   Base = null
    ).

known_value(none,          null, published_as_none) :- !.
known_value(indeterminate, null, unknown) :- !.
known_value(V,             V,    known).

%! programs_json(-Dict) is det.
%  Everything a client would otherwise have to hardcode about the programmes,
%  for the same reason /api/ruleset exists: the page names no programme, no
%  currency and no tier of its own, so it cannot drift from the tables.
programs_json(_{ programs: Programs }) :-
    earn_programs(Ids),
    maplist(program_summary, Ids, Programs).

program_summary(Id, _{ id: Id, name: Name,
                       currencies: Currencies,
                       sources: Sources,
                       notes: Notes }) :-
    earn_program(Id, Name, _),
    findall(_{ key: Key, name: CName,
               bonusApplies: Bonus, rounding: Rounding, scope: Scope },
            ( currency(Id, Key, CName, Opts),
              option_or(bonus_applies(B), Opts, false, B, Bonus),
              option_or(rounding(R), Opts, nearest, R, Rounding),
              option_or(scope(Sc), Opts, per_segment, Sc, Scope) ),
            Currencies),
    findall(_{ table: Table, url: Url, fetched: Fetched },
            program_source(Id, Table, source(Url, Fetched)),
            Sources),
    findall(Note, program_note(Id, Note), Notes).

option_or(Template, Opts, Default, Var, Value) :-
    (   memberchk(Template, Opts)
    ->  Value = Var
    ;   Value = Default
    ).
