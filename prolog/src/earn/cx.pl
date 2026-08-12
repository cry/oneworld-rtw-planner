:- module(earn_cx, []).

/** <module> Cathay, as a kernel plugin.

    This programme is the interface's audit. It was written second, deliberately
    against a kernel built around Qantas, to find out what that kernel had
    assumed. It forced exactly one change -- ranges, below -- and that change is
    recorded in PLANS/05 rather than absorbed quietly.

    Everything else it needed was already there, and each of those was a
    deliberate choice made in phase 1 for a reason this file is the proof of:

      * *A bucket is opaque.* Qantas binds category(business); this binds
        bucket(economy, flex, ybhk), and the kernel never looks inside either.
      * *route_basis/5 takes the endpoints.* Short - Type 2 is the same 751 to
        2,750 miles as Short - Type 1, separated only by whether the sector is
        to or from one of six countries. A signature taking only a distance
        could not have expressed it.
      * *A currency declares its own rules.* Status Points take no tier bonus
        and Asia Miles do; that is two lines of data here and no conditional in
        the kernel.

    The one thing it did force. Cathay lists the same economy booking classes --
    Y,B,H,K, then M,L,V, then S,N,Q,O -- under Flex, Essential *and* Light, with
    different earn against each. A ticket in K on an ultra-short sector earns 25
    Status Points as Flex, 15 as Essential and 10 as Light. So the class does
    not imply the family and there is nothing to derive one from: an itinerary
    that gives a class and no `fareFamily` has genuinely bought one of three
    things. Refusing to answer would be useless and picking one would be a guess
    wearing the same clothes as an answer, so the bucket comes back as
    `one_of/2` and the kernel prices every candidate and reports the spread.

    That is confined to Economy, and to part of it. In every other cabin the
    class picks the family out on its own: W and R are Premium Economy Flex, E is
    Premium Economy Essential, J and C are Business Flex, D, P and I are Business
    Essential, and F and A are First, which is sold as Flex only. Within Economy,
    Y is full-fare and therefore the flexible fare whatever the grid lists it
    under -- the one place in either programme where a fact that is not on the
    page decides an answer, which is why it is a predicate of its own,
    cx_class_settled/3, carrying its reason into the register. B, H and K are not
    settled that way and stay a range.

    Cathay-marketed flights only. Partner earn is a share of flown miles served
    by Cathay's calculator rather than published as a table, so a partner sector
    comes back undecided saying so -- it earns, and this cannot say how much,
    which is a different thing from earning nothing.
*/

:- use_module('../geo').
:- use_module(presumed).
:- use_module('../../data/earn/cx/buckets').
:- use_module('../../data/earn/cx/zones').
:- use_module('../../data/earn/cx/table_cx').
:- use_module('../../data/earn/cx/source').
:- use_module(library(apply)).
:- use_module(library(lists)).

:- multifile earn_kernel:earn_program/3.
:- multifile earn_kernel:currency/4.
:- multifile earn_kernel:eligible/4.
:- multifile earn_kernel:fare_bucket/5.
:- multifile earn_kernel:route_basis/5.
:- multifile earn_kernel:route_basis_edges/3.
:- multifile earn_kernel:accrual/5.
:- multifile earn_kernel:program_source/3.
:- multifile earn_kernel:program_note/2.
:- multifile earn_kernel:term_label/2.
:- multifile earn_kernel:fare_family/2.

earn_kernel:earn_program(cx, 'Cathay', cx).

% What a caller may put in `fareFamily`. Served from /api/programs so a page can
% offer the choice without knowing a programme's name.
earn_kernel:fare_family(cx, Family) :- cx_family(Family).

% Two currencies out of one number -- every published row has Asia Miles at a
% hundred times Status Points, which the generator refuses to write a table
% without. They stay separate because they are two things a member holds and
% only one of them is what a membership tier is measured in.
earn_kernel:currency(cx, asia_miles, 'Asia Miles',
                     [ rounding(nearest), scope(per_segment), bonus_applies(true) ]).
earn_kernel:currency(cx, status_points, 'Status Points',
                     [ rounding(nearest), scope(per_segment), bonus_applies(false) ]).

% --- eligibility -----------------------------------------------------------

earn_kernel:eligible(cx, S, _A, Outcome) :-
    Marketing = S.marketing,
    (   Marketing == unknown
    ->  Outcome = indeterminate('No marketing carrier, so there is no earning table to read this segment against.')
    ;   Marketing == cx
    ->  Outcome = eligible
    ;   iata(Marketing, U),
        format(atom(Why),
               'Cathay serves partner earn from its calculator rather than as a published table, so what a ~w-marketed sector earns cannot be read here. It is not nothing.',
               [U]),
        Outcome = indeterminate(Why)
    ).

% --- which bucket -----------------------------------------------------------

earn_kernel:fare_bucket(cx, S, A, Bucket, Basis) :-
    Family = S.fare_family,
    Class = S.booking_class,
    (   Class \== unknown
    ->  candidates(Class, Family, Candidates),
        resolve(Class, Family, Candidates, Bucket, Basis)
    ;   % No class given, so the fare's own is used -- see src/earn/presumed.pl.
        presumed_classes(S, A.cabin, Presumed),
        Presumed \== [],
        presumption(A.cabin, Presumed, Why)
    ->  findall(B, ( member(C, Presumed), candidates(C, Family, Cs), member(B, Cs) ), Bs0),
        sort(Bs0, Buckets),
        resolve_presumed(Buckets, Why, Bucket, Basis)
    ;   Bucket = indeterminate('The class this segment is sold in is not given, and no 5(b) row says what this fare books into on this carrier.'),
        Basis = null
    ).

