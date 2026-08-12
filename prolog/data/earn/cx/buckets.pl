:- module(cx_buckets,
          [ cx_row/4,
            cx_class/5,
            cx_group_label/2,
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

    One row per (airline, cabin, class group, fare brand), which is the grain the
    calculator publishes. The brand is a real axis only on Cathay's own Economy:
    there the same booking classes sit under Flex, Essential and Light with
    different earn against each, so a ticket that names a class and not a family
    has genuinely bought one of three things and the honest answer is the spread.
    In every other cabin, and on every partner, the brand is the cabin repeated
    and a class picks its card out on its own.
*/

%! cx_row(?Airline, ?Cabin, ?Brand, ?Group) is nondet.
cx_row(cx, first, first, af).
cx_row(cx, business, business, cj).
cx_row(cx, business, business, dip).
cx_row(cx, premium_economy, premium_economy, e).
cx_row(cx, premium_economy, premium_economy, rw).
cx_row(cx, economy, economy_flex, bhky).
cx_row(cx, economy, economy_essential, bhky).
cx_row(cx, economy, economy_light, bhky).
cx_row(cx, economy, codeshare, bhky).
cx_row(cx, economy, economy_flex, lmv).
cx_row(cx, economy, economy_essential, lmv).
cx_row(cx, economy, economy_light, lmv).
cx_row(cx, economy, codeshare, lmv).
cx_row(cx, economy, economy_flex, noqs).
cx_row(cx, economy, economy_essential, noqs).
cx_row(cx, economy, economy_light, noqs).
cx_row(cx, economy, codeshare, noqs).
cx_row(aa, first, first, af).
cx_row(aa, business, business, cdijr).
cx_row(aa, premium_economy, premium_economy, p).
cx_row(aa, premium_economy, premium_economy, w).
cx_row(aa, economy, economy, y).
cx_row(aa, economy, economy, hklmv).
cx_row(aa, economy, economy, gnqs).
cx_row(ac, business, business, cdjpz).
cx_row(ac, premium_economy, premium_economy, aeo).
cx_row(ac, economy, economy, bhmquvwy).
cx_row(ac, economy, economy, gklst).
cx_row(as, first, first, acdfij).
cx_row(as, economy, economy, bhklmnsvy).
cx_row(as, economy, economy, goq).
cx_row(at, business, business, cdij).
cx_row(at, economy, economy, y).
cx_row(at, economy, economy, bh).
cx_row(at, economy, economy, klm).
cx_row(ay, business, business, cdj).
cx_row(ay, business, business, ir).
cx_row(ay, premium_economy, premium_economy, eptw).
cx_row(ay, economy, economy, bhkmy).
cx_row(ay, economy, economy, lv).
cx_row(ba, first, first, af).
cx_row(ba, business, business, cdijr).
cx_row(ba, premium_economy, premium_economy, et).
cx_row(ba, premium_economy, premium_economy, w).
cx_row(ba, economy, economy, bhy).
cx_row(ba, economy, economy, klmnqsv).
cx_row(ca, first, first, a).
cx_row(ca, first, first, f).
cx_row(ca, business, business, cj).
cx_row(ca, business, business, drz).
cx_row(ca, premium_economy, premium_economy, e).
cx_row(ca, premium_economy, premium_economy, g).
cx_row(ca, economy, economy, by).
cx_row(ca, economy, economy, mu).
cx_row(ca, economy, economy, hqstvw).
cx_row(ca, economy, economy, klp).
cx_row(fj, business, business, cj).
cx_row(fj, business, business, diz).
cx_row(fj, economy, economy, bhky).
cx_row(fj, economy, economy, lmw).
cx_row(fj, economy, economy, nsv).
cx_row(fj, economy, economy, afgopqrt).
cx_row(i2, business, business, cdijr).
cx_row(i2, premium_economy, premium_economy, et).
cx_row(i2, premium_economy, premium_economy, w).
cx_row(i2, economy, economy, bhy).
cx_row(i2, economy, economy, fgklmnqsvz).
cx_row(ib, business, business, cdijr).
cx_row(ib, premium_economy, premium_economy, et).
cx_row(ib, premium_economy, premium_economy, w).
cx_row(ib, economy, economy, bhy).
cx_row(ib, economy, economy, fgklmnqsvz).
cx_row(jl, first, first, af).
cx_row(jl, first, first, e).
cx_row(jl, business, business, c).
cx_row(jl, business, business, h).
cx_row(jl, premium_economy, premium_economy, w).
cx_row(jl, premium_economy, premium_economy, p).
cx_row(jl, economy, economy, y).
cx_row(jl, economy, economy, j).
cx_row(jl, economy, economy, r).
cx_row(jl, economy, economy, ai).
cx_row(la, business, business, cdijz).
cx_row(la, premium_economy, premium_economy, pw).
cx_row(la, economy, economy, bhklmnoqsvxy).
cx_row(lh, first, first, af).
cx_row(lh, business, business, cdjz).
cx_row(lh, business, business, p).
cx_row(lh, premium_economy, premium_economy, eg).
cx_row(lh, premium_economy, premium_economy, n).
cx_row(lh, economy, economy, bmuy).
cx_row(lh, economy, economy, hqsvw).
cx_row(lx, first, first, af).
cx_row(lx, business, business, cdjz).
cx_row(lx, business, business, p).
cx_row(lx, premium_economy, premium_economy, eg).
cx_row(lx, premium_economy, premium_economy, n).
cx_row(lx, economy, economy, bmuy).
cx_row(lx, economy, economy, hqsvw).
cx_row(mh, first, first, afp).
cx_row(mh, business, business, cdjz).
cx_row(mh, economy, economy, bhy).
cx_row(mh, economy, economy, km).
cx_row(nu, first, first, f).
cx_row(nu, first, first, e).
cx_row(nu, business, business, c).
cx_row(nu, business, business, h).
cx_row(nu, premium_economy, premium_economy, w).
cx_row(nu, premium_economy, premium_economy, p).
cx_row(nu, economy, economy, jy).
cx_row(nu, economy, economy, ai).
cx_row(nu, economy, economy, r).
cx_row(nz, business, business, cdjz).
cx_row(nz, premium_economy, premium_economy, aeou).
cx_row(nz, economy, economy, bmy).
cx_row(nz, economy, economy, hqtvw).
cx_row(os, business, business, cdjz).
cx_row(os, business, business, p).
cx_row(os, economy, economy, bmuy).
cx_row(os, economy, economy, hqsvw).
cx_row(pg, business, business, cd).
cx_row(pg, economy, economy, hklmnty).
cx_row(pg, economy, economy, bgqv).
cx_row(qf, first, first, af).
cx_row(qf, business, business, cdij).
cx_row(qf, premium_economy, premium_economy, rtw).
cx_row(qf, economy, economy, y).
cx_row(qf, economy, economy, bhklmv).
cx_row(qr, first, first, af).
cx_row(qr, business, business, cdijr).
cx_row(qr, business, business, p).
cx_row(qr, economy, economy, bhy).
cx_row(qr, economy, economy, klmv).
cx_row(qr, economy, economy, gnqs).
cx_row(rj, business, business, cdj).
cx_row(rj, business, business, iz).
cx_row(rj, economy, economy, y).
cx_row(rj, economy, economy, bhk).
cx_row(rj, economy, economy, lmnqsv).
cx_row(ul, business, business, cdj).
cx_row(ul, business, business, i).
cx_row(ul, economy, economy, bhpy).
cx_row(ul, economy, economy, ekmw).
cx_row(ul, economy, economy, lrsv).
cx_row(ul, economy, economy, n).
cx_row(wy, first, first, af).
cx_row(wy, business, business, cdijp).
cx_row(wy, economy, economy, y).
cx_row(wy, economy, economy, b).
cx_row(wy, economy, economy, hklmnoqrstv).
cx_row(zh, business, business, cj).
cx_row(zh, business, business, drz).
cx_row(zh, premium_economy, premium_economy, e).
cx_row(zh, premium_economy, premium_economy, g).
cx_row(zh, economy, economy, bhmuy).
cx_row(zh, economy, economy, qstvw).
cx_row(zh, economy, economy, aklp).

%! cx_class(?Airline, ?Cabin, ?Brand, ?Group, ?Class) is nondet.
%  A faithful transcription: a class appears once per card that lists it.
cx_class(cx, first, first, af, a).
cx_class(cx, first, first, af, f).
cx_class(cx, business, business, cj, c).
cx_class(cx, business, business, cj, j).
cx_class(cx, business, business, dip, d).
cx_class(cx, business, business, dip, i).
cx_class(cx, business, business, dip, p).
cx_class(cx, premium_economy, premium_economy, e, e).
cx_class(cx, premium_economy, premium_economy, rw, r).
cx_class(cx, premium_economy, premium_economy, rw, w).
cx_class(cx, economy, economy_flex, bhky, b).
cx_class(cx, economy, economy_flex, bhky, h).
cx_class(cx, economy, economy_flex, bhky, k).
cx_class(cx, economy, economy_flex, bhky, y).
cx_class(cx, economy, economy_essential, bhky, b).
cx_class(cx, economy, economy_essential, bhky, h).
cx_class(cx, economy, economy_essential, bhky, k).
cx_class(cx, economy, economy_essential, bhky, y).
cx_class(cx, economy, economy_light, bhky, b).
cx_class(cx, economy, economy_light, bhky, h).
cx_class(cx, economy, economy_light, bhky, k).
cx_class(cx, economy, economy_light, bhky, y).
cx_class(cx, economy, codeshare, bhky, b).
cx_class(cx, economy, codeshare, bhky, h).
cx_class(cx, economy, codeshare, bhky, k).
cx_class(cx, economy, codeshare, bhky, y).
cx_class(cx, economy, economy_flex, lmv, l).
cx_class(cx, economy, economy_flex, lmv, m).
cx_class(cx, economy, economy_flex, lmv, v).
cx_class(cx, economy, economy_essential, lmv, l).
cx_class(cx, economy, economy_essential, lmv, m).
cx_class(cx, economy, economy_essential, lmv, v).
cx_class(cx, economy, economy_light, lmv, l).
cx_class(cx, economy, economy_light, lmv, m).
cx_class(cx, economy, economy_light, lmv, v).
cx_class(cx, economy, codeshare, lmv, l).
cx_class(cx, economy, codeshare, lmv, m).
cx_class(cx, economy, codeshare, lmv, v).
cx_class(cx, economy, economy_flex, noqs, n).
cx_class(cx, economy, economy_flex, noqs, o).
cx_class(cx, economy, economy_flex, noqs, q).
cx_class(cx, economy, economy_flex, noqs, s).
cx_class(cx, economy, economy_essential, noqs, n).
cx_class(cx, economy, economy_essential, noqs, o).
cx_class(cx, economy, economy_essential, noqs, q).
cx_class(cx, economy, economy_essential, noqs, s).
cx_class(cx, economy, economy_light, noqs, n).
cx_class(cx, economy, economy_light, noqs, o).
cx_class(cx, economy, economy_light, noqs, q).
cx_class(cx, economy, economy_light, noqs, s).
cx_class(cx, economy, codeshare, noqs, n).
cx_class(cx, economy, codeshare, noqs, o).
cx_class(cx, economy, codeshare, noqs, q).
cx_class(cx, economy, codeshare, noqs, s).
cx_class(aa, first, first, af, a).
cx_class(aa, first, first, af, f).
cx_class(aa, business, business, cdijr, c).
cx_class(aa, business, business, cdijr, d).
cx_class(aa, business, business, cdijr, i).
cx_class(aa, business, business, cdijr, j).
cx_class(aa, business, business, cdijr, r).
cx_class(aa, premium_economy, premium_economy, p, p).
cx_class(aa, premium_economy, premium_economy, w, w).
cx_class(aa, economy, economy, y, y).
cx_class(aa, economy, economy, hklmv, h).
cx_class(aa, economy, economy, hklmv, k).
cx_class(aa, economy, economy, hklmv, l).
cx_class(aa, economy, economy, hklmv, m).
cx_class(aa, economy, economy, hklmv, v).
cx_class(aa, economy, economy, gnqs, g).
cx_class(aa, economy, economy, gnqs, n).
cx_class(aa, economy, economy, gnqs, q).
cx_class(aa, economy, economy, gnqs, s).
cx_class(ac, business, business, cdjpz, c).
cx_class(ac, business, business, cdjpz, d).
cx_class(ac, business, business, cdjpz, j).
cx_class(ac, business, business, cdjpz, p).
cx_class(ac, business, business, cdjpz, z).
cx_class(ac, premium_economy, premium_economy, aeo, a).
cx_class(ac, premium_economy, premium_economy, aeo, e).
cx_class(ac, premium_economy, premium_economy, aeo, o).
cx_class(ac, economy, economy, bhmquvwy, b).
cx_class(ac, economy, economy, bhmquvwy, h).
cx_class(ac, economy, economy, bhmquvwy, m).
cx_class(ac, economy, economy, bhmquvwy, q).
cx_class(ac, economy, economy, bhmquvwy, u).
cx_class(ac, economy, economy, bhmquvwy, v).
cx_class(ac, economy, economy, bhmquvwy, w).
cx_class(ac, economy, economy, bhmquvwy, y).
cx_class(ac, economy, economy, gklst, g).
cx_class(ac, economy, economy, gklst, k).
cx_class(ac, economy, economy, gklst, l).
cx_class(ac, economy, economy, gklst, s).
cx_class(ac, economy, economy, gklst, t).
cx_class(as, first, first, acdfij, a).
cx_class(as, first, first, acdfij, c).
cx_class(as, first, first, acdfij, d).
cx_class(as, first, first, acdfij, f).
cx_class(as, first, first, acdfij, i).
cx_class(as, first, first, acdfij, j).
cx_class(as, economy, economy, bhklmnsvy, b).
cx_class(as, economy, economy, bhklmnsvy, h).
cx_class(as, economy, economy, bhklmnsvy, k).
cx_class(as, economy, economy, bhklmnsvy, l).
cx_class(as, economy, economy, bhklmnsvy, m).
cx_class(as, economy, economy, bhklmnsvy, n).
cx_class(as, economy, economy, bhklmnsvy, s).
cx_class(as, economy, economy, bhklmnsvy, v).
cx_class(as, economy, economy, bhklmnsvy, y).
cx_class(as, economy, economy, goq, g).
cx_class(as, economy, economy, goq, o).
cx_class(as, economy, economy, goq, q).
cx_class(at, business, business, cdij, c).
cx_class(at, business, business, cdij, d).
cx_class(at, business, business, cdij, i).
cx_class(at, business, business, cdij, j).
cx_class(at, economy, economy, y, y).
cx_class(at, economy, economy, bh, b).
cx_class(at, economy, economy, bh, h).
cx_class(at, economy, economy, klm, k).
cx_class(at, economy, economy, klm, l).
cx_class(at, economy, economy, klm, m).
cx_class(ay, business, business, cdj, c).
cx_class(ay, business, business, cdj, d).
cx_class(ay, business, business, cdj, j).
cx_class(ay, business, business, ir, i).
cx_class(ay, business, business, ir, r).
cx_class(ay, premium_economy, premium_economy, eptw, e).
cx_class(ay, premium_economy, premium_economy, eptw, p).
cx_class(ay, premium_economy, premium_economy, eptw, t).
cx_class(ay, premium_economy, premium_economy, eptw, w).
cx_class(ay, economy, economy, bhkmy, b).
cx_class(ay, economy, economy, bhkmy, h).
cx_class(ay, economy, economy, bhkmy, k).
cx_class(ay, economy, economy, bhkmy, m).
cx_class(ay, economy, economy, bhkmy, y).
cx_class(ay, economy, economy, lv, l).
cx_class(ay, economy, economy, lv, v).
cx_class(ba, first, first, af, a).
cx_class(ba, first, first, af, f).
cx_class(ba, business, business, cdijr, c).
cx_class(ba, business, business, cdijr, d).
cx_class(ba, business, business, cdijr, i).
cx_class(ba, business, business, cdijr, j).
cx_class(ba, business, business, cdijr, r).
cx_class(ba, premium_economy, premium_economy, et, e).
cx_class(ba, premium_economy, premium_economy, et, t).
cx_class(ba, premium_economy, premium_economy, w, w).
cx_class(ba, economy, economy, bhy, b).
cx_class(ba, economy, economy, bhy, h).
cx_class(ba, economy, economy, bhy, y).
cx_class(ba, economy, economy, klmnqsv, k).
cx_class(ba, economy, economy, klmnqsv, l).
cx_class(ba, economy, economy, klmnqsv, m).
cx_class(ba, economy, economy, klmnqsv, n).
cx_class(ba, economy, economy, klmnqsv, q).
cx_class(ba, economy, economy, klmnqsv, s).
cx_class(ba, economy, economy, klmnqsv, v).
cx_class(ca, first, first, a, a).
cx_class(ca, first, first, f, f).
cx_class(ca, business, business, cj, c).
cx_class(ca, business, business, cj, j).
cx_class(ca, business, business, drz, d).
cx_class(ca, business, business, drz, r).
cx_class(ca, business, business, drz, z).
cx_class(ca, premium_economy, premium_economy, e, e).
cx_class(ca, premium_economy, premium_economy, g, g).
cx_class(ca, economy, economy, by, b).
cx_class(ca, economy, economy, by, y).
cx_class(ca, economy, economy, mu, m).
cx_class(ca, economy, economy, mu, u).
cx_class(ca, economy, economy, hqstvw, h).
cx_class(ca, economy, economy, hqstvw, q).
cx_class(ca, economy, economy, hqstvw, s).
cx_class(ca, economy, economy, hqstvw, t).
cx_class(ca, economy, economy, hqstvw, v).
cx_class(ca, economy, economy, hqstvw, w).
cx_class(ca, economy, economy, klp, k).
cx_class(ca, economy, economy, klp, l).
cx_class(ca, economy, economy, klp, p).
cx_class(fj, business, business, cj, c).
cx_class(fj, business, business, cj, j).
cx_class(fj, business, business, diz, d).
cx_class(fj, business, business, diz, i).
cx_class(fj, business, business, diz, z).
cx_class(fj, economy, economy, bhky, b).
cx_class(fj, economy, economy, bhky, h).
cx_class(fj, economy, economy, bhky, k).
cx_class(fj, economy, economy, bhky, y).
cx_class(fj, economy, economy, lmw, l).
cx_class(fj, economy, economy, lmw, m).
cx_class(fj, economy, economy, lmw, w).
cx_class(fj, economy, economy, nsv, n).
cx_class(fj, economy, economy, nsv, s).
cx_class(fj, economy, economy, nsv, v).
cx_class(fj, economy, economy, afgopqrt, a).
cx_class(fj, economy, economy, afgopqrt, f).
cx_class(fj, economy, economy, afgopqrt, g).
cx_class(fj, economy, economy, afgopqrt, o).
cx_class(fj, economy, economy, afgopqrt, p).
cx_class(fj, economy, economy, afgopqrt, q).
cx_class(fj, economy, economy, afgopqrt, r).
cx_class(fj, economy, economy, afgopqrt, t).
cx_class(i2, business, business, cdijr, c).
cx_class(i2, business, business, cdijr, d).
cx_class(i2, business, business, cdijr, i).
cx_class(i2, business, business, cdijr, j).
cx_class(i2, business, business, cdijr, r).
cx_class(i2, premium_economy, premium_economy, et, e).
cx_class(i2, premium_economy, premium_economy, et, t).
cx_class(i2, premium_economy, premium_economy, w, w).
cx_class(i2, economy, economy, bhy, b).
cx_class(i2, economy, economy, bhy, h).
cx_class(i2, economy, economy, bhy, y).
cx_class(i2, economy, economy, fgklmnqsvz, f).
cx_class(i2, economy, economy, fgklmnqsvz, g).
cx_class(i2, economy, economy, fgklmnqsvz, k).
cx_class(i2, economy, economy, fgklmnqsvz, l).
cx_class(i2, economy, economy, fgklmnqsvz, m).
cx_class(i2, economy, economy, fgklmnqsvz, n).
cx_class(i2, economy, economy, fgklmnqsvz, q).
cx_class(i2, economy, economy, fgklmnqsvz, s).
cx_class(i2, economy, economy, fgklmnqsvz, v).
cx_class(i2, economy, economy, fgklmnqsvz, z).
cx_class(ib, business, business, cdijr, c).
cx_class(ib, business, business, cdijr, d).
cx_class(ib, business, business, cdijr, i).
cx_class(ib, business, business, cdijr, j).
cx_class(ib, business, business, cdijr, r).
cx_class(ib, premium_economy, premium_economy, et, e).
cx_class(ib, premium_economy, premium_economy, et, t).
cx_class(ib, premium_economy, premium_economy, w, w).
cx_class(ib, economy, economy, bhy, b).
cx_class(ib, economy, economy, bhy, h).
cx_class(ib, economy, economy, bhy, y).
cx_class(ib, economy, economy, fgklmnqsvz, f).
cx_class(ib, economy, economy, fgklmnqsvz, g).
cx_class(ib, economy, economy, fgklmnqsvz, k).
cx_class(ib, economy, economy, fgklmnqsvz, l).
cx_class(ib, economy, economy, fgklmnqsvz, m).
cx_class(ib, economy, economy, fgklmnqsvz, n).
cx_class(ib, economy, economy, fgklmnqsvz, q).
cx_class(ib, economy, economy, fgklmnqsvz, s).
cx_class(ib, economy, economy, fgklmnqsvz, v).
cx_class(ib, economy, economy, fgklmnqsvz, z).
cx_class(jl, first, first, af, a).
cx_class(jl, first, first, af, f).
cx_class(jl, first, first, e, e).
cx_class(jl, business, business, c, c).
cx_class(jl, business, business, h, h).
cx_class(jl, premium_economy, premium_economy, w, w).
cx_class(jl, premium_economy, premium_economy, p, p).
cx_class(jl, economy, economy, y, y).
cx_class(jl, economy, economy, j, j).
cx_class(jl, economy, economy, r, r).
cx_class(jl, economy, economy, ai, a).
cx_class(jl, economy, economy, ai, i).
cx_class(la, business, business, cdijz, c).
cx_class(la, business, business, cdijz, d).
cx_class(la, business, business, cdijz, i).
cx_class(la, business, business, cdijz, j).
cx_class(la, business, business, cdijz, z).
cx_class(la, premium_economy, premium_economy, pw, p).
cx_class(la, premium_economy, premium_economy, pw, w).
cx_class(la, economy, economy, bhklmnoqsvxy, b).
cx_class(la, economy, economy, bhklmnoqsvxy, h).
cx_class(la, economy, economy, bhklmnoqsvxy, k).
cx_class(la, economy, economy, bhklmnoqsvxy, l).
cx_class(la, economy, economy, bhklmnoqsvxy, m).
cx_class(la, economy, economy, bhklmnoqsvxy, n).
cx_class(la, economy, economy, bhklmnoqsvxy, o).
cx_class(la, economy, economy, bhklmnoqsvxy, q).
cx_class(la, economy, economy, bhklmnoqsvxy, s).
cx_class(la, economy, economy, bhklmnoqsvxy, v).
cx_class(la, economy, economy, bhklmnoqsvxy, x).
cx_class(la, economy, economy, bhklmnoqsvxy, y).
cx_class(lh, first, first, af, a).
cx_class(lh, first, first, af, f).
cx_class(lh, business, business, cdjz, c).
cx_class(lh, business, business, cdjz, d).
cx_class(lh, business, business, cdjz, j).
cx_class(lh, business, business, cdjz, z).
cx_class(lh, business, business, p, p).
cx_class(lh, premium_economy, premium_economy, eg, e).
cx_class(lh, premium_economy, premium_economy, eg, g).
cx_class(lh, premium_economy, premium_economy, n, n).
cx_class(lh, economy, economy, bmuy, b).
cx_class(lh, economy, economy, bmuy, m).
cx_class(lh, economy, economy, bmuy, u).
cx_class(lh, economy, economy, bmuy, y).
cx_class(lh, economy, economy, hqsvw, h).
cx_class(lh, economy, economy, hqsvw, q).
cx_class(lh, economy, economy, hqsvw, s).
cx_class(lh, economy, economy, hqsvw, v).
cx_class(lh, economy, economy, hqsvw, w).
cx_class(lx, first, first, af, a).
cx_class(lx, first, first, af, f).
cx_class(lx, business, business, cdjz, c).
cx_class(lx, business, business, cdjz, d).
cx_class(lx, business, business, cdjz, j).
cx_class(lx, business, business, cdjz, z).
cx_class(lx, business, business, p, p).
cx_class(lx, premium_economy, premium_economy, eg, e).
cx_class(lx, premium_economy, premium_economy, eg, g).
cx_class(lx, premium_economy, premium_economy, n, n).
cx_class(lx, economy, economy, bmuy, b).
cx_class(lx, economy, economy, bmuy, m).
cx_class(lx, economy, economy, bmuy, u).
cx_class(lx, economy, economy, bmuy, y).
cx_class(lx, economy, economy, hqsvw, h).
cx_class(lx, economy, economy, hqsvw, q).
cx_class(lx, economy, economy, hqsvw, s).
cx_class(lx, economy, economy, hqsvw, v).
cx_class(lx, economy, economy, hqsvw, w).
cx_class(mh, first, first, afp, a).
cx_class(mh, first, first, afp, f).
cx_class(mh, first, first, afp, p).
cx_class(mh, business, business, cdjz, c).
cx_class(mh, business, business, cdjz, d).
cx_class(mh, business, business, cdjz, j).
cx_class(mh, business, business, cdjz, z).
cx_class(mh, economy, economy, bhy, b).
cx_class(mh, economy, economy, bhy, h).
cx_class(mh, economy, economy, bhy, y).
cx_class(mh, economy, economy, km, k).
cx_class(mh, economy, economy, km, m).
cx_class(nu, first, first, f, f).
cx_class(nu, first, first, e, e).
cx_class(nu, business, business, c, c).
cx_class(nu, business, business, h, h).
cx_class(nu, premium_economy, premium_economy, w, w).
cx_class(nu, premium_economy, premium_economy, p, p).
cx_class(nu, economy, economy, jy, j).
cx_class(nu, economy, economy, jy, y).
cx_class(nu, economy, economy, ai, a).
cx_class(nu, economy, economy, ai, i).
cx_class(nu, economy, economy, r, r).
cx_class(nz, business, business, cdjz, c).
cx_class(nz, business, business, cdjz, d).
cx_class(nz, business, business, cdjz, j).
cx_class(nz, business, business, cdjz, z).
cx_class(nz, premium_economy, premium_economy, aeou, a).
cx_class(nz, premium_economy, premium_economy, aeou, e).
cx_class(nz, premium_economy, premium_economy, aeou, o).
cx_class(nz, premium_economy, premium_economy, aeou, u).
cx_class(nz, economy, economy, bmy, b).
cx_class(nz, economy, economy, bmy, m).
cx_class(nz, economy, economy, bmy, y).
cx_class(nz, economy, economy, hqtvw, h).
cx_class(nz, economy, economy, hqtvw, q).
cx_class(nz, economy, economy, hqtvw, t).
cx_class(nz, economy, economy, hqtvw, v).
cx_class(nz, economy, economy, hqtvw, w).
cx_class(os, business, business, cdjz, c).
cx_class(os, business, business, cdjz, d).
cx_class(os, business, business, cdjz, j).
cx_class(os, business, business, cdjz, z).
cx_class(os, business, business, p, p).
cx_class(os, economy, economy, bmuy, b).
cx_class(os, economy, economy, bmuy, m).
cx_class(os, economy, economy, bmuy, u).
cx_class(os, economy, economy, bmuy, y).
cx_class(os, economy, economy, hqsvw, h).
cx_class(os, economy, economy, hqsvw, q).
cx_class(os, economy, economy, hqsvw, s).
cx_class(os, economy, economy, hqsvw, v).
cx_class(os, economy, economy, hqsvw, w).
cx_class(pg, business, business, cd, c).
cx_class(pg, business, business, cd, d).
cx_class(pg, economy, economy, hklmnty, h).
cx_class(pg, economy, economy, hklmnty, k).
cx_class(pg, economy, economy, hklmnty, l).
cx_class(pg, economy, economy, hklmnty, m).
cx_class(pg, economy, economy, hklmnty, n).
cx_class(pg, economy, economy, hklmnty, t).
cx_class(pg, economy, economy, hklmnty, y).
cx_class(pg, economy, economy, bgqv, b).
cx_class(pg, economy, economy, bgqv, g).
cx_class(pg, economy, economy, bgqv, q).
cx_class(pg, economy, economy, bgqv, v).
cx_class(qf, first, first, af, a).
cx_class(qf, first, first, af, f).
cx_class(qf, business, business, cdij, c).
cx_class(qf, business, business, cdij, d).
cx_class(qf, business, business, cdij, i).
cx_class(qf, business, business, cdij, j).
cx_class(qf, premium_economy, premium_economy, rtw, r).
cx_class(qf, premium_economy, premium_economy, rtw, t).
cx_class(qf, premium_economy, premium_economy, rtw, w).
cx_class(qf, economy, economy, y, y).
cx_class(qf, economy, economy, bhklmv, b).
cx_class(qf, economy, economy, bhklmv, h).
cx_class(qf, economy, economy, bhklmv, k).
cx_class(qf, economy, economy, bhklmv, l).
cx_class(qf, economy, economy, bhklmv, m).
cx_class(qf, economy, economy, bhklmv, v).
cx_class(qr, first, first, af, a).
cx_class(qr, first, first, af, f).
cx_class(qr, business, business, cdijr, c).
cx_class(qr, business, business, cdijr, d).
cx_class(qr, business, business, cdijr, i).
cx_class(qr, business, business, cdijr, j).
cx_class(qr, business, business, cdijr, r).
cx_class(qr, business, business, p, p).
cx_class(qr, economy, economy, bhy, b).
cx_class(qr, economy, economy, bhy, h).
cx_class(qr, economy, economy, bhy, y).
cx_class(qr, economy, economy, klmv, k).
cx_class(qr, economy, economy, klmv, l).
cx_class(qr, economy, economy, klmv, m).
cx_class(qr, economy, economy, klmv, v).
cx_class(qr, economy, economy, gnqs, g).
cx_class(qr, economy, economy, gnqs, n).
cx_class(qr, economy, economy, gnqs, q).
cx_class(qr, economy, economy, gnqs, s).
cx_class(rj, business, business, cdj, c).
cx_class(rj, business, business, cdj, d).
cx_class(rj, business, business, cdj, j).
cx_class(rj, business, business, iz, i).
cx_class(rj, business, business, iz, z).
cx_class(rj, economy, economy, y, y).
cx_class(rj, economy, economy, bhk, b).
cx_class(rj, economy, economy, bhk, h).
cx_class(rj, economy, economy, bhk, k).
cx_class(rj, economy, economy, lmnqsv, l).
cx_class(rj, economy, economy, lmnqsv, m).
cx_class(rj, economy, economy, lmnqsv, n).
cx_class(rj, economy, economy, lmnqsv, q).
cx_class(rj, economy, economy, lmnqsv, s).
cx_class(rj, economy, economy, lmnqsv, v).
cx_class(ul, business, business, cdj, c).
cx_class(ul, business, business, cdj, d).
cx_class(ul, business, business, cdj, j).
cx_class(ul, business, business, i, i).
cx_class(ul, economy, economy, bhpy, b).
cx_class(ul, economy, economy, bhpy, h).
cx_class(ul, economy, economy, bhpy, p).
cx_class(ul, economy, economy, bhpy, y).
cx_class(ul, economy, economy, ekmw, e).
cx_class(ul, economy, economy, ekmw, k).
cx_class(ul, economy, economy, ekmw, m).
cx_class(ul, economy, economy, ekmw, w).
cx_class(ul, economy, economy, lrsv, l).
cx_class(ul, economy, economy, lrsv, r).
cx_class(ul, economy, economy, lrsv, s).
cx_class(ul, economy, economy, lrsv, v).
cx_class(ul, economy, economy, n, n).
cx_class(wy, first, first, af, a).
cx_class(wy, first, first, af, f).
cx_class(wy, business, business, cdijp, c).
cx_class(wy, business, business, cdijp, d).
cx_class(wy, business, business, cdijp, i).
cx_class(wy, business, business, cdijp, j).
cx_class(wy, business, business, cdijp, p).
cx_class(wy, economy, economy, y, y).
cx_class(wy, economy, economy, b, b).
cx_class(wy, economy, economy, hklmnoqrstv, h).
cx_class(wy, economy, economy, hklmnoqrstv, k).
cx_class(wy, economy, economy, hklmnoqrstv, l).
cx_class(wy, economy, economy, hklmnoqrstv, m).
cx_class(wy, economy, economy, hklmnoqrstv, n).
cx_class(wy, economy, economy, hklmnoqrstv, o).
cx_class(wy, economy, economy, hklmnoqrstv, q).
cx_class(wy, economy, economy, hklmnoqrstv, r).
cx_class(wy, economy, economy, hklmnoqrstv, s).
cx_class(wy, economy, economy, hklmnoqrstv, t).
cx_class(wy, economy, economy, hklmnoqrstv, v).
cx_class(zh, business, business, cj, c).
cx_class(zh, business, business, cj, j).
cx_class(zh, business, business, drz, d).
cx_class(zh, business, business, drz, r).
cx_class(zh, business, business, drz, z).
cx_class(zh, premium_economy, premium_economy, e, e).
cx_class(zh, premium_economy, premium_economy, g, g).
cx_class(zh, economy, economy, bhmuy, b).
cx_class(zh, economy, economy, bhmuy, h).
cx_class(zh, economy, economy, bhmuy, m).
cx_class(zh, economy, economy, bhmuy, u).
cx_class(zh, economy, economy, bhmuy, y).
cx_class(zh, economy, economy, qstvw, q).
cx_class(zh, economy, economy, qstvw, s).
cx_class(zh, economy, economy, qstvw, t).
cx_class(zh, economy, economy, qstvw, v).
cx_class(zh, economy, economy, qstvw, w).
cx_class(zh, economy, economy, aklp, a).
cx_class(zh, economy, economy, aklp, k).
cx_class(zh, economy, economy, aklp, l).
cx_class(zh, economy, economy, aklp, p).

%! cx_group_label(?Group, ?Label) is nondet.
%  The class group as the table writes it, so a figure can be checked against the
%  published row rather than against a key this file invented.
cx_group_label(af, 'A F').
cx_group_label(cj, 'C J').
cx_group_label(dip, 'D I P').
cx_group_label(e, 'E').
cx_group_label(rw, 'R W').
cx_group_label(bhky, 'B H K Y').
cx_group_label(lmv, 'L M V').
cx_group_label(noqs, 'N O Q S').
cx_group_label(cdijr, 'C D I J R').
cx_group_label(p, 'P').
cx_group_label(w, 'W').
cx_group_label(y, 'Y').
cx_group_label(hklmv, 'H K L M V').
cx_group_label(gnqs, 'G N Q S').
cx_group_label(cdjpz, 'C D J P Z').
cx_group_label(aeo, 'A E O').
cx_group_label(bhmquvwy, 'B H M Q U V W Y').
cx_group_label(gklst, 'G K L S T').
cx_group_label(acdfij, 'A C D F I J').
cx_group_label(bhklmnsvy, 'B H K L M N S V Y').
cx_group_label(goq, 'G O Q').
cx_group_label(cdij, 'C D I J').
cx_group_label(bh, 'B H').
cx_group_label(klm, 'K L M').
cx_group_label(cdj, 'C D J').
cx_group_label(ir, 'I R').
cx_group_label(eptw, 'E P T W').
cx_group_label(bhkmy, 'B H K M Y').
cx_group_label(lv, 'L V').
cx_group_label(et, 'E T').
cx_group_label(bhy, 'B H Y').
cx_group_label(klmnqsv, 'K L M N Q S V').
cx_group_label(a, 'A').
cx_group_label(f, 'F').
cx_group_label(drz, 'D R Z').
cx_group_label(g, 'G').
cx_group_label(by, 'B Y').
cx_group_label(mu, 'M U').
cx_group_label(hqstvw, 'H Q S T V W').
cx_group_label(klp, 'K L P').
cx_group_label(diz, 'D I Z').
cx_group_label(lmw, 'L M W').
cx_group_label(nsv, 'N S V').
cx_group_label(afgopqrt, 'A F G O P Q R T').
cx_group_label(fgklmnqsvz, 'F G K L M N Q S V Z').
cx_group_label(c, 'C').
cx_group_label(h, 'H').
cx_group_label(j, 'J').
cx_group_label(r, 'R').
cx_group_label(ai, 'A I').
cx_group_label(cdijz, 'C D I J Z').
cx_group_label(pw, 'P W').
cx_group_label(bhklmnoqsvxy, 'B H K L M N O Q S V X Y').
cx_group_label(cdjz, 'C D J Z').
cx_group_label(eg, 'E G').
cx_group_label(n, 'N').
cx_group_label(bmuy, 'B M U Y').
cx_group_label(hqsvw, 'H Q S V W').
cx_group_label(afp, 'A F P').
cx_group_label(km, 'K M').
cx_group_label(jy, 'J Y').
cx_group_label(aeou, 'A E O U').
cx_group_label(bmy, 'B M Y').
cx_group_label(hqtvw, 'H Q T V W').
cx_group_label(cd, 'C D').
cx_group_label(hklmnty, 'H K L M N T Y').
cx_group_label(bgqv, 'B G Q V').
cx_group_label(rtw, 'R T W').
cx_group_label(bhklmv, 'B H K L M V').
cx_group_label(klmv, 'K L M V').
cx_group_label(iz, 'I Z').
cx_group_label(bhk, 'B H K').
cx_group_label(lmnqsv, 'L M N Q S V').
cx_group_label(i, 'I').
cx_group_label(bhpy, 'B H P Y').
cx_group_label(ekmw, 'E K M W').
cx_group_label(lrsv, 'L R S V').
cx_group_label(cdijp, 'C D I J P').
cx_group_label(b, 'B').
cx_group_label(hklmnoqrstv, 'H K L M N O Q R S T V').
cx_group_label(bhmuy, 'B H M U Y').
cx_group_label(qstvw, 'Q S T V W').
cx_group_label(aklp, 'A K L P').

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
