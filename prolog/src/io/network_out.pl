:- module(network_out, [network_json/2, manifest_json/1]).

/** <module> Network report -> JSON dict.

    Two things this does that a pass-through would not.

    *A status is flattened.* `flown(year_round)` and `windowed(begins('2027-03-15'))`
    are compound terms, and no compound term may reach a JSON consumer as
    whatever term_to_atom/2 happened to make of it. Every row therefore carries
    the same four status keys whatever its status -- `status`, `season`,
    `window`, `windowDate` -- with the ones that do not apply set to `null`, so a
    client never has to ask which shape it got and never meets a missing field.

    *`absent` is not `false`.* The status is an atom rather than a boolean for
    the same reason the earning side refuses to render an unpriceable sector as
    zero: `absent` means the snapshot has no such row, which is a much weaker
    claim than "this cannot be flown", and a client rendering a boolean has no
    way left to say so. `manifest` travels with every reply for exactly that
    reason -- it is what tells the reader how old the claim is.
*/

:- use_module('../geo').
:- use_module('../network').
:- use_module(library(apply)).

%! network_json(+Report, -Dict) is det.
network_json(network_report(Sectors, Coverage, Manifest),
             _{ sectors: Rows, coverage: C, manifest: M }) :-
    maplist(sector_json, Sectors, Rows),
    coverage_json(Coverage, C),
    manifest_dict(Manifest, M).

sector_json(S, _{ segment: N, type: Type, from: From, to: To,
                  marketingCarrier: Mkt, operatingCarrier: Op,
                  lookupCarrier: Used, lookupCarrierRole: Role,
                  status: Status, season: Season,
                  window: Window, windowDate: Date }) :-
    N = S.n, Type = S.type,
    iata_or_null(S.from, From),
    iata_or_null(S.to, To),
    iata_or_null(S.marketing, Mkt),
    iata_or_null(S.operating, Op),
    iata_or_null(S.carrier, Used),
    role_json(S.carrier_role, Role),
    status_json(S.status, Status, Season, Window, Date).

% `none` rather than null, because the field says which carrier the lookup used
% and "it used none" is an answer -- the row that carries it is the
% carrier_unknown one, and a null there would read as a missing field.
role_json(none, none) :- !.
role_json(Role, Role).

status_json(flown(Season),  flown,           Season, null,   null) :- !.
status_json(windowed(When), windowed,        null,   Kind,   Date) :- !,
    When =.. [Kind, Date].
status_json(Status,         Status,          null,   null,   null).

coverage_json(C, _{ segments: N, flown: Flown, windowed: Windowed,
                    absent: Absent, carrierUnknown: CarrierUnknown,
                    notApplicable: NotApplicable }) :-
    N = C.segments,
    Flown = C.flown, Windowed = C.windowed, Absent = C.absent,
    CarrierUnknown = C.carrier_unknown,
    NotApplicable = C.not_applicable.

% `unknown` stays the atom `unknown` rather than becoming null: null would say
% the field does not apply, and what is true is that nobody stated it. The
% distinction is the same one the earning side draws between a rate published as
% nothing and a rate nobody published.
manifest_dict(M, _{ snapshot: Snapshot, articles: Articles, revisions: Revisions,
                    services: Services, windows: Windows }) :-
    Snapshot = M.snapshot, Articles = M.articles, Revisions = M.revisions,
    Services = M.services, Windows = M.windows.

%! manifest_json(-Dict) is det.
%  The provenance on its own, for /api/ruleset. The page hardcodes no snapshot
%  date and no fact count, for the same reason it hardcodes no limit and no
%  city code: a number written into the page is one that drifts from the table
%  it describes the first time the table is refreshed.
manifest_json(Dict) :-
    network_manifest(M),
    manifest_dict(M, Dict).

iata_or_null(unknown, null) :- !.
iata_or_null(Code, Upper) :- iata(Code, Upper).
