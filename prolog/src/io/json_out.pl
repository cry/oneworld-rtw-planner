:- module(json_out,
          [ report_json/2,
            report_json/3,
            annotations_json/2,
            ruleset_json/1,
            airport_json/2
          ]).

/** <module> Report term -> JSON dict.

    The web UI needs more than the verdict: it wants to draw the route and show
    *why* a rule fired, so the annotated itinerary travels with the report.
*/

:- use_module('../../data/limits').
:- use_module('../../data/cities').
:- use_module('../../data/surcharges').
:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../itinerary').
:- use_module('../carriers').
:- use_module(route_in).
:- use_module(route_out).
:- use_module(library(apply)).

%! report_json(+Report, -Dict) is det.
report_json(Report, Dict) :- report_json(Report, _{}, Dict).

%! report_json(+Report, +Extra, -Dict) is det.
%  Extra is merged in last, so a caller can attach the annotated itinerary.
report_json(report(Verdict, Violations, Fare, NotChecked, Checks), Extra, Dict) :-
    ruleset_version(Version),
    maplist(violation_json, Violations, Vs),
    maplist(not_checked_json, NotChecked, NCs),
    maplist(check_json, Checks, Cs),
    fare_json(Fare, FareDict),
    Base = _{ verdict: Verdict,
              rulesetVersion: Version,
              violations: Vs,
              notChecked: NCs,
              checks: Cs,
              fare: FareDict },
    Dict = Base.put(Extra).

% Rules the input could not answer at all. A client that renders `verdict`
% without rendering this is claiming coverage the report does not give.
not_checked_json(nc(Rule, Citation, Reason),
                 _{ rule: Rule, citation: Citation, reason: Reason }).

% What each rule measured, whether or not it was broken. `outcome` is derived
% from the violations in the same report, so it cannot contradict `verdict`.
check_json(check(Rule, Citation, Label, Outcome, Detail),
           _{ rule: Rule, citation: Citation, label: Label,
              outcome: Outcome, detail: Detail }).

violation_json(v(Rule, Citation, Severity, Message, Evidence),
               _{ rule: Rule,
                  citation: Citation,
                  severity: Severity,
                  message: Message,
                  evidence: Ev }) :-
    evidence_json(Evidence, Ev).

%! evidence_json(+Evidence, -Dict) is det.
%  Evidence is a list of Key(Value) terms. One generic converter keeps every
%  rule free of serialization concerns.
evidence_json(Evidence, Dict) :-
    foldl(add_evidence, Evidence, _{}, Dict).

add_evidence(Term, In, Out) :-
    Term =.. [Key, Value], !,
    value_json(Value, V),
    put_dict(Key, In, V, Out).
add_evidence(_, D, D).

value_json(V, J) :- is_list(V), !, maplist(value_json, V, J).
value_json(A-B, J) :- !, format(atom(J), '~w-~w', [A, B]).
value_json(V, V) :- number(V), !.
value_json(V, V) :- atom(V), !.
value_json(V, J) :- term_to_atom(V, J).

fare_json(Fare, _{ continents: N,
                   continentList: Cs,
                   cabin: Cabin,
                   fareBasis: Basis,
                   premiumEconomyUpgradeUsd: Usd,
                   premiumEconomySegments: Rows,
                   discounts: Discounts }) :-
    N = Fare.continents,
    Cs = Fare.continent_list,
    Cabin = Fare.cabin,
    Basis = Fare.basis,
    Usd = Fare.premium_economy_upgrade_usd,
    Rows = Fare.premium_economy_segments,
    Discounts = Fare.discounts.

%! annotations_json(+A, -Dict) is det.
%  The derived facts the rules were decided on. Sent with every report so the
%  UI can draw the route and explain a violation in context rather than just
%  printing its message.
annotations_json(A, _{ origin: Origin,
                       mode: Mode,
                       routing: Routing,
                       continentSequence: Continents,
                       trafficConferenceSequence: TCs,
                       visitedContinents: Visited,
                       names: Names,
                       segments: Segs,
                       points: Points }) :-
    place_names(Names),
    upcase_or_unknown(A.origin, Origin),
    Mode = A.mode,
    % The same journey written as a routing, whichever way it came in. Null when
    % a point is neither transfer nor stopover, because the notation has no way
    % to write that down -- see io/route_out.pl.
    (   annotated_route(A, R)
    ->  Routing = R
    ;   Routing = null
    ),
    Continents = A.continents,
    TCs = A.tcs,
    Visited = A.visited,
    maplist(segment_json, A.segments, Segs),
    maplist(point_json, A.points, Points).

% Sent with the report rather than fetched once from /api/ruleset, because the
% first report can render before a separate request has come back, and a table
% of nine short strings is cheaper than the bug where it has not.
place_names(Names) :-
    findall(Key-Name,
            ( continent_name(Key, Name) ; tc_name(Key, Name) ),
            Pairs),
    dict_pairs(Names, _, Pairs).

