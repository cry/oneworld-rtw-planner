:- module(cx_buckets,
          [ cx_row/5,
            cx_class/6,
            cx_group_label/5,
            cx_brand_label/2,
            cx_cabin_label/2,
            cx_family/2,
            cx_codeshare_brand/2,
            cx_class_settled/3
          ]).

/** <module> Which rate card a ticket reads against. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/asia-miles-lookup.csv and asia-miles-rules.csv,
    snapshot 2026-08-11 of
    https://api.cathaypacific.com/mpo-miles-services/v3/miles-calculator

    See data/earn/sources/asia-miles-parsing-guide.md for what the columns mean
    and how the figures were obtained.

    One row per (airline, cabin, fare group, scope, fare brand), which is the grain
    the calculator publishes. The fare group is the carrier's own code and the
    real unit of earning: every class in a group earns identically, and the
    membership comes from the carrier's published fare groups rather than from
    sampling -- so a class this file does not name is a class no group contains,
    not one nobody happened to observe.

    Scope is the domestic/international test, and only Japan Airlines and Japan
    Transocean use anything but `all`. There it decides the answer: JL Economy Y
    is group F at 100% on an international sector and group H at 50% on a
    domestic one, so (airline, cabin, class) is not a key for them.

    The brand is a real axis only on Cathay's own Economy: there the same booking
    classes sit under Flex, Essential and Light with different earn against each,
    so a ticket that names a class and not a family has genuinely bought one of
    three things and the honest answer is the spread. In every other cabin, and on
    every partner, the brand is the cabin repeated and a class picks its card out
    on its own.
*/

%! cx_row(?Airline, ?Cabin, ?Brand, ?Group, ?Scope) is nondet.
cx_row(cx, first, first, a, all).
cx_row(cx, business, business, b, all).
cx_row(cx, business, business, c, all).
cx_row(cx, premium_economy, premium_economy, d, all).
cx_row(cx, premium_economy, premium_economy, e, all).
cx_row(cx, economy, economy_flex, f, all).
cx_row(cx, economy, economy_essential, f, all).
cx_row(cx, economy, economy_light, f, all).
cx_row(cx, economy, codeshare, f, all).
cx_row(cx, economy, economy_flex, g, all).
cx_row(cx, economy, economy_essential, g, all).
cx_row(cx, economy, economy_light, g, all).
cx_row(cx, economy, codeshare, g, all).
cx_row(cx, economy, economy_flex, j, all).
cx_row(cx, economy, economy_essential, j, all).
cx_row(cx, economy, economy_light, j, all).
cx_row(cx, economy, codeshare, j, all).
cx_row(aa, first, first, a, all).
cx_row(aa, business, business, b, all).
cx_row(aa, premium_economy, premium_economy, d, all).
cx_row(aa, premium_economy, premium_economy, e, all).
cx_row(aa, economy, economy, f, all).
cx_row(aa, economy, economy, g, all).
cx_row(aa, economy, economy, j, all).
cx_row(ac, business, business, b, all).
cx_row(ac, premium_economy, premium_economy, d, all).
cx_row(ac, economy, economy, f, all).
cx_row(ac, economy, economy, h, all).
cx_row(as, first, first, a, all).
cx_row(as, economy, economy, f, all).
cx_row(as, economy, economy, g, all).
cx_row(at, business, business, b, all).
cx_row(at, economy, economy, f, all).
cx_row(at, economy, economy, h, all).
cx_row(at, economy, economy, j, all).
cx_row(ay, business, business, b, all).
cx_row(ay, business, business, c, all).
cx_row(ay, premium_economy, premium_economy, e, all).
cx_row(ay, economy, economy, f, all).
cx_row(ay, economy, economy, h, all).
cx_row(ba, first, first, a, all).
cx_row(ba, business, business, b, all).
cx_row(ba, premium_economy, premium_economy, d, all).
cx_row(ba, premium_economy, premium_economy, e, all).
cx_row(ba, economy, economy, f, all).
cx_row(ba, economy, economy, j, all).
cx_row(ca, first, first, a, all).
cx_row(ca, first, first, b, all).
cx_row(ca, business, business, b, all).
cx_row(ca, business, business, c, all).
cx_row(ca, premium_economy, premium_economy, d, all).
cx_row(ca, premium_economy, premium_economy, e, all).
cx_row(ca, economy, economy, f, all).
cx_row(ca, economy, economy, g, all).
cx_row(ca, economy, economy, h, all).
cx_row(ca, economy, economy, j, all).
cx_row(fj, business, business, b, all).
cx_row(fj, business, business, c, all).
cx_row(fj, economy, economy, f, all).
cx_row(fj, economy, economy, g, all).
cx_row(fj, economy, economy, h, all).
cx_row(fj, economy, economy, j, all).
cx_row(i2, business, business, b, all).
cx_row(i2, premium_economy, premium_economy, d, all).
cx_row(i2, premium_economy, premium_economy, e, all).
cx_row(i2, economy, economy, f, all).
cx_row(i2, economy, economy, j, all).
cx_row(ib, business, business, b, all).
cx_row(ib, premium_economy, premium_economy, d, all).
cx_row(ib, premium_economy, premium_economy, e, all).
cx_row(ib, economy, economy, f, all).
cx_row(ib, economy, economy, j, all).
cx_row(jl, first, first, a, all).
cx_row(jl, first, first, b, domestic).
cx_row(jl, business, business, b, all).
cx_row(jl, business, business, g, all).
cx_row(jl, premium_economy, premium_economy, f, all).
cx_row(jl, premium_economy, premium_economy, h, all).
cx_row(jl, economy, economy, f, all).
cx_row(jl, economy, economy, h, international).
cx_row(jl, economy, economy, h, domestic).
cx_row(la, business, business, b, all).
cx_row(la, premium_economy, premium_economy, d, all).
cx_row(la, economy, economy, f, all).
cx_row(lh, first, first, a, all).
cx_row(lh, business, business, b, all).
cx_row(lh, business, business, c, all).
cx_row(lh, premium_economy, premium_economy, d, all).
cx_row(lh, premium_economy, premium_economy, e, all).
cx_row(lh, economy, economy, f, all).
cx_row(lh, economy, economy, g, all).
cx_row(lx, first, first, a, all).
cx_row(lx, business, business, b, all).
cx_row(lx, business, business, c, all).
cx_row(lx, premium_economy, premium_economy, d, all).
cx_row(lx, premium_economy, premium_economy, e, all).
cx_row(lx, economy, economy, f, all).
cx_row(lx, economy, economy, g, all).
cx_row(lx, economy, economy, h, all).
cx_row(mh, first, first, a, all).
cx_row(mh, business, business, b, all).
cx_row(mh, economy, economy, f, all).
cx_row(mh, economy, economy, h, all).
cx_row(nu, first, first, a, all).
cx_row(nu, first, first, b, domestic).
cx_row(nu, business, business, b, all).
cx_row(nu, business, business, g, all).
cx_row(nu, premium_economy, premium_economy, f, all).
cx_row(nu, premium_economy, premium_economy, h, all).
cx_row(nu, economy, economy, f, all).
cx_row(nu, economy, economy, h, domestic).
cx_row(nz, business, business, b, all).
cx_row(nz, premium_economy, premium_economy, d, all).
cx_row(nz, economy, economy, f, all).
cx_row(nz, economy, economy, g, all).
cx_row(os, business, business, b, all).
cx_row(os, business, business, c, all).
cx_row(os, economy, economy, f, all).
cx_row(os, economy, economy, g, all).
cx_row(os, economy, economy, h, all).
cx_row(pg, business, business, b, all).
cx_row(pg, economy, economy, f, all).
cx_row(pg, economy, economy, g, all).
cx_row(qf, first, first, a, all).
cx_row(qf, business, business, b, all).
cx_row(qf, premium_economy, premium_economy, d, all).
cx_row(qf, economy, economy, f, all).
cx_row(qf, economy, economy, h, all).
cx_row(qr, first, first, a, all).
cx_row(qr, business, business, b, all).
cx_row(qr, business, business, g, all).
cx_row(qr, economy, economy, f, all).
cx_row(qr, economy, economy, h, all).
cx_row(qr, economy, economy, j, all).
cx_row(rj, business, business, b, all).
cx_row(rj, business, business, c, all).
cx_row(rj, economy, economy, f, all).
cx_row(rj, economy, economy, g, all).
cx_row(rj, economy, economy, h, all).
cx_row(ul, business, business, b, all).
cx_row(ul, business, business, c, all).
cx_row(ul, economy, economy, f, all).
cx_row(ul, economy, economy, g, all).
cx_row(ul, economy, economy, h, all).
cx_row(ul, economy, economy, j, all).
cx_row(wy, first, first, a, all).
cx_row(wy, business, business, c, all).
cx_row(wy, economy, economy, f, all).
cx_row(wy, economy, economy, h, all).
cx_row(wy, economy, economy, j, all).
cx_row(zh, business, business, b, all).
cx_row(zh, business, business, c, all).
cx_row(zh, premium_economy, premium_economy, d, all).
cx_row(zh, premium_economy, premium_economy, e, all).
cx_row(zh, economy, economy, f, all).
cx_row(zh, economy, economy, g, all).
cx_row(zh, economy, economy, h, all).

