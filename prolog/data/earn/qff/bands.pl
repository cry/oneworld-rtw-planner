:- module(qff_bands,
          [ partner_band/3,
            band_accrual/3,
            band_edges/1,
            band_label/2
          ]).

/** <module> Qantas Frequent Flyer partner mileage bands. GENERATED -- do not edit.

    Built by prolog/tools/build_qff_tables.mjs from
    data/earn/sources/qff-bands.json, read 2026-08-11 from
    https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/partner-airlines

    The "All other flights" table: what a partner-marketed sector earns per
    one-way flight, by distance and earn category, when no region pair in the
    published table covers it. Phase 2 adds the region pairs, which take
    precedence; these are the fallback and the only basis phase 1 resolves.

    Base rate throughout -- no tier bonus, which is applied by the kernel from
    data/earn/qff/tiers.pl.
*/

%! partner_band(?Band, ?LowMiles, ?HighMiles) is nondet.
%  Inclusive at both ends; `inf` is the open top of the table.
partner_band(band(1, 100), 1, 100).
partner_band(band(101, 250), 101, 250).
partner_band(band(251, 500), 251, 500).
partner_band(band(501, 750), 501, 750).
partner_band(band(751, 1500), 751, 1500).
partner_band(band(1501, 2500), 1501, 2500).
partner_band(band(2501, 3500), 2501, 3500).
partner_band(band(3501, 5000), 3501, 5000).
partner_band(band(5001, 6500), 5001, 6500).
partner_band(band(6501, inf), 6501, inf).

%! band_label(?Band, ?Label) is nondet.
%  How the band is written in the register, matching the published table.
band_label(band(1, 100), 'up to 100 miles').
band_label(band(101, 250), '101 to 250 miles').
band_label(band(251, 500), '251 to 500 miles').
band_label(band(501, 750), '501 to 750 miles').
band_label(band(751, 1500), '751 to 1,500 miles').
band_label(band(1501, 2500), '1,501 to 2,500 miles').
band_label(band(2501, 3500), '2,501 to 3,500 miles').
band_label(band(3501, 5000), '3,501 to 5,000 miles').
band_label(band(5001, 6500), '5,001 to 6,500 miles').
band_label(band(6501, inf), '6,501 miles and above').

%! band_edges(-Edges) is det.
%  Every boundary in this table, for the near-a-boundary warning in
%  src/earn/distance.pl.
band_edges([100, 250, 500, 750, 1500, 2500, 3500, 5000, 6500]).

%! band_accrual(?Band, ?Category, ?Rates) is nondet.
band_accrual(band(1, 100), discount_economy,
              [ rate(points, fixed(25)),
                rate(status_credits, fixed(5)) ]).
band_accrual(band(1, 100), economy,
              [ rate(points, fixed(50)),
                rate(status_credits, fixed(5)) ]).
