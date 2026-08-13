:- module(flown_network,
          [ serves/3,
            destinations/3,
            carriers_between/3,
            network_manifest/1,
            network_report/2
          ]).

/** <module> Which sectors are actually flown, and by whom.

    The module is `flown_network` rather than `network`, and the provenance
    predicate `network_manifest/1` rather than `manifest/1`, for the reason
    src/earn/distance.pl gives for calling itself `earn_distance`: SWI module
    names are global, and neither this file nor any other has a claim on a word
    that general. The file keeps the subject's own name, as geo.pl and
    carriers.pl do.

    service/4 and service_window/4 are deliberately **not** exported, by the
    same argument -- load.pl imports every module into `user`, and `service/4`
    is about as general as a name gets. Callers that need the raw table (the
    suite's referential-integrity and coverage checks) reach it as
    `flown_network:service/4`, which says where it came from.

    A committed snapshot of "carrier C flies A to B nonstop", plus the narrow
    query surface over it. It delivers data, not search: nothing here proposes a
    routing, and nothing here decides anything about a fare. See
    PLANS/06-flown-network.md.

    **Nothing in this file produces a violation, and that is deliberate.** Rule
    3015 says nothing about whether a flight exists, so "this sector is not in
    the table" is not a breach of any clause -- there would be no citation to
    put beside it in a register whose whole design is that every entry cites
    one. The evidence is also of a different kind: a wiki snapshot with a stated
    age, in which the absence of an edge is much weaker evidence than the
    presence of one. A missing sector costs a trip nobody plans; an invented one
    costs an itinerary that validates and then will not ticket. So flyability is
    its own operation -- `network`, beside `validate`, `routing`, `earn` and
    `ruleset` -- exactly as earning is, and for the same reason.

    The generated fact base is *included* rather than imported, the way
    src/geo.pl includes the airport table, so service/4 lives in this module and
    gets first-argument indexing on the carrier without an extra layer of
    indirection.

    The shape of the table, fixed in Phase 0 of the plan and restated here
    because every query below depends on it:

        service(Carrier, From, To, Season)      % year_round | seasonal | unknown
        service_window(Carrier, From, To, When)  % begins(Date) | ends(Date)

    Edges are **directed**: LHR's article listing BA->JFK and JFK's listing
    BA->LHR produce two facts, and asymmetry is a data-quality signal reported
    by the suite rather than silently repaired here.

    Service that has not started or has ended is recorded as service_window/4
    and is deliberately *not* a service/4 fact, so a sector that begins next
    March never reads as flyable today.
*/

:- use_module(library(aggregate)).

% Two predicates the generated table may legitimately not mention at all: a
% snapshot in which no article carried a dated annotation emits no
% service_window/4, and the provisional placeholder carries neither those nor a
% manifest. Declaring them here gives them existence, so a lookup fails rather
% than raising an existence error against a table that is merely complete in a
% different way. service/4 is deliberately *not* declared: an empty services
% table is a broken build, not a data state worth degrading into.
:- dynamic service_window/4.
:- dynamic service_manifest/2.

:- include('../data/generated/services').

%! serves(+Carrier, +From, +To) is semidet.
%  True when the table holds a current sector for this carrier, whatever its
%  season. Directed: serves(ba, lhr, jfk) says nothing about jfk-lhr.
serves(Carrier, From, To) :-
    service(Carrier, From, To, _), !.

%! destinations(+Carrier, +From, -Tos) is det.
%  Every airport the carrier is recorded as flying to from here, sorted and
%  without repeats. Empty where the carrier is not in the table at all, which is
%  the same answer as "it flies nowhere from here" -- the table cannot tell
%  those apart, and manifest/1 is what says how much to trust either.
destinations(Carrier, From, Tos) :-
    findall(To, service(Carrier, From, To, _), Tos0),
    sort(Tos0, Tos).

%! carriers_between(+From, +To, -Carriers) is det.
%  Every carrier recorded as flying this directed sector, sorted.
carriers_between(From, To, Carriers) :-
    findall(C, service(C, From, To, _), Cs),
    sort(Cs, Carriers).

%! network_manifest(-Manifest) is det.
%  The snapshot's provenance, so a reader can see how old the claim is. The two
%  counts are measured from the loaded facts rather than read from the file, so
%  they cannot disagree with what is actually in the program; the rest is what
%  the generator recorded.
%
%  It degrades rather than throwing. Until the generator emits
%  service_manifest/2 the dates and article counts come back as `unknown`, which
%  is an honest description of a table whose age nobody stated -- and a page
%  that renders "snapshot: unknown" is telling the reader something true, where
%  a 500 would tell them nothing at all.
network_manifest(manifest{ snapshot: Snapshot,
                           articles: Articles,
                           revisions: Revisions,
                           services: Services,
                           windows: Windows }) :-
    manifest_value(snapshot, Snapshot),
    manifest_value(articles, Articles),
    manifest_value(revisions, Revisions),
    aggregate_all(count, service(_, _, _, _), Services),
    aggregate_all(count, service_window(_, _, _, _), Windows).

