:- module(cities, [city_code/2, city_name/2, city_airports/2, city_of/2]).

/** <module> IATA metropolitan city codes.

    Fare construction is written in city codes, not airport codes: a routing
    reads `NYC-X/LON-SIN`, never `JFK-X/LHR-SIN`. The airport table has no such
    codes -- OurAirports lists airports -- so this table maps each multi-airport
    city onto a representative airport.

    The table runs in both directions, and both are load-bearing.

    Forward, `city_code/2` picks a representative airport so a routing written
    `NYC-X/LON-SIN` resolves to airports before anything else sees it.

    Backward, `city_of/2` says which metropolitan area an airport belongs to.
    That is what 4(i) is written in -- "the same city pairs / sectors cannot be
    flown more than once in the same direction" -- and what 4(c) and 4(d) mean
    by a point. Without it LHR and LGW are two places, so LON-NYC flown out of
    Heathrow and back into Gatwick is not a repeat, an itinerary routed via its
    own origin city is not via the point of origin, and a journey that ends
    across town from where it started looks like it ended somewhere else.

    Only airports in the generated table belong here; test/test_route.pl
    asserts that every entry resolves, so a regenerated airport table that
    drops an airport fails the suite rather than turning a city code into
    "unknown airport" at runtime. Kyiv (IEV) is absent for exactly that
    reason -- KBP currently has no scheduled service. Airports marketed under a
    city's name but held by IATA as their own city are likewise absent: Paris
    Beauvais (BVA), Westchester (HPN) and Kitchener/Waterloo (YKF) are not
    members here, because grouping a place that the fare rule keeps separate
    invents violations, which is the more expensive way to be wrong.
*/

%! city_airports(?City, ?Airports) is nondet.
%  The head of each list is the representative city_code/2 resolves to.
city_airports(bjs, [pek, pkx]).                  % Beijing
city_airports(bhz, [cnf]).                       % Belo Horizonte
city_airports(bue, [eze, aep]).                  % Buenos Aires
city_airports(buh, [otp, bbu]).                  % Bucharest
city_airports(chi, [ord, mdw, rfd]).             % Chicago
city_airports(dtt, [dtw]).                       % Detroit
city_airports(jkt, [cgk, hlp]).                  % Jakarta
city_airports(lon, [lhr, lgw, stn, ltn, lcy, sen]).  % London
city_airports(mil, [mxp, lin, bgy]).             % Milan
city_airports(mow, [svo, dme, vko, zia]).        % Moscow
city_airports(nyc, [jfk, lga, ewr, swf]).        % New York
city_airports(osa, [kix, itm, ukb]).             % Osaka
city_airports(par, [cdg, ory]).                  % Paris
city_airports(rio, [gig, sdu]).                  % Rio de Janeiro
city_airports(rom, [fco, cia]).                  % Rome
city_airports(sao, [gru, cgh, vcp]).             % Sao Paulo
city_airports(sel, [icn, gmp]).                  % Seoul
city_airports(spk, [cts, okd]).                  % Sapporo
city_airports(sto, [arn, bma, nyo, vst]).        % Stockholm
city_airports(tyo, [nrt, hnd]).                  % Tokyo
city_airports(was, [iad, dca, bwi]).             % Washington
city_airports(yea, [yeg]).                       % Edmonton
city_airports(ymq, [yul, ymx]).                  % Montreal
city_airports(yto, [yyz, ytz, yhm]).             % Toronto

%! city_code(?City, ?Airport) is nondet.
%  The representative airport a metropolitan code resolves to.
city_code(City, Representative) :-
    city_airports(City, [Representative|_]).

%! city_of(+Airport, -City) is semidet.
%  Airports belong to at most one metropolitan area, so the first match is the
%  only one and the search commits to it.
city_of(Airport, City) :-
    city_airports(C, Airports),
    memberchk(Airport, Airports),
    !,
    City = C.

%! city_name(?City, ?Name) is nondet.
city_name(bjs, 'Beijing').
city_name(bhz, 'Belo Horizonte').
city_name(bue, 'Buenos Aires').
city_name(buh, 'Bucharest').
city_name(chi, 'Chicago').
city_name(dtt, 'Detroit').
city_name(jkt, 'Jakarta').
city_name(lon, 'London').
city_name(mil, 'Milan').
city_name(mow, 'Moscow').
city_name(nyc, 'New York').
city_name(osa, 'Osaka').
city_name(par, 'Paris').
city_name(rio, 'Rio de Janeiro').
city_name(rom, 'Rome').
city_name(sao, 'Sao Paulo').
city_name(sel, 'Seoul').
city_name(spk, 'Sapporo').
city_name(sto, 'Stockholm').
city_name(tyo, 'Tokyo').
city_name(was, 'Washington').
city_name(yea, 'Edmonton').
city_name(ymq, 'Montreal').
city_name(yto, 'Toronto').
