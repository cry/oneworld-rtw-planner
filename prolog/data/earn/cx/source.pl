:- module(cx_source, [cx_source/2, cx_note/1]).

/** <module> Where the Asia Miles tables were read, and when. GENERATED -- do not edit.
*/

%! cx_source(?Table, ?Source) is nondet.
cx_source(earning, source('https://api.cathaypacific.com/mpo-miles-services/v3/miles-calculator', '2026-08-11')).

%! cx_note(?Note) is nondet.
cx_note('These figures are an estimate. The airline\'s own calculator is authoritative.').
cx_note('Cathay-marketed sectors are priced off the fixed table effective from 2025-08-20; partner-marketed sectors earn Asia Miles as a percentage of the distance flown.').
cx_note('Base rate for a one-way sector. No tier table is loaded, so no tier bonus is applied.').
cx_note('Partner rates were sampled rather than enumerated, so a band nobody sampled is reported undecided rather than as a number. Cathay\'s own table was enumerated in full.').