segment_json(S, _{ n: N, type: Type, from: From, to: To,
                   fromCity: FromCity, toCity: ToCity,
                   fromContinent: FC, toContinent: TC,
                   fromTrafficConference: FTC, toTrafficConference: TTC,
                   marketingCarrier: Mkt, operatingCarrier: Op, flight: Flight,
                   dep: Dep, arr: Arr,
                   stop: Stop, bookingClass: Class, fareFamily: Family,
                   intercontinental: Inter, international: Intl, ocean: Ocean,
                   fromCoords: FromCoords, toCoords: ToCoords }) :-
    N = S.n, Type = S.type,
    null_if_unknown(S.stop, Stop),
    upcase_or_unknown(S.booking_class, Class),
    null_if_unknown(S.fare_family, Family),
    upcase_or_unknown(S.from, From),
    upcase_or_unknown(S.to, To),
    city_or_unknown(S.from, FromCity),
    city_or_unknown(S.to, ToCity),
    FC = S.from_cont, TC = S.to_cont,
    FTC = S.from_tc,  TTC = S.to_tc,
    upcase_or_unknown(S.marketing, Mkt),
    upcase_or_unknown(S.operating, Op),
    Flight = S.flight,
    dt_iso_or_null(S.dep, Dep),
    dt_iso_or_null(S.arr, Arr),
    Inter = S.intercontinental, Intl = S.international, Ocean = S.ocean,
    coords_json(S.from, FromCoords),
    coords_json(S.to, ToCoords).

% Both the declared and the derived classification travel with the point, not
% just the one that won, so a client can show which source decided it.
point_json(P, _{ afterSegment: N, airport: Airport, continent: Cont,
                 kind: Kind, declaredKind: Declared, derivedKind: Derived,
                 surfaceAdjacent: Surface, groundHours: Hours }) :-
    N = P.after,
    upcase_or_unknown(P.airport, Airport),
    Cont = P.continent,
    Kind = P.kind,
    null_if_unknown(P.declared, Declared),
    null_if_unknown(P.derived, Derived),
    Surface = P.surface,
    (   P.ground_minutes == unknown
    ->  Hours = null
    ;   Hours is round(P.ground_minutes / 6) / 10.0
    ).

coords_json(A, Coords) :-
    (   airport_coords(A, Lat, Lon)
    ->  Coords = _{ lat: Lat, lon: Lon }
    ;   Coords = null
    ).

upcase_or_unknown(unknown, null) :- !.
upcase_or_unknown(A, U) :- upcase_atom(A, U).

null_if_unknown(unknown, null) :- !.
null_if_unknown(V, V).

city_or_unknown(A, City) :-
    (   airport_city(A, City) -> true ; City = null ).

dt_iso_or_null(unknown, null) :- !.
dt_iso_or_null(Dt, Iso) :- dt_iso(Dt, Iso).

%! ruleset_json(-Dict) is det.
%  Everything a web UI would otherwise have to hardcode.
ruleset_json(_{ version: Version,
                source: 'oneworld Explorer, Tariff RWR2 Rule 3015',
                limits: Limits,
                freeSegments: Free,
                continents: Continents,
                fareBasis: Bases,
                carriers: Carriers,
                cityCodes: Cities,
                stopKinds: StopKinds,
                modes: Modes,
                routeSyntax: RouteHelp,
                surchargeBands: Bands }) :-
    ruleset_version(Version),
    all_limits(Pairs),
    foldl([K-V, In, Out]>>put_dict(K, In, V, Out), Pairs, _{}, Limits),
    findall(C-M, free_segments(C, M), FreePairs),
    foldl([K-V, In, Out]>>put_dict(K, In, V, Out), FreePairs, _{}, Free),
    findall(_{ name: C, trafficConference: TC },
            ( continent(C), traffic_conference(C, TC) ),
            Continents),
    findall(_{ cabin: Cabin, continents: Count, basis: B },
            fare_basis(Cabin, Count, B),
            Bases),
    findall(_{ code: C, name: Name },
            ( eligible_carrier(C), carrier_name(C, Name) ),
            Carriers),
    findall(_{ code: Upper, name: Name, airport: AirportUpper },
            ( city_code(City, Airport), city_name(City, Name),
              upcase_atom(City, Upper), upcase_atom(Airport, AirportUpper) ),
            Cities),
    findall(K, stop_kind(K), StopKinds),
    findall(M, itinerary_mode(M), Modes),
    route_help(RouteHelp),
    surcharge_bands(Bands0),
    maplist([band(Desc, Usd), _{ sectors: Desc, usd: Usd }]>>true, Bands0, Bands).

%! airport_json(+Iata, -Dict) is det.
airport_json(A, _{ iata: Upper, city: City, country: Country, region: Region,
                   continent: Continent, lat: Lat, lon: Lon }) :-
    airport(A, Country, Region, City, Lat, Lon),
    upcase_atom(A, Upper),
    (   airport_continent(A, Continent) -> true ; Continent = unknown ).
