:- module(cx_table, [cx_rate/4, cx_unpriced/2]).

/** <module> Status Points and Asia Miles, per card and zone. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/asia-miles-lookup.csv and asia-miles-rules.csv,
    snapshot 2026-08-11 of
    https://api.cathaypacific.com/mpo-miles-services/v3/miles-calculator

    See data/earn/sources/asia-miles-parsing-guide.md for what the columns mean
    and how the figures were obtained.

    One fact per (card, zone position, reach), binding the rate list
    src/earn/kernel.pl expects. Cathay's own rows carry both currencies as fixed
    amounts, with Asia Miles at exactly 100 times the Status Points; a partner's
    carry fixed Status Points and Asia Miles as a percentage of the distance
    flown.

    A zone nobody sampled has no Status Points rate at all rather than a zero.
    That is the whole reason this file is generated with a hole in it: the kernel
    reports an absent rate as undecided, and 0 would be a claim the observations
    do not support. 106 of the 942 cells are such holes.

    Reach is `any` except on American's Business card, the one row in the table
    whose percentage varies: 150% where both airports are in the same country and
    125% otherwise. That is a fact about the sector, so it arrives here as part of
    the route basis rather than as a special case in the resolver.
*/

%! cx_rate(?Card, ?Zone, ?Reach, ?Rates) is nondet.
cx_rate(fare(cx, first, first, a, all), 1, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, first, first, a, all), 2, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, first, first, a, all), 3, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, first, first, a, all), 4, any, [rate(status_points, fixed(110)), rate(asia_miles, fixed(11000))]).
cx_rate(fare(cx, first, first, a, all), 5, any, [rate(status_points, fixed(160)), rate(asia_miles, fixed(16000))]).
cx_rate(fare(cx, first, first, a, all), 6, any, [rate(status_points, fixed(180)), rate(asia_miles, fixed(18000))]).
cx_rate(fare(cx, business, business, b, all), 1, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, business, business, b, all), 2, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, business, business, b, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, business, business, b, all), 4, any, [rate(status_points, fixed(90)), rate(asia_miles, fixed(9000))]).
cx_rate(fare(cx, business, business, b, all), 5, any, [rate(status_points, fixed(130)), rate(asia_miles, fixed(13000))]).
cx_rate(fare(cx, business, business, b, all), 6, any, [rate(status_points, fixed(150)), rate(asia_miles, fixed(15000))]).
cx_rate(fare(cx, business, business, c, all), 1, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, business, business, c, all), 2, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, business, business, c, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, business, business, c, all), 4, any, [rate(status_points, fixed(75)), rate(asia_miles, fixed(7500))]).
cx_rate(fare(cx, business, business, c, all), 5, any, [rate(status_points, fixed(100)), rate(asia_miles, fixed(10000))]).
cx_rate(fare(cx, business, business, c, all), 6, any, [rate(status_points, fixed(120)), rate(asia_miles, fixed(12000))]).
cx_rate(fare(cx, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(80)), rate(asia_miles, fixed(8000))]).
cx_rate(fare(cx, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, fixed(10000))]).
cx_rate(fare(cx, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, fixed(6500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, fixed(8500))]).
cx_rate(fare(cx, economy, economy_flex, f, all), 1, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_flex, f, all), 2, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, economy_flex, f, all), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, economy, economy_flex, f, all), 4, any, [rate(status_points, fixed(48)), rate(asia_miles, fixed(4800))]).
cx_rate(fare(cx, economy, economy_flex, f, all), 5, any, [rate(status_points, fixed(70)), rate(asia_miles, fixed(7000))]).
cx_rate(fare(cx, economy, economy_flex, f, all), 6, any, [rate(status_points, fixed(90)), rate(asia_miles, fixed(9000))]).
cx_rate(fare(cx, economy, economy_essential, f, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_essential, f, all), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_essential, f, all), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_essential, f, all), 4, any, [rate(status_points, fixed(38)), rate(asia_miles, fixed(3800))]).
cx_rate(fare(cx, economy, economy_essential, f, all), 5, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, economy, economy_essential, f, all), 6, any, [rate(status_points, fixed(70)), rate(asia_miles, fixed(7000))]).
cx_rate(fare(cx, economy, economy_light, f, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_light, f, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_light, f, all), 3, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, economy_light, f, all), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, economy_light, f, all), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, economy_light, f, all), 6, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, economy, codeshare, f, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, codeshare, f, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, codeshare, f, all), 3, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, codeshare, f, all), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, codeshare, f, all), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, codeshare, f, all), 6, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, economy, economy_flex, g, all), 1, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_flex, g, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_flex, g, all), 3, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, economy_flex, g, all), 4, any, [rate(status_points, fixed(42)), rate(asia_miles, fixed(4200))]).
cx_rate(fare(cx, economy, economy_flex, g, all), 5, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, economy, economy_flex, g, all), 6, any, [rate(status_points, fixed(80)), rate(asia_miles, fixed(8000))]).
cx_rate(fare(cx, economy, economy_essential, g, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_essential, g, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_essential, g, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_essential, g, all), 4, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, economy_essential, g, all), 5, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, economy, economy_essential, g, all), 6, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, economy, economy_light, g, all), 1, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, economy_light, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_light, g, all), 3, any, [rate(status_points, fixed(12)), rate(asia_miles, fixed(1200))]).
cx_rate(fare(cx, economy, economy_light, g, all), 4, any, [rate(status_points, fixed(22)), rate(asia_miles, fixed(2200))]).
cx_rate(fare(cx, economy, economy_light, g, all), 5, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, economy_light, g, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, codeshare, g, all), 1, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, codeshare, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, codeshare, g, all), 3, any, [rate(status_points, fixed(12)), rate(asia_miles, fixed(1200))]).
cx_rate(fare(cx, economy, codeshare, g, all), 4, any, [rate(status_points, fixed(22)), rate(asia_miles, fixed(2200))]).
cx_rate(fare(cx, economy, codeshare, g, all), 5, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, codeshare, g, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, economy_flex, j, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_flex, j, all), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_flex, j, all), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_flex, j, all), 4, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, economy_flex, j, all), 5, any, [rate(status_points, fixed(38)), rate(asia_miles, fixed(3800))]).
cx_rate(fare(cx, economy, economy_flex, j, all), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, economy, economy_essential, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, fixed(500))]).
cx_rate(fare(cx, economy, economy_essential, j, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_essential, j, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_essential, j, all), 4, any, [rate(status_points, fixed(22)), rate(asia_miles, fixed(2200))]).
cx_rate(fare(cx, economy, economy_essential, j, all), 5, any, [rate(status_points, fixed(28)), rate(asia_miles, fixed(2800))]).
cx_rate(fare(cx, economy, economy_essential, j, all), 6, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, economy, economy_light, j, all), 1, any, [rate(status_points, fixed(3)), rate(asia_miles, fixed(300))]).
cx_rate(fare(cx, economy, economy_light, j, all), 2, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, economy_light, j, all), 3, any, [rate(status_points, fixed(8)), rate(asia_miles, fixed(800))]).
cx_rate(fare(cx, economy, economy_light, j, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_light, j, all), 5, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, economy_light, j, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, codeshare, j, all), 1, any, [rate(status_points, fixed(3)), rate(asia_miles, fixed(300))]).
cx_rate(fare(cx, economy, codeshare, j, all), 2, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, codeshare, j, all), 3, any, [rate(status_points, fixed(8)), rate(asia_miles, fixed(800))]).
cx_rate(fare(cx, economy, codeshare, j, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, codeshare, j, all), 5, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, codeshare, j, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(aa, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, a, all), 3, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, a, all), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, b, all), 1, domestic, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, b, all), 1, international, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, b, all), 2, domestic, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, b, all), 2, international, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, b, all), 3, domestic, [rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, b, all), 3, international, [rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, b, all), 4, domestic, [rate(status_points, fixed(60)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, b, all), 4, international, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, b, all), 5, domestic, [rate(status_points, fixed(75)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, b, all), 5, international, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, b, all), 6, domestic, [rate(status_points, fixed(85)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, b, all), 6, international, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, d, all), 3, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, e, all), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, f, all), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, g, all), 3, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, g, all), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, g, all), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, g, all), 6, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, j, all), 3, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, j, all), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, h, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, h, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, h, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, h, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, h, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, h, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(as, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, a, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, a, all), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(as, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, g, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, g, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, g, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, g, all), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(at, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, b, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, h, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, j, all), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, j, all), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ay, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, b, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, c, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, c, all), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, c, all), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, c, all), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, c, all), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, c, all), 6, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, h, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(ba, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, a, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, a, all), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, b, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, j, all), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, j, all), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, first, first, a, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, a, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, a, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, a, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, a, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, a, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, c, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, c, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, c, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, c, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, c, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, c, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, g, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, g, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, g, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, g, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, g, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, g, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, h, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, h, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, h, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, h, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, h, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, h, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, j, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, j, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, j, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, j, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, j, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, j, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, b, all), 3, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, b, all), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, c, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, c, all), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, c, all), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, c, all), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, c, all), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, c, all), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(fj, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, f, all), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, g, all), 3, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, g, all), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, g, all), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, g, all), 6, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, h, all), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, h, all), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, j, all), 3, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, j, all), 6, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, b, all), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, b, all), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, b, all), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, b, all), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, d, all), 3, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, d, all), 4, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, d, all), 5, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, d, all), 6, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, e, all), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, e, all), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, e, all), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, e, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, f, all), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, f, all), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, f, all), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, j, all), 3, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, j, all), 4, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, j, all), 5, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, j, all), 6, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(ib, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, b, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, j, all), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, j, all), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(jl, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, a, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, a, all), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, b, domestic), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, b, domestic), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, b, domestic), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, b, domestic), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, b, domestic), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, b, domestic), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, b, all), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, g, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, g, all), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, g, all), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, g, all), 6, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(jl, premium_economy, premium_economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, h, all), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, h, international), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, international), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, international), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, international), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, international), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, international), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, domestic), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, domestic), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, domestic), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, domestic), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, domestic), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, h, domestic), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(la, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, first, first, a, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, a, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, a, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, a, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, a, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, a, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, c, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, c, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, c, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, c, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, c, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, c, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, g, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, g, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, g, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, g, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, g, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, g, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, first, first, a, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, a, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, a, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, a, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, a, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, a, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, c, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, c, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, c, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, c, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, c, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, c, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, g, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, g, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, g, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, g, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, g, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, g, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, a, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, a, all), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, b, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, h, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, a, all), 3, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, a, all), 4, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, a, all), 5, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, a, all), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, b, domestic), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, b, domestic), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, b, domestic), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, b, domestic), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, b, domestic), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, b, domestic), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, b, all), 2, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, b, all), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, b, all), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, b, all), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, b, all), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, g, all), 2, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, g, all), 3, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, g, all), 4, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, g, all), 5, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, g, all), 6, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, premium_economy, premium_economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, f, all), 2, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, f, all), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, f, all), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, f, all), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, h, all), 2, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, h, all), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, h, all), 4, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, h, all), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, h, all), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, f, all), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, f, all), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, f, all), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, h, domestic), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, h, domestic), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, h, domestic), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, h, domestic), 4, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, h, domestic), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, h, domestic), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nz, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, g, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, g, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, g, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, g, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, g, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, g, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, c, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, c, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, c, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, c, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, c, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, c, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, g, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, g, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, g, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, g, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, g, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, g, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, g, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, g, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, g, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, g, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, g, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, g, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, a, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, a, all), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, b, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, h, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, a, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, a, all), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(qr, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, b, all), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, g, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, g, all), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, g, all), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, g, all), 6, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(qr, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, h, all), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, j, all), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, j, all), 6, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(rj, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, b, all), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, b, all), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, c, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, c, all), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, c, all), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, c, all), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, c, all), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, c, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, f, all), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, f, all), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, g, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, g, all), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, g, all), 5, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, g, all), 6, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, h, all), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, h, all), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(ul, business, business, b, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, b, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, b, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, b, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, b, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, b, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, c, all), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, c, all), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, c, all), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, c, all), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, c, all), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, c, all), 6, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, g, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, g, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, g, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, g, all), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, g, all), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, g, all), 6, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, h, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, j, all), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, j, all), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, first, first, a, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, a, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, a, all), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, a, all), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, a, all), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, a, all), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, business, business, c, all), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, c, all), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, c, all), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, c, all), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, c, all), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, c, all), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, economy, economy, f, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, f, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, f, all), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, f, all), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, f, all), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, f, all), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, h, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, h, all), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, h, all), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, h, all), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, h, all), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, h, all), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, j, all), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, j, all), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, j, all), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, j, all), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, j, all), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, j, all), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, business, business, b, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, b, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, b, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, b, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, b, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, b, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, c, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, c, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, c, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, c, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, c, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, c, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, premium_economy, premium_economy, d, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, d, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, d, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, d, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, d, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, d, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, e, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, f, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, f, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, f, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, f, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, f, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, f, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, g, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, g, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, g, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, g, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, g, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, g, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, h, all), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, h, all), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, h, all), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, h, all), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, h, all), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, h, all), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).

%! cx_unpriced(?Card, ?Why) is nondet.
%  A fare group the carrier defines and the sampling never reached, so it has no
%  rate at any distance and no percentage either. Two of them, and they are a
%  different thing from a card whose rate is simply zero.
cx_unpriced(fare(lx, economy, economy, h, all), 'Group exists in the page model but never appeared in sampling. Percentage and points both unknown').
cx_unpriced(fare(os, economy, economy, h, all), 'Group exists in the page model but never appeared in sampling. Percentage and points both unknown').
