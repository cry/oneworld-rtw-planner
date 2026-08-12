:- module(qff_categories,
          [ earn_category/4,
            earn_category_unpublished/3,
            earn_scope/2,
            earn_categories/1
          ]).

/** <module> Qantas Frequent Flyer earn categories. GENERATED -- do not edit.

    Built by prolog/tools/build_qff_tables.mjs from
    data/earn/sources/qff-categories.json, read 2026-08-11 from
    https://www.qantas.com/en-au/frequent-flyer/calculators/earning-tables/categories

    Which category a segment earns in, from the marketing carrier and the class
    it is sold in. The category is then priced by data/earn/qff/bands.pl.

    Only the sixteen carriers Rule 3015 4(j) permits are here; Qantas publishes
    categories for airlines an Explorer fare may not be flown on at all.

    Rows superseded by a later effective date are dropped rather than carried,
    because nothing yet reads an effective date -- see PLANS/05, phase 4. The
    dates that were in force at the capture are recorded in source.pl.
*/

%! earn_scope(?Scope, ?Kind) is nondet.
%  How a scope is decided for a segment. `always` applies to everything,
%  `sector` is decided from the two endpoints, `residual` applies when no
%  sector scope of the same carrier did, and `region` needs the region tables
%  that phase 2 adds -- until then a segment that could fall either side of one
%  is priced only where the candidate rows agree.
earn_scope(all,           always).
earn_scope(international, sector).
earn_scope(domestic,      sector).
earn_scope(within_fiji,   sector).
earn_scope(within_japan,  sector).
earn_scope(all_other,     residual).
earn_scope(long_haul,     region).
earn_scope(named_routes,  region).

%! earn_categories(-Categories) is det.
%  The six columns of the partner earning table, in published order.
earn_categories([discount_economy, economy, flexible_economy, premium_economy, business, first]).