band_accrual(band(1, 100), flexible_economy,
              [ rate(points, fixed(100)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(1, 100), premium_economy,
              [ rate(points, fixed(110)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(1, 100), business,
              [ rate(points, fixed(125)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(1, 100), first,
              [ rate(points, fixed(150)),
                rate(status_credits, fixed(30)) ]).
band_accrual(band(101, 250), discount_economy,
              [ rate(points, fixed(50)),
                rate(status_credits, fixed(5)) ]).
band_accrual(band(101, 250), economy,
              [ rate(points, fixed(100)),
                rate(status_credits, fixed(5)) ]).
band_accrual(band(101, 250), flexible_economy,
              [ rate(points, fixed(200)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(101, 250), premium_economy,
              [ rate(points, fixed(220)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(101, 250), business,
              [ rate(points, fixed(250)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(101, 250), first,
              [ rate(points, fixed(300)),
                rate(status_credits, fixed(30)) ]).
band_accrual(band(251, 500), discount_economy,
              [ rate(points, fixed(100)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(251, 500), economy,
              [ rate(points, fixed(200)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(251, 500), flexible_economy,
              [ rate(points, fixed(400)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(251, 500), premium_economy,
              [ rate(points, fixed(450)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(251, 500), business,
              [ rate(points, fixed(500)),
                rate(status_credits, fixed(40)) ]).
band_accrual(band(251, 500), first,
              [ rate(points, fixed(600)),
                rate(status_credits, fixed(50)) ]).
band_accrual(band(501, 750), discount_economy,
              [ rate(points, fixed(170)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(501, 750), economy,
              [ rate(points, fixed(325)),
                rate(status_credits, fixed(10)) ]).
band_accrual(band(501, 750), flexible_economy,
              [ rate(points, fixed(650)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(501, 750), premium_economy,
              [ rate(points, fixed(715)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(501, 750), business,
              [ rate(points, fixed(825)),
                rate(status_credits, fixed(40)) ]).
band_accrual(band(501, 750), first,
              [ rate(points, fixed(975)),
                rate(status_credits, fixed(60)) ]).
band_accrual(band(751, 1500), discount_economy,
              [ rate(points, fixed(275)),
                rate(status_credits, fixed(15)) ]).
band_accrual(band(751, 1500), economy,
              [ rate(points, fixed(550)),
                rate(status_credits, fixed(15)) ]).
band_accrual(band(751, 1500), flexible_economy,
              [ rate(points, fixed(1100)),
                rate(status_credits, fixed(30)) ]).
band_accrual(band(751, 1500), premium_economy,
              [ rate(points, fixed(1210)),
                rate(status_credits, fixed(30)) ]).
band_accrual(band(751, 1500), business,
              [ rate(points, fixed(1375)),
                rate(status_credits, fixed(60)) ]).
band_accrual(band(751, 1500), first,
              [ rate(points, fixed(1650)),
                rate(status_credits, fixed(90)) ]).
band_accrual(band(1501, 2500), discount_economy,
              [ rate(points, fixed(500)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(1501, 2500), economy,
              [ rate(points, fixed(1000)),
                rate(status_credits, fixed(20)) ]).
band_accrual(band(1501, 2500), flexible_economy,
              [ rate(points, fixed(2000)),
                rate(status_credits, fixed(40)) ]).
band_accrual(band(1501, 2500), premium_economy,
              [ rate(points, fixed(2200)),
                rate(status_credits, fixed(40)) ]).
band_accrual(band(1501, 2500), business,
              [ rate(points, fixed(2500)),
                rate(status_credits, fixed(80)) ]).
band_accrual(band(1501, 2500), first,
              [ rate(points, fixed(3000)),
                rate(status_credits, fixed(120)) ]).
band_accrual(band(2501, 3500), discount_economy,
              [ rate(points, fixed(800)),
                rate(status_credits, fixed(25)) ]).
band_accrual(band(2501, 3500), economy,
              [ rate(points, fixed(1600)),
                rate(status_credits, fixed(25)) ]).
band_accrual(band(2501, 3500), flexible_economy,
              [ rate(points, fixed(3200)),
                rate(status_credits, fixed(50)) ]).
band_accrual(band(2501, 3500), premium_economy,
              [ rate(points, fixed(3520)),
                rate(status_credits, fixed(50)) ]).
band_accrual(band(2501, 3500), business,
              [ rate(points, fixed(4000)),
                rate(status_credits, fixed(100)) ]).
band_accrual(band(2501, 3500), first,
              [ rate(points, fixed(4800)),
                rate(status_credits, fixed(150)) ]).
band_accrual(band(3501, 5000), discount_economy,
              [ rate(points, fixed(1050)),
                rate(status_credits, fixed(30)) ]).
band_accrual(band(3501, 5000), economy,
              [ rate(points, fixed(2100)),
                rate(status_credits, fixed(30)) ]).
band_accrual(band(3501, 5000), flexible_economy,
              [ rate(points, fixed(4200)),
                rate(status_credits, fixed(60)) ]).
band_accrual(band(3501, 5000), premium_economy,
              [ rate(points, fixed(4600)),
                rate(status_credits, fixed(60)) ]).
band_accrual(band(3501, 5000), business,
              [ rate(points, fixed(5250)),
                rate(status_credits, fixed(120)) ]).
band_accrual(band(3501, 5000), first,
              [ rate(points, fixed(6300)),
                rate(status_credits, fixed(180)) ]).
band_accrual(band(5001, 6500), discount_economy,
              [ rate(points, fixed(1425)),
                rate(status_credits, fixed(35)) ]).
band_accrual(band(5001, 6500), economy,
              [ rate(points, fixed(2850)),
                rate(status_credits, fixed(35)) ]).
band_accrual(band(5001, 6500), flexible_economy,
              [ rate(points, fixed(5700)),
                rate(status_credits, fixed(70)) ]).
band_accrual(band(5001, 6500), premium_economy,
              [ rate(points, fixed(6300)),
                rate(status_credits, fixed(70)) ]).
band_accrual(band(5001, 6500), business,
              [ rate(points, fixed(7125)),
                rate(status_credits, fixed(140)) ]).
band_accrual(band(5001, 6500), first,
              [ rate(points, fixed(8600)),
                rate(status_credits, fixed(210)) ]).
band_accrual(band(6501, inf), discount_economy,
              [ rate(points, fixed(1875)),
                rate(status_credits, fixed(40)) ]).
band_accrual(band(6501, inf), economy,
              [ rate(points, fixed(3750)),
                rate(status_credits, fixed(40)) ]).
band_accrual(band(6501, inf), flexible_economy,
              [ rate(points, fixed(7500)),
                rate(status_credits, fixed(80)) ]).
band_accrual(band(6501, inf), premium_economy,
              [ rate(points, fixed(8250)),
                rate(status_credits, fixed(80)) ]).
band_accrual(band(6501, inf), business,
              [ rate(points, fixed(9400)),
                rate(status_credits, fixed(160)) ]).
band_accrual(band(6501, inf), first,
              [ rate(points, fixed(11250)),
                rate(status_credits, fixed(240)) ]).
