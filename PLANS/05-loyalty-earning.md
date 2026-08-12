# What the ticket earns

## The problem

The validator answers "may this itinerary be sold as an Explorer fare". It does not answer the
question every traveller asks next, which is what the ticket is worth: how many points, miles and
status currency a routing earns, and — since an Explorer fare can be credited to any oneworld
programme — which programme to credit it to.

That is a different question with a different shape. It runs no fare rules, it needs input the
validator does not (a booked class, a member tier), and its data comes from airline loyalty pages
rather than from a tariff. So it is a fourth operation beside `validate`, `routing` and `ruleset`,
not a field on the report.

## The shape of the answer

Two programmes are in scope, Qantas Frequent Flyer and Cathay. They disagree at nearly every join:

| | Qantas Frequent Flyer | Cathay |
|---|---|---|
| Currencies | Points + Status Credits | Asia Miles + Status Points |
| Route basis | region **pair**, with a mileage-band fallback | distance **zone** |
| Zone inputs | endpoints | distance **and** endpoints |
| Fare granularity | earn category from (carrier, RBD, sometimes route) | cabin **and** fare family, RBD within that |
| Accrual shape | fixed integers from a table row | fixed for CX metal; a share of flown miles for partners |
| Tier bonus | on the redeemable currency only | not on Status Points |

So the shared abstraction has to be **the pipeline**, not the lookup. If a table lookup becomes the
interface, Cathay arrives as a special case and a third programme arrives as a rewrite. A programme
is a set of resolvers — is this segment eligible, which fare bucket, which route basis, what does
that pair accrue, what does the tier add — and `src/earn/kernel.pl` owns the sequencing, the
register and the indeterminate propagation without naming a single programme.

Everything the validator already does stays true of it. No numbers in rules; the tables live under
`data/earn/` tagged with where and when they were fetched. Nothing reimplemented in JavaScript; the
browser runs the same `.pl` files compiled to WebAssembly. Missing data degrades honestly, so a
segment whose class was not given is a range or an `indeterminate`, never a zero. And every number
that reaches a reader carries the row it came from, the same way every violation carries its clause.

## What the tables actually look like

The plan this document replaces was written before anyone had read the published tables. Five things
found in them change the design, and each is the kind of detail that would otherwise have arrived
halfway through the implementation as a special case.

**Qantas has two whole tables, not one.** Its own flights are priced off the Qantas and Jetstar
table, which publishes *ten* earn categories — business and premium economy each split into
discount, standard and flexible — and its partners' off the partner table, which publishes six. The
same ground earns differently depending on who sold the ticket, so `route_basis/5` cannot be handed
only a distance and a pair of airports.

**Qantas has two band tables, not one.** The partner earning table is thirteen groups of named
endpoints — "Between Sydney, Melbourne, Brisbane, Gold Coast and …" — plus an "All other flights"
table of ten mileage bands. But one of the thirteen groups, *Intra-USA Short Haul*, is itself banded
(up to 400 miles, 401 to 750). So `route_basis/5` cannot be "region pair, else bands": it has to
return an opaque basis, and Qantas resolves that basis to a region pair, a region-scoped band, or a
global band.

**A Qantas earn category depends on the route as well as the class.** Malaysia Airlines, SriLankan,
Fiji Airways, Japan Airlines and Qantas itself publish different class-to-category rows for
different parts of their network. `fare_bucket/4` therefore takes the whole segment, not an RBD.

**Cathay's fare family cannot be derived from the RBD.** This is the sharpest of the five. The
Economy table lists the same three class groups — Y,B,H,K then M,L,V then S,N,Q,O — under Flex,
Essential *and* Light, with different numbers each time. A ticket in K earns 25 Status Points on an
ultra-short sector as Flex, 15 as Essential and 10 as Light. So an itinerary that gives a class and
not a family has not given enough to price, and the honest answer is a **range** across the three
families with the spread named, not a point value chosen by a rule of thumb. The earlier plan had
RBD-derivation as the fallback with a warning where the two disagree; there is nothing to derive
from.

**Cathay's buckets are not one per family.** Business publishes one row for Flex (J,C) and one
shared row for "Essential, Light" (D,P,I), and First publishes Flex only. A bucket is a set of
(cabin, family, class) triples that share a rate, which is why the kernel must treat it as opaque.

**Both programmes are already mid-transition.** Cathay's current rates took effect on 20 August
2025, and its own transition rule turns on the **ticket issuance date** as well as the departure
date — a field no itinerary here carries. Qantas has three carriers on dated rows of its own
(Finnair from 1 February 2026, Malaysia from 1 September 2025, Oman Air from 30 September 2025), and
those are on the *category* table rather than the rate table. So `effective/2` has to sit on
`fare_bucket` rows as well as `accrual` rows, and where issuance decides the answer the report has
to say that it cannot see it rather than pick the departure-dated row and look confident.

One more, which is a gift rather than a hazard: in every row of the Cathay table Asia Miles is
exactly one hundred times Status Points. That is worth asserting in conformance, because the day it
stops being true is the day the table has been transcribed wrong.

