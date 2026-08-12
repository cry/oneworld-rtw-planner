:- module(cx_buckets, [cx_class/4, cx_bucket/3, cx_cabin_label/2, cx_family/1]).

/** <module> Cathay fare buckets. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/cx-marketed.json, read 2026-08-11 from
    https://www.cathaypacific.com/cx/en_US/membership/news-and-updates/Changes-to-your-Status-Points-and-Asia-Miles-earnings-on-flights.html

    A bucket is a cabin, a fare family and a class group. The family is an axis
    of its own rather than something the class implies: the Economy table lists
    Y,B,H,K under Flex, Essential and Light with different earn against each, so
    a ticket that names a class and not a family has bought one of three things
    and the honest answer is the spread.

    Business publishes one row for Flex and one shared row for "Essential,
    Light"; it is written out under both families with the same rates, so
    nothing downstream needs to know the row was shared.
*/

%! cx_family(?Family) is nondet.
cx_family(flex).
cx_family(essential).
cx_family(light).

%! cx_bucket(?Cabin, ?Family, ?Group) is nondet.
cx_bucket(economy, flex, ybhk).
cx_bucket(economy, essential, ybhk).
cx_bucket(economy, light, ybhk).
cx_bucket(economy, flex, mlv).
cx_bucket(economy, essential, mlv).
cx_bucket(economy, light, mlv).
cx_bucket(economy, flex, snqo).
cx_bucket(economy, essential, snqo).
cx_bucket(economy, light, snqo).
cx_bucket(premium_economy, flex, wr).
cx_bucket(premium_economy, essential, e).
cx_bucket(business, flex, jc).
cx_bucket(business, essential, dpi).
cx_bucket(business, light, dpi).
cx_bucket(first, flex, fa).

%! cx_class(?Cabin, ?Family, ?Group, ?Class) is nondet.
cx_class(economy, flex, ybhk, y).
cx_class(economy, flex, ybhk, b).
cx_class(economy, flex, ybhk, h).
cx_class(economy, flex, ybhk, k).
cx_class(economy, essential, ybhk, y).
cx_class(economy, essential, ybhk, b).
cx_class(economy, essential, ybhk, h).
cx_class(economy, essential, ybhk, k).
cx_class(economy, light, ybhk, y).
cx_class(economy, light, ybhk, b).
cx_class(economy, light, ybhk, h).
cx_class(economy, light, ybhk, k).
cx_class(economy, flex, mlv, m).
cx_class(economy, flex, mlv, l).
cx_class(economy, flex, mlv, v).
cx_class(economy, essential, mlv, m).
cx_class(economy, essential, mlv, l).
cx_class(economy, essential, mlv, v).
cx_class(economy, light, mlv, m).
cx_class(economy, light, mlv, l).
cx_class(economy, light, mlv, v).
cx_class(economy, flex, snqo, s).
cx_class(economy, flex, snqo, n).
cx_class(economy, flex, snqo, q).
cx_class(economy, flex, snqo, o).
cx_class(economy, essential, snqo, s).
cx_class(economy, essential, snqo, n).
cx_class(economy, essential, snqo, q).
cx_class(economy, essential, snqo, o).
cx_class(economy, light, snqo, s).
cx_class(economy, light, snqo, n).
cx_class(economy, light, snqo, q).
cx_class(economy, light, snqo, o).
cx_class(premium_economy, flex, wr, w).
cx_class(premium_economy, flex, wr, r).
cx_class(premium_economy, essential, e, e).
cx_class(business, flex, jc, j).
cx_class(business, flex, jc, c).
cx_class(business, essential, dpi, d).
cx_class(business, essential, dpi, p).
cx_class(business, essential, dpi, i).
cx_class(business, light, dpi, d).
cx_class(business, light, dpi, p).
cx_class(business, light, dpi, i).
cx_class(first, flex, fa, f).
cx_class(first, flex, fa, a).

%! cx_cabin_label(?Cabin, ?Label) is nondet.
cx_cabin_label(economy,         'Economy').
cx_cabin_label(premium_economy, 'Premium Economy').
cx_cabin_label(business,        'Business').
cx_cabin_label(first,           'First').
