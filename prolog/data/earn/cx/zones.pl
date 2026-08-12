:- module(cx_zones, [cx_zone/3, cx_zone_label/2, cx_zone_countries/2, cx_zone_edges/1]).

/** <module> Cathay distance zones. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/cx-marketed.json, read 2026-08-11 from
    https://www.cathaypacific.com/cx/en_US/membership/news-and-updates/Changes-to-your-Status-Points-and-Asia-Miles-earnings-on-flights.html

    Six zones, five of them distance alone. The sixth is why route_basis/5 takes
    the endpoints: Short - Type 2 is the same 751 to 2,750 miles as Short -
    Type 1, separated only by whether the sector is to or from Japan, Indonesia,
    Sri Lanka, Nepal, Bangladesh or India. No distance can decide it.

    The fourth geography taxonomy in this repository, and independent of the
    other three: it is a six-country list, and the fare rule, OurAirports and
    the Qantas earning regions each cut the world somewhere else.
*/

%! cx_zone(?Zone, ?Low, ?High) is nondet.
%  Inclusive at both ends; `inf` is the open top of the table.
cx_zone(ultra_short, 1, 750).
cx_zone(short_1, 751, 2750).
cx_zone(short_2, 751, 2750).
cx_zone(medium, 2751, 5000).
cx_zone(long, 5001, 7500).
cx_zone(ultra_long, 7501, inf).

%! cx_zone_label(?Zone, ?Label) is nondet.
cx_zone_label(ultra_short, 'Ultra-short (1-750 miles)').
cx_zone_label(short_1, 'Short - Type 1 (751-2,750 miles)').
cx_zone_label(short_2, 'Short - Type 2 (751-2,750 miles)').
cx_zone_label(medium, 'Medium (2,751-5,000 miles)').
cx_zone_label(long, 'Long (5,001-7,500 miles)').
cx_zone_label(ultra_long, 'Ultra-long (7,501 miles or above)').

%! cx_zone_countries(?Zone, ?Countries) is nondet.
%  A zone that distance alone cannot decide. Only Short - Type 2 has one.
cx_zone_countries(short_2, ['JP', 'ID', 'LK', 'NP', 'BD', 'IN']).

%! cx_zone_edges(-Edges) is det.
cx_zone_edges([750, 2750, 5000, 7500]).