%! earn_category(?Carrier, ?Scope, ?Class, ?Category) is nondet.
earn_category(aa, all, n, discount_economy).
earn_category(aa, all, o, discount_economy).
earn_category(aa, all, q, discount_economy).
earn_category(aa, all, g, economy).
earn_category(aa, all, k, economy).
earn_category(aa, all, l, economy).
earn_category(aa, all, m, economy).
earn_category(aa, all, s, economy).
earn_category(aa, all, v, economy).
earn_category(aa, all, h, flexible_economy).
earn_category(aa, all, y, flexible_economy).
earn_category(aa, all, p, premium_economy).
earn_category(aa, all, w, premium_economy).
earn_category(aa, all, c, business).
earn_category(aa, all, d, business).
earn_category(aa, all, i, business).
earn_category(aa, all, j, business).
earn_category(aa, all, r, business).
earn_category(aa, all, a, first).
earn_category(aa, all, f, first).
earn_category(as, all, g, discount_economy).
earn_category(as, all, o, discount_economy).
earn_category(as, all, q, discount_economy).
earn_category(as, all, x, discount_economy).
earn_category(as, all, k, economy).
earn_category(as, all, l, economy).
earn_category(as, all, m, economy).
earn_category(as, all, n, economy).
earn_category(as, all, s, economy).
earn_category(as, all, v, economy).
earn_category(as, all, b, flexible_economy).
earn_category(as, all, h, flexible_economy).
earn_category(as, all, y, flexible_economy).
earn_category(as, all, c, business).
earn_category(as, all, d, business).
earn_category(as, all, i, business).
earn_category(as, all, j, business).
earn_category(as, all, a, first).
earn_category(as, all, f, first).
earn_category(at, all, n, discount_economy).
earn_category(at, all, o, discount_economy).
earn_category(at, all, q, discount_economy).
earn_category(at, all, r, discount_economy).
earn_category(at, all, s, discount_economy).
earn_category(at, all, t, discount_economy).
earn_category(at, all, w, discount_economy).
earn_category(at, all, h, economy).
earn_category(at, all, k, economy).
earn_category(at, all, l, economy).
earn_category(at, all, m, economy).
earn_category(at, all, v, economy).
earn_category(at, all, b, flexible_economy).
earn_category(at, all, y, flexible_economy).
earn_category(at, all, c, business).
earn_category(at, all, d, business).
earn_category(at, all, i, business).
earn_category(at, all, j, business).
earn_category(ay, all, a, discount_economy).
earn_category(ay, all, g, economy).
earn_category(ay, all, l, economy).
earn_category(ay, all, n, economy).
earn_category(ay, all, o, economy).
earn_category(ay, all, q, economy).
earn_category(ay, all, s, economy).
earn_category(ay, all, v, economy).
earn_category(ay, all, z, economy).
earn_category(ay, all, b, flexible_economy).
earn_category(ay, all, h, flexible_economy).
earn_category(ay, all, k, flexible_economy).
earn_category(ay, all, y, flexible_economy).
earn_category(ay, all, m, flexible_economy).
earn_category(ay, all, e, premium_economy).
earn_category(ay, all, p, premium_economy).
earn_category(ay, all, t, premium_economy).
earn_category(ay, all, w, premium_economy).
earn_category(ay, all, c, business).
earn_category(ay, all, d, business).
earn_category(ay, all, i, business).
earn_category(ay, all, j, business).
earn_category(ay, all, r, business).
earn_category(ba, all, g, discount_economy).
earn_category(ba, all, k, discount_economy).
earn_category(ba, all, l, discount_economy).
earn_category(ba, all, m, discount_economy).
earn_category(ba, all, n, discount_economy).
earn_category(ba, all, o, discount_economy).
earn_category(ba, all, q, discount_economy).
earn_category(ba, all, s, discount_economy).
earn_category(ba, all, v, discount_economy).
earn_category(ba, all, b, flexible_economy).
earn_category(ba, all, e, flexible_economy).
earn_category(ba, all, h, flexible_economy).
earn_category(ba, all, t, flexible_economy).
earn_category(ba, all, w, flexible_economy).
earn_category(ba, all, y, flexible_economy).
earn_category(ba, all, c, business).
earn_category(ba, all, d, business).
earn_category(ba, all, i, business).
earn_category(ba, all, r, business).
earn_category(ba, all, j, business).
earn_category(ba, all, a, first).
earn_category(ba, all, f, first).
earn_category(cx, all, m, discount_economy).
earn_category(cx, all, l, discount_economy).
earn_category(cx, all, b, economy).
earn_category(cx, all, h, economy).
earn_category(cx, all, k, economy).
earn_category(cx, all, y, flexible_economy).
earn_category(cx, all, e, flexible_economy).
earn_category(cx, all, r, premium_economy).
earn_category(cx, all, w, premium_economy).
earn_category(cx, all, c, business).
earn_category(cx, all, d, business).
earn_category(cx, all, i, business).
earn_category(cx, all, j, business).
earn_category(cx, all, p, business).
earn_category(cx, all, a, first).
earn_category(cx, all, f, first).
earn_category(fj, all_other, g, discount_economy).
earn_category(fj, all_other, n, discount_economy).
earn_category(fj, all_other, t, discount_economy).
earn_category(fj, all_other, v, discount_economy).
earn_category(fj, all_other, k, economy).
earn_category(fj, all_other, l, economy).
earn_category(fj, all_other, m, economy).
earn_category(fj, all_other, o, economy).
earn_category(fj, all_other, q, economy).
earn_category(fj, all_other, s, economy).
earn_category(fj, all_other, w, economy).
earn_category(fj, all_other, b, flexible_economy).
earn_category(fj, all_other, h, flexible_economy).
earn_category(fj, all_other, y, flexible_economy).
earn_category(fj, all_other, c, business).
earn_category(fj, all_other, d, business).
earn_category(fj, all_other, i, business).
earn_category(fj, all_other, j, business).
earn_category(fj, all_other, z, business).
earn_category(fj, within_fiji, h, flexible_economy).
earn_category(fj, within_fiji, l, flexible_economy).
earn_category(fj, within_fiji, q, flexible_economy).
earn_category(fj, within_fiji, y, flexible_economy).
earn_category(ib, all, a, discount_economy).
earn_category(ib, all, f, discount_economy).
earn_category(ib, all, g, discount_economy).
earn_category(ib, all, n, discount_economy).
earn_category(ib, all, o, discount_economy).
earn_category(ib, all, q, discount_economy).
earn_category(ib, all, z, discount_economy).
earn_category(ib, all, k, economy).
earn_category(ib, all, l, economy).
earn_category(ib, all, m, economy).
earn_category(ib, all, s, economy).
earn_category(ib, all, v, economy).
earn_category(ib, all, b, flexible_economy).
earn_category(ib, all, h, flexible_economy).
earn_category(ib, all, y, flexible_economy).
earn_category(ib, all, e, premium_economy).
earn_category(ib, all, t, premium_economy).
earn_category(ib, all, w, premium_economy).
earn_category(ib, all, c, business).
earn_category(ib, all, d, business).
earn_category(ib, all, i, business).
earn_category(ib, all, j, business).
earn_category(ib, all, r, business).
earn_category(jl, all_other, g, discount_economy).
earn_category(jl, all_other, n, discount_economy).
earn_category(jl, all_other, o, discount_economy).
earn_category(jl, all_other, q, discount_economy).
earn_category(jl, all_other, z, discount_economy).
earn_category(jl, all_other, h, economy).
earn_category(jl, all_other, k, economy).
earn_category(jl, all_other, l, economy).
earn_category(jl, all_other, m, economy).
earn_category(jl, all_other, s, economy).
earn_category(jl, all_other, v, economy).
earn_category(jl, all_other, b, flexible_economy).
earn_category(jl, all_other, y, flexible_economy).
earn_category(jl, all_other, e, premium_economy).
earn_category(jl, all_other, w, premium_economy).
earn_category(jl, all_other, p, premium_economy).
earn_category(jl, all_other, r, premium_economy).
earn_category(jl, all_other, c, business).
earn_category(jl, all_other, d, business).
earn_category(jl, all_other, i, business).
earn_category(jl, all_other, j, business).
earn_category(jl, all_other, x, business).
earn_category(jl, all_other, a, first).
earn_category(jl, all_other, f, first).
earn_category(mh, all_other, k, discount_economy).
earn_category(mh, all_other, l, discount_economy).
earn_category(mh, all_other, m, discount_economy).
earn_category(mh, all_other, v, discount_economy).
earn_category(mh, all_other, y, economy).
earn_category(mh, all_other, b, economy).
earn_category(mh, all_other, h, economy).
earn_category(mh, all_other, z, flexible_economy).
earn_category(mh, all_other, c, business).
earn_category(mh, all_other, d, business).
earn_category(mh, all_other, j, business).
earn_category(mh, all_other, a, first).
earn_category(mh, all_other, f, first).
earn_category(mh, long_haul, k, discount_economy).
earn_category(mh, long_haul, l, discount_economy).
earn_category(mh, long_haul, m, discount_economy).
earn_category(mh, long_haul, v, discount_economy).
earn_category(mh, long_haul, y, economy).
earn_category(mh, long_haul, b, economy).
earn_category(mh, long_haul, h, economy).
earn_category(mh, long_haul, z, flexible_economy).
earn_category(mh, long_haul, a, business).
earn_category(mh, long_haul, f, business).
earn_category(mh, long_haul, c, business).
earn_category(mh, long_haul, d, business).
earn_category(mh, long_haul, j, business).
earn_category(nu, all_other, g, discount_economy).
earn_category(nu, all_other, n, discount_economy).
earn_category(nu, all_other, o, discount_economy).
earn_category(nu, all_other, q, discount_economy).
earn_category(nu, all_other, z, discount_economy).
earn_category(nu, all_other, h, economy).
earn_category(nu, all_other, k, economy).
earn_category(nu, all_other, l, economy).
earn_category(nu, all_other, m, economy).
earn_category(nu, all_other, s, economy).
earn_category(nu, all_other, v, economy).
earn_category(nu, all_other, b, flexible_economy).
earn_category(nu, all_other, y, flexible_economy).
earn_category(nu, all_other, e, premium_economy).
earn_category(nu, all_other, w, premium_economy).
earn_category(nu, all_other, p, premium_economy).
earn_category(nu, all_other, r, premium_economy).
earn_category(nu, all_other, c, business).
earn_category(nu, all_other, d, business).
earn_category(nu, all_other, i, business).
earn_category(nu, all_other, j, business).
earn_category(nu, all_other, x, business).
earn_category(nu, all_other, a, first).
earn_category(nu, all_other, f, first).
earn_category(qf, international, e, discount_economy).
earn_category(qf, international, n, discount_economy).
earn_category(qf, international, o, discount_economy).
earn_category(qf, international, q, discount_economy).
earn_category(qf, international, g, economy).
earn_category(qf, international, k, economy).
earn_category(qf, international, l, economy).
earn_category(qf, international, m, economy).
earn_category(qf, international, s, economy).
earn_category(qf, international, v, economy).
earn_category(qf, international, b, flexible_economy).
earn_category(qf, international, h, flexible_economy).
earn_category(qf, international, y, flexible_economy).
earn_category(qf, international, r, premium_economy).
earn_category(qf, international, d, business).
earn_category(qf, international, a, first).
earn_category(qf, international, f, first).
earn_category(qf, domestic, e, discount_economy).
earn_category(qf, domestic, g, discount_economy).
earn_category(qf, domestic, l, discount_economy).
earn_category(qf, domestic, m, discount_economy).
earn_category(qf, domestic, n, discount_economy).
earn_category(qf, domestic, o, discount_economy).
earn_category(qf, domestic, q, discount_economy).
earn_category(qf, domestic, s, discount_economy).
earn_category(qf, domestic, v, discount_economy).
earn_category(qf, domestic, b, flexible_economy).
earn_category(qf, domestic, h, flexible_economy).
earn_category(qf, domestic, k, flexible_economy).
earn_category(qf, domestic, y, flexible_economy).
earn_category(qf, domestic, r, premium_economy).
earn_category(qf, domestic, d, business).
earn_category(qf, domestic, i, business).
earn_category(qr, all, k, discount_economy).
earn_category(qr, all, l, discount_economy).
earn_category(qr, all, m, discount_economy).
earn_category(qr, all, v, discount_economy).
earn_category(qr, all, b, economy).
earn_category(qr, all, h, economy).
earn_category(qr, all, y, flexible_economy).
earn_category(qr, all, c, business).
earn_category(qr, all, d, business).
earn_category(qr, all, i, business).
earn_category(qr, all, j, business).
earn_category(qr, all, p, business).
earn_category(qr, all, r, business).
earn_category(qr, all, a, first).
earn_category(qr, all, f, first).
earn_category(rj, all, v, discount_economy).
earn_category(rj, all, s, discount_economy).
earn_category(rj, all, n, discount_economy).
earn_category(rj, all, q, discount_economy).
earn_category(rj, all, o, discount_economy).
earn_category(rj, all, p, discount_economy).
earn_category(rj, all, w, discount_economy).
earn_category(rj, all, k, economy).
earn_category(rj, all, m, economy).
earn_category(rj, all, l, economy).
earn_category(rj, all, b, flexible_economy).
earn_category(rj, all, y, flexible_economy).
earn_category(rj, all, h, flexible_economy).
earn_category(rj, all, i, premium_economy).
earn_category(rj, all, z, premium_economy).
earn_category(rj, all, c, business).
earn_category(rj, all, d, business).
earn_category(rj, all, j, business).
earn_category(ul, all_other, g, discount_economy).
earn_category(ul, all_other, l, discount_economy).
earn_category(ul, all_other, n, discount_economy).
earn_category(ul, all_other, o, discount_economy).
earn_category(ul, all_other, q, discount_economy).
earn_category(ul, all_other, r, discount_economy).
earn_category(ul, all_other, s, discount_economy).
earn_category(ul, all_other, v, discount_economy).
earn_category(ul, all_other, e, economy).
earn_category(ul, all_other, k, economy).
earn_category(ul, all_other, m, economy).
earn_category(ul, all_other, w, economy).
earn_category(ul, all_other, b, flexible_economy).
earn_category(ul, all_other, h, flexible_economy).
earn_category(ul, all_other, p, flexible_economy).
earn_category(ul, all_other, y, flexible_economy).
earn_category(ul, all_other, c, business).
earn_category(ul, all_other, d, business).
earn_category(ul, all_other, i, business).
earn_category(ul, all_other, j, business).
earn_category(ul, named_routes, e, discount_economy).
earn_category(ul, named_routes, g, discount_economy).
earn_category(ul, named_routes, k, discount_economy).
earn_category(ul, named_routes, l, discount_economy).
earn_category(ul, named_routes, m, discount_economy).
earn_category(ul, named_routes, n, discount_economy).
earn_category(ul, named_routes, o, discount_economy).
earn_category(ul, named_routes, q, discount_economy).
earn_category(ul, named_routes, r, discount_economy).
earn_category(ul, named_routes, s, discount_economy).
earn_category(ul, named_routes, w, discount_economy).
earn_category(ul, named_routes, b, economy).
earn_category(ul, named_routes, h, economy).
earn_category(ul, named_routes, p, economy).
earn_category(ul, named_routes, y, flexible_economy).
earn_category(ul, named_routes, c, business).
earn_category(ul, named_routes, d, business).
earn_category(ul, named_routes, i, business).
earn_category(ul, named_routes, j, business).
earn_category(wy, all, n, discount_economy).
earn_category(wy, all, q, discount_economy).
earn_category(wy, all, o, discount_economy).
earn_category(wy, all, r, discount_economy).
earn_category(wy, all, t, discount_economy).
earn_category(wy, all, e, discount_economy).
earn_category(wy, all, m, economy).
earn_category(wy, all, l, economy).
earn_category(wy, all, v, economy).
earn_category(wy, all, s, economy).
earn_category(wy, all, y, flexible_economy).
earn_category(wy, all, b, flexible_economy).
earn_category(wy, all, h, flexible_economy).
earn_category(wy, all, k, flexible_economy).
earn_category(wy, all, j, business).
earn_category(wy, all, c, business).
earn_category(wy, all, d, business).
earn_category(wy, all, i, business).
earn_category(wy, all, p, business).
earn_category(wy, all, f, first).
earn_category(wy, all, a, first).

%! earn_category_unpublished(?Carrier, ?Scope, ?Reason) is nondet.
%  A row the table names but does not fill in. It is not an absence of earn:
%  it is an earn this table cannot state, so it must reach the reader as
%  undecided rather than as nothing.
earn_category_unpublished(jl, within_japan, 'awarded on information provided by Japan Airlines; not tabulated').
earn_category_unpublished(nu, within_japan, 'awarded on information provided by Japan Airlines; not tabulated').
