:- module(qff_source, [qff_source/2, qff_note/1]).

/** <module> Where the Qantas tables were read, and when. GENERATED -- do not edit.

    The earning tables carry no version and no clause numbers, so this is the
    whole of the provenance a number can cite. It is printed with every earn
    report and served from /api/programs. See PLANS/05-loyalty-earning.md.
*/

%! qff_source(?Table, ?Source) is nondet.
qff_source(categories, source('https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/categories', '2026-08-11')).
qff_source(bands,      source('https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/partner-airlines', '2026-08-11')).
qff_source(regions,    source('https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/partner-airlines', '2026-08-11')).
qff_source(region_definitions, source('https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/region-definitions', '2026-08-11')).
qff_source(tiers,      source('https://www.qantas.com/au/en/frequent-flyer/discover-and-earn/earning-points.html', '2026-08-11')).

%! qff_note(?Note) is nondet.
%  What a reader of these numbers has to be told alongside them.
qff_note('These figures are an estimate. The airline\'s own calculator is authoritative.').
qff_note('A tier bonus applies to Qantas Points on Qantas-marketed sectors only; every other figure is the base rate.').
qff_note('Transcribed by hand from the published tier bonus table; unlike the other captures here it was not read out of the page, which the scraper could not reach.').
qff_note('AY categories are the rows in force from 2026-02-01; earlier rows are not carried.').
qff_note('MH categories are the rows in force from 2025-09-01; earlier rows are not carried.').
qff_note('WY categories are the rows in force from 2025-09-30; earlier rows are not carried.').