manifest_value(Key, Value) :-
    (   service_manifest(Key, V)
    ->  Value = V
    ;   Value = unknown
    ).

% --- the network report ----------------------------------------------------

%! network_report(+A, -Report) is det.
%  A is the annotated itinerary. One entry per segment, in order, each carrying
%  exactly one status:
%
%    flown(Season)     the sector is in the table
%    windowed(When)    only a service_window/4 matches -- the service starts or
%                      ends outside the current period, so it is recorded but
%                      not currently flyable
%    absent            a carrier was named and no fact matches
%    carrier_unknown   the segment names no carrier, so nothing can be looked up
%    not_applicable    a surface sector: the traveller covers it themselves, so
%                      asking whether it is flown is meaningless
%
%  The last two are what keep the panel honest. Without `not_applicable` every
%  `//` leg in a routing reads as an unflyable sector, and without
%  `carrier_unknown` so does every segment that named no airline -- both of
%  which would report a gap in the *input* as a gap in the *network*.
%
%  An endpoint that is not a known airport falls out as `absent`, which is
%  literally what the table says: no fact matches. It is not this operation's
%  job to relitigate the code -- validate/1 already reports an unknown airport
%  as an input error, with a citation, where a reader will see it.
network_report(A, network_report(Sectors, Coverage, Manifest)) :-
    findall(Sector, ( member(S, A.segments), sector(S, Sector) ), Sectors),
    coverage(Sectors, Coverage),
    network_manifest(Manifest).

sector(S, sector{ n: N, type: Type, from: From, to: To,
                  marketing: Mkt, operating: Op,
                  carrier: Carrier, carrier_role: Role,
                  status: Status }) :-
    N = S.n, Type = S.type, From = S.from, To = S.to,
    Mkt = S.marketing, Op = S.operating,
    lookup_carrier(S, Carrier, Role),
    status(Type, Carrier, From, To, Status).

%! lookup_carrier(+Segment, -Carrier, -Role) is det.
%  **The operating carrier, where there is one.** The table's rows are
%  operating-carrier rows -- Wikipedia's airport tables exclude codeshares for
%  the secondary carrier by convention -- so looking up the marketing carrier on
%  a codeshare would ask about a row that was never there and report `absent`
%  for a sector that is flown daily.
%
%  Where the operator is unknown but a marketing carrier was given, the lookup
%  uses that and says so, rather than refusing to answer. That is the same
%  degradation 4(j) already makes on an absent operating carrier, and the role
%  travels with the entry so a reader can weigh the answer accordingly.
lookup_carrier(S, Carrier, Role) :-
    (   S.operating \== unknown
    ->  Carrier = S.operating, Role = operating
    ;   S.marketing \== unknown
    ->  Carrier = S.marketing, Role = marketing
    ;   Carrier = unknown, Role = none
    ).

status(surface, _, _, _, not_applicable) :- !.
status(_, unknown, _, _, carrier_unknown) :- !.
status(_, Carrier, From, To, Status) :-
    (   service(Carrier, From, To, Season)
    ->  Status = flown(Season)
    ;   service_window(Carrier, From, To, When)
    ->  Status = windowed(When)
    ;   Status = absent
    ).

%! coverage(+Sectors, -Coverage) is det.
%  The tallies. `segments` counts every entry, so the five status counts add up
%  to it and a reader can see at a glance how much of the journey the table had
%  anything to say about.
coverage(Sectors, coverage{ segments: N,
                            flown: Flown,
                            windowed: Windowed,
                            absent: Absent,
                            carrier_unknown: CarrierUnknown,
                            not_applicable: NotApplicable }) :-
    length(Sectors, N),
    tally(Sectors, flown(_), Flown),
    tally(Sectors, windowed(_), Windowed),
    tally(Sectors, absent, Absent),
    tally(Sectors, carrier_unknown, CarrierUnknown),
    tally(Sectors, not_applicable, NotApplicable).

% get_dict/3 rather than the functional notation, because the access sits inside
% a meta-called goal: the dict expansion would hoist it out of the aggregation
% and ask for the key of a variable that member/2 has not bound yet.
tally(Sectors, Pattern, Count) :-
    aggregate_all(count,
                  ( member(Sector, Sectors),
                    get_dict(status, Sector, Status),
                    subsumes_term(Pattern, Status) ),
                  Count).