resolve_presumed([], Why, indeterminate(Reason), null) :-
    !,
    format(atom(Reason), 'Cathay lists no earn for the class this fare books into (~w).', [Why]).
resolve_presumed([Bucket], Why, Bucket, Why) :- !.
resolve_presumed(Buckets, Why, one_of(Buckets, Reason), null) :-
    format(atom(Reason),
           'The figures span every fare this class could have been sold under: ~w.', [Why]).

% A declared family wins outright. Failing that, a class whose family is settled
% off the page -- see cx_class_settled/3 -- is filtered to it, and everything
% else keeps every family the grid lists it under, which is what becomes a range.
candidates(Class, Family, Candidates) :-
    (   Family \== unknown
    ->  Wanted = Family
    ;   cx_class_settled(Class, Settled, _)
    ->  Wanted = Settled
    ;   Wanted = any
    ),
    findall(bucket(Cabin, F, Group),
            (   cx_class(Cabin, F, Group, Class),
                ( Wanted == any -> true ; F == Wanted )
            ),
            Candidates0),
    sort(Candidates0, Candidates).

resolve(Class, Family, [], indeterminate(Why), null) :-
    !,
    upcase_atom(Class, U),
    (   Family == unknown
    ->  format(atom(Why), 'Cathay lists no earn for class ~w.', [U])
    ;   format(atom(Why), 'Cathay lists no earn for class ~w on an ~w fare.', [U, Family])
    ).
% How the family was settled travels with the answer, because "declared" and
% "there was only one it could be" are different degrees of confidence and the
% register is the place a reader checks which they were given.
resolve(Class, Declared, [Bucket], Bucket, Basis) :-
    !,
    (   Declared \== unknown
    ->  Basis = 'fare family declared'
    ;   cx_class_settled(Class, _, Reason)
    ->  Basis = Reason
    ;   Basis = 'the only fare family listing this class'
    ).
% More than one family lists this class, and the input did not say which was
% bought. The kernel prices every candidate and reports the spread; naming the
% families here is what lets the register say why the answer is a range.
resolve(Class, _, Candidates, one_of(Candidates, Why), null) :-
    findall(F, member(bucket(_, F, _), Candidates), Families0),
    sort(Families0, Families),
    atomic_list_concat(Families, ', ', List),
    upcase_atom(Class, U),
    format(atom(Why),
           'Cathay lists class ~w under more than one fare family (~w) with different earn against each, and no fareFamily was given. The figures span all of them.',
           [U, List]).

earn_kernel:term_label(bucket(Cabin, Family, _), Label) :-
    cx_cabin_label(Cabin, Cabin1),
    format(atom(Label), '~w ~w', [Cabin1, Family]).
earn_kernel:term_label(zone(_, Label), Label).

% --- which zone -------------------------------------------------------------

% The one place a distance is not enough. Short - Type 2 covers the same 751 to
% 2,750 miles as Short - Type 1 and is separated from it only by whether the
% sector touches Japan, Indonesia, Sri Lanka, Nepal, Bangladesh or India -- so
% the endpoints have to be in the signature, and they are.
earn_kernel:route_basis(cx, S, _A, Miles, Basis) :-
    (   zone_for(S.from, S.to, Miles, Zone)
    ->  cx_zone_label(Zone, Label),
        Basis = zone(Zone, Label)
    ;   format(atom(Why), 'No Cathay distance zone covers ~w miles.', [Miles]),
        Basis = indeterminate(Why)
    ).

zone_for(From, To, Miles, Zone) :-
    findall(Z, ( cx_zone(Z, Low, High), in_zone(Miles, Low, High) ), Zones),
    (   Zones = [One]
    ->  Zone = One
    ;   % The overlapping pair. Qualified first, unqualified as the residue --
        % which is exactly how the page words it: Type 2 is the named countries
        % and Type 1 is "other destinations".
        (   member(Q, Zones), cx_zone_countries(Q, Countries), touches(From, To, Countries)
        ->  Zone = Q
        ;   member(Zone, Zones), \+ cx_zone_countries(Zone, _)
        )
    ),
    !.

in_zone(Miles, Low, High) :-
    Miles >= Low,
    ( High == inf -> true ; Miles =< High ).

touches(From, To, Countries) :-
    (   airport_country(From, C) ; airport_country(To, C) ),
    memberchk(C, Countries),
    !.

earn_kernel:route_basis_edges(cx, zone(_, _), Edges) :- cx_zone_edges(Edges).

earn_kernel:accrual(cx, Bucket, zone(Zone, _), _Carrier, Rates) :-
    findall(rate(Currency, Rate), cx_rate(Bucket, Zone, Currency, Rate), Rates),
    Rates \== [].

% --- provenance -------------------------------------------------------------

earn_kernel:program_source(cx, Table, Source) :- cx_source(Table, Source).
earn_kernel:program_note(cx, Note) :- cx_note(Note).
