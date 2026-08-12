:- module(cx_source, [cx_source/2, cx_note/1]).

/** <module> Where the Cathay tables were read, and when. GENERATED -- do not edit.
*/

%! cx_source(?Table, ?Source) is nondet.
cx_source(marketed, source('https://www.cathaypacific.com/cx/en_US/membership/news-and-updates/Changes-to-your-Status-Points-and-Asia-Miles-earnings-on-flights.html', '2026-08-11')).

%! cx_note(?Note) is nondet.
cx_note('These figures are an estimate. The airline\'s own calculator is authoritative.').
cx_note('Cathay-marketed flights only, at the rates effective from 2025-08-20.').
cx_note('Base rate for a one-way sector. No tier table is loaded, so no tier bonus is applied.').
