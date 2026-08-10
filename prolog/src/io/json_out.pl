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
:- use_module('../../data/surcharges').
:- use_module('../geo').
:- use_module('../annotate').
:- use_module('../itinerary').
:- use_module('../carriers').
:- use_module(library(apply)).

%! report_json(+Report, -Dict) is det.
report_json(Report, Dict) :- report_json(Report, _{}, Dict).

%! report_json(+Report, +Extra, -Dict) is det.
%  Extra is merged in last, so a caller can attach the annotated itinerary.
report_json(report(Verdict, Violations, Fare), Extra, Dict) :-
    ruleset_version(Version),
    maplist(violation_json, Violations, Vs),
    fare_json(Fare, FareDict),
    Base = _{ verdict: Verdict,
              rulesetVersion: Version,
              violations: Vs,
              fare: FareDict },
    Dict = Base.put(Extra).

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
                       continentSequence: Continents,
                       trafficConferenceSequence: TCs,
                       visitedContinents: Visited,
                       segments: Segs,
                       points: Points }) :-
    upcase_or_unknown(A.origin, Origin),
    Continents = A.continents,
    TCs = A.tcs,
    Visited = A.visited,
    maplist(segment_json, A.segments, Segs),
    maplist(point_json, A.points, Points).

segment_json(S, _{ n: N, type: Type, from: From, to: To,
                   fromCity: FromCity, toCity: ToCity,
                   fromContinent: FC, toContinent: TC,
                   fromTrafficConference: FTC, toTrafficConference: TTC,
                   marketingCarrier: Mkt, operatingCarrier: Op, flight: Flight,
                   dep: Dep, arr: Arr,
                   intercontinental: Inter, international: Intl, ocean: Ocean,
                   fromCoords: FromCoords, toCoords: ToCoords }) :-
    N = S.n, Type = S.type,
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

point_json(P, _{ afterSegment: N, airport: Airport, continent: Cont,
                 kind: Kind, groundHours: Hours }) :-
    N = P.after,
    upcase_or_unknown(P.airport, Airport),
    Cont = P.continent,
    Kind = P.kind,
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
    surcharge_bands(Bands0),
    maplist([band(Desc, Usd), _{ sectors: Desc, usd: Usd }]>>true, Bands0, Bands).

%! airport_json(+Iata, -Dict) is det.
airport_json(A, _{ iata: Upper, city: City, country: Country, region: Region,
                   continent: Continent, lat: Lat, lon: Lon }) :-
    airport(A, Country, Region, City, Lat, Lon),
    upcase_atom(A, Upper),
    (   airport_continent(A, Continent) -> true ; Continent = unknown ).
