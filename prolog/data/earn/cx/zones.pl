:- module(cx_zones,
          [ cx_zone/5,
            cx_zone_label/3,
            cx_zone_edges/2,
            cx_enhanced_country/1,
            cx_override/4,
            cx_boundary/3
          ]).

/** <module> The two distance-zone schemes. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/asia-miles-lookup.csv and asia-miles-rules.csv,
    snapshot 2026-08-11 of
    https://api.cathaypacific.com/mpo-miles-services/v3/miles-calculator

    See data/earn/sources/asia-miles-parsing-guide.md for what the columns mean
    and how the figures were obtained.

    Six positions each, and position 3 is where they part company: on a partner
    it is a distance band of its own, 2,751 to 3,700 miles, and on Cathay it is
    the region variant of band 2 at the same 751 to 2,750 miles as position 2.
    A sector between 2,751 and 5,000 miles read against the wrong scheme returns
    a plausible number from the wrong row, which is why the scheme is an argument
    here and not an assumption anywhere.

    The fourth geography taxonomy in this repository, and independent of the
    other three: it is a seven-country list and a distance, where the fare rule,
    OurAirports and the Qantas earning regions each cut the world somewhere
    else.
*/

%! cx_zone(?Scheme, ?Position, ?Low, ?High, ?Region) is nondet.
%  Inclusive at both ends; `inf` is the open top of each scheme. Region is
%  `any`, or `standard`/`enhanced` for the Cathay pair that share a distance
%  band and are told apart by the endpoints.
cx_zone(cx, 1, 1, 750, any).
cx_zone(cx, 2, 751, 2750, standard).
cx_zone(cx, 3, 751, 2750, enhanced).
cx_zone(cx, 4, 2751, 5000, any).
cx_zone(cx, 5, 5001, 7500, any).
cx_zone(cx, 6, 7501, inf, any).
cx_zone(partner, 1, 1, 750, any).
cx_zone(partner, 2, 751, 2750, any).
cx_zone(partner, 3, 2751, 3700, any).
cx_zone(partner, 4, 3701, 5000, any).
cx_zone(partner, 5, 5001, 7500, any).
cx_zone(partner, 6, 7501, inf, any).

%! cx_zone_label(?Scheme, ?Position, ?Label) is nondet.
cx_zone_label(cx, 1, 'Zone 1 (1-750 miles)').
cx_zone_label(cx, 2, 'Zone 2 (751-2,750 miles)').
cx_zone_label(cx, 3, 'Zone 3 (751-2,750 miles, enhanced region)').
cx_zone_label(cx, 4, 'Zone 4 (2,751-5,000 miles)').
cx_zone_label(cx, 5, 'Zone 5 (5,001-7,500 miles)').
cx_zone_label(cx, 6, 'Zone 6 (7,501 miles or above)').
cx_zone_label(partner, 1, 'Zone 1 (1-750 miles)').
cx_zone_label(partner, 2, 'Zone 2 (751-2,750 miles)').
cx_zone_label(partner, 3, 'Zone 3 (2,751-3,700 miles)').
cx_zone_label(partner, 4, 'Zone 4 (3,701-5,000 miles)').
cx_zone_label(partner, 5, 'Zone 5 (5,001-7,500 miles)').
cx_zone_label(partner, 6, 'Zone 6 (7,501 miles or above)').

%! cx_zone_edges(?Scheme, ?Edges) is nondet.
%  Where a great circle stops being a good enough stand-in for the airline's own
%  sector mileage -- see src/earn/distance.pl.
cx_zone_edges(cx, [750, 2750, 5000, 7500]).
cx_zone_edges(partner, [750, 2750, 3700, 5000, 7500]).

%! cx_boundary(?Miles, ?Reliability, ?Note) is nondet.
%  How well each cutoff is pinned down by the sampling behind these tables.
cx_boundary(750, fuzzy, 'FUZZY on great-circle. Bracketed to 749-756 across airlines. Cathay uses published sector mileage').
cx_boundary(2750, clean, 'CLEAN. Bracketed to 2743-2784').
cx_boundary(3700, clean, 'CLEAN. Bracketed to 3699-3711 by a targeted 64-pair refinement across BA, AA, JL and QF').
cx_boundary(5000, clean, 'CLEAN. Bracketed to 4986-5060').
cx_boundary(7500, clean, 'CLEAN. Bracketed to 7312-7796').

%! cx_enhanced_country(?Country) is nondet.
%  Either endpoint in one of these pulls a 751-2,750 mile Cathay sector onto the
%  enhanced card. It is the one place a distance alone cannot decide a zone, and
%  the reason route_basis/5 is handed the segment rather than only a number.
cx_enhanced_country('JP').
cx_enhanced_country('IN').
cx_enhanced_country('BD').
cx_enhanced_country('LK').
cx_enhanced_country('NP').
cx_enhanced_country('KZ').
cx_enhanced_country('ID').

%! cx_override(?From, ?To, ?Position, ?Why) is nondet.
%  City pairs whose card is not the one their distance predicts. Applied before
%  the distance is looked at. Cathay publishes no reason for any of them, so the
%  note is the observation rather than an explanation.
cx_override(hkg, czx, 1, 'Great-circle 755 mi predicts Zone 2; actual card is Zone 1').
cx_override(czx, hkg, 1, 'Great-circle 755 mi predicts Zone 2; actual card is Zone 1').
cx_override(mfm, nkg, 2, 'Great-circle 738 mi predicts Zone 1; actual card is Zone 2').
cx_override(nkg, mfm, 2, 'Great-circle 738 mi predicts Zone 1; actual card is Zone 2').
cx_override(ala, tse, 4, 'Almaty-Astana is 591 gc mi but earns the 5001-7500 card. No rule explains this').
cx_override(tse, ala, 4, 'Almaty-Astana is 591 gc mi but earns the 5001-7500 card. No rule explains this').
cx_override(hkg, nop, 5, 'NOP could not be resolved to a location so distance is unverified').
cx_override(nop, hkg, 5, 'NOP could not be resolved to a location so distance is unverified').
