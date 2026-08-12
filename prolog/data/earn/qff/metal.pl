:- module(qff_metal,
          [ metal_region_places/2,
            metal_region_countries/2,
            metal_region_iso/2,
            metal_region_label/2,
            metal_pair/4,
            metal_band/3,
            metal_band_label/2,
            metal_band_accrual/3,
            metal_domestic/3,
            metal_domestic_label/2,
            metal_domestic_accrual/3,
            metal_edges/1,
            metal_carrier/1
          ]).

/** <module> Qantas' own earning table. GENERATED -- do not edit.

    Built by prolog/tools/build_qff_tables.mjs from
    data/earn/sources/qff-metal.json, 2026-08-11, effective from
    2025-07-22:
    https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/qantas-jetstar

    Qantas- and Jetstar-marketed flights. Only the Qantas-marketed rows are used: an Explorer fare cannot be sold with a JQ flight number. This table publishes all ten earn categories, where the partner table publishes six -- which is why the two are separate tables here and why a QF-marketed sector is priced off this one.

    The page writes the last two bands as '5,001 to 6,500' and '6,500 miles and over', which overlap at exactly 6,500. The lower band's stated upper bound is taken as binding, so the top band starts at 6,501.
*/

%! metal_carrier(?Carrier) is nondet.
%  The marketing carriers this table prices. Jetstar's rows are on the same page
%  and are not here: an Explorer fare cannot be sold with a JQ flight number.
metal_carrier(qf).

%! metal_region_places(?Region, ?Places) is nondet.
metal_region_places(adelaide_brisbane_gold_coast_melbourne_sydney, [adl, bne, ool, mel, syd]).
metal_region_places(darwin_perth, [drw, per]).
metal_region_places(delhi_or_bengaluru, [del, blr]).
metal_region_places(johannesburg, [jnb]).
metal_region_places(santiago, [scl]).
metal_region_places(dallas, [dfw]).
metal_region_places(west_coast_usa_canada_or_dubai, [las, lax, phx, sfo, sea, yvr, dxb]).
metal_region_places(east_coast_usa_canada_or_europe, [bos, clt, chi, mia, nyc, mco, yto, was]).
metal_region_places(dubai, [dxb]).
metal_region_places(east_coast_usa_canada, [bos, clt, chi, mia, nyc, mco, yto, was]).
metal_region_places(west_coast_usa_canada, [las, lax, phx, sfo, sea, yvr]).
metal_region_places(tel_aviv, [tlv]).

%! metal_region_countries(?Region, ?Countries) is nondet.
metal_region_countries(australia, ['AU']).
metal_region_countries(new_zealand_or_papua_new_guinea, ['NZ', 'PG']).
metal_region_countries(northeast_asia_or_southeast_asia, ['CN', 'HK', 'JP', 'MO', 'MN', 'KP', 'KR', 'TW', 'BN', 'BT', 'KH', 'CC', 'ID', 'LA', 'MY', 'MM', 'PH', 'SG', 'TH', 'TL', 'VN']).
metal_region_countries(east_coast_usa_canada_or_europe, ['GR', 'TR', 'CY', 'FI', 'NO', 'SE', 'AT', 'BE', 'CZ', 'DE', 'DK', 'ES', 'FR', 'GB', 'IE', 'IT', 'NL', 'PT', 'CH']).
metal_region_countries(southeast_asia, ['BN', 'BT', 'KH', 'CC', 'ID', 'LA', 'MY', 'MM', 'PH', 'SG', 'TH', 'TL', 'VN']).
metal_region_countries(northeast_asia, ['CN', 'HK', 'JP', 'MO', 'MN', 'KP', 'KR', 'TW']).
metal_region_countries(europe, ['GR', 'TR', 'CY', 'FI', 'NO', 'SE', 'AT', 'BE', 'CZ', 'DE', 'DK', 'ES', 'FR', 'GB', 'IE', 'IT', 'NL', 'PT', 'CH']).
metal_region_countries(new_zealand, ['NZ']).
metal_region_countries(europe_or_northern_africa_or_southeast_asia, ['GR', 'TR', 'CY', 'FI', 'NO', 'SE', 'AT', 'BE', 'CZ', 'DE', 'DK', 'ES', 'FR', 'GB', 'IE', 'IT', 'NL', 'PT', 'CH', 'BF', 'DZ', 'BJ', 'CV', 'CF', 'TD', 'CD', 'DJ', 'EG', 'GQ', 'ER', 'ET', 'GM', 'GH', 'GN', 'GW', 'CI', 'KE', 'LR', 'LY', 'ML', 'MA', 'NE', 'NG', 'CM', 'ST', 'SN', 'SC', 'SL', 'SO', 'SS', 'SD', 'TG', 'TN', 'UG', 'BN', 'BT', 'KH', 'CC', 'ID', 'LA', 'MY', 'MM', 'PH', 'SG', 'TH', 'TL', 'VN']).
metal_region_countries(hong_kong, ['HK']).

%! metal_region_iso(?Region, ?IsoRegions) is nondet.
%  Regions the table names that are a state rather than a country or a city.
metal_region_iso(hawaii, ['US-HI']).

%! metal_region_label(?Region, ?Label) is nondet.
metal_region_label(adelaide_brisbane_gold_coast_melbourne_sydney, 'Adelaide, Brisbane, Gold Coast, Melbourne, Sydney').
metal_region_label(darwin_perth, 'Darwin, Perth').
metal_region_label(hawaii, 'Hawaii').
metal_region_label(delhi_or_bengaluru, 'Delhi or Bengaluru').
metal_region_label(johannesburg, 'Johannesburg').
metal_region_label(australia, 'Australia').
metal_region_label(new_zealand_or_papua_new_guinea, 'New Zealand or Papua New Guinea').
metal_region_label(northeast_asia_or_southeast_asia, 'Northeast Asia or Southeast Asia').
metal_region_label(santiago, 'Santiago').
metal_region_label(dallas, 'Dallas').
metal_region_label(west_coast_usa_canada_or_dubai, 'West Coast USA/Canada or Dubai').
metal_region_label(east_coast_usa_canada_or_europe, 'East Coast USA/Canada or Europe').
metal_region_label(southeast_asia, 'Southeast Asia').
metal_region_label(northeast_asia, 'Northeast Asia').
metal_region_label(dubai, 'Dubai').
metal_region_label(europe, 'Europe').
metal_region_label(new_zealand, 'New Zealand').
metal_region_label(east_coast_usa_canada, 'East Coast USA/Canada').
metal_region_label(west_coast_usa_canada, 'West Coast USA/Canada').
metal_region_label(europe_or_northern_africa_or_southeast_asia, 'Europe or Northern Africa or Southeast Asia').
metal_region_label(tel_aviv, 'Tel Aviv').
metal_region_label(hong_kong, 'Hong Kong').

