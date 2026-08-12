:- module(cx_airlines,
          [ cx_airline/3,
            cx_zero_points/1,
            cx_coverage/4
          ]).

/** <module> The 26 airlines Asia Miles publishes earning for. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/asia-miles-lookup.csv and asia-miles-rules.csv,
    snapshot 2026-08-11 of
    https://api.cathaypacific.com/mpo-miles-services/v3/miles-calculator

    See data/earn/sources/asia-miles-parsing-guide.md for what the columns mean
    and how the figures were obtained.

    The scheme is the load-bearing column. Cathay's own flights are priced off
    a table of fixed amounts; every partner earns Asia Miles as a percentage of
    the distance flown, off a band set with one more boundary in it. Nothing may
    read a rate without first reading the scheme.
*/

%! cx_airline(?Code, ?Name, ?Scheme) is nondet.
%  Scheme is `cx` or `partner`.
cx_airline(cx, 'Cathay Pacific', cx).
cx_airline(aa, 'American Airlines', partner).
cx_airline(ac, 'Air Canada', partner).
cx_airline(as, 'Alaska Air Group', partner).
cx_airline(at, 'Royal Air Maroc', partner).
cx_airline(ay, 'Finnair', partner).
cx_airline(ba, 'British Airways', partner).
cx_airline(ca, 'Air China', partner).
cx_airline(fj, 'Fiji Airways', partner).
cx_airline(i2, 'Iberia Express', partner).
cx_airline(ib, 'Iberia', partner).
cx_airline(jl, 'Japan Airlines', partner).
cx_airline(la, 'LATAM', partner).
cx_airline(lh, 'Lufthansa', partner).
cx_airline(lx, 'Swiss', partner).
cx_airline(mh, 'Malaysia Airlines', partner).
cx_airline(nu, 'Japan Transocean Air', partner).
cx_airline(nz, 'Air New Zealand', partner).
cx_airline(os, 'Austrian Airlines', partner).
cx_airline(pg, 'Bangkok Airways', partner).
cx_airline(qf, 'Qantas', partner).
cx_airline(qr, 'Qatar Airways', partner).
cx_airline(rj, 'Royal Jordanian Airlines', partner).
cx_airline(ul, 'SriLankan Airlines', partner).
cx_airline(wy, 'Oman Air', partner).
cx_airline(zh, 'Shenzhen Airlines', partner).

%! cx_zero_points(?Code) is nondet.
%  Earns Asia Miles and no Status Points at all, on every sector. These nine are
%  exactly the non-oneworld partners, which is a useful sanity check and an
%  inference rather than something the calculator states -- so the list is the
%  data and the pattern is only this comment.
cx_zero_points(ac).
cx_zero_points(ca).
cx_zero_points(nz).
cx_zero_points(os).
cx_zero_points(pg).
cx_zero_points(la).
cx_zero_points(lh).
cx_zero_points(zh).
cx_zero_points(lx).

%! cx_coverage(?Code, ?Zones, ?Summary, ?Detail) is nondet.
%  Which distance zones this airline was actually sampled in. Cathay was
%  enumerated exhaustively; the partners were sampled 23-90 city pairs each, so a
%  rate outside these zones was never seen. src/earn/cx.pl says so on the sector
%  rather than leaving the reader to assume the table is complete.
cx_coverage(nz, [5], 'zones 5 only', '3 pairs, 5697-5867 mi. Zones 1,2,3,4,6 unobserved').
cx_coverage(os, [1], 'zones 1 only', '4 pairs, 193-488 mi. Zones 2,3,4,5,6 unobserved').
cx_coverage(ac, [1, 2], 'zones 1-2', '26 pairs, 38-2287 mi. Zones 3,4,5,6 unobserved').
cx_coverage(i2, [1, 2], 'zones 1-2', '33 pairs, 221-1796 mi. Zones 3,4,5,6 unobserved').
cx_coverage(nu, [1, 2], 'zones 1-2', '23 pairs, 75-1210 mi. Zones 3,4,5,6 unobserved').
cx_coverage(pg, [1, 2], 'zones 1-2', '40 pairs, 75-1967 mi. Zones 3,4,5,6 unobserved').
cx_coverage(zh, [1, 2], 'zones 1-2', '90 pairs, 109-2246 mi. Zones 3,4,5,6 unobserved').
cx_coverage(fj, [1, 2, 4, 5], 'zones 1-2 4-5', '41 pairs, 75-6626 mi. Zones 3,6 unobserved').
cx_coverage(lx, [1, 2, 4, 5], 'zones 1-2 4-5', '28 pairs, 31-5867 mi. Zones 3,6 unobserved').
cx_coverage(la, [1, 2, 3, 4], 'zones 1-4', '90 pairs, 107-4986 mi. Zones 5,6 unobserved').
cx_coverage(rj, [1, 2, 3, 4], 'zones 1-4', '82 pairs, 39-4740 mi. Zones 5,6 unobserved').
cx_coverage(aa, [1, 2, 4, 5, 6], 'zones 1-2 4-6', '90 pairs, 68-8794 mi. Zone 3 unobserved').
cx_coverage(as, [1, 2, 3, 4, 5], 'zones 1-5', '43 pairs, 56-5438 mi. Zone 6 unobserved').
cx_coverage(ca, [1, 2, 3, 4, 5], 'zones 1-5', '90 pairs, 163-7355 mi. Zone 6 unobserved').
cx_coverage(jl, [1, 2, 3, 4, 5], 'zones 1-5', '89 pairs, 105-6737 mi. Zone 6 unobserved. Class lists resolved from the page model, not from sampling').
cx_coverage(lh, [1, 2, 3, 4, 5], 'zones 1-5', '32 pairs, 85-5867 mi. Zone 6 unobserved').
cx_coverage(qr, [1, 2, 3, 4, 5], 'zones 1-5', '90 pairs, 55-7036 mi. Zone 6 unobserved').
cx_coverage(at, [1, 2, 3, 4, 5, 6], 'all 6 zones', '80 pairs, 88-7689 mi. Complete').
cx_coverage(ay, [1, 2, 3, 4, 5, 6], 'all 6 zones', '89 pairs, 50-9031 mi. Complete').
cx_coverage(ba, [1, 2, 3, 4, 5, 6], 'all 6 zones', '90 pairs, 58-9000 mi. Complete').
cx_coverage(ib, [1, 2, 3, 4, 5, 6], 'all 6 zones', '89 pairs, 45-10568 mi. Complete').
cx_coverage(mh, [1, 2, 3, 4, 5, 6], 'all 6 zones', '79 pairs, 23-7796 mi. Complete').
cx_coverage(qf, [1, 2, 3, 4, 5, 6], 'all 6 zones', '89 pairs, 44-10505 mi. Complete').
cx_coverage(ul, [1, 2, 3, 4, 5, 6], 'all 6 zones', '81 pairs, 65-8034 mi. Complete').
cx_coverage(wy, [1, 2, 3, 4, 5, 6], 'all 6 zones', '72 pairs, 121-9031 mi. Complete').
cx_coverage(cx, [1, 2, 3, 4, 5, 6], 'all 6 cards', '1,593 city pairs exhaustively enumerated, not sampled. Complete').
