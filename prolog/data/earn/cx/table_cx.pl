:- module(cx_table, [cx_rate/4]).

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
    do not support. 118 of the 942 cells are such holes.

    Reach is `any` except on American's Business card, the one row in the table
    whose percentage varies: 150% where both airports are in the same country and
    125% otherwise. That is a fact about the sector, so it arrives here as part of
    the route basis rather than as a special case in the resolver.
*/

%! cx_rate(?Card, ?Zone, ?Reach, ?Rates) is nondet.
cx_rate(fare(cx, first, first, af), 1, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, first, first, af), 2, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, first, first, af), 3, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, first, first, af), 4, any, [rate(status_points, fixed(110)), rate(asia_miles, fixed(11000))]).
cx_rate(fare(cx, first, first, af), 5, any, [rate(status_points, fixed(160)), rate(asia_miles, fixed(16000))]).
cx_rate(fare(cx, first, first, af), 6, any, [rate(status_points, fixed(180)), rate(asia_miles, fixed(18000))]).
cx_rate(fare(cx, business, business, cj), 1, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, business, business, cj), 2, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, business, business, cj), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, business, business, cj), 4, any, [rate(status_points, fixed(90)), rate(asia_miles, fixed(9000))]).
cx_rate(fare(cx, business, business, cj), 5, any, [rate(status_points, fixed(130)), rate(asia_miles, fixed(13000))]).
cx_rate(fare(cx, business, business, cj), 6, any, [rate(status_points, fixed(150)), rate(asia_miles, fixed(15000))]).
cx_rate(fare(cx, business, business, dip), 1, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, business, business, dip), 2, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, business, business, dip), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, business, business, dip), 4, any, [rate(status_points, fixed(75)), rate(asia_miles, fixed(7500))]).
cx_rate(fare(cx, business, business, dip), 5, any, [rate(status_points, fixed(100)), rate(asia_miles, fixed(10000))]).
cx_rate(fare(cx, business, business, dip), 6, any, [rate(status_points, fixed(120)), rate(asia_miles, fixed(12000))]).
cx_rate(fare(cx, premium_economy, premium_economy, e), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, premium_economy, premium_economy, e), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e), 4, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, fixed(6500))]).
cx_rate(fare(cx, premium_economy, premium_economy, e), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, fixed(8500))]).
cx_rate(fare(cx, premium_economy, premium_economy, rw), 1, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, premium_economy, premium_economy, rw), 2, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, premium_economy, premium_economy, rw), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, premium_economy, premium_economy, rw), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, premium_economy, premium_economy, rw), 5, any, [rate(status_points, fixed(80)), rate(asia_miles, fixed(8000))]).
cx_rate(fare(cx, premium_economy, premium_economy, rw), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, fixed(10000))]).
cx_rate(fare(cx, economy, economy_flex, bhky), 1, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_flex, bhky), 2, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, economy_flex, bhky), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, economy, economy_flex, bhky), 4, any, [rate(status_points, fixed(48)), rate(asia_miles, fixed(4800))]).
cx_rate(fare(cx, economy, economy_flex, bhky), 5, any, [rate(status_points, fixed(70)), rate(asia_miles, fixed(7000))]).
cx_rate(fare(cx, economy, economy_flex, bhky), 6, any, [rate(status_points, fixed(90)), rate(asia_miles, fixed(9000))]).
cx_rate(fare(cx, economy, economy_essential, bhky), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_essential, bhky), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_essential, bhky), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_essential, bhky), 4, any, [rate(status_points, fixed(38)), rate(asia_miles, fixed(3800))]).
cx_rate(fare(cx, economy, economy_essential, bhky), 5, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, economy, economy_essential, bhky), 6, any, [rate(status_points, fixed(70)), rate(asia_miles, fixed(7000))]).
cx_rate(fare(cx, economy, economy_light, bhky), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_light, bhky), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_light, bhky), 3, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, economy_light, bhky), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, economy_light, bhky), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, economy_light, bhky), 6, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, economy, codeshare, bhky), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, codeshare, bhky), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, codeshare, bhky), 3, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, codeshare, bhky), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, codeshare, bhky), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, codeshare, bhky), 6, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, economy, economy_flex, lmv), 1, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_flex, lmv), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_flex, lmv), 3, any, [rate(status_points, fixed(30)), rate(asia_miles, fixed(3000))]).
cx_rate(fare(cx, economy, economy_flex, lmv), 4, any, [rate(status_points, fixed(42)), rate(asia_miles, fixed(4200))]).
cx_rate(fare(cx, economy, economy_flex, lmv), 5, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, economy, economy_flex, lmv), 6, any, [rate(status_points, fixed(80)), rate(asia_miles, fixed(8000))]).
cx_rate(fare(cx, economy, economy_essential, lmv), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_essential, lmv), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_essential, lmv), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_essential, lmv), 4, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, economy_essential, lmv), 5, any, [rate(status_points, fixed(50)), rate(asia_miles, fixed(5000))]).
cx_rate(fare(cx, economy, economy_essential, lmv), 6, any, [rate(status_points, fixed(60)), rate(asia_miles, fixed(6000))]).
cx_rate(fare(cx, economy, economy_light, lmv), 1, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, economy_light, lmv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_light, lmv), 3, any, [rate(status_points, fixed(12)), rate(asia_miles, fixed(1200))]).
cx_rate(fare(cx, economy, economy_light, lmv), 4, any, [rate(status_points, fixed(22)), rate(asia_miles, fixed(2200))]).
cx_rate(fare(cx, economy, economy_light, lmv), 5, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, economy_light, lmv), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, codeshare, lmv), 1, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, codeshare, lmv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, codeshare, lmv), 3, any, [rate(status_points, fixed(12)), rate(asia_miles, fixed(1200))]).
cx_rate(fare(cx, economy, codeshare, lmv), 4, any, [rate(status_points, fixed(22)), rate(asia_miles, fixed(2200))]).
cx_rate(fare(cx, economy, codeshare, lmv), 5, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, codeshare, lmv), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, fixed(4000))]).
cx_rate(fare(cx, economy, economy_flex, noqs), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_flex, noqs), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, fixed(2000))]).
cx_rate(fare(cx, economy, economy_flex, noqs), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, economy_flex, noqs), 4, any, [rate(status_points, fixed(32)), rate(asia_miles, fixed(3200))]).
cx_rate(fare(cx, economy, economy_flex, noqs), 5, any, [rate(status_points, fixed(38)), rate(asia_miles, fixed(3800))]).
cx_rate(fare(cx, economy, economy_flex, noqs), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, fixed(4500))]).
cx_rate(fare(cx, economy, economy_essential, noqs), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, fixed(500))]).
cx_rate(fare(cx, economy, economy_essential, noqs), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, fixed(1000))]).
cx_rate(fare(cx, economy, economy_essential, noqs), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_essential, noqs), 4, any, [rate(status_points, fixed(22)), rate(asia_miles, fixed(2200))]).
cx_rate(fare(cx, economy, economy_essential, noqs), 5, any, [rate(status_points, fixed(28)), rate(asia_miles, fixed(2800))]).
cx_rate(fare(cx, economy, economy_essential, noqs), 6, any, [rate(status_points, fixed(35)), rate(asia_miles, fixed(3500))]).
cx_rate(fare(cx, economy, economy_light, noqs), 1, any, [rate(status_points, fixed(3)), rate(asia_miles, fixed(300))]).
cx_rate(fare(cx, economy, economy_light, noqs), 2, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, economy_light, noqs), 3, any, [rate(status_points, fixed(8)), rate(asia_miles, fixed(800))]).
cx_rate(fare(cx, economy, economy_light, noqs), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, economy_light, noqs), 5, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, economy_light, noqs), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(cx, economy, codeshare, noqs), 1, any, [rate(status_points, fixed(3)), rate(asia_miles, fixed(300))]).
cx_rate(fare(cx, economy, codeshare, noqs), 2, any, [rate(status_points, fixed(6)), rate(asia_miles, fixed(600))]).
cx_rate(fare(cx, economy, codeshare, noqs), 3, any, [rate(status_points, fixed(8)), rate(asia_miles, fixed(800))]).
cx_rate(fare(cx, economy, codeshare, noqs), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, fixed(1500))]).
cx_rate(fare(cx, economy, codeshare, noqs), 5, any, [rate(status_points, fixed(18)), rate(asia_miles, fixed(1800))]).
cx_rate(fare(cx, economy, codeshare, noqs), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, fixed(2500))]).
cx_rate(fare(aa, first, first, af), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, af), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, af), 3, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, af), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, af), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, first, first, af), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, cdijr), 1, domestic, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, cdijr), 1, international, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, cdijr), 2, domestic, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, cdijr), 2, international, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, cdijr), 3, domestic, [rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, cdijr), 3, international, [rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, cdijr), 4, domestic, [rate(status_points, fixed(60)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, cdijr), 4, international, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, cdijr), 5, domestic, [rate(status_points, fixed(75)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, cdijr), 5, international, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, business, business, cdijr), 6, domestic, [rate(status_points, fixed(85)), rate(asia_miles, pct(150))]).
cx_rate(fare(aa, business, business, cdijr), 6, international, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(aa, premium_economy, premium_economy, p), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, p), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, p), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, p), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, p), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, p), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, premium_economy, premium_economy, w), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, w), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, w), 3, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, w), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, w), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, premium_economy, premium_economy, w), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(aa, economy, economy, y), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, y), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, y), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, y), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, y), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, y), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(aa, economy, economy, hklmv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, hklmv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, hklmv), 3, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, hklmv), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, hklmv), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, hklmv), 6, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(75))]).
cx_rate(fare(aa, economy, economy, gnqs), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, gnqs), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, gnqs), 3, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, gnqs), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, gnqs), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(aa, economy, economy, gnqs), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, business, business, cdjpz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, cdjpz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, cdjpz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, cdjpz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, cdjpz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, business, business, cdjpz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ac, premium_economy, premium_economy, aeo), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, aeo), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, aeo), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, aeo), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, aeo), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, premium_economy, premium_economy, aeo), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ac, economy, economy, bhmquvwy), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, bhmquvwy), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, bhmquvwy), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, bhmquvwy), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, bhmquvwy), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, bhmquvwy), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ac, economy, economy, gklst), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, gklst), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, gklst), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, gklst), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, gklst), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ac, economy, economy, gklst), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(as, first, first, acdfij), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, acdfij), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, acdfij), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, acdfij), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, acdfij), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(as, first, first, acdfij), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(as, economy, economy, bhklmnsvy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, bhklmnsvy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, bhklmnsvy), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, bhklmnsvy), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, bhklmnsvy), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, bhklmnsvy), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(as, economy, economy, goq), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, goq), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, goq), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, goq), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, goq), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(as, economy, economy, goq), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(at, business, business, cdij), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, cdij), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, cdij), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, cdij), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, cdij), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, business, business, cdij), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(at, economy, economy, y), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, y), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, y), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, y), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, y), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, y), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(at, economy, economy, bh), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, bh), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, bh), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, bh), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, bh), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, bh), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(at, economy, economy, klm), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, klm), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, klm), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, klm), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, klm), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(at, economy, economy, klm), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ay, business, business, cdj), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, cdj), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, cdj), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, cdj), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, cdj), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, cdj), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ay, business, business, ir), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, ir), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, ir), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, ir), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, ir), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, business, business, ir), 6, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, eptw), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, eptw), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, eptw), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, eptw), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, eptw), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, premium_economy, premium_economy, eptw), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, bhkmy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, bhkmy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, bhkmy), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, bhkmy), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, bhkmy), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, bhkmy), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ay, economy, economy, lv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, lv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, lv), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, lv), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, lv), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(ay, economy, economy, lv), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(ba, first, first, af), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, af), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, af), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, af), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, af), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, first, first, af), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(ba, business, business, cdijr), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, cdijr), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, cdijr), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, cdijr), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, cdijr), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, business, business, cdijr), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ba, premium_economy, premium_economy, et), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, et), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, et), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, et), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, et), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, et), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, premium_economy, premium_economy, w), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, w), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, w), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, w), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, w), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, premium_economy, premium_economy, w), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(ba, economy, economy, bhy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, bhy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, bhy), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, bhy), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, bhy), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, bhy), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ba, economy, economy, klmnqsv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, klmnqsv), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, klmnqsv), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, klmnqsv), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, klmnqsv), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ba, economy, economy, klmnqsv), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, first, first, a), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, a), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, a), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, a), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, a), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, a), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, first, first, f), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, f), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, f), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, f), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, f), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, first, first, f), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(200))]).
cx_rate(fare(ca, business, business, cj), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, cj), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, cj), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, cj), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, cj), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, cj), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(ca, business, business, drz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, drz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, drz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, drz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, drz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, business, business, drz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(ca, premium_economy, premium_economy, e), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, e), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, premium_economy, premium_economy, g), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, g), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, g), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, g), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, g), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, premium_economy, premium_economy, g), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(ca, economy, economy, by), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, by), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, by), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, by), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, by), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, by), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(ca, economy, economy, mu), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, mu), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, mu), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, mu), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, mu), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, mu), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(75))]).
cx_rate(fare(ca, economy, economy, hqstvw), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, hqstvw), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, hqstvw), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, hqstvw), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, hqstvw), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, hqstvw), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(ca, economy, economy, klp), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, klp), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, klp), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, klp), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, klp), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(ca, economy, economy, klp), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, business, business, cj), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, cj), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, cj), 3, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, cj), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, cj), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, cj), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(fj, business, business, diz), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, diz), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, diz), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, diz), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, diz), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, pct(125))]).
cx_rate(fare(fj, business, business, diz), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(fj, economy, economy, bhky), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, bhky), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, bhky), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, bhky), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, bhky), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, bhky), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(fj, economy, economy, lmw), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, lmw), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, lmw), 3, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, lmw), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, lmw), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, lmw), 6, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(fj, economy, economy, nsv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, nsv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, nsv), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, nsv), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, nsv), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, nsv), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(fj, economy, economy, afgopqrt), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, afgopqrt), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, afgopqrt), 3, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, afgopqrt), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, afgopqrt), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(fj, economy, economy, afgopqrt), 6, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, business, business, cdijr), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, cdijr), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, cdijr), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, cdijr), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, cdijr), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, business, business, cdijr), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(i2, premium_economy, premium_economy, et), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, et), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, et), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, et), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, et), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, et), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, premium_economy, premium_economy, w), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, w), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, w), 3, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, w), 4, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, w), 5, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, premium_economy, premium_economy, w), 6, any, [rate(asia_miles, pct(110))]).
cx_rate(fare(i2, economy, economy, bhy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, bhy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, bhy), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, bhy), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, bhy), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, bhy), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(i2, economy, economy, fgklmnqsvz), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, fgklmnqsvz), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, fgklmnqsvz), 3, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, fgklmnqsvz), 4, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, fgklmnqsvz), 5, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(i2, economy, economy, fgklmnqsvz), 6, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(ib, business, business, cdijr), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, cdijr), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, cdijr), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, cdijr), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, cdijr), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, business, business, cdijr), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ib, premium_economy, premium_economy, et), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, et), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, et), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, et), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, et), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, et), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, premium_economy, premium_economy, w), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, w), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, w), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, w), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, w), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, premium_economy, premium_economy, w), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(ib, economy, economy, bhy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, bhy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, bhy), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, bhy), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, bhy), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, bhy), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ib, economy, economy, fgklmnqsvz), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, fgklmnqsvz), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, fgklmnqsvz), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, fgklmnqsvz), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, fgklmnqsvz), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ib, economy, economy, fgklmnqsvz), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(jl, first, first, af), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, af), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, af), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, af), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, af), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, af), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(jl, first, first, e), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, e), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, e), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, e), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, e), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, first, first, e), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, c), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, c), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, c), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, c), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, c), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, c), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(jl, business, business, h), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, h), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, h), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, h), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, h), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(70))]).
cx_rate(fare(jl, business, business, h), 6, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(jl, premium_economy, premium_economy, w), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, w), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, w), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, w), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, w), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, w), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, premium_economy, premium_economy, p), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, p), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, p), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, p), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, p), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, premium_economy, premium_economy, p), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, y), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, y), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, y), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, y), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, y), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, y), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, j), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, j), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, j), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, j), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, j), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, j), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(jl, economy, economy, r), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, r), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, r), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, r), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, r), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, r), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, ai), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, ai), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, ai), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, ai), 4, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, ai), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(jl, economy, economy, ai), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(la, business, business, cdijz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, cdijz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, cdijz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, cdijz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, cdijz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, business, business, cdijz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(la, premium_economy, premium_economy, pw), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, pw), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, pw), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, pw), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, pw), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, premium_economy, premium_economy, pw), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(la, economy, economy, bhklmnoqsvxy), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, bhklmnoqsvxy), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, bhklmnoqsvxy), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, bhklmnoqsvxy), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, bhklmnoqsvxy), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(la, economy, economy, bhklmnoqsvxy), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, first, first, af), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, af), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, af), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, af), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, af), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, first, first, af), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lh, business, business, cdjz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, cdjz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, cdjz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, cdjz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, cdjz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, cdjz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lh, business, business, p), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, p), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, p), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, p), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, p), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, business, business, p), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, eg), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, eg), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, eg), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, eg), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, eg), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, eg), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lh, premium_economy, premium_economy, n), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, n), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, n), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, n), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, n), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, premium_economy, premium_economy, n), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, bmuy), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, bmuy), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, bmuy), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, bmuy), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, bmuy), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, bmuy), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lh, economy, economy, hqsvw), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, hqsvw), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, hqsvw), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, hqsvw), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, hqsvw), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lh, economy, economy, hqsvw), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, first, first, af), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, af), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, af), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, af), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, af), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, first, first, af), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(lx, business, business, cdjz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, cdjz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, cdjz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, cdjz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, cdjz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, cdjz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(lx, business, business, p), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, p), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, p), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, p), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, p), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, business, business, p), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, eg), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, eg), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, eg), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, eg), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, eg), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, eg), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(lx, premium_economy, premium_economy, n), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, n), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, n), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, n), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, n), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, premium_economy, premium_economy, n), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, bmuy), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, bmuy), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, bmuy), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, bmuy), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, bmuy), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, bmuy), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(lx, economy, economy, hqsvw), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, hqsvw), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, hqsvw), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, hqsvw), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, hqsvw), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(lx, economy, economy, hqsvw), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, first, first, afp), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, afp), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, afp), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, afp), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, afp), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, first, first, afp), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(mh, business, business, cdjz), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, cdjz), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, cdjz), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, cdjz), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, cdjz), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, business, business, cdjz), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(mh, economy, economy, bhy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, bhy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, bhy), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, bhy), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, bhy), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, bhy), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(mh, economy, economy, km), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, km), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, km), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, km), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, km), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(mh, economy, economy, km), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, first, first, f), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, f), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, f), 3, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, f), 4, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, f), 5, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, f), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(nu, first, first, e), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, e), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, e), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, e), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, e), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, first, first, e), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, c), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, c), 2, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, c), 3, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, c), 4, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, c), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, c), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(nu, business, business, h), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, h), 2, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, h), 3, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, h), 4, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, h), 5, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, business, business, h), 6, any, [rate(asia_miles, pct(70))]).
cx_rate(fare(nu, premium_economy, premium_economy, w), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, w), 2, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, w), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, w), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, w), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, w), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, premium_economy, premium_economy, p), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, p), 2, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, p), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, p), 4, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, p), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, premium_economy, premium_economy, p), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, jy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, jy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, jy), 3, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, jy), 4, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, jy), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, jy), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(nu, economy, economy, ai), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, ai), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, ai), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, ai), 4, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, ai), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, ai), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, r), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, r), 2, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, r), 3, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, r), 4, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, r), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nu, economy, economy, r), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(nz, business, business, cdjz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, cdjz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, cdjz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, cdjz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, cdjz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, business, business, cdjz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(nz, premium_economy, premium_economy, aeou), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, aeou), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, aeou), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, aeou), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, aeou), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, premium_economy, premium_economy, aeou), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(nz, economy, economy, bmy), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, bmy), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, bmy), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, bmy), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, bmy), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, bmy), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(nz, economy, economy, hqtvw), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, hqtvw), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, hqtvw), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, hqtvw), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, hqtvw), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(nz, economy, economy, hqtvw), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, business, business, cdjz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, cdjz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, cdjz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, cdjz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, cdjz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, cdjz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(os, business, business, p), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, p), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, p), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, p), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, p), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, business, business, p), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, bmuy), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, bmuy), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, bmuy), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, bmuy), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, bmuy), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, bmuy), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(os, economy, economy, hqsvw), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, hqsvw), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, hqsvw), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, hqsvw), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, hqsvw), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(os, economy, economy, hqsvw), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, business, business, cd), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, cd), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, cd), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, cd), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, cd), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, business, business, cd), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(pg, economy, economy, hklmnty), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, hklmnty), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, hklmnty), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, hklmnty), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, hklmnty), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, hklmnty), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(pg, economy, economy, bgqv), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, bgqv), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, bgqv), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, bgqv), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, bgqv), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(pg, economy, economy, bgqv), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, first, first, af), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, af), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, af), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, af), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, af), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, first, first, af), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(qf, business, business, cdij), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, cdij), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, cdij), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, cdij), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, cdij), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, business, business, cdij), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(qf, premium_economy, premium_economy, rtw), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, rtw), 2, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, rtw), 3, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, rtw), 4, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, rtw), 5, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, premium_economy, premium_economy, rtw), 6, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(110))]).
cx_rate(fare(qf, economy, economy, y), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, y), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, y), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, y), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, y), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, y), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(qf, economy, economy, bhklmv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, bhklmv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, bhklmv), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, bhklmv), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, bhklmv), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(qf, economy, economy, bhklmv), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, first, first, af), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, af), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, af), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, af), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, af), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(qr, first, first, af), 6, any, [rate(asia_miles, pct(150))]).
cx_rate(fare(qr, business, business, cdijr), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, cdijr), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, cdijr), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, cdijr), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, cdijr), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, cdijr), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(qr, business, business, p), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, p), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, p), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, p), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, p), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(qr, business, business, p), 6, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(qr, economy, economy, bhy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, bhy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, bhy), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, bhy), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, bhy), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, bhy), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(qr, economy, economy, klmv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, klmv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, klmv), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, klmv), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, klmv), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, klmv), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(qr, economy, economy, gnqs), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, gnqs), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, gnqs), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, gnqs), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, gnqs), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(qr, economy, economy, gnqs), 6, any, [rate(asia_miles, pct(25))]).
cx_rate(fare(rj, business, business, cdj), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, cdj), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, cdj), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, cdj), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, cdj), 5, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, cdj), 6, any, [rate(asia_miles, pct(125))]).
cx_rate(fare(rj, business, business, iz), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, iz), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, iz), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, iz), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, iz), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, business, business, iz), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, y), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, y), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, y), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, y), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, y), 5, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, y), 6, any, [rate(asia_miles, pct(100))]).
cx_rate(fare(rj, economy, economy, bhk), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, bhk), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, bhk), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, bhk), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, bhk), 5, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, bhk), 6, any, [rate(asia_miles, pct(75))]).
cx_rate(fare(rj, economy, economy, lmnqsv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, lmnqsv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, lmnqsv), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, lmnqsv), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, lmnqsv), 5, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(rj, economy, economy, lmnqsv), 6, any, [rate(asia_miles, pct(50))]).
cx_rate(fare(ul, business, business, cdj), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, cdj), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, cdj), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, cdj), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, cdj), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, cdj), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(ul, business, business, i), 1, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, i), 2, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, i), 3, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, i), 4, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, i), 5, any, [rate(status_points, fixed(65)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, business, business, i), 6, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, bhpy), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, bhpy), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, bhpy), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, bhpy), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, bhpy), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, bhpy), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(ul, economy, economy, ekmw), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, ekmw), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, ekmw), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, ekmw), 4, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, ekmw), 5, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, ekmw), 6, any, [rate(status_points, fixed(30)), rate(asia_miles, pct(75))]).
cx_rate(fare(ul, economy, economy, lrsv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, lrsv), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, lrsv), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, lrsv), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, lrsv), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, lrsv), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(ul, economy, economy, n), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, n), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, n), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, n), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, n), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(ul, economy, economy, n), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, first, first, af), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, af), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, af), 3, any, [rate(status_points, fixed(50)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, af), 4, any, [rate(status_points, fixed(70)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, af), 5, any, [rate(status_points, fixed(90)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, first, first, af), 6, any, [rate(status_points, fixed(100)), rate(asia_miles, pct(150))]).
cx_rate(fare(wy, business, business, cdijp), 1, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, cdijp), 2, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, cdijp), 3, any, [rate(status_points, fixed(45)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, cdijp), 4, any, [rate(status_points, fixed(60)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, cdijp), 5, any, [rate(status_points, fixed(75)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, business, business, cdijp), 6, any, [rate(status_points, fixed(85)), rate(asia_miles, pct(125))]).
cx_rate(fare(wy, economy, economy, y), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, y), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, y), 3, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, y), 4, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, y), 5, any, [rate(status_points, fixed(35)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, y), 6, any, [rate(status_points, fixed(40)), rate(asia_miles, pct(100))]).
cx_rate(fare(wy, economy, economy, b), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, b), 2, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, b), 3, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, b), 4, any, [rate(status_points, fixed(15)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, b), 5, any, [rate(status_points, fixed(20)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, b), 6, any, [rate(status_points, fixed(25)), rate(asia_miles, pct(50))]).
cx_rate(fare(wy, economy, economy, hklmnoqrstv), 1, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, hklmnoqrstv), 2, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, hklmnoqrstv), 3, any, [rate(status_points, fixed(5)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, hklmnoqrstv), 4, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, hklmnoqrstv), 5, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(wy, economy, economy, hklmnoqrstv), 6, any, [rate(status_points, fixed(10)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, business, business, cj), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, cj), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, cj), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, cj), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, cj), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, cj), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(150))]).
cx_rate(fare(zh, business, business, drz), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, drz), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, drz), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, drz), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, drz), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, business, business, drz), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(125))]).
cx_rate(fare(zh, premium_economy, premium_economy, e), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, e), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, premium_economy, premium_economy, g), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, g), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, g), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, g), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, g), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, premium_economy, premium_economy, g), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(110))]).
cx_rate(fare(zh, economy, economy, bhmuy), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, bhmuy), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, bhmuy), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, bhmuy), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, bhmuy), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, bhmuy), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(100))]).
cx_rate(fare(zh, economy, economy, qstvw), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, qstvw), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, qstvw), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, qstvw), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, qstvw), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, qstvw), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(50))]).
cx_rate(fare(zh, economy, economy, aklp), 1, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, aklp), 2, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, aklp), 3, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, aklp), 4, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, aklp), 5, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
cx_rate(fare(zh, economy, economy, aklp), 6, any, [rate(status_points, fixed(0)), rate(asia_miles, pct(25))]).
