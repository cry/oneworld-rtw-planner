:- module(test_earn_conformance, []).

/** <module> Every registered earning programme must pass this.

    The deliverable that makes a third programme cheap. Adding one is a
    resolver module, a directory of tables and a directory of fixtures; if
    conformance passes, it is wired correctly, and nothing in this file had to
    learn its name.

    Two of the assertions below are worth more than the rest and are the reason
    the others exist to keep them company:

      * a bucket every accrual can price, and an accrual for every bucket. A
        table with an unreachable row is a transcription error nobody would
        notice; a bucket with no row is a request that returns `indeterminate`
        for a reason the reader will assume is their fault.
      * indeterminate never rendered as zero. Every currency of every programme
        has to survive an unnamed operating carrier as an undecided answer.

    The register-coverage test in test_rules.pl is this file's counterpart on
    the validation side, and for the same reason: a number nobody can trace back
    to a row is worse than no number.
*/

:- use_module(library(plunit)).
:- use_module('../../src/earn/kernel').
:- use_module('../../src/earn/registry').
:- use_module('../../src/earn/expr').
:- use_module('../../src/earn/distance').
:- use_module('../../src/annotate').
:- use_module('../../src/itinerary').
:- use_module('../../src/io/json_in').
:- use_module('../../data/limits').
:- use_module(library(lists)).
:- use_module(library(apply)).

:- begin_tests(earn_conformance).

% Nothing below means anything if the list is empty, and an empty list is what a
% registry file broken by a bad merge produces.
test(at_least_one_programme_is_registered) :-
    earn_programs(Ids),
    assertion(Ids \== []).

test(every_programme_declares_a_name_and_a_currency) :-
    forall(known_program(Id),
           (   earn_program(Id, Name, _),
               assertion(atom(Name)),
               assertion(Name \== ''),
               findall(K, currency(Id, K, _, _), Keys),
               assertion(Keys \== []),
               sort(Keys, Distinct),
               length(Keys, N), length(Distinct, N)   % no currency declared twice
           )).

% A currency nothing produces is a promise in /api/programs that no report can
% keep.
test(every_declared_currency_is_produced_by_some_accrual) :-
    findall(Id-Key,
            (   currency(Id, Key, _, _),
                \+ ( accrual(Id, _, _, _, Rates), memberchk(rate(Key, _), Rates) )
            ),
            Orphans),
    assertion(Orphans == []).

% And the other direction: a rate for a currency the programme never declared
% would be computed and then silently dropped.
test(every_priced_currency_is_declared) :-
    findall(Id-Key,
            (   accrual(Id, _, _, _, Rates),
                member(rate(Key, _), Rates),
                \+ currency(Id, Key, _, _)
            ),
            Strays),
    sort(Strays, Sorted),
    assertion(Sorted == []).

% Every rate is something src/earn/expr.pl can evaluate. A typo here would
% otherwise fail at the first request that reached the row rather than here.
test(every_rate_is_a_known_expression) :-
    findall(Id-Expr,
            (   accrual(Id, _, _, _, Rates),
                member(rate(_, Expr), Rates),
                \+ well_formed(Expr)
            ),
            Bad),
    assertion(Bad == []).

well_formed(none) :- !.
well_formed(Expr) :-
    compound(Expr),
    functor(Expr, Name, _),
    expr_shape(Name),
    Expr =.. [_|Args],
    forall(member(Arg, Args), well_formed_arg(Arg)).

well_formed_arg(Arg) :- number(Arg), !.
well_formed_arg(Args) :- is_list(Args), !, forall(member(A, Args), well_formed(A)).
well_formed_arg(Arg) :- well_formed(Arg).

% A programme that bands or zones on distance has to say where its edges are, or
% the near-a-boundary warning silently never fires and the one case a great
% circle is not good enough for goes unreported.
test(a_banding_programme_declares_its_edges) :-
    forall(( known_program(Id), banded(Id) ),
           (   route_basis_edges(Id, Edges),
               assertion(Edges \== []),
               assertion(forall(member(E, Edges), number(E))),
               msort(Edges, Sorted),
               assertion(Sorted == Edges)
           )).

banded(Id) :- accrual(Id, _, Basis, _, _), compound(Basis), functor(Basis, F, _),
              sub_atom(F, _, _, _, band), !.

% --- the same assertions, run over an itinerary ----------------------------