## Provenance, which has no equivalent upstream

The fare rule has a version and clause numbers to cite; every violation this validator reports
carries one. **The earning tables have neither.** They change without notice and there is nothing
to point at. So the substitutes have to be built:

* `program_source/3` carries the URL a table was read from and the date it was read, printed in
  every earn report and served from `/api/programs`.
* The generator scripts write committed `.pl` files, so an update arrives as a reviewable diff —
  the same arrangement `data/generated/airports.pl` already has.
* The report says plainly that the figure is an estimate and that the airline's own calculator is
  authoritative.

Cathay's tables moved within the last year and Qantas has three carriers on dated rows. The fetch
date is doing more work here than it looks like.

## Geography, again

`data/earn/qff/regions.pl` and `data/earn/cx/zones.pl` are the **third and fourth** geography
taxonomies in this repository, and each has to be independent of the others and of each other.
Qantas splits West Coast from East Coast USA/Canada and files Santiago, Dallas and Tel Aviv as
regions of their own; the fare rule does none of that; OurAirports' physical continents match
neither; Cathay's zones are a distance band qualified by a seven-country list, under one of two band
schemes depending on who sold the ticket. The repo
learned this once already, when `data/countries.pl` had to diverge from the CSV's `continent`
column. A test asserts the taxonomies stay separate tables, so a later contributor cannot tidy up by
aliasing one to another.

## Phases

Each ships and is reviewable on its own.

**0 — a booked class, and rule 5(b).** `segments[].bookingClass`, and the one section of the
ruleset the README lists as checkable in principle but out of reach for want of a booked class. One
field, two payoffs, no new machinery.

**1 — the kernel, through the plugin interface.** `kernel.pl`, `expr.pl`, `distance.pl`,
`registry.pl`, and `qff.pl` with mileage bands only. Wired end to end: a CLI `earn` subcommand,
`/api/earn`, `rtw_call(earn, …)`, `/api/programs`. Qantas is the only programme registered, but it
is registered *as a plugin* — building it directly and extracting the interface afterwards is how
the interface ends up shaped like Qantas.

**2 — the Qantas region tables.** Categories, regions, the region-pair rows, the two band tables,
the generator, the provenance facts.

*Done.* One thing it changed in the interface, and it is the good kind: the near-a-boundary flag
now asks the programme for the edges of the *basis* it resolved rather than of the programme, because
a region pair never reads the distance and flagging it would send a reader to check a number that
decided nothing. It also settled two labels the earlier phases had left open — a pair is named the
way the table names it, group heading first, so an outbound sector and its return read as the one row
they are; and Malaysia's and SriLankan's route-scoped categories turned out **not** to be decidable
from these tables after all. They are scoped to "Australia", "the UK" and "the Middle East", which
the earning-table region page does not define, so they stay undecided rather than becoming a fifth
geography invented rather than read.

**3 — Cathay, CX metal only.** Zones qualified by distance *and* endpoint, buckets over cabin and
family, and the range answer when no family is declared. **This phase is the interface's audit:**
any kernel change it forces is a phase 1 design miss and gets said out loud in the commit rather
than absorbed.

*Done, and the audit came back with one finding.* The opaque bucket, the endpoints in
`route_basis/5` and the per-currency bonus rule all held without alteration — Cathay's zone
qualifier and its cabin-and-family bucket dropped straight into them. What it forced was **ranges**:
`fare_bucket/4` may now bind `one_of(Buckets, Why)`, and the kernel prices every candidate and
reports the spread. That is a real phase 1 miss. The plan had already found that Cathay's fare family
cannot be derived from the RBD, and had still filed ranges under phase 5 as a nicety for classless
routings — when for Cathay a range is the *ordinary* answer, not the degenerate one. Everything else
the phase needed was already there.

**4 — Cathay partner earn, effective dating, more than one programme at once.** Partner earn is a
percentage of flown miles, which is what proves fixed and proportional accrual share one path.

*Partner earn done, from a capture nobody had when this plan was written.* The blocker was real —
Cathay serves partner earn from its calculator rather than publishing a grid — and it was cleared by
querying that calculator: 26,780 observations over 1,752 city pairs, arriving as two CSVs and a
parsing guide rather than as a transcription of a page. The whole Cathay implementation was replaced
against them, and **the audit came back clean a second time**: 26 airlines, two earning models and a
conditional percentage went in without widening the protocol once.

The three things that could have forced a change and did not are worth naming, because each was a
phase 1 decision paying for itself:

* *Two band schemes in one programme.* Partners band at 3,700 miles and Cathay does not. The scheme
  is part of the basis term, which the kernel never looks inside, so `route_basis_edges/3` returns a
  different edge list per sector without the kernel knowing there are two.
* *A percentage that varies by sector.* American's Business card is 150% where both airports are in
  the same country and 125% otherwise — the only conditional rate in 157 cards. It is a fact about
  the sector, so `route_basis/5` carried it into the accrual as part of the basis. Had the accrual
  been handed a bucket and a distance, as the original plan had it, this would have needed a sixth
  argument.