%! cx_class(?Airline, ?Cabin, ?Brand, ?Group, ?Scope, ?Class) is nondet.
%  A faithful transcription: a class appears once per card that lists it.
cx_class(cx, first, first, a, all, f).
cx_class(cx, first, first, a, all, a).
cx_class(cx, business, business, b, all, j).
cx_class(cx, business, business, b, all, c).
cx_class(cx, business, business, c, all, d).
cx_class(cx, business, business, c, all, p).
cx_class(cx, business, business, c, all, i).
cx_class(cx, premium_economy, premium_economy, d, all, w).
cx_class(cx, premium_economy, premium_economy, d, all, r).
cx_class(cx, premium_economy, premium_economy, e, all, e).
cx_class(cx, economy, economy_flex, f, all, y).
cx_class(cx, economy, economy_flex, f, all, b).
cx_class(cx, economy, economy_flex, f, all, h).
cx_class(cx, economy, economy_flex, f, all, k).
cx_class(cx, economy, economy_essential, f, all, y).
cx_class(cx, economy, economy_essential, f, all, b).
cx_class(cx, economy, economy_essential, f, all, h).
cx_class(cx, economy, economy_essential, f, all, k).
cx_class(cx, economy, economy_light, f, all, y).
cx_class(cx, economy, economy_light, f, all, b).
cx_class(cx, economy, economy_light, f, all, h).
cx_class(cx, economy, economy_light, f, all, k).
cx_class(cx, economy, codeshare, f, all, y).
cx_class(cx, economy, codeshare, f, all, b).
cx_class(cx, economy, codeshare, f, all, h).
cx_class(cx, economy, codeshare, f, all, k).
cx_class(cx, economy, economy_flex, g, all, m).
cx_class(cx, economy, economy_flex, g, all, l).
cx_class(cx, economy, economy_flex, g, all, v).
cx_class(cx, economy, economy_essential, g, all, m).
cx_class(cx, economy, economy_essential, g, all, l).
cx_class(cx, economy, economy_essential, g, all, v).
cx_class(cx, economy, economy_light, g, all, m).
cx_class(cx, economy, economy_light, g, all, l).
cx_class(cx, economy, economy_light, g, all, v).
cx_class(cx, economy, codeshare, g, all, m).
cx_class(cx, economy, codeshare, g, all, l).
cx_class(cx, economy, codeshare, g, all, v).
cx_class(cx, economy, economy_flex, j, all, s).
cx_class(cx, economy, economy_flex, j, all, n).
cx_class(cx, economy, economy_flex, j, all, q).
cx_class(cx, economy, economy_flex, j, all, o).
cx_class(cx, economy, economy_essential, j, all, s).
cx_class(cx, economy, economy_essential, j, all, n).
cx_class(cx, economy, economy_essential, j, all, q).
cx_class(cx, economy, economy_essential, j, all, o).
cx_class(cx, economy, economy_light, j, all, s).
cx_class(cx, economy, economy_light, j, all, n).
cx_class(cx, economy, economy_light, j, all, q).
cx_class(cx, economy, economy_light, j, all, o).
cx_class(cx, economy, codeshare, j, all, s).
cx_class(cx, economy, codeshare, j, all, n).
cx_class(cx, economy, codeshare, j, all, q).
cx_class(cx, economy, codeshare, j, all, o).
cx_class(aa, first, first, a, all, f).
cx_class(aa, first, first, a, all, a).
cx_class(aa, business, business, b, all, j).
cx_class(aa, business, business, b, all, c).
cx_class(aa, business, business, b, all, d).
cx_class(aa, business, business, b, all, r).
cx_class(aa, business, business, b, all, i).
cx_class(aa, premium_economy, premium_economy, d, all, w).
cx_class(aa, premium_economy, premium_economy, e, all, p).
cx_class(aa, economy, economy, f, all, y).
cx_class(aa, economy, economy, g, all, h).
cx_class(aa, economy, economy, g, all, k).
cx_class(aa, economy, economy, g, all, m).
cx_class(aa, economy, economy, g, all, l).
cx_class(aa, economy, economy, g, all, v).
cx_class(aa, economy, economy, j, all, g).
cx_class(aa, economy, economy, j, all, s).
cx_class(aa, economy, economy, j, all, n).
cx_class(aa, economy, economy, j, all, q).
cx_class(ac, business, business, b, all, j).
cx_class(ac, business, business, b, all, c).
cx_class(ac, business, business, b, all, d).
cx_class(ac, business, business, b, all, z).
cx_class(ac, business, business, b, all, p).
cx_class(ac, premium_economy, premium_economy, d, all, e).
cx_class(ac, premium_economy, premium_economy, d, all, o).
cx_class(ac, premium_economy, premium_economy, d, all, a).
cx_class(ac, economy, economy, f, all, y).
cx_class(ac, economy, economy, f, all, b).
cx_class(ac, economy, economy, f, all, m).
cx_class(ac, economy, economy, f, all, u).
cx_class(ac, economy, economy, f, all, h).
cx_class(ac, economy, economy, f, all, q).
cx_class(ac, economy, economy, f, all, v).
cx_class(ac, economy, economy, f, all, w).
cx_class(ac, economy, economy, h, all, s).
cx_class(ac, economy, economy, h, all, t).
cx_class(ac, economy, economy, h, all, l).
cx_class(ac, economy, economy, h, all, k).
cx_class(ac, economy, economy, h, all, g).
cx_class(as, first, first, a, all, f).
cx_class(as, first, first, a, all, a).
cx_class(as, first, first, a, all, j).
cx_class(as, first, first, a, all, c).
cx_class(as, first, first, a, all, d).
cx_class(as, first, first, a, all, i).
cx_class(as, economy, economy, f, all, y).
cx_class(as, economy, economy, f, all, b).
cx_class(as, economy, economy, f, all, h).
cx_class(as, economy, economy, f, all, k).
cx_class(as, economy, economy, f, all, m).
cx_class(as, economy, economy, f, all, l).
cx_class(as, economy, economy, f, all, v).
cx_class(as, economy, economy, f, all, s).
cx_class(as, economy, economy, f, all, n).
cx_class(as, economy, economy, g, all, q).
cx_class(as, economy, economy, g, all, o).
cx_class(as, economy, economy, g, all, g).
cx_class(at, business, business, b, all, j).
cx_class(at, business, business, b, all, c).
cx_class(at, business, business, b, all, d).
cx_class(at, business, business, b, all, i).
cx_class(at, economy, economy, f, all, y).
cx_class(at, economy, economy, h, all, b).
cx_class(at, economy, economy, h, all, h).
cx_class(at, economy, economy, j, all, k).
cx_class(at, economy, economy, j, all, m).
cx_class(at, economy, economy, j, all, l).
cx_class(ay, business, business, b, all, j).
cx_class(ay, business, business, b, all, c).
cx_class(ay, business, business, b, all, d).
cx_class(ay, business, business, c, all, r).
cx_class(ay, business, business, c, all, i).
cx_class(ay, premium_economy, premium_economy, e, all, w).
cx_class(ay, premium_economy, premium_economy, e, all, e).
cx_class(ay, premium_economy, premium_economy, e, all, t).
cx_class(ay, premium_economy, premium_economy, e, all, p).
cx_class(ay, economy, economy, f, all, y).
cx_class(ay, economy, economy, f, all, b).
cx_class(ay, economy, economy, f, all, h).
cx_class(ay, economy, economy, f, all, k).
cx_class(ay, economy, economy, f, all, m).
cx_class(ay, economy, economy, h, all, v).
cx_class(ay, economy, economy, h, all, l).
cx_class(ba, first, first, a, all, f).
cx_class(ba, first, first, a, all, a).
cx_class(ba, business, business, b, all, j).
cx_class(ba, business, business, b, all, c).
cx_class(ba, business, business, b, all, d).
cx_class(ba, business, business, b, all, i).
cx_class(ba, business, business, b, all, r).
cx_class(ba, premium_economy, premium_economy, d, all, w).
cx_class(ba, premium_economy, premium_economy, e, all, t).
cx_class(ba, premium_economy, premium_economy, e, all, e).
cx_class(ba, economy, economy, f, all, y).
cx_class(ba, economy, economy, f, all, b).
cx_class(ba, economy, economy, f, all, h).
cx_class(ba, economy, economy, j, all, k).
cx_class(ba, economy, economy, j, all, l).
cx_class(ba, economy, economy, j, all, m).
cx_class(ba, economy, economy, j, all, v).
cx_class(ba, economy, economy, j, all, s).
cx_class(ba, economy, economy, j, all, n).
cx_class(ba, economy, economy, j, all, q).
cx_class(ca, first, first, a, all, f).
cx_class(ca, first, first, b, all, a).
cx_class(ca, business, business, b, all, j).
cx_class(ca, business, business, b, all, c).
cx_class(ca, business, business, c, all, d).
cx_class(ca, business, business, c, all, z).
cx_class(ca, business, business, c, all, r).
cx_class(ca, premium_economy, premium_economy, d, all, g).
cx_class(ca, premium_economy, premium_economy, e, all, e).
cx_class(ca, economy, economy, f, all, y).
cx_class(ca, economy, economy, f, all, b).
cx_class(ca, economy, economy, g, all, m).
cx_class(ca, economy, economy, g, all, u).
cx_class(ca, economy, economy, h, all, h).
cx_class(ca, economy, economy, h, all, q).
cx_class(ca, economy, economy, h, all, v).
cx_class(ca, economy, economy, h, all, w).
cx_class(ca, economy, economy, h, all, s).
cx_class(ca, economy, economy, h, all, t).
cx_class(ca, economy, economy, j, all, l).
cx_class(ca, economy, economy, j, all, k).
cx_class(ca, economy, economy, j, all, p).
cx_class(fj, business, business, b, all, j).
cx_class(fj, business, business, b, all, c).
cx_class(fj, business, business, c, all, d).
cx_class(fj, business, business, c, all, z).
cx_class(fj, business, business, c, all, i).
cx_class(fj, economy, economy, f, all, y).
cx_class(fj, economy, economy, f, all, b).
cx_class(fj, economy, economy, f, all, h).
cx_class(fj, economy, economy, f, all, k).
cx_class(fj, economy, economy, g, all, m).
cx_class(fj, economy, economy, g, all, l).
cx_class(fj, economy, economy, g, all, w).
cx_class(fj, economy, economy, h, all, v).
cx_class(fj, economy, economy, h, all, s).
cx_class(fj, economy, economy, h, all, n).
cx_class(fj, economy, economy, j, all, q).
cx_class(fj, economy, economy, j, all, o).
cx_class(fj, economy, economy, j, all, t).
cx_class(fj, economy, economy, j, all, g).
cx_class(fj, economy, economy, j, all, r).
cx_class(fj, economy, economy, j, all, f).
cx_class(fj, economy, economy, j, all, p).
cx_class(fj, economy, economy, j, all, a).
cx_class(i2, business, business, b, all, j).
cx_class(i2, business, business, b, all, c).
cx_class(i2, business, business, b, all, d).
cx_class(i2, business, business, b, all, i).
cx_class(i2, business, business, b, all, r).
cx_class(i2, premium_economy, premium_economy, d, all, w).
cx_class(i2, premium_economy, premium_economy, e, all, e).
cx_class(i2, premium_economy, premium_economy, e, all, t).
cx_class(i2, economy, economy, f, all, y).
cx_class(i2, economy, economy, f, all, b).
cx_class(i2, economy, economy, f, all, h).
cx_class(i2, economy, economy, j, all, k).
cx_class(i2, economy, economy, j, all, l).
cx_class(i2, economy, economy, j, all, m).
cx_class(i2, economy, economy, j, all, v).
cx_class(i2, economy, economy, j, all, s).
cx_class(i2, economy, economy, j, all, n).
cx_class(i2, economy, economy, j, all, q).
cx_class(i2, economy, economy, j, all, f).
cx_class(i2, economy, economy, j, all, g).
cx_class(i2, economy, economy, j, all, z).
cx_class(ib, business, business, b, all, j).
cx_class(ib, business, business, b, all, c).
cx_class(ib, business, business, b, all, d).
cx_class(ib, business, business, b, all, i).
cx_class(ib, business, business, b, all, r).
cx_class(ib, premium_economy, premium_economy, d, all, w).
cx_class(ib, premium_economy, premium_economy, e, all, e).
cx_class(ib, premium_economy, premium_economy, e, all, t).
cx_class(ib, economy, economy, f, all, y).
cx_class(ib, economy, economy, f, all, b).
cx_class(ib, economy, economy, f, all, h).
cx_class(ib, economy, economy, j, all, k).
cx_class(ib, economy, economy, j, all, l).
cx_class(ib, economy, economy, j, all, m).
cx_class(ib, economy, economy, j, all, v).
cx_class(ib, economy, economy, j, all, s).
cx_class(ib, economy, economy, j, all, n).
cx_class(ib, economy, economy, j, all, q).
cx_class(ib, economy, economy, j, all, f).
cx_class(ib, economy, economy, j, all, g).
cx_class(ib, economy, economy, j, all, z).
cx_class(jl, first, first, a, all, f).
cx_class(jl, first, first, a, all, a).
cx_class(jl, first, first, b, domestic, f).
cx_class(jl, business, business, b, all, j).
cx_class(jl, business, business, b, all, c).
cx_class(jl, business, business, b, all, d).
cx_class(jl, business, business, b, all, i).
cx_class(jl, business, business, g, all, x).
cx_class(jl, premium_economy, premium_economy, f, all, w).
cx_class(jl, premium_economy, premium_economy, f, all, r).
cx_class(jl, premium_economy, premium_economy, h, all, e).
cx_class(jl, premium_economy, premium_economy, h, all, p).
cx_class(jl, economy, economy, f, all, y).
cx_class(jl, economy, economy, h, international, b).
cx_class(jl, economy, economy, h, international, h).
cx_class(jl, economy, economy, h, international, k).
cx_class(jl, economy, economy, h, international, m).
cx_class(jl, economy, economy, h, international, l).
cx_class(jl, economy, economy, h, international, v).
cx_class(jl, economy, economy, h, international, s).
cx_class(jl, economy, economy, h, domestic, j).
cx_class(jl, economy, economy, h, domestic, y).
cx_class(la, business, business, b, all, j).
cx_class(la, business, business, b, all, c).
cx_class(la, business, business, b, all, d).
cx_class(la, business, business, b, all, i).
cx_class(la, business, business, b, all, z).
cx_class(la, premium_economy, premium_economy, d, all, w).
cx_class(la, premium_economy, premium_economy, d, all, p).
cx_class(la, economy, economy, f, all, y).
cx_class(la, economy, economy, f, all, b).
cx_class(la, economy, economy, f, all, h).
cx_class(la, economy, economy, f, all, x).
cx_class(la, economy, economy, f, all, k).
cx_class(la, economy, economy, f, all, m).
cx_class(la, economy, economy, f, all, l).
cx_class(la, economy, economy, f, all, v).
cx_class(la, economy, economy, f, all, s).
cx_class(la, economy, economy, f, all, n).
cx_class(la, economy, economy, f, all, q).
cx_class(la, economy, economy, f, all, o).
cx_class(lh, first, first, a, all, f).
cx_class(lh, first, first, a, all, a).
cx_class(lh, business, business, b, all, j).
cx_class(lh, business, business, b, all, c).
cx_class(lh, business, business, b, all, d).
cx_class(lh, business, business, b, all, z).
cx_class(lh, business, business, c, all, p).
cx_class(lh, premium_economy, premium_economy, d, all, g).
cx_class(lh, premium_economy, premium_economy, d, all, e).
cx_class(lh, premium_economy, premium_economy, e, all, n).
cx_class(lh, economy, economy, f, all, y).
cx_class(lh, economy, economy, f, all, b).
cx_class(lh, economy, economy, f, all, m).
cx_class(lh, economy, economy, f, all, u).
cx_class(lh, economy, economy, g, all, h).
cx_class(lh, economy, economy, g, all, q).
cx_class(lh, economy, economy, g, all, v).
cx_class(lh, economy, economy, g, all, w).
cx_class(lh, economy, economy, g, all, s).
cx_class(lx, first, first, a, all, a).
cx_class(lx, first, first, a, all, f).
cx_class(lx, business, business, b, all, j).
cx_class(lx, business, business, b, all, c).
cx_class(lx, business, business, b, all, d).
cx_class(lx, business, business, b, all, z).
cx_class(lx, business, business, c, all, p).
cx_class(lx, premium_economy, premium_economy, d, all, g).
cx_class(lx, premium_economy, premium_economy, d, all, e).
cx_class(lx, premium_economy, premium_economy, e, all, n).
cx_class(lx, economy, economy, f, all, y).
cx_class(lx, economy, economy, f, all, b).
cx_class(lx, economy, economy, f, all, m).
cx_class(lx, economy, economy, f, all, u).
cx_class(lx, economy, economy, g, all, h).
cx_class(lx, economy, economy, g, all, q).
cx_class(lx, economy, economy, g, all, v).
cx_class(lx, economy, economy, g, all, w).
cx_class(lx, economy, economy, g, all, s).
cx_class(lx, economy, economy, h, all, t).
cx_class(lx, economy, economy, h, all, l).
cx_class(mh, first, first, a, all, f).
cx_class(mh, first, first, a, all, a).
cx_class(mh, first, first, a, all, p).
cx_class(mh, business, business, b, all, j).
cx_class(mh, business, business, b, all, c).
cx_class(mh, business, business, b, all, d).
cx_class(mh, business, business, b, all, z).
cx_class(mh, economy, economy, f, all, y).
cx_class(mh, economy, economy, f, all, b).
cx_class(mh, economy, economy, f, all, h).
cx_class(mh, economy, economy, h, all, k).
cx_class(mh, economy, economy, h, all, m).
cx_class(nu, first, first, a, all, f).
cx_class(nu, first, first, a, all, a).
cx_class(nu, first, first, b, domestic, f).
cx_class(nu, business, business, b, all, j).
cx_class(nu, business, business, b, all, c).
cx_class(nu, business, business, b, all, d).
cx_class(nu, business, business, b, all, x).
cx_class(nu, business, business, g, all, i).
cx_class(nu, premium_economy, premium_economy, f, all, w).
cx_class(nu, premium_economy, premium_economy, f, all, r).
cx_class(nu, premium_economy, premium_economy, h, all, e).
cx_class(nu, premium_economy, premium_economy, h, all, p).
cx_class(nu, economy, economy, f, all, y).
cx_class(nu, economy, economy, h, domestic, j).
cx_class(nu, economy, economy, h, domestic, b).
cx_class(nu, economy, economy, h, domestic, h).
cx_class(nu, economy, economy, h, domestic, k).
cx_class(nu, economy, economy, h, domestic, m).
cx_class(nu, economy, economy, h, domestic, l).
cx_class(nu, economy, economy, h, domestic, v).
cx_class(nu, economy, economy, h, domestic, s).
cx_class(nu, economy, economy, h, domestic, y).
cx_class(nz, business, business, b, all, c).
cx_class(nz, business, business, b, all, d).
cx_class(nz, business, business, b, all, j).
cx_class(nz, business, business, b, all, z).
cx_class(nz, premium_economy, premium_economy, d, all, u).
cx_class(nz, premium_economy, premium_economy, d, all, e).
cx_class(nz, premium_economy, premium_economy, d, all, o).
cx_class(nz, premium_economy, premium_economy, d, all, a).
cx_class(nz, economy, economy, f, all, y).
cx_class(nz, economy, economy, f, all, b).
cx_class(nz, economy, economy, f, all, m).
cx_class(nz, economy, economy, g, all, h).
cx_class(nz, economy, economy, g, all, q).
cx_class(nz, economy, economy, g, all, v).
cx_class(nz, economy, economy, g, all, w).
cx_class(nz, economy, economy, g, all, t).
cx_class(os, business, business, b, all, j).
cx_class(os, business, business, b, all, c).
cx_class(os, business, business, b, all, d).
cx_class(os, business, business, b, all, z).
cx_class(os, business, business, c, all, p).
cx_class(os, economy, economy, f, all, y).
cx_class(os, economy, economy, f, all, b).
cx_class(os, economy, economy, f, all, m).
cx_class(os, economy, economy, f, all, u).
cx_class(os, economy, economy, g, all, h).
cx_class(os, economy, economy, g, all, q).
cx_class(os, economy, economy, g, all, v).
cx_class(os, economy, economy, g, all, w).
cx_class(os, economy, economy, g, all, s).
cx_class(os, economy, economy, h, all, t).
cx_class(os, economy, economy, h, all, l).
cx_class(pg, business, business, b, all, c).
cx_class(pg, business, business, b, all, d).
cx_class(pg, economy, economy, f, all, y).
cx_class(pg, economy, economy, f, all, m).
cx_class(pg, economy, economy, f, all, k).
cx_class(pg, economy, economy, f, all, n).
cx_class(pg, economy, economy, f, all, t).
cx_class(pg, economy, economy, f, all, l).
cx_class(pg, economy, economy, f, all, h).
cx_class(pg, economy, economy, g, all, v).
cx_class(pg, economy, economy, g, all, q).
cx_class(pg, economy, economy, g, all, g).
cx_class(pg, economy, economy, g, all, b).
cx_class(qf, first, first, a, all, f).
cx_class(qf, first, first, a, all, a).
cx_class(qf, business, business, b, all, j).
cx_class(qf, business, business, b, all, c).
cx_class(qf, business, business, b, all, d).
cx_class(qf, business, business, b, all, i).
cx_class(qf, premium_economy, premium_economy, d, all, w).
cx_class(qf, premium_economy, premium_economy, d, all, r).
cx_class(qf, premium_economy, premium_economy, d, all, t).
cx_class(qf, economy, economy, f, all, y).
cx_class(qf, economy, economy, h, all, b).
cx_class(qf, economy, economy, h, all, h).
cx_class(qf, economy, economy, h, all, k).
cx_class(qf, economy, economy, h, all, l).
cx_class(qf, economy, economy, h, all, m).
cx_class(qf, economy, economy, h, all, v).
cx_class(qr, first, first, a, all, f).
cx_class(qr, first, first, a, all, a).
cx_class(qr, business, business, b, all, j).
cx_class(qr, business, business, b, all, c).
cx_class(qr, business, business, b, all, d).
cx_class(qr, business, business, b, all, i).
cx_class(qr, business, business, b, all, r).
cx_class(qr, business, business, g, all, p).
cx_class(qr, economy, economy, f, all, y).
cx_class(qr, economy, economy, f, all, b).
cx_class(qr, economy, economy, f, all, h).
cx_class(qr, economy, economy, h, all, k).
cx_class(qr, economy, economy, h, all, m).
cx_class(qr, economy, economy, h, all, l).
cx_class(qr, economy, economy, h, all, v).
cx_class(qr, economy, economy, j, all, s).
cx_class(qr, economy, economy, j, all, n).
cx_class(qr, economy, economy, j, all, q).
cx_class(qr, economy, economy, j, all, g).
cx_class(rj, business, business, b, all, j).
cx_class(rj, business, business, b, all, c).
cx_class(rj, business, business, b, all, d).
cx_class(rj, business, business, c, all, i).
cx_class(rj, business, business, c, all, z).
cx_class(rj, economy, economy, f, all, y).
cx_class(rj, economy, economy, g, all, b).
cx_class(rj, economy, economy, g, all, h).
cx_class(rj, economy, economy, g, all, k).
cx_class(rj, economy, economy, h, all, m).
cx_class(rj, economy, economy, h, all, l).
cx_class(rj, economy, economy, h, all, v).
cx_class(rj, economy, economy, h, all, s).
cx_class(rj, economy, economy, h, all, n).
cx_class(rj, economy, economy, h, all, q).
cx_class(ul, business, business, b, all, j).
cx_class(ul, business, business, b, all, c).
cx_class(ul, business, business, b, all, d).
cx_class(ul, business, business, c, all, i).
cx_class(ul, economy, economy, f, all, y).
cx_class(ul, economy, economy, f, all, b).
cx_class(ul, economy, economy, f, all, p).
cx_class(ul, economy, economy, f, all, h).
cx_class(ul, economy, economy, g, all, k).
cx_class(ul, economy, economy, g, all, w).
cx_class(ul, economy, economy, g, all, m).
cx_class(ul, economy, economy, g, all, e).
cx_class(ul, economy, economy, h, all, v).
cx_class(ul, economy, economy, h, all, s).
cx_class(ul, economy, economy, h, all, l).
cx_class(ul, economy, economy, h, all, r).
cx_class(ul, economy, economy, j, all, n).
cx_class(wy, first, first, a, all, a).
cx_class(wy, first, first, a, all, f).
cx_class(wy, business, business, c, all, j).
cx_class(wy, business, business, c, all, c).
cx_class(wy, business, business, c, all, d).
cx_class(wy, business, business, c, all, i).
cx_class(wy, business, business, c, all, p).
cx_class(wy, economy, economy, f, all, y).
cx_class(wy, economy, economy, h, all, b).
cx_class(wy, economy, economy, j, all, h).
cx_class(wy, economy, economy, j, all, k).
cx_class(wy, economy, economy, j, all, m).
cx_class(wy, economy, economy, j, all, l).
cx_class(wy, economy, economy, j, all, v).
cx_class(wy, economy, economy, j, all, s).
cx_class(wy, economy, economy, j, all, n).
cx_class(wy, economy, economy, j, all, q).
cx_class(wy, economy, economy, j, all, o).
cx_class(wy, economy, economy, j, all, r).
cx_class(wy, economy, economy, j, all, t).
cx_class(zh, business, business, b, all, j).
cx_class(zh, business, business, b, all, c).
cx_class(zh, business, business, c, all, d).
cx_class(zh, business, business, c, all, z).
cx_class(zh, business, business, c, all, r).
cx_class(zh, premium_economy, premium_economy, d, all, g).
cx_class(zh, premium_economy, premium_economy, e, all, e).
cx_class(zh, economy, economy, f, all, y).
cx_class(zh, economy, economy, f, all, b).
cx_class(zh, economy, economy, f, all, m).
cx_class(zh, economy, economy, f, all, u).
cx_class(zh, economy, economy, f, all, h).
cx_class(zh, economy, economy, g, all, q).
cx_class(zh, economy, economy, g, all, v).
cx_class(zh, economy, economy, g, all, w).
cx_class(zh, economy, economy, g, all, s).
cx_class(zh, economy, economy, g, all, t).
cx_class(zh, economy, economy, h, all, a).
cx_class(zh, economy, economy, h, all, k).
cx_class(zh, economy, economy, h, all, l).
cx_class(zh, economy, economy, h, all, p).