% Surface sectors earn nothing in every programme, and it is `n/a` rather than
% undecided: nobody flew it, so there is nothing missing.
test(a_surface_sector_earns_nothing_everywhere) :-
    itinerary(_{ cabin: "business", mode: "routing",
                 segments: [ _{from: "LHR", to: "JFK", carrier: "BA", bookingClass: "D", stop: "stopover"},
                             _{type: "surface", from: "JFK", to: "BOS", stop: "stopover"},
                             _{from: "BOS", to: "LHR", carrier: "BA", bookingClass: "D"} ] },
              A),
    earn_programs(Ids),
    earn(A, Ids, Report),
    forall(member(P, Report.programs),
           (   member(Row, P.segments),
               Row.segment == 2
           ->  assertion(Row.outcome == not_applicable),
               assertion(Row.amounts == [])
           ;   true
           )).

% The load-bearing one. An unnamed operator must never be priced as zero, in any
% programme: the restriction it blocks is about who flies the flight, and "the
% operator is unknown" is not an answer to that.
test(an_unknown_operating_carrier_is_undecided_never_zero) :-
    itinerary(_{ cabin: "business", mode: "routing",
                 segments: [ _{from: "LHR", to: "JFK", marketingCarrier: "BA", bookingClass: "D", stop: "stopover"},
                             _{from: "JFK", to: "LHR", marketingCarrier: "BA", bookingClass: "D"} ] },
              A),
    earn_programs(Ids),
    earn(A, Ids, Report),
    forall(member(P, Report.programs),
           forall(member(Row, P.segments),
                  (   assertion(Row.outcome == indeterminate),
                      assertion(\+ ( member(Amt, Row.amounts), get_dict(value, Amt, V), V == 0 ))
                  ))).

% ...and it must reach the journey total as a lower bound rather than as a
% smaller number that looks complete.
test(an_unpriced_sector_makes_the_total_a_lower_bound) :-
    itinerary(_{ cabin: "business", mode: "routing",
                 segments: [ _{from: "LHR", to: "JFK", marketingCarrier: "BA", bookingClass: "D", stop: "stopover"},
                             _{from: "JFK", to: "LHR", carrier: "BA", bookingClass: "D"} ] },
              A),
    earn_programs(Ids),
    earn(A, Ids, Report),
    forall(member(P, Report.programs),
           forall(member(Total, P.totals),
                  (   assertion(Total.lowerBound == true),
                      assertion(Total.unpriced > 0)
                  ))).

% Asking for two programmes at once must be the same computation as asking for
% each on its own. It is the only reason a multi-programme reply is worth having,
% and it is the property a shared cache or a stray side effect would break.
test(asking_together_matches_asking_separately) :-
    itinerary(_{ cabin: "business", mode: "routing",
                 segments: [ _{from: "LHR", to: "JFK", carrier: "BA", bookingClass: "D", stop: "stopover"},
                             _{from: "JFK", to: "LHR", carrier: "BA", bookingClass: "D"} ] },
              A),
    earn_programs(Ids),
    earn(A, Ids, Together),
    findall(One, ( member(Id, Ids), earn(A, [Id], R), R.programs = [One] ), Separately),
    assertion(Together.programs == Separately).

% 4(h) caps the journey at 16 segments, so no programme can report more rows
% than the validator would ever accept. A free ceiling, and the shape of bug it
% catches -- a resolver that emits a row per candidate rather than per sector --
% is one that would otherwise inflate a total rather than fail.
test(no_programme_reports_more_rows_than_4h_allows) :-
    itinerary(_{ route: "LHR-BA-JFK-AA-X/LAX-QF-SYD-QF-X/SIN-BA-LHR", cabin: "business" }, A),
    limit(max_segments, Max),
    earn_programs(Ids),
    earn(A, Ids, Report),
    forall(member(P, Report.programs),
           (   length(P.segments, N),
               assertion(N =< Max),
               assertion(N == Report.segments)
           )).

% Every programme's provenance is present, because a number from an unversioned
% table with no fetch date is a number nobody can check.
test(every_programme_carries_a_source_and_a_caveat) :-
    forall(known_program(Id),
           (   findall(S, program_source(Id, _, S), Sources),
               assertion(Sources \== []),
               forall(member(source(Url, Fetched), Sources),
                      (   assertion(sub_atom(Url, 0, _, _, 'https://')),
                          assertion(fetched_date(Fetched))
                      )),
               findall(N, program_note(Id, N), Notes),
               assertion(Notes \== [])
           )).

fetched_date(Atom) :- atom_length(Atom, 10), parse_dt(Atom, _).

itinerary(Dict, A) :-
    itinerary_from_json(Dict, Itin),
    annotate(Itin, A).

:- end_tests(earn_conformance).
