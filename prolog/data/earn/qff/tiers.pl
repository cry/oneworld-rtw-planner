:- module(qff_tiers, [qff_tier/3, qff_tier_currency/1, qff_tier_carrier/1]).

/** <module> Qantas Frequent Flyer status bonus. GENERATED -- do not edit.

    Built by prolog/tools/build_qff_tables.mjs from
    data/earn/sources/qff-tiers.json.

    Qantas Points only. Status Credits take no tier bonus, and neither currency takes one on a partner-marketed sector -- the bonus is a Qantas-flight benefit.

    Two conditions, and both matter. The bonus is on Qantas Points and not on
    Status Credits, which is the currency's own `bonus_applies` flag rather
    than anything the kernel decides. And it is a Qantas-flight benefit: a
    partner-marketed sector earns the base rate whatever the member's tier, so
    the same journey can carry a bonus on one sector and none on the next.

    A Qantas flight number. Qantas describes the bonus as applying to eligible Qantas and Jetstar flights, which is how every other row of its earning tables is selected; an Explorer fare cannot be flown on Jetstar as the marketing carrier, so QF is the whole of it here.
*/

%! qff_tier(?Tier, ?Label, ?BonusPercent) is nondet.
qff_tier(bronze, 'Bronze', 0).
qff_tier(silver, 'Silver', 50).
qff_tier(gold, 'Gold', 75).
qff_tier(platinum, 'Platinum', 100).
qff_tier(platinum_one, 'Platinum One', 100).

%! qff_tier_currency(?Currency) is nondet.
%  The currencies a tier bonus reaches.
qff_tier_currency(points).

%! qff_tier_carrier(?Carrier) is nondet.
%  The marketing carriers whose sectors carry it.
qff_tier_carrier(qf).