%! cx_group_label(?Airline, ?Cabin, ?Group, ?Scope, ?Label) is nondet.
%  The fare group's membership as the table writes it, so a figure can be checked
%  against the published row rather than against a key this file invented.
cx_group_label(cx, first, a, all, 'F A').
cx_group_label(cx, business, b, all, 'J C').
cx_group_label(cx, business, c, all, 'D P I').
cx_group_label(cx, premium_economy, d, all, 'W R').
cx_group_label(cx, premium_economy, e, all, 'E').
cx_group_label(cx, economy, f, all, 'Y B H K').
cx_group_label(cx, economy, g, all, 'M L V').
cx_group_label(cx, economy, j, all, 'S N Q O').
cx_group_label(aa, first, a, all, 'F A').
cx_group_label(aa, business, b, all, 'J C D R I').
cx_group_label(aa, premium_economy, d, all, 'W').
cx_group_label(aa, premium_economy, e, all, 'P').
cx_group_label(aa, economy, f, all, 'Y').
cx_group_label(aa, economy, g, all, 'H K M L V').
cx_group_label(aa, economy, j, all, 'G S N Q').
cx_group_label(ac, business, b, all, 'J C D Z P').
cx_group_label(ac, premium_economy, d, all, 'E O A').
cx_group_label(ac, economy, f, all, 'Y B M U H Q V W').
cx_group_label(ac, economy, h, all, 'S T L K G').
cx_group_label(as, first, a, all, 'F A J C D I').
cx_group_label(as, economy, f, all, 'Y B H K M L V S N').
cx_group_label(as, economy, g, all, 'Q O G').
cx_group_label(at, business, b, all, 'J C D I').
cx_group_label(at, economy, f, all, 'Y').
cx_group_label(at, economy, h, all, 'B H').
cx_group_label(at, economy, j, all, 'K M L').
cx_group_label(ay, business, b, all, 'J C D').
cx_group_label(ay, business, c, all, 'R I').
cx_group_label(ay, premium_economy, e, all, 'W E T P').
cx_group_label(ay, economy, f, all, 'Y B H K M').
cx_group_label(ay, economy, h, all, 'V L').
cx_group_label(ba, first, a, all, 'F A').
cx_group_label(ba, business, b, all, 'J C D I R').
cx_group_label(ba, premium_economy, d, all, 'W').
cx_group_label(ba, premium_economy, e, all, 'T E').
cx_group_label(ba, economy, f, all, 'Y B H').
cx_group_label(ba, economy, j, all, 'K L M V S N Q').
cx_group_label(ca, first, a, all, 'F').
cx_group_label(ca, first, b, all, 'A').
cx_group_label(ca, business, b, all, 'J C').
cx_group_label(ca, business, c, all, 'D Z R').
cx_group_label(ca, premium_economy, d, all, 'G').
cx_group_label(ca, premium_economy, e, all, 'E').
cx_group_label(ca, economy, f, all, 'Y B').
cx_group_label(ca, economy, g, all, 'M U').
cx_group_label(ca, economy, h, all, 'H Q V W S T').
cx_group_label(ca, economy, j, all, 'L K P').
cx_group_label(fj, business, b, all, 'J C').
cx_group_label(fj, business, c, all, 'D Z I').
cx_group_label(fj, economy, f, all, 'Y B H K').
cx_group_label(fj, economy, g, all, 'M L W').
cx_group_label(fj, economy, h, all, 'V S N').
cx_group_label(fj, economy, j, all, 'Q O T G R F P A').
cx_group_label(i2, business, b, all, 'J C D I R').
cx_group_label(i2, premium_economy, d, all, 'W').
cx_group_label(i2, premium_economy, e, all, 'E T').
cx_group_label(i2, economy, f, all, 'Y B H').
cx_group_label(i2, economy, j, all, 'K L M V S N Q F G Z').
cx_group_label(ib, business, b, all, 'J C D I R').
cx_group_label(ib, premium_economy, d, all, 'W').
cx_group_label(ib, premium_economy, e, all, 'E T').
cx_group_label(ib, economy, f, all, 'Y B H').
cx_group_label(ib, economy, j, all, 'K L M V S N Q F G Z').
cx_group_label(jl, first, a, all, 'F A').
cx_group_label(jl, first, b, domestic, 'F').
cx_group_label(jl, business, b, all, 'J C D I').
cx_group_label(jl, business, g, all, 'X').
cx_group_label(jl, premium_economy, f, all, 'W R').
cx_group_label(jl, premium_economy, h, all, 'E P').
cx_group_label(jl, economy, f, all, 'Y').
cx_group_label(jl, economy, h, international, 'B H K M L V S').
cx_group_label(jl, economy, h, domestic, 'J Y').
cx_group_label(la, business, b, all, 'J C D I Z').
cx_group_label(la, premium_economy, d, all, 'W P').
cx_group_label(la, economy, f, all, 'Y B H X K M L V S N Q O').
cx_group_label(lh, first, a, all, 'F A').
cx_group_label(lh, business, b, all, 'J C D Z').
cx_group_label(lh, business, c, all, 'P').
cx_group_label(lh, premium_economy, d, all, 'G E').
cx_group_label(lh, premium_economy, e, all, 'N').
cx_group_label(lh, economy, f, all, 'Y B M U').
cx_group_label(lh, economy, g, all, 'H Q V W S').
cx_group_label(lx, first, a, all, 'A F').
cx_group_label(lx, business, b, all, 'J C D Z').
cx_group_label(lx, business, c, all, 'P').
cx_group_label(lx, premium_economy, d, all, 'G E').
cx_group_label(lx, premium_economy, e, all, 'N').
cx_group_label(lx, economy, f, all, 'Y B M U').
cx_group_label(lx, economy, g, all, 'H Q V W S').
cx_group_label(lx, economy, h, all, 'T L').
cx_group_label(mh, first, a, all, 'F A P').
cx_group_label(mh, business, b, all, 'J C D Z').
cx_group_label(mh, economy, f, all, 'Y B H').
cx_group_label(mh, economy, h, all, 'K M').
cx_group_label(nu, first, a, all, 'F A').
cx_group_label(nu, first, b, domestic, 'F').
cx_group_label(nu, business, b, all, 'J C D X').
cx_group_label(nu, business, g, all, 'I').
cx_group_label(nu, premium_economy, f, all, 'W R').
cx_group_label(nu, premium_economy, h, all, 'E P').
cx_group_label(nu, economy, f, all, 'Y').
cx_group_label(nu, economy, h, domestic, 'J B H K M L V S Y').
cx_group_label(nz, business, b, all, 'C D J Z').
cx_group_label(nz, premium_economy, d, all, 'U E O A').
cx_group_label(nz, economy, f, all, 'Y B M').
cx_group_label(nz, economy, g, all, 'H Q V W T').
cx_group_label(os, business, b, all, 'J C D Z').
cx_group_label(os, business, c, all, 'P').
cx_group_label(os, economy, f, all, 'Y B M U').
cx_group_label(os, economy, g, all, 'H Q V W S').
cx_group_label(os, economy, h, all, 'T L').
cx_group_label(pg, business, b, all, 'C D').
cx_group_label(pg, economy, f, all, 'Y M K N T L H').
cx_group_label(pg, economy, g, all, 'V Q G B').
cx_group_label(qf, first, a, all, 'F A').
cx_group_label(qf, business, b, all, 'J C D I').
cx_group_label(qf, premium_economy, d, all, 'W R T').
cx_group_label(qf, economy, f, all, 'Y').
cx_group_label(qf, economy, h, all, 'B H K L M V').
cx_group_label(qr, first, a, all, 'F A').
cx_group_label(qr, business, b, all, 'J C D I R').
cx_group_label(qr, business, g, all, 'P').
cx_group_label(qr, economy, f, all, 'Y B H').
cx_group_label(qr, economy, h, all, 'K M L V').
cx_group_label(qr, economy, j, all, 'S N Q G').
cx_group_label(rj, business, b, all, 'J C D').
cx_group_label(rj, business, c, all, 'I Z').
cx_group_label(rj, economy, f, all, 'Y').
cx_group_label(rj, economy, g, all, 'B H K').
cx_group_label(rj, economy, h, all, 'M L V S N Q').
cx_group_label(ul, business, b, all, 'J C D').
cx_group_label(ul, business, c, all, 'I').
cx_group_label(ul, economy, f, all, 'Y B P H').
cx_group_label(ul, economy, g, all, 'K W M E').
cx_group_label(ul, economy, h, all, 'V S L R').
cx_group_label(ul, economy, j, all, 'N').
cx_group_label(wy, first, a, all, 'A F').
cx_group_label(wy, business, c, all, 'J C D I P').
cx_group_label(wy, economy, f, all, 'Y').
cx_group_label(wy, economy, h, all, 'B').
cx_group_label(wy, economy, j, all, 'H K M L V S N Q O R T').
cx_group_label(zh, business, b, all, 'J C').
cx_group_label(zh, business, c, all, 'D Z R').
cx_group_label(zh, premium_economy, d, all, 'G').
cx_group_label(zh, premium_economy, e, all, 'E').
cx_group_label(zh, economy, f, all, 'Y B M U H').
cx_group_label(zh, economy, g, all, 'Q V W S T').
cx_group_label(zh, economy, h, all, 'A K L P').