* *Holes in the data.* The partner tables were sampled, not enumerated, so about a tenth of the
  cells were never observed. Those rows omit the Status Points rate entirely, and the kernel's
  existing rule — a rate row silent about a declared currency has not priced it — reports them
  undecided beside a mileage figure that *is* known. `none` and `indeterminate` being different
  things, decided in phase 1, is what made a half-priced sector expressible at all.

What it did cost: the conformance test for an unnamed operating carrier had to change its fixture
from a partner flight number to a Cathay one. That is not a weakening. Asia Miles reads the
*marketing* carrier's rows whoever flies the aircraft, so on a partner sector the operator decides
nothing and there is nothing for the test to hold; on a Cathay flight number both programmes turn on
it, for different reasons. The property survives; the fixture that exercised it did not.

*Rebuilt again a snapshot later, and this time the data was wrong rather than thin.* The v3 capture
takes booking-class membership from each carrier's published fare groups instead of from the
calculator's one representative class per group — a representative that is sometimes not even a
member of the group it names. On Japan Airlines and Japan Transocean that had both invented classes
and dropped real ones; every rate was right and only the labels were wrong, which is the shape of
error a totals-only check cannot see. It also added a `scope` column, because those two airlines
price the same class differently by whether the sector stays inside one country.

The kernel again needed nothing. The fare group and the scope went into the bucket term, which the
kernel does not look inside, and the domestic/international test was already being computed for
American's conditional percentage. What it *did* find was a real defect in the resolver's ordering:
preferring an exactly-scoped card before applying the cabin read a domestic business ticket in `J` as
an economy one, because Japan Airlines lists `J` in both. Scope filters before the cabin and prefers
after it.

The 5(b) coverage list shrank from three carriers to one as a result: `JL` and `NU` were never
missing the codes an Explorer fare books into, and the previous phase had written that down as a fact
about the airlines. Only Malaysia is genuinely short.

Two corrections to earlier phases came out of the v2 capture, and both were the old data being
thinner than it looked rather than read wrongly. The enhanced-region country list is **seven**
countries and not six — Kazakhstan was missing. And the Business row headed "Essential, Light" was
read as two fare families; the calculator publishes no Business brands at all, only two class-group
cards at the same rates. Fare brands are Cathay's own Economy and nowhere else.

**5 — tiers, ranges and the page.** Class and family columns in the Segments tab, a programme
picker fed by `/api/programs`, an earn panel beside the report, and the new URL parameters.

*Done, apart from Cathay's tiers, whose table has not been captured.* Ranges arrived
early, in phase 3, because Cathay needs them for the ordinary case rather than the edge one. Two
things the page settled that the plan had not: the fare-family column hides itself when no
registered programme prices a family, which the page learns from `/api/programs` rather than
deciding, so it still names no programme; and `b`/`f` are positional one-character parameters
precisely so that a class typed against a routing does not drag the whole segment table into `s` and
bury a legible link. Editing only those two fields leaves the rows derived.

Two more interface findings came out of the tier work, and both were the protocol being too narrow
rather than the design being wrong. `bonus/5` became `bonus/6`, taking the segment: Qantas pays its
status bonus on Qantas-marketed sectors and not on partner ones, so a bonus can be a benefit of
flying one airline rather than of holding a card, and the same journey carries one on one sector and
none on the next. And `fare_bucket/4` became `fare_bucket/5`, taking the annotated itinerary as
`eligible/4` always had: a bucket can turn on something the segment does not carry — the fare's
cabin is the obvious one, and it is what lets a programme fall back on the class the tariff says the
fare is sold in. `route_basis/5` went the same way when Qantas' own table arrived: which table
prices a sector is decided by who sold it.

Three widenings in three phases is a pattern rather than three accidents. Giving each resolver a
bespoke signature — a distance here, a pair of airports there — was premature narrowing: the plan
guessed which facts each one would want, and guessed wrong every time. Every resolver now takes the
segment and the annotated itinerary, the same two things, and picks what it needs out of them.

Sub-totals per programme, and **no ranking between them**. A mile and a Status Point are not
commensurable without a valuation, valuations are opinions, and this codebase's whole posture is
that every number traces to a source.

## Out of scope

Award bookings, which earn nothing. Qantas Loyalty Bonus, Points Club and lifetime credits. Cathay's
club-tier mechanics. Miles from anything that is not a flight. Any minimum-earn-per-segment
guarantee, in either programme, until it is read rather than assumed.

Cathay's nine non-oneworld partners *are* priced, which reverses an earlier line here. They cannot
appear on an Explorer fare, so nothing in this repository can reach them — but they are rows of the
capture, and leaving rows out of a transcription is how a transcription stops being one. They earn a
measured zero Status Points, which is worth having written down somewhere.

A free sanity ceiling worth asserting: 4(h) caps the journey at 16 segments, so every total has an
upper bound the validator already knows.
