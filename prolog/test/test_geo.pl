:- module(test_geo, []).

/** <module> Geography units.

    The fare rule's continents are not physical geography, and the OurAirports
    `continent` column is. These tests pin every place the two disagree.
*/

:- use_module(library(plunit)).
:- use_module('../src/geo').
:- use_module('../data/limits').

:- begin_tests(geography).

test(casablanca_is_europe) :-
    airport_continent(cmn, europe_middle_east),
    airport_zone(cmn, europe).

test(tunis_and_algiers_are_europe, [forall(member(A, [tun, alg]))]) :-
    airport_zone(A, europe).

test(cairo_is_middle_east) :-
    airport_continent(cai, europe_middle_east),
    airport_zone(cai, middle_east).

test(khartoum_and_tripoli_are_middle_east, [forall(member(A, [krt, mji]))]) :-
    airport_zone(A, middle_east).

test(dubai_is_not_asia) :-
    airport_continent(dxb, europe_middle_east).

test(panama_city_is_north_america) :-
    airport_continent(pty, north_america).

test(havana_is_north_america) :-
    airport_continent(hav, north_america).

test(tashkent_is_asia) :-
    airport_continent(tas, asia).

% The CSV files Honolulu under Oceania. 4(b) speaks of "backtracking between
% Hawaii and other points in North America", so the fare rule needs it in
% North America -- flagged, but not moved out of the continent.
test(honolulu_is_north_america_and_flagged) :-
    airport_continent(hnl, north_america),
    is_hawaii(hnl).

test(anchorage_is_alaska) :-
    is_alaska(anc),
    airport_continent(anc, north_america).

% The CSV's own continent column files Astrakhan and Grozny, both west of the
% Urals, as Asia; longitude gets them right.
test(russia_splits_at_the_urals) :-
    airport_continent(led, europe_middle_east),   % St Petersburg
    airport_continent(asf, europe_middle_east),   % Astrakhan
    airport_continent(svx, asia),                 % Yekaterinburg
    airport_continent(ovb, asia).                 % Novosibirsk

test(russian_far_east_past_the_antimeridian) :-
    airport_continent(dyr, asia).                 % Anadyr, longitude 177.7

test(eastern_russia_has_no_europe_zone) :-
    \+ airport_zone(svx, _).

test(transcontinental_usa) :-
    is_transcontinental_us(sfo, jfk),
    is_transcontinental_us(jfk, lax),
    \+ is_transcontinental_us(ord, jfk),          % Illinois is in neither column
    \+ is_transcontinental_us(sfo, lax).          % both Column A

test(oceans_follow_traffic_conferences) :-
    ocean_crossing(lhr, jfk, atlantic),
    ocean_crossing(lax, syd, pacific),
    ocean_crossing(lhr, hkg, none),               % TC2-TC3 crosses neither
    ocean_crossing(jfk, gru, none).               % within TC1

test(traffic_conferences) :-
    airport_tc(jfk, tc1), airport_tc(gru, tc1),
    airport_tc(lhr, tc2), airport_tc(nbo, tc2),
    airport_tc(hkg, tc3), airport_tc(syd, tc3).

test(section_12_regions) :-
    airport_fare_region(syd, australia),
    airport_fare_region(akl, new_zealand),
    airport_fare_region(ppt, french_polynesia),
    airport_fare_region(nan, swp_other),
    airport_fare_region(bkk, south_east_asia),
    airport_fare_region(cmb, south_asian_subcontinent),
    airport_fare_region(nrt, japan_korea),
    airport_fare_region(doh, middle_east).

% Every airport in the generated table must resolve to a fare-rule continent;
% an unmapped country would silently make segments look intra-continental.
test(every_airport_resolves) :-
    findall(A, ( airport(A, _, _, _, _, _), \+ airport_continent(A, _) ), Bad),
    assertion(Bad == []).

test(search_finds_heathrow) :-
    airport_search(lhr, 5, Results),
    memberchk(lhr, Results).

:- end_tests(geography).
