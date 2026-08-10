:- module(cities, [city_code/2, city_name/2]).

/** <module> IATA metropolitan city codes.

    Fare construction is written in city codes, not airport codes: a routing
    reads `NYC-X/LON-SIN`, never `JFK-X/LHR-SIN`. The airport table has no such
    codes -- OurAirports lists airports -- so this table maps each multi-airport
    city onto a representative airport.

    Aliasing rather than adding a separate kind of place is deliberate. Every
    use the validator makes of a code is either geography (country, region,
    continent, traffic conference) or identity (4(i) compares sector pairs).
    Geography is identical for any airport of the same city, and aliasing is
    what makes `NYC` and `JFK` the same place, so an itinerary that writes the
    sector one way and returns the other way is still caught as a duplicate.
    Treating `NYC` as its own place would silently lose that.

    Only cities whose representative is in the generated airport table belong
    here; test/test_geo.pl asserts that every entry resolves, so a regenerated
    airport table that drops an airport fails the suite rather than turning a
    city code into "unknown airport" at runtime. Kyiv (IEV) is absent for
    exactly that reason -- KBP currently has no scheduled service.
*/

%! city_code(?City, ?Airport) is nondet.
city_code(bjs, pek).   % Beijing
city_code(bhz, cnf).   % Belo Horizonte
city_code(bue, eze).   % Buenos Aires
city_code(buh, otp).   % Bucharest
city_code(chi, ord).   % Chicago
city_code(dtt, dtw).   % Detroit
city_code(jkt, cgk).   % Jakarta
city_code(lon, lhr).   % London
city_code(mil, mxp).   % Milan
city_code(mow, svo).   % Moscow
city_code(nyc, jfk).   % New York
city_code(osa, kix).   % Osaka
city_code(par, cdg).   % Paris
city_code(rio, gig).   % Rio de Janeiro
city_code(rom, fco).   % Rome
city_code(sao, gru).   % Sao Paulo
city_code(sel, icn).   % Seoul
city_code(spk, cts).   % Sapporo
city_code(sto, arn).   % Stockholm
city_code(tyo, nrt).   % Tokyo
city_code(was, iad).   % Washington
city_code(yea, yeg).   % Edmonton
city_code(ymq, yul).   % Montreal
city_code(yto, yyz).   % Toronto

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
