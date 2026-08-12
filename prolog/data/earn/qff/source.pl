:- module(qff_source, [qff_source/2, qff_note/1]).

/** <module> Where the Qantas tables were read, and when. GENERATED -- do not edit.

    The earning tables carry no version and no clause numbers, so this is the
    whole of the provenance a number can cite. It is printed with every earn
    report and served from /api/programs. See PLANS/05-loyalty-earning.md.
*/

%! qff_source(?Table, ?Source) is nondet.
qff_source(categories, source('https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/categories', '2026-08-11')).
qff_source(bands,      source('https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/partner-airlines', '2026-08-11')).

%! qff_note(?Note) is nondet.
%  What a reader of these numbers has to be told alongside them.
qff_note('These figures are an estimate. The airline\'s own calculator is authoritative.').
qff_note('Base rate for a one-way sector, before any tier bonus.').
qff_note('AY categories are the rows in force from 2026-02-01; earlier rows are not carried.').
qff_note('MH categories are the rows in force from 2025-09-01; earlier rows are not carried.').
qff_note('WY categories are the rows in force from 2025-09-30; earlier rows are not carried.').