%! metal_pair(?From, ?To, ?Category, ?Rates) is nondet.
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, discount_economy,
           [ rate(points, fixed(1000)),
             rate(status_credits, fixed(20)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, economy,
           [ rate(points, fixed(1375)),
             rate(status_credits, fixed(25)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, flexible_economy,
           [ rate(points, fixed(1750)),
             rate(status_credits, fixed(40)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, discount_premium_economy,
           [ rate(points, fixed(1750)),
             rate(status_credits, fixed(40)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, premium_economy,
           [ rate(points, fixed(2125)),
             rate(status_credits, fixed(45)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, flexible_premium_economy,
           [ rate(points, fixed(2300)),
             rate(status_credits, fixed(50)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, discount_business,
           [ rate(points, fixed(2500)),
             rate(status_credits, fixed(80)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, business,
           [ rate(points, fixed(2700)),
             rate(status_credits, fixed(85)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, flexible_business,
           [ rate(points, fixed(2875)),
             rate(status_credits, fixed(90)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, new_zealand_or_papua_new_guinea, first,
           [ rate(points, fixed(3250)),
             rate(status_credits, fixed(120)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, discount_economy,
           [ rate(points, fixed(2600)),
             rate(status_credits, fixed(30)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, economy,
           [ rate(points, fixed(3900)),
             rate(status_credits, fixed(40)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, flexible_economy,
           [ rate(points, fixed(5200)),
             rate(status_credits, fixed(60)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, discount_premium_economy,
           [ rate(points, fixed(5200)),
             rate(status_credits, fixed(60)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, premium_economy,
           [ rate(points, fixed(6500)),
             rate(status_credits, fixed(65)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, flexible_premium_economy,
           [ rate(points, fixed(7200)),
             rate(status_credits, fixed(70)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, discount_business,
           [ rate(points, fixed(7800)),
             rate(status_credits, fixed(120)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, business,
           [ rate(points, fixed(8450)),
             rate(status_credits, fixed(125)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, flexible_business,
           [ rate(points, fixed(9100)),
             rate(status_credits, fixed(135)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, northeast_asia_or_southeast_asia, first,
           [ rate(points, fixed(10400)),
             rate(status_credits, fixed(180)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, discount_economy,
           [ rate(points, fixed(3000)),
             rate(status_credits, fixed(35)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, economy,
           [ rate(points, fixed(4500)),
             rate(status_credits, fixed(45)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, flexible_economy,
           [ rate(points, fixed(6000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, discount_premium_economy,
           [ rate(points, fixed(6000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, premium_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(75)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, flexible_premium_economy,
           [ rate(points, fixed(8250)),
             rate(status_credits, fixed(80)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, discount_business,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(140)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, business,
           [ rate(points, fixed(9750)),
             rate(status_credits, fixed(150)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, flexible_business,
           [ rate(points, fixed(10500)),
             rate(status_credits, fixed(160)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, hawaii, first,
           [ rate(points, fixed(12000)),
             rate(status_credits, fixed(210)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, discount_economy,
           [ rate(points, fixed(3600)),
             rate(status_credits, fixed(40)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, economy,
           [ rate(points, fixed(5400)),
             rate(status_credits, fixed(50)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, flexible_economy,
           [ rate(points, fixed(7200)),
             rate(status_credits, fixed(75)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, discount_premium_economy,
           [ rate(points, fixed(7200)),
             rate(status_credits, fixed(75)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, premium_economy,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(80)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, flexible_premium_economy,
           [ rate(points, fixed(9800)),
             rate(status_credits, fixed(85)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, discount_business,
           [ rate(points, fixed(10700)),
             rate(status_credits, fixed(150)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, business,
           [ rate(points, fixed(11600)),
             rate(status_credits, fixed(155)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, flexible_business,
           [ rate(points, fixed(12500)),
             rate(status_credits, fixed(165)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, delhi_or_bengaluru, first,
           [ rate(points, fixed(14300)),
             rate(status_credits, fixed(230)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, discount_economy,
           [ rate(points, fixed(3750)),
             rate(status_credits, fixed(40)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, economy,
           [ rate(points, fixed(5625)),
             rate(status_credits, fixed(55)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, flexible_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(80)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, discount_premium_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(80)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, premium_economy,
           [ rate(points, fixed(9375)),
             rate(status_credits, fixed(85)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, flexible_premium_economy,
           [ rate(points, fixed(10300)),
             rate(status_credits, fixed(90)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, discount_business,
           [ rate(points, fixed(11250)),
             rate(status_credits, fixed(160)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, business,
           [ rate(points, fixed(12200)),
             rate(status_credits, fixed(165)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, flexible_business,
           [ rate(points, fixed(13125)),
             rate(status_credits, fixed(175)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, johannesburg, first,
           [ rate(points, fixed(15000)),
             rate(status_credits, fixed(240)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, discount_economy,
           [ rate(points, fixed(3750)),
             rate(status_credits, fixed(40)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, economy,
           [ rate(points, fixed(5625)),
             rate(status_credits, fixed(55)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, flexible_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(80)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, discount_premium_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(80)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, premium_economy,
           [ rate(points, fixed(9375)),
             rate(status_credits, fixed(85)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, flexible_premium_economy,
           [ rate(points, fixed(10300)),
             rate(status_credits, fixed(90)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, discount_business,
           [ rate(points, fixed(11250)),
             rate(status_credits, fixed(160)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, business,
           [ rate(points, fixed(12200)),
             rate(status_credits, fixed(165)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, flexible_business,
           [ rate(points, fixed(13125)),
             rate(status_credits, fixed(175)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, santiago, first,
           [ rate(points, fixed(15000)),
             rate(status_credits, fixed(240)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, discount_economy,
           [ rate(points, fixed(4900)),
             rate(status_credits, fixed(50)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, economy,
           [ rate(points, fixed(7350)),
             rate(status_credits, fixed(70)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, flexible_economy,
           [ rate(points, fixed(9800)),
             rate(status_credits, fixed(100)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, discount_premium_economy,
           [ rate(points, fixed(9800)),
             rate(status_credits, fixed(100)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, premium_economy,
           [ rate(points, fixed(12250)),
             rate(status_credits, fixed(105)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, flexible_premium_economy,
           [ rate(points, fixed(13400)),
             rate(status_credits, fixed(115)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, discount_business,
           [ rate(points, fixed(14700)),
             rate(status_credits, fixed(200)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, business,
           [ rate(points, fixed(15950)),
             rate(status_credits, fixed(210)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, flexible_business,
           [ rate(points, fixed(17200)),
             rate(status_credits, fixed(220)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, dallas, first,
           [ rate(points, fixed(19600)),
             rate(status_credits, fixed(300)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, discount_economy,
           [ rate(points, fixed(4500)),
             rate(status_credits, fixed(45)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, economy,
           [ rate(points, fixed(6750)),
             rate(status_credits, fixed(60)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, flexible_economy,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(90)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, discount_premium_economy,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(90)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, premium_economy,
           [ rate(points, fixed(11250)),
             rate(status_credits, fixed(100)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, flexible_premium_economy,
           [ rate(points, fixed(12400)),
             rate(status_credits, fixed(115)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, discount_business,
           [ rate(points, fixed(13500)),
             rate(status_credits, fixed(180)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, business,
           [ rate(points, fixed(14625)),
             rate(status_credits, fixed(190)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, flexible_business,
           [ rate(points, fixed(15750)),
             rate(status_credits, fixed(200)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, west_coast_usa_canada_or_dubai, first,
           [ rate(points, fixed(18000)),
             rate(status_credits, fixed(270)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, discount_economy,
           [ rate(points, fixed(6200)),
             rate(status_credits, fixed(70)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, economy,
           [ rate(points, fixed(9300)),
             rate(status_credits, fixed(95)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, flexible_economy,
           [ rate(points, fixed(12400)),
             rate(status_credits, fixed(140)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, discount_premium_economy,
           [ rate(points, fixed(12400)),
             rate(status_credits, fixed(140)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, premium_economy,
           [ rate(points, fixed(15500)),
             rate(status_credits, fixed(150)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, flexible_premium_economy,
           [ rate(points, fixed(17000)),
             rate(status_credits, fixed(165)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, discount_business,
           [ rate(points, fixed(18600)),
             rate(status_credits, fixed(280)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, business,
           [ rate(points, fixed(20150)),
             rate(status_credits, fixed(295)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, flexible_business,
           [ rate(points, fixed(21700)),
             rate(status_credits, fixed(310)) ]).
metal_pair(adelaide_brisbane_gold_coast_melbourne_sydney, east_coast_usa_canada_or_europe, first,
           [ rate(points, fixed(24800)),
             rate(status_credits, fixed(420)) ]).
metal_pair(darwin_perth, southeast_asia, discount_economy,
           [ rate(points, fixed(1450)),
             rate(status_credits, fixed(25)) ]).
metal_pair(darwin_perth, southeast_asia, economy,
           [ rate(points, fixed(2025)),
             rate(status_credits, fixed(25)) ]).
metal_pair(darwin_perth, southeast_asia, flexible_economy,
           [ rate(points, fixed(2700)),
             rate(status_credits, fixed(50)) ]).
metal_pair(darwin_perth, southeast_asia, discount_premium_economy,
           [ rate(points, fixed(2700)),
             rate(status_credits, fixed(50)) ]).
metal_pair(darwin_perth, southeast_asia, premium_economy,
           [ rate(points, fixed(3375)),
             rate(status_credits, fixed(50)) ]).
metal_pair(darwin_perth, southeast_asia, flexible_premium_economy,
           [ rate(points, fixed(3725)),
             rate(status_credits, fixed(50)) ]).
metal_pair(darwin_perth, southeast_asia, discount_business,
           [ rate(points, fixed(4050)),
             rate(status_credits, fixed(100)) ]).
metal_pair(darwin_perth, southeast_asia, business,
           [ rate(points, fixed(4400)),
             rate(status_credits, fixed(100)) ]).
metal_pair(darwin_perth, southeast_asia, flexible_business,
           [ rate(points, fixed(4725)),
             rate(status_credits, fixed(100)) ]).
metal_pair(darwin_perth, southeast_asia, first,
           [ rate(points, fixed(5400)),
             rate(status_credits, fixed(150)) ]).
metal_pair(darwin_perth, northeast_asia, discount_economy,
           [ rate(points, fixed(2500)),
             rate(status_credits, fixed(30)) ]).
metal_pair(darwin_perth, northeast_asia, economy,
           [ rate(points, fixed(3750)),
             rate(status_credits, fixed(40)) ]).
metal_pair(darwin_perth, northeast_asia, flexible_economy,
           [ rate(points, fixed(5000)),
             rate(status_credits, fixed(60)) ]).
metal_pair(darwin_perth, northeast_asia, discount_premium_economy,
           [ rate(points, fixed(5000)),
             rate(status_credits, fixed(60)) ]).
metal_pair(darwin_perth, northeast_asia, premium_economy,
           [ rate(points, fixed(6250)),
             rate(status_credits, fixed(65)) ]).
metal_pair(darwin_perth, northeast_asia, flexible_premium_economy,
           [ rate(points, fixed(6900)),
             rate(status_credits, fixed(70)) ]).
metal_pair(darwin_perth, northeast_asia, discount_business,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(120)) ]).
metal_pair(darwin_perth, northeast_asia, business,
           [ rate(points, fixed(8125)),
             rate(status_credits, fixed(125)) ]).
metal_pair(darwin_perth, northeast_asia, flexible_business,
           [ rate(points, fixed(8750)),
             rate(status_credits, fixed(135)) ]).
metal_pair(darwin_perth, northeast_asia, first,
           [ rate(points, fixed(10000)),
             rate(status_credits, fixed(180)) ]).
metal_pair(darwin_perth, dubai, discount_economy,
           [ rate(points, fixed(3000)),
             rate(status_credits, fixed(35)) ]).
metal_pair(darwin_perth, dubai, economy,
           [ rate(points, fixed(4500)),
             rate(status_credits, fixed(45)) ]).
metal_pair(darwin_perth, dubai, flexible_economy,
           [ rate(points, fixed(6000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(darwin_perth, dubai, discount_premium_economy,
           [ rate(points, fixed(6000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(darwin_perth, dubai, premium_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(75)) ]).
metal_pair(darwin_perth, dubai, flexible_premium_economy,
           [ rate(points, fixed(8250)),
             rate(status_credits, fixed(80)) ]).
metal_pair(darwin_perth, dubai, discount_business,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(140)) ]).
metal_pair(darwin_perth, dubai, business,
           [ rate(points, fixed(9750)),
             rate(status_credits, fixed(150)) ]).
metal_pair(darwin_perth, dubai, flexible_business,
           [ rate(points, fixed(10500)),
             rate(status_credits, fixed(160)) ]).
metal_pair(darwin_perth, dubai, first,
           [ rate(points, fixed(12000)),
             rate(status_credits, fixed(210)) ]).
metal_pair(darwin_perth, europe, discount_economy,
           [ rate(points, fixed(4700)),
             rate(status_credits, fixed(60)) ]).
metal_pair(darwin_perth, europe, economy,
           [ rate(points, fixed(7050)),
             rate(status_credits, fixed(80)) ]).
metal_pair(darwin_perth, europe, flexible_economy,
           [ rate(points, fixed(9400)),
             rate(status_credits, fixed(120)) ]).
metal_pair(darwin_perth, europe, discount_premium_economy,
           [ rate(points, fixed(9400)),
             rate(status_credits, fixed(120)) ]).
metal_pair(darwin_perth, europe, premium_economy,
           [ rate(points, fixed(11750)),
             rate(status_credits, fixed(130)) ]).
metal_pair(darwin_perth, europe, flexible_premium_economy,
           [ rate(points, fixed(12850)),
             rate(status_credits, fixed(140)) ]).
metal_pair(darwin_perth, europe, discount_business,
           [ rate(points, fixed(14100)),
             rate(status_credits, fixed(240)) ]).
metal_pair(darwin_perth, europe, business,
           [ rate(points, fixed(15300)),
             rate(status_credits, fixed(255)) ]).
metal_pair(darwin_perth, europe, flexible_business,
           [ rate(points, fixed(16450)),
             rate(status_credits, fixed(270)) ]).
metal_pair(darwin_perth, europe, first,
           [ rate(points, fixed(18800)),
             rate(status_credits, fixed(360)) ]).
metal_pair(darwin_perth, johannesburg, discount_economy,
           [ rate(points, fixed(3000)),
             rate(status_credits, fixed(35)) ]).
metal_pair(darwin_perth, johannesburg, economy,
           [ rate(points, fixed(4500)),
             rate(status_credits, fixed(45)) ]).
metal_pair(darwin_perth, johannesburg, flexible_economy,
           [ rate(points, fixed(6000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(darwin_perth, johannesburg, discount_premium_economy,
           [ rate(points, fixed(6000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(darwin_perth, johannesburg, premium_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(70)) ]).
metal_pair(darwin_perth, johannesburg, flexible_premium_economy,
           [ rate(points, fixed(8250)),
             rate(status_credits, fixed(80)) ]).
metal_pair(darwin_perth, johannesburg, discount_business,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(140)) ]).
metal_pair(darwin_perth, johannesburg, business,
           [ rate(points, fixed(9750)),
             rate(status_credits, fixed(150)) ]).
metal_pair(darwin_perth, johannesburg, flexible_business,
           [ rate(points, fixed(10500)),
             rate(status_credits, fixed(160)) ]).
metal_pair(darwin_perth, johannesburg, first,
           [ rate(points, fixed(12000)),
             rate(status_credits, fixed(210)) ]).
metal_pair(new_zealand, dallas, discount_economy,
           [ rate(points, fixed(4250)),
             rate(status_credits, fixed(45)) ]).
metal_pair(new_zealand, dallas, economy,
           [ rate(points, fixed(6375)),
             rate(status_credits, fixed(60)) ]).
metal_pair(new_zealand, dallas, flexible_economy,
           [ rate(points, fixed(8500)),
             rate(status_credits, fixed(85)) ]).
metal_pair(new_zealand, dallas, discount_premium_economy,
           [ rate(points, fixed(8500)),
             rate(status_credits, fixed(85)) ]).
metal_pair(new_zealand, dallas, premium_economy,
           [ rate(points, fixed(10625)),
             rate(status_credits, fixed(90)) ]).
metal_pair(new_zealand, dallas, flexible_premium_economy,
           [ rate(points, fixed(11625)),
             rate(status_credits, fixed(100)) ]).
metal_pair(new_zealand, dallas, discount_business,
           [ rate(points, fixed(12750)),
             rate(status_credits, fixed(170)) ]).
metal_pair(new_zealand, dallas, business,
           [ rate(points, fixed(13835)),
             rate(status_credits, fixed(180)) ]).
metal_pair(new_zealand, dallas, flexible_business,
           [ rate(points, fixed(14920)),
             rate(status_credits, fixed(190)) ]).
metal_pair(new_zealand, dallas, first,
           [ rate(points, fixed(17000)),
             rate(status_credits, fixed(260)) ]).
metal_pair(new_zealand, santiago, discount_economy,
           [ rate(points, fixed(2900)),
             rate(status_credits, fixed(35)) ]).
metal_pair(new_zealand, santiago, economy,
           [ rate(points, fixed(4350)),
             rate(status_credits, fixed(45)) ]).
metal_pair(new_zealand, santiago, flexible_economy,
           [ rate(points, fixed(5800)),
             rate(status_credits, fixed(70)) ]).
metal_pair(new_zealand, santiago, discount_premium_economy,
           [ rate(points, fixed(5800)),
             rate(status_credits, fixed(70)) ]).
metal_pair(new_zealand, santiago, premium_economy,
           [ rate(points, fixed(7250)),
             rate(status_credits, fixed(70)) ]).
metal_pair(new_zealand, santiago, flexible_premium_economy,
           [ rate(points, fixed(8000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(new_zealand, santiago, discount_business,
           [ rate(points, fixed(8700)),
             rate(status_credits, fixed(140)) ]).
metal_pair(new_zealand, santiago, business,
           [ rate(points, fixed(9450)),
             rate(status_credits, fixed(150)) ]).
metal_pair(new_zealand, santiago, flexible_business,
           [ rate(points, fixed(10150)),
             rate(status_credits, fixed(160)) ]).
metal_pair(new_zealand, santiago, first,
           [ rate(points, fixed(11600)),
             rate(status_credits, fixed(210)) ]).
metal_pair(new_zealand, east_coast_usa_canada, discount_economy,
           [ rate(points, fixed(5200)),
             rate(status_credits, fixed(50)) ]).
metal_pair(new_zealand, east_coast_usa_canada, economy,
           [ rate(points, fixed(7925)),
             rate(status_credits, fixed(70)) ]).
metal_pair(new_zealand, east_coast_usa_canada, flexible_economy,
           [ rate(points, fixed(10650)),
             rate(status_credits, fixed(100)) ]).
metal_pair(new_zealand, east_coast_usa_canada, discount_premium_economy,
           [ rate(points, fixed(10650)),
             rate(status_credits, fixed(100)) ]).
metal_pair(new_zealand, east_coast_usa_canada, premium_economy,
           [ rate(points, fixed(13375)),
             rate(status_credits, fixed(105)) ]).
metal_pair(new_zealand, east_coast_usa_canada, flexible_premium_economy,
           [ rate(points, fixed(14700)),
             rate(status_credits, fixed(110)) ]).
metal_pair(new_zealand, east_coast_usa_canada, discount_business,
           [ rate(points, fixed(16100)),
             rate(status_credits, fixed(200)) ]).
metal_pair(new_zealand, east_coast_usa_canada, business,
           [ rate(points, fixed(17450)),
             rate(status_credits, fixed(210)) ]).
metal_pair(new_zealand, east_coast_usa_canada, flexible_business,
           [ rate(points, fixed(18825)),
             rate(status_credits, fixed(220)) ]).
metal_pair(new_zealand, east_coast_usa_canada, first,
           [ rate(points, fixed(21550)),
             rate(status_credits, fixed(300)) ]).
metal_pair(dallas, east_coast_usa_canada, discount_economy,
           [ rate(points, fixed(1300)),
             rate(status_credits, fixed(20)) ]).
metal_pair(dallas, east_coast_usa_canada, economy,
           [ rate(points, fixed(1950)),
             rate(status_credits, fixed(25)) ]).
metal_pair(dallas, east_coast_usa_canada, flexible_economy,
           [ rate(points, fixed(2600)),
             rate(status_credits, fixed(40)) ]).
metal_pair(dallas, east_coast_usa_canada, discount_premium_economy,
           [ rate(points, fixed(2600)),
             rate(status_credits, fixed(40)) ]).
metal_pair(dallas, east_coast_usa_canada, premium_economy,
           [ rate(points, fixed(3250)),
             rate(status_credits, fixed(45)) ]).
metal_pair(dallas, east_coast_usa_canada, flexible_premium_economy,
           [ rate(points, fixed(3600)),
             rate(status_credits, fixed(50)) ]).
metal_pair(dallas, east_coast_usa_canada, discount_business,
           [ rate(points, fixed(3900)),
             rate(status_credits, fixed(80)) ]).
metal_pair(dallas, east_coast_usa_canada, business,
           [ rate(points, fixed(4200)),
             rate(status_credits, fixed(85)) ]).
metal_pair(dallas, east_coast_usa_canada, flexible_business,
           [ rate(points, fixed(4500)),
             rate(status_credits, fixed(90)) ]).
metal_pair(dallas, east_coast_usa_canada, first,
           [ rate(points, fixed(5200)),
             rate(status_credits, fixed(120)) ]).
metal_pair(dallas, west_coast_usa_canada, discount_economy,
           [ rate(points, fixed(1700)),
             rate(status_credits, fixed(25)) ]).
metal_pair(dallas, west_coast_usa_canada, economy,
           [ rate(points, fixed(2550)),
             rate(status_credits, fixed(35)) ]).
metal_pair(dallas, west_coast_usa_canada, flexible_economy,
           [ rate(points, fixed(3400)),
             rate(status_credits, fixed(50)) ]).
metal_pair(dallas, west_coast_usa_canada, discount_premium_economy,
           [ rate(points, fixed(3400)),
             rate(status_credits, fixed(50)) ]).
metal_pair(dallas, west_coast_usa_canada, premium_economy,
           [ rate(points, fixed(4250)),
             rate(status_credits, fixed(55)) ]).
metal_pair(dallas, west_coast_usa_canada, flexible_premium_economy,
           [ rate(points, fixed(4600)),
             rate(status_credits, fixed(60)) ]).
metal_pair(dallas, west_coast_usa_canada, discount_business,
           [ rate(points, fixed(5100)),
             rate(status_credits, fixed(100)) ]).
metal_pair(dallas, west_coast_usa_canada, business,
           [ rate(points, fixed(5525)),
             rate(status_credits, fixed(105)) ]).
metal_pair(dallas, west_coast_usa_canada, flexible_business,
           [ rate(points, fixed(5950)),
             rate(status_credits, fixed(110)) ]).
metal_pair(dallas, west_coast_usa_canada, first,
           [ rate(points, fixed(6800)),
             rate(status_credits, fixed(150)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, discount_economy,
           [ rate(points, fixed(1700)),
             rate(status_credits, fixed(25)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, economy,
           [ rate(points, fixed(2550)),
             rate(status_credits, fixed(35)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, flexible_economy,
           [ rate(points, fixed(3400)),
             rate(status_credits, fixed(50)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, discount_premium_economy,
           [ rate(points, fixed(3400)),
             rate(status_credits, fixed(50)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, premium_economy,
           [ rate(points, fixed(4250)),
             rate(status_credits, fixed(55)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, flexible_premium_economy,
           [ rate(points, fixed(4600)),
             rate(status_credits, fixed(60)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, discount_business,
           [ rate(points, fixed(5100)),
             rate(status_credits, fixed(100)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, business,
           [ rate(points, fixed(5525)),
             rate(status_credits, fixed(105)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, flexible_business,
           [ rate(points, fixed(5950)),
             rate(status_credits, fixed(110)) ]).
metal_pair(east_coast_usa_canada, west_coast_usa_canada, first,
           [ rate(points, fixed(6800)),
             rate(status_credits, fixed(150)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, discount_economy,
           [ rate(points, fixed(1700)),
             rate(status_credits, fixed(25)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, economy,
           [ rate(points, fixed(2550)),
             rate(status_credits, fixed(35)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, flexible_economy,
           [ rate(points, fixed(3400)),
             rate(status_credits, fixed(50)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, discount_premium_economy,
           [ rate(points, fixed(3400)),
             rate(status_credits, fixed(50)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, premium_economy,
           [ rate(points, fixed(4250)),
             rate(status_credits, fixed(55)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, flexible_premium_economy,
           [ rate(points, fixed(4600)),
             rate(status_credits, fixed(60)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, discount_business,
           [ rate(points, fixed(5100)),
             rate(status_credits, fixed(100)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, business,
           [ rate(points, fixed(5525)),
             rate(status_credits, fixed(105)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, flexible_business,
           [ rate(points, fixed(5950)),
             rate(status_credits, fixed(110)) ]).
metal_pair(dubai, europe_or_northern_africa_or_southeast_asia, first,
           [ rate(points, fixed(6800)),
             rate(status_credits, fixed(150)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, discount_economy,
           [ rate(points, fixed(3600)),
             rate(status_credits, fixed(40)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, economy,
           [ rate(points, fixed(5400)),
             rate(status_credits, fixed(55)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, flexible_economy,
           [ rate(points, fixed(7200)),
             rate(status_credits, fixed(80)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, discount_premium_economy,
           [ rate(points, fixed(7200)),
             rate(status_credits, fixed(80)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, premium_economy,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(85)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, flexible_premium_economy,
           [ rate(points, fixed(9800)),
             rate(status_credits, fixed(90)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, discount_business,
           [ rate(points, fixed(10800)),
             rate(status_credits, fixed(160)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, business,
           [ rate(points, fixed(11700)),
             rate(status_credits, fixed(165)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, flexible_business,
           [ rate(points, fixed(12600)),
             rate(status_credits, fixed(175)) ]).
metal_pair(europe, northeast_asia_or_southeast_asia, first,
           [ rate(points, fixed(14400)),
             rate(status_credits, fixed(240)) ]).
metal_pair(tel_aviv, hong_kong, discount_economy,
           [ rate(points, fixed(3500)),
             rate(status_credits, fixed(30)) ]).
metal_pair(tel_aviv, hong_kong, economy,
           [ rate(points, fixed(5500)),
             rate(status_credits, fixed(40)) ]).
metal_pair(tel_aviv, hong_kong, flexible_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(60)) ]).
metal_pair(tel_aviv, hong_kong, discount_premium_economy,
           [ rate(points, fixed(7500)),
             rate(status_credits, fixed(60)) ]).
metal_pair(tel_aviv, hong_kong, premium_economy,
           [ rate(points, fixed(9000)),
             rate(status_credits, fixed(70)) ]).
metal_pair(tel_aviv, hong_kong, flexible_premium_economy,
           [ rate(points, fixed(10000)),
             rate(status_credits, fixed(80)) ]).
metal_pair(tel_aviv, hong_kong, discount_business,
           [ rate(points, fixed(12000)),
             rate(status_credits, fixed(120)) ]).
metal_pair(tel_aviv, hong_kong, business,
           [ rate(points, fixed(13000)),
             rate(status_credits, fixed(130)) ]).
metal_pair(tel_aviv, hong_kong, flexible_business,
           [ rate(points, fixed(14000)),
             rate(status_credits, fixed(140)) ]).
metal_pair(tel_aviv, hong_kong, first,
           [ rate(points, fixed(16000)),
             rate(status_credits, fixed(180)) ]).

%! metal_domestic(?Band, ?Low, ?High) is nondet.
%  Both endpoints in Australia, banded on distance.
metal_domestic(band(1, 750), 1, 750).
metal_domestic(band(751, 1500), 751, 1500).
metal_domestic(band(1501, inf), 1501, inf).

%! metal_domestic_label(?Band, ?Label) is nondet.
metal_domestic_label(band(1, 750), 'Domestic Australia short, 0 to 750 miles').
metal_domestic_label(band(751, 1500), 'Domestic Australia medium, 751 to 1,500 miles').
metal_domestic_label(band(1501, inf), 'Domestic Australia long, 1,501 miles and over').

%! metal_domestic_accrual(?Band, ?Category, ?Rates) is nondet.
metal_domestic_accrual(band(1, 750), discount_economy,
                       [ rate(points, fixed(500)),
                         rate(status_credits, fixed(10)) ]).
metal_domestic_accrual(band(1, 750), economy,
                       [ rate(points, fixed(500)),
                         rate(status_credits, fixed(10)) ]).
metal_domestic_accrual(band(1, 750), flexible_economy,
                       [ rate(points, fixed(750)),
                         rate(status_credits, fixed(20)) ]).
metal_domestic_accrual(band(1, 750), discount_premium_economy,
                       [ rate(points, fixed(750)),
                         rate(status_credits, fixed(20)) ]).
metal_domestic_accrual(band(1, 750), premium_economy,
                       [ rate(points, fixed(1125)),
                         rate(status_credits, fixed(20)) ]).
metal_domestic_accrual(band(1, 750), flexible_premium_economy,
                       [ rate(points, fixed(1250)),
                         rate(status_credits, fixed(20)) ]).
metal_domestic_accrual(band(1, 750), discount_business,
                       [ rate(points, none),
                         rate(status_credits, none) ]).
metal_domestic_accrual(band(1, 750), business,
                       [ rate(points, fixed(1750)),
                         rate(status_credits, fixed(40)) ]).
metal_domestic_accrual(band(1, 750), flexible_business,
                       [ rate(points, fixed(2000)),
                         rate(status_credits, fixed(45)) ]).
metal_domestic_accrual(band(1, 750), first,
                       [ rate(points, fixed(2250)),
                         rate(status_credits, fixed(60)) ]).
metal_domestic_accrual(band(751, 1500), discount_economy,
                       [ rate(points, fixed(875)),
                         rate(status_credits, fixed(15)) ]).
metal_domestic_accrual(band(751, 1500), economy,
                       [ rate(points, fixed(875)),
                         rate(status_credits, fixed(15)) ]).
metal_domestic_accrual(band(751, 1500), flexible_economy,
                       [ rate(points, fixed(1375)),
                         rate(status_credits, fixed(30)) ]).
metal_domestic_accrual(band(751, 1500), discount_premium_economy,
                       [ rate(points, fixed(1375)),
                         rate(status_credits, fixed(30)) ]).
metal_domestic_accrual(band(751, 1500), premium_economy,
                       [ rate(points, fixed(1750)),
                         rate(status_credits, fixed(30)) ]).
metal_domestic_accrual(band(751, 1500), flexible_premium_economy,
                       [ rate(points, fixed(1940)),
                         rate(status_credits, fixed(30)) ]).
metal_domestic_accrual(band(751, 1500), discount_business,
                       [ rate(points, none),
                         rate(status_credits, none) ]).
metal_domestic_accrual(band(751, 1500), business,
                       [ rate(points, fixed(2625)),
                         rate(status_credits, fixed(60)) ]).
metal_domestic_accrual(band(751, 1500), flexible_business,
                       [ rate(points, fixed(2940)),
                         rate(status_credits, fixed(70)) ]).
metal_domestic_accrual(band(751, 1500), first,
                       [ rate(points, fixed(3500)),
                         rate(status_credits, fixed(90)) ]).
metal_domestic_accrual(band(1501, inf), discount_economy,
                       [ rate(points, fixed(1815)),
                         rate(status_credits, fixed(20)) ]).
metal_domestic_accrual(band(1501, inf), economy,
                       [ rate(points, fixed(1815)),
                         rate(status_credits, fixed(20)) ]).
metal_domestic_accrual(band(1501, inf), flexible_economy,
                       [ rate(points, fixed(2750)),
                         rate(status_credits, fixed(40)) ]).
metal_domestic_accrual(band(1501, inf), discount_premium_economy,
                       [ rate(points, fixed(2750)),
                         rate(status_credits, fixed(40)) ]).
metal_domestic_accrual(band(1501, inf), premium_economy,
                       [ rate(points, fixed(3375)),
                         rate(status_credits, fixed(40)) ]).
metal_domestic_accrual(band(1501, inf), flexible_premium_economy,
                       [ rate(points, fixed(3625)),
                         rate(status_credits, fixed(40)) ]).
metal_domestic_accrual(band(1501, inf), discount_business,
                       [ rate(points, none),
                         rate(status_credits, none) ]).
metal_domestic_accrual(band(1501, inf), business,
                       [ rate(points, fixed(4125)),
                         rate(status_credits, fixed(80)) ]).
metal_domestic_accrual(band(1501, inf), flexible_business,
                       [ rate(points, fixed(4500)),
                         rate(status_credits, fixed(95)) ]).
metal_domestic_accrual(band(1501, inf), first,
                       [ rate(points, fixed(5500)),
                         rate(status_credits, fixed(120)) ]).

%! metal_band(?Band, ?Low, ?High) is nondet.
metal_band(band(1, 750), 1, 750).
metal_band(band(751, 1500), 751, 1500).
metal_band(band(1501, 2500), 1501, 2500).
metal_band(band(2501, 3500), 2501, 3500).
metal_band(band(3501, 5000), 3501, 5000).
metal_band(band(5001, 6500), 5001, 6500).
metal_band(band(6501, inf), 6501, inf).

%! metal_band_label(?Band, ?Label) is nondet.
metal_band_label(band(1, 750), 'up to 750 miles').
metal_band_label(band(751, 1500), '751 to 1,500 miles').
metal_band_label(band(1501, 2500), '1,501 to 2,500 miles').
metal_band_label(band(2501, 3500), '2,501 to 3,500 miles').
metal_band_label(band(3501, 5000), '3,501 to 5,000 miles').
metal_band_label(band(5001, 6500), '5,001 to 6,500 miles').
metal_band_label(band(6501, inf), '6,501 miles and over').

%! metal_band_accrual(?Band, ?Category, ?Rates) is nondet.
metal_band_accrual(band(1, 750), discount_economy,
                   [ rate(points, fixed(300)),
                     rate(status_credits, fixed(10)) ]).
metal_band_accrual(band(1, 750), economy,
                   [ rate(points, fixed(450)),
                     rate(status_credits, fixed(10)) ]).
metal_band_accrual(band(1, 750), flexible_economy,
                   [ rate(points, fixed(650)),
                     rate(status_credits, fixed(20)) ]).
metal_band_accrual(band(1, 750), discount_premium_economy,
                   [ rate(points, fixed(650)),
                     rate(status_credits, fixed(20)) ]).
metal_band_accrual(band(1, 750), premium_economy,
                   [ rate(points, fixed(750)),
                     rate(status_credits, fixed(20)) ]).
metal_band_accrual(band(1, 750), flexible_premium_economy,
                   [ rate(points, fixed(850)),
                     rate(status_credits, fixed(20)) ]).
metal_band_accrual(band(1, 750), discount_business,
                   [ rate(points, fixed(900)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(1, 750), business,
                   [ rate(points, fixed(975)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(1, 750), flexible_business,
                   [ rate(points, fixed(1050)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(1, 750), first,
                   [ rate(points, fixed(1200)),
                     rate(status_credits, fixed(60)) ]).
metal_band_accrual(band(751, 1500), discount_economy,
                   [ rate(points, fixed(550)),
                     rate(status_credits, fixed(15)) ]).
metal_band_accrual(band(751, 1500), economy,
                   [ rate(points, fixed(850)),
                     rate(status_credits, fixed(15)) ]).
metal_band_accrual(band(751, 1500), flexible_economy,
                   [ rate(points, fixed(1100)),
                     rate(status_credits, fixed(30)) ]).
metal_band_accrual(band(751, 1500), discount_premium_economy,
                   [ rate(points, fixed(1100)),
                     rate(status_credits, fixed(30)) ]).
metal_band_accrual(band(751, 1500), premium_economy,
                   [ rate(points, fixed(1350)),
                     rate(status_credits, fixed(30)) ]).
metal_band_accrual(band(751, 1500), flexible_premium_economy,
                   [ rate(points, fixed(1500)),
                     rate(status_credits, fixed(30)) ]).
metal_band_accrual(band(751, 1500), discount_business,
                   [ rate(points, fixed(1650)),
                     rate(status_credits, fixed(60)) ]).
metal_band_accrual(band(751, 1500), business,
                   [ rate(points, fixed(1800)),
                     rate(status_credits, fixed(65)) ]).
metal_band_accrual(band(751, 1500), flexible_business,
                   [ rate(points, fixed(1950)),
                     rate(status_credits, fixed(70)) ]).
metal_band_accrual(band(751, 1500), first,
                   [ rate(points, fixed(2200)),
                     rate(status_credits, fixed(90)) ]).
metal_band_accrual(band(1501, 2500), discount_economy,
                   [ rate(points, fixed(1100)),
                     rate(status_credits, fixed(20)) ]).
metal_band_accrual(band(1501, 2500), economy,
                   [ rate(points, fixed(1650)),
                     rate(status_credits, fixed(25)) ]).
metal_band_accrual(band(1501, 2500), flexible_economy,
                   [ rate(points, fixed(2200)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(1501, 2500), discount_premium_economy,
                   [ rate(points, fixed(2200)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(1501, 2500), premium_economy,
                   [ rate(points, fixed(2750)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(1501, 2500), flexible_premium_economy,
                   [ rate(points, fixed(3050)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(1501, 2500), discount_business,
                   [ rate(points, fixed(3300)),
                     rate(status_credits, fixed(80)) ]).
metal_band_accrual(band(1501, 2500), business,
                   [ rate(points, fixed(3575)),
                     rate(status_credits, fixed(85)) ]).
metal_band_accrual(band(1501, 2500), flexible_business,
                   [ rate(points, fixed(3850)),
                     rate(status_credits, fixed(95)) ]).
metal_band_accrual(band(1501, 2500), first,
                   [ rate(points, fixed(4400)),
                     rate(status_credits, fixed(120)) ]).
metal_band_accrual(band(2501, 3500), discount_economy,
                   [ rate(points, fixed(1600)),
                     rate(status_credits, fixed(25)) ]).
metal_band_accrual(band(2501, 3500), economy,
                   [ rate(points, fixed(2400)),
                     rate(status_credits, fixed(35)) ]).
metal_band_accrual(band(2501, 3500), flexible_economy,
                   [ rate(points, fixed(3200)),
                     rate(status_credits, fixed(50)) ]).
metal_band_accrual(band(2501, 3500), discount_premium_economy,
                   [ rate(points, fixed(3200)),
                     rate(status_credits, fixed(50)) ]).
metal_band_accrual(band(2501, 3500), premium_economy,
                   [ rate(points, fixed(4000)),
                     rate(status_credits, fixed(50)) ]).
metal_band_accrual(band(2501, 3500), flexible_premium_economy,
                   [ rate(points, fixed(4400)),
                     rate(status_credits, fixed(50)) ]).
metal_band_accrual(band(2501, 3500), discount_business,
                   [ rate(points, fixed(4800)),
                     rate(status_credits, fixed(100)) ]).
metal_band_accrual(band(2501, 3500), business,
                   [ rate(points, fixed(5200)),
                     rate(status_credits, fixed(105)) ]).
metal_band_accrual(band(2501, 3500), flexible_business,
                   [ rate(points, fixed(5600)),
                     rate(status_credits, fixed(115)) ]).
metal_band_accrual(band(2501, 3500), first,
                   [ rate(points, fixed(6400)),
                     rate(status_credits, fixed(150)) ]).
metal_band_accrual(band(3501, 5000), discount_economy,
                   [ rate(points, fixed(2450)),
                     rate(status_credits, fixed(30)) ]).
metal_band_accrual(band(3501, 5000), economy,
                   [ rate(points, fixed(3700)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(3501, 5000), flexible_economy,
                   [ rate(points, fixed(4900)),
                     rate(status_credits, fixed(60)) ]).
metal_band_accrual(band(3501, 5000), discount_premium_economy,
                   [ rate(points, fixed(4900)),
                     rate(status_credits, fixed(60)) ]).
metal_band_accrual(band(3501, 5000), premium_economy,
                   [ rate(points, fixed(6150)),
                     rate(status_credits, fixed(60)) ]).
metal_band_accrual(band(3501, 5000), flexible_premium_economy,
                   [ rate(points, fixed(6750)),
                     rate(status_credits, fixed(60)) ]).
metal_band_accrual(band(3501, 5000), discount_business,
                   [ rate(points, fixed(7350)),
                     rate(status_credits, fixed(120)) ]).
metal_band_accrual(band(3501, 5000), business,
                   [ rate(points, fixed(7975)),
                     rate(status_credits, fixed(130)) ]).
metal_band_accrual(band(3501, 5000), flexible_business,
                   [ rate(points, fixed(8600)),
                     rate(status_credits, fixed(140)) ]).
metal_band_accrual(band(3501, 5000), first,
                   [ rate(points, fixed(9800)),
                     rate(status_credits, fixed(180)) ]).
metal_band_accrual(band(5001, 6500), discount_economy,
                   [ rate(points, fixed(2900)),
                     rate(status_credits, fixed(35)) ]).
metal_band_accrual(band(5001, 6500), economy,
                   [ rate(points, fixed(4350)),
                     rate(status_credits, fixed(45)) ]).
metal_band_accrual(band(5001, 6500), flexible_economy,
                   [ rate(points, fixed(5800)),
                     rate(status_credits, fixed(70)) ]).
metal_band_accrual(band(5001, 6500), discount_premium_economy,
                   [ rate(points, fixed(5800)),
                     rate(status_credits, fixed(70)) ]).
metal_band_accrual(band(5001, 6500), premium_economy,
                   [ rate(points, fixed(7250)),
                     rate(status_credits, fixed(70)) ]).
metal_band_accrual(band(5001, 6500), flexible_premium_economy,
                   [ rate(points, fixed(8000)),
                     rate(status_credits, fixed(70)) ]).
metal_band_accrual(band(5001, 6500), discount_business,
                   [ rate(points, fixed(8700)),
                     rate(status_credits, fixed(140)) ]).
metal_band_accrual(band(5001, 6500), business,
                   [ rate(points, fixed(9425)),
                     rate(status_credits, fixed(150)) ]).
metal_band_accrual(band(5001, 6500), flexible_business,
                   [ rate(points, fixed(10150)),
                     rate(status_credits, fixed(160)) ]).
metal_band_accrual(band(5001, 6500), first,
                   [ rate(points, fixed(11600)),
                     rate(status_credits, fixed(210)) ]).
metal_band_accrual(band(6501, inf), discount_economy,
                   [ rate(points, fixed(4000)),
                     rate(status_credits, fixed(40)) ]).
metal_band_accrual(band(6501, inf), economy,
                   [ rate(points, fixed(6000)),
                     rate(status_credits, fixed(55)) ]).
metal_band_accrual(band(6501, inf), flexible_economy,
                   [ rate(points, fixed(8000)),
                     rate(status_credits, fixed(80)) ]).
metal_band_accrual(band(6501, inf), discount_premium_economy,
                   [ rate(points, fixed(8000)),
                     rate(status_credits, fixed(80)) ]).
metal_band_accrual(band(6501, inf), premium_economy,
                   [ rate(points, fixed(10000)),
                     rate(status_credits, fixed(80)) ]).
metal_band_accrual(band(6501, inf), flexible_premium_economy,
                   [ rate(points, fixed(11000)),
                     rate(status_credits, fixed(80)) ]).
metal_band_accrual(band(6501, inf), discount_business,
                   [ rate(points, fixed(12000)),
                     rate(status_credits, fixed(160)) ]).
metal_band_accrual(band(6501, inf), business,
                   [ rate(points, fixed(13000)),
                     rate(status_credits, fixed(170)) ]).
metal_band_accrual(band(6501, inf), flexible_business,
                   [ rate(points, fixed(14000)),
                     rate(status_credits, fixed(180)) ]).
metal_band_accrual(band(6501, inf), first,
                   [ rate(points, fixed(16000)),
                     rate(status_credits, fixed(240)) ]).

%! metal_edges(-Edges) is det.
metal_edges([750, 1500, 2500, 3500, 5000, 6500]).
