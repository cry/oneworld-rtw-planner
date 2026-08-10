:- module(overrides,
          [ continent_override/4,
            zone_override/4,
            urals_longitude/1,
            hawaii_region/1
          ]).

/** <module> Sub-country geography the fare rule needs.

    Everything here exists because a country-level table cannot express it.
*/

%! urals_longitude(-Degrees) is det.
%  Section 0 splits Russia at the Urals. The range runs close to the 60th
%  meridian, so longitude is the workable proxy. The CSV's own `continent`
%  column cannot be used for this: it files Astrakhan and Grozny -- both well
%  west of the Urals -- as Asia, and disagrees with itself within Bashkortostan.
urals_longitude(60.0).

%! continent_override(+Country, +Region, +Longitude, -Continent) is semidet.
%  Chukotka reaches past the antimeridian into negative longitudes; every part
%  of European Russia sits between roughly 20E and 60E, so a negative longitude
%  is unambiguously the Far East.
continent_override('RU', _Region, Lon, asia) :-
    number(Lon),
    (   urals_longitude(U), Lon >= U
    ;   Lon < 0
    ),
    !.
continent_override('RU', _Region, _Lon, europe_middle_east).

%! zone_override(+Country, +Region, +Longitude, -Zone) is semidet.
%  Russia west of the Urals is named in the Europe zone; the eastern part is
%  Asia and therefore has no Europe/Middle East zone at all. The continent is
%  resolved first and then compared -- passing europe_middle_east in as an
%  argument would skip the Asia clause on head unification and wrongly succeed.
zone_override('RU', Region, Lon, europe) :-
    continent_override('RU', Region, Lon, Continent),
    Continent == europe_middle_east.

%! hawaii_region(?IsoRegion) is nondet.
%  4(b) forbids backtracking between Hawaii and other points in North America,
%  which is the one place the rule reaches inside a continent. Hawaii stays in
%  North America for every other purpose.
hawaii_region('US-HI').
