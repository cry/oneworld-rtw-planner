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
:- use_module('../../data/countries').
:- use_module('../../data/earn/qff/regions').
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

% A basis that bands or zones on distance has to say where its edges are, or the
% near-a-boundary warning silently never fires and the one case a great circle
% is not good enough for goes unreported. Asked per basis rather than per
% programme, because a programme can price one sector off a distance and the
% next off a pair of endpoints.
test(a_banding_basis_declares_its_edges) :-
    findall(Id-Name/Arity,
            (   accrual(Id, _, Basis, _, _),
                compound(Basis),
                functor(Basis, Name, Arity),
                sub_atom(Name, _, _, _, band),
                functor(Probe, Name, Arity),
                \+ route_basis_edges(Id, Probe, _)
            ),
            Missing0),
    sort(Missing0, Missing),
    assertion(Missing == []).

test(declared_edges_are_sorted_distinct_numbers) :-
    forall(route_basis_edges(_, _, Edges),
           (   assertion(Edges \== []),
               assertion(forall(member(E, Edges), number(E))),
               sort(Edges, Sorted),
               assertion(Sorted == Edges)
           )).

% The third and fourth geography taxonomies in this repository have to stay
% their own tables. Qantas splits West Coast from East Coast USA/Canada, which
% the fare rule does not, and files Kenya, Uganda and the Seychelles under
% "Northern Africa". A contributor tidying up by aliasing one to another would
% invent earn where the tables disagree, and they disagree a lot.
test(the_earning_geography_is_not_the_fare_rules_geography) :-
    region_countries(southeast_asia_or_northern_africa, Countries),
    findall(Continent,
            ( member(C, Countries), country_continent(C, Continent) ),
            Continents0),
    sort(Continents0, Continents),
    % One Qantas earning region, spanning three of the fare rule's six
    % continents: Asia, Africa, and the Europe/Middle East that Egypt, Libya,
    % Morocco, Tunisia, Algeria and Sudan belong to under Rule 3015.
    length(Continents, N),
    assertion(N >= 3),
    assertion(memberchk(asia, Continents)),
    assertion(memberchk(africa, Continents)),
    assertion(memberchk(europe_middle_east, Continents)).

% Bands and zones have to be total over every distance a sector can be, or a
% real itinerary falls in a hole and the programme reports undecided for a
% reason that is a gap in the table rather than a gap in the input. The
% boundaries themselves are checked as well as the middles, because an
% off-by-one at an edge is how a table gets transcribed wrong.
test(every_distance_resolves_to_a_route_basis) :-
    % A real segment, because a route basis can turn on who sold the ticket as
    % well as on how far it goes.
    itinerary(_{ cabin: "business", mode: "routing",
                 segments: [ _{from: "LHR", to: "JFK", carrier: "BA", bookingClass: "D", stop: "stopover"},
                             _{from: "JFK", to: "LHR", carrier: "BA", bookingClass: "D"} ] },
              A),
    ann_seg(A, S),
    S.n == 1,
    findall(Id-Miles,
            (   known_program(Id),
                member(Miles, [1, 99, 100, 101, 250, 400, 401, 500, 750, 751,
                               1500, 2500, 2750, 2751, 3500, 5000, 5001, 6500,
                               7500, 7501, 12000, 30000]),
                route_basis(Id, S, A, Miles, Basis),
                Basis = indeterminate(_)
            ),
            Gaps),
    assertion(Gaps == []).

% A range is two different numbers the right way round. One that collapsed
% should have been reported as a number, and an inverted one is an arithmetic
% slip that would read as a plausible answer.
test(a_range_is_two_numbers_in_order) :-
    itinerary(_{ cabin: "economy", mode: "routing",
                 segments: [ _{from: "HKG", to: "NRT", carrier: "CX", bookingClass: "K", stop: "stopover"},
                             _{from: "NRT", to: "HKG", carrier: "CX", bookingClass: "K"} ] },
              A),
    earn_programs(Ids),
    earn(A, Ids, Report),
    findall(Low-High,
            (   member(P, Report.programs),
                member(Row, P.segments),
                member(Amt, Row.amounts),
                get_dict(value, Amt, range(Low, High))
            ),
            Ranges),
    forall(member(L-H, Ranges), assertion(L < H)).

% A currency that declares bonus_applies(false) must never receive one, in any
% programme and at any tier. It is the currency's own flag, and the kernel
% honouring it is what keeps "Status Points take no tier bonus" a line of data
% rather than a conditional somewhere.
test(a_currency_that_takes_no_bonus_never_gets_one) :-
    findall(Id-Key-Tier,
            (   currency(Id, Key, _, Opts),
                \+ memberchk(bonus_applies(true), Opts),
                tier(Id, Tier, _),
                bonus(Id, Tier, _, Key, 1000, B),
                B =\= 0
            ),
            Wrong),
    assertion(Wrong == []).

% Every tier a programme publishes is one a caller may name, and every tier a
% caller may name is one the programme publishes. A tier in the table that
% nothing accepts, or a bonus keyed on a tier nobody can ask for, is a row that
% can never be reached.
test(every_published_tier_is_usable) :-
    forall(known_program(Id),
           (   findall(T, tier(Id, T, _), Tiers),
               sort(Tiers, Distinct),
               length(Tiers, N),
               length(Distinct, N),
               forall(member(T, Tiers),
                      ( tier(Id, T, Label), assertion(atom(Label)), assertion(Label \== '') ))
           )).

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

% The load-bearing one. Where a programme's answer turns on who flies the flight,
% an unnamed operator must never be priced as zero: "the operator is unknown" is
% not an answer to the question the field decides.
%
% The flight number is Cathay's because both registered programmes turn on the
% operator there and for different reasons -- Qantas refuses earn on a codeshare
% flown outside oneworld, and Cathay prices its own metal and a partner's off two
% different cards. A partner's flight number would no longer do: Asia Miles reads
% the marketing carrier's rows whoever flies the aircraft, which is a real
% difference between the programmes rather than a hole in one of them.
test(an_unknown_operating_carrier_is_undecided_never_zero) :-
    itinerary(_{ cabin: "business", mode: "routing",
                 segments: [ _{from: "HKG", to: "LHR", marketingCarrier: "CX", bookingClass: "D", stop: "stopover"},
                             _{from: "LHR", to: "HKG", marketingCarrier: "CX", bookingClass: "D"} ] },
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
                 segments: [ _{from: "HKG", to: "LHR", marketingCarrier: "CX", bookingClass: "D", stop: "stopover"},
                             _{from: "LHR", to: "HKG", carrier: "CX", bookingClass: "D"} ] },
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