%! cx_brand_label(?Brand, ?Label) is nondet.
cx_brand_label(first, 'First').
cx_brand_label(business, 'Business').
cx_brand_label(premium_economy, 'Premium Economy').
cx_brand_label(economy_flex, 'Economy Flex').
cx_brand_label(economy_essential, 'Economy Essential').
cx_brand_label(economy_light, 'Economy Light').
cx_brand_label(codeshare, 'Codeshare').
cx_brand_label(economy, 'Economy').

%! cx_cabin_label(?Cabin, ?Label) is nondet.
cx_cabin_label(economy,         'Economy').
cx_cabin_label(premium_economy, 'Premium Economy').
cx_cabin_label(business,        'Business').
cx_cabin_label(first,           'First').

%! cx_family(?Family, ?Brand) is nondet.
%  What a caller may put in `fareFamily`, and the card it names. Codeshare is
%  deliberately not one of them: it is settled by who operates the flight rather
%  than by what was bought.
cx_family(flex, economy_flex).
cx_family(essential, economy_essential).
cx_family(light, economy_light).

%! cx_codeshare_brand(?Cabin, ?Brand) is nondet.
%  The card a Cathay flight number on partner metal reads against. Economy has
%  one and it is numerically identical to Economy Light in every band; the other
%  three cabins publish none, so a codeshare in them is unknown rather than
%  priced off the Cathay-operated figure.
cx_codeshare_brand(economy, codeshare).

%! cx_class_settled(?Class, ?Brand, ?Reason) is nondet.
%  The one place a fact that is not on the page decides an answer. Y is full-fare
%  economy and therefore the flexible fare whatever the grid lists it under; B, H
%  and K are not, and stay a range until a fareFamily says which they were.
%  src/earn/cx.pl reports this reason as the basis rather than claiming the table
%  settled it.
cx_class_settled(y, economy_flex, 'Y is full-fare economy, which is sold as the flexible fare').
