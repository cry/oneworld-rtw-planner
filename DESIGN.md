# Design notes

Why the validator is built the way it is. [`README.md`](README.md) is how to run it and what it
answers; this is the reasoning behind the answers — the rule readings that are not obvious, the
shape of the code, and what each test suite is actually holding in place.

Three themes run through all of it.

*Nothing is reported as a number that is not one.* A rule that cannot be decided from the input says
so; a rate nobody published is not a zero; a total over an unpriced sector is a lower bound and is
labelled one. The failure this codebase is organised against is a plausible answer, not a missing
one.

*Every answer traces to a source.* A violation cites its clause, a check states what it measured,
and an earning figure names the row and the date the table was read. The fare rule has clause
numbers to cite; the earning tables have neither a version nor a notice period, so the substitutes
are built.

*One implementation per fact.* Three front ends render the same report term, both directions of the
routing grammar are in Prolog, and no cap is written anywhere but the data files.

## How it works

Three layers with one contract between them:

```
"route" ──route_in──┐
                    ├──> itinerary ──annotate──> A ──validate──> report(Verdict, Violations,
"segments" ─json_in─┘                            │                      │      Fare, NotChecked,
                                                 │                      │      Checks)
                                                 │  ┌───────────────────┴────────┐
                                    route_out ───┘  explain (text)        json_out (dicts)
                                        │                  │                     │
                                    "route"              cli.pl        server.pl · wasm.pl
```

`json_out` has two callers and neither contains rule logic: `server.pl` answers HTTP, and `wasm.pl`
answers the browser directly. Three front ends, one `report/3`.

The two input forms meet at `build_itinerary/6` and no rule knows which was used, which is what
makes the routing form a second front end rather than a separate, weaker validator; the test suite
asserts that the same journey written both ways reaches the same verdict.

`route_out` closes the loop from the other end. It hangs off the annotation rather than the raw
itinerary because the notation records what each point *counts as*, which is a conclusion and not an
input: a stop inferred from a two-hour connection and one declared `X/` are indistinguishable by the
time they reach it. That is what makes the round trip assertable — parse a routing, annotate it,
write it out, get the same string — and what stops the browser from needing to know the grammar in
either direction.

**Rules are violation generators.** Each rule is a clause of `validate:violation/2` that *succeeds
when the rule is broken* and binds a term describing the breakage. A naive
`valid(I) :- rule1(I), rule2(I), ...` would give a bare "no"; inverting it means backtracking
enumerates every violation of every rule in one pass, each carrying its own evidence. Two smaller
registries sit beside it: `validate:not_checked/2` for rules the input mode puts out of reach, and
`validate:check/2` for what each rule measured. A check reports the measurement and names the
violation ids it decides; the driver, not the rule, turns that into an outcome.

**One annotation pass.** `annotate/2` runs once and derives continents, traffic conferences, ocean
crossings and the stopover/transfer classification of every connection, so most rule bodies stay two
or three goals long. It is eager and pure — it returns a term, asserts nothing, tables nothing —
which is what makes the validator safe to call concurrently from HTTP worker threads.

**No numbers in rules.** Every cap comes from [`prolog/data/limits.pl`](prolog/data/limits.pl),
tagged with a ruleset version, so a reissued fare is a data change plus tests rather than a rewrite.

Two things the code encodes deliberately, because they are where a naive implementation goes wrong:

- **4(a) + 4(b) + 4(c) collapse into one invariant.** One crossing of each ocean, a continuous
  forward TC1–TC2–TC3 direction, and termination at origin together force the collapsed
  traffic-conference sequence to be exactly a 3-cycle. Checking that one property catches all three
  and gives a better message than counting ocean crossings.
- **4(b) is a traffic-conference rule; 4(e) is a continent rule.** A South America excursion never
  leaves TC1 and an Africa excursion never leaves TC2, so neither breaks the forward-direction rule;
  what bounds them is 4(e)'s allowance. Encoding these at the same level makes every legal
  side-trip look like a violation.

There is no timezone database anywhere, and none is needed: ground time is the gap between an
arrival and the next departure *at the same airport*, and rules 6 and 7 compare times only at day
and month granularity.

## Rules, violations and the register

A violation covers a case, not a segment. Four sectors on one ineligible airline are one thing wrong
with the ticket; two sectors on the same codeshare pair are one pairing. Reported one per segment
they buried whatever else the report had to say, so each rule groups by the fact — the carrier, the
codeshare pair, the case that permits the code — and two different facts stay two violations. The
evidence carries every segment number either way, and the register's own sentences group the same
way.

A check clause states the measurement and nothing else. Its outcome — `ok`, `failed`, `flagged`,
`undecided`, `not run`, `n/a` — is derived by the driver from the violations the same run produced,
so the register cannot contradict the verdict above it, and a rule cannot be marked satisfied by
forgetting to check it. The suite asserts the other half: no rule can fire without a check covering
it.

## Reading the rule where it is ambiguous

Three places where the clause admits more than one reading, and the reasoning for the one taken.
Each is somewhere a naive implementation rejects itineraries that get ticketed. Two more are in
[How it works](#how-it-works) — the 4(a)+4(b)+4(c) collapse and the traffic-conference/continent
split — and a third is in [Geography](#geography), where two words of 4(e) carry the answer.

**A 4(c) surface gap does not count toward 4(h).**

Where there is a real gap, it is checked against 4(c)'s seven permitted relations and named in the
report, but it is **not** counted toward 4(h)'s maximum of 16. 4(h) does say "including surface
segments between any 2 airports", and the gap is between 2 airports — but the segments it has in
view are 4(g)'s intermediate ones, which are sectors of the journey, and the gap is the part of the
world the ticket deliberately does not cover. Counting it would cap an open-jaw journey at 15
flights while a closed loop gets 16, a penalty for using 4(c) that no clause in 4(c) or 4(h)
describes. Held itineraries agree: a 16-flight `CAI-…-DOH` closed by a 4(c)(b) Middle East open jaw
prices, and it cannot if the gap counts.

**A code 5(b) permits conditionally is not a warning.**

Where a class *is* given, three outcomes are possible, because 5(b) has three kinds of class in it.
The applicable code for the cabin passes. Anything the table does not name for that carrier is an
error. In between sit the codes its notes permit conditionally — a lower cabin's own code, `Y` on a
First fare, `B` (or `H` on AA) on a DONE Business fare, and `A` on QR for services within the Middle
East. Those pass too, and the register names the segments and the note they lean on:

> **[5(b)] ok — Booking codes.** 7 of 7 flights state the class sold, on a Business fare. 1 is a code
> 5(b) allows only in a stated case and 6 are the applicable code. Segment 4 is sold in L on CX
> rather than the applicable code. That is allowed: it is the Economy code, which a Business fare may
> use only where Business is not offered or not available on that flight. The fare for the highest
> class used applies.

Each of them turns on what the *flight* offers rather than on the routing — "for flights where First
or Business Class is not offered or available, passengers may travel in a lower class" makes a
business fare ticketed in `L` legal on an aircraft with no business cabin and illegal on one that has
it — and an itinerary carries the route, not the seat map. That was once reported as a warning, and
it should not have been. The permission is the tariff's own, a ticket sold under it is a correct
ticket, and the condition was settled by the airline's inventory at the point of sale: the code is in
the itinerary because a seat in it was sold. There is nothing for a traveller to act on, and a
warning nobody can act on crowds out the ones they can.

**There is deliberately no "too many continents" rule.**

The fare table stops at six and the continent list has exactly six members, so it could never fire.
What it would have been reaching for — that the fare table covers every count the geography can
produce — is asserted as a test instead.

## What the ticket earns

Not part of Rule 3015 and a separate operation for that reason — see
[`PLANS/05-loyalty-earning.md`](PLANS/05-loyalty-earning.md) for the design as it was planned and
what each phase actually forced.

**Nothing in the kernel names a programme.** [`prolog/src/earn/kernel.pl`](prolog/src/earn/kernel.pl)
owns the sequencing, the totals, the register and the propagation of what could not be decided; a
programme is a module supplying multifile clauses of a protocol — is this segment eligible, which
fare bucket, which route basis, what does that pair accrue, what does a tier add. The two registered
programmes disagree at nearly every join, so the thing they share is the pipeline and not the lookup.
If a table lookup were the interface, the second programme would arrive as a special case in it and a
third would arrive as a rewrite.

Four properties hold it together, and each has since paid for itself. *A bucket is opaque* — the
kernel only ever hands one back to the same programme's accrual, so it never has to know what a fare
brand or an earn category is. *No resolver is handed less than the segment and the annotation*, which
is what let a rate that varies by sector arrive without widening the protocol. *An accrual returns an
expression, not a number*, so a table of fixed integers and a percentage of the miles flown reach the
reader down one path. *A currency declares its own rules*, so "Status Points take no tier bonus" is a
line of data rather than a conditional in the kernel.

An amount can be in four states and only one of them is a number: known, a `range` with both ends,
`published_as_none` — a rate the table prints as a dash, which is a fact — and `unknown`. A renderer
that printed any of the last three as `0` would destroy the distinction the whole design exists to
keep. [`prolog/test/earn/conformance.pl`](prolog/test/earn/conformance.pl) asserts all of this over
*every* registered programme and names none of them.

**Which table prices a sector is decided by who sold it.** Qantas publishes one set of rates for its
own flights and another for its partners', with ten earn categories against the partner table's six —
so a `QF`-marketed sector and a `BA`-marketed one over the same ground earn differently and are read
off different pages. `SYD-LAX` in `D` is 14,625 Qantas Points on Qantas and 13,500 on American.

**Within a table, a sector takes the most specific row that covers it** — Australian domestic bands,
then the named region pairs, then the mileage bands; on the partner table, region pairs, then
Intra-USA Short Haul (a region group that is itself banded on distance), then the bands. That middle
case is why the route basis a programme returns is opaque to the kernel rather than being "a region
pair, else a band".

**A sector within 1.5% of a band edge says so.** What an airline bands on is ticketed mileage, which
is not a great-circle distance; everywhere except near an edge the two agree well inside the width of
a band, and near an edge is exactly where a good-enough answer stops being good enough. The edges are
asked for per *basis*, so a region pair — which never looked at the distance — is never flagged.

**Two earning models can live in one programme.** Asia Miles covers Cathay and 25 partners, and the
two halves work differently enough that reading one against the other returns a plausible number
from the wrong row. Cathay's own flights earn fixed Status Points per distance zone and Asia Miles at
exactly a hundred times the points; every partner earns fixed points per zone and Asia Miles as a
*percentage of the distance flown*, off a band set with one more boundary in it, at 3,700 miles. So
`HKG-SYD` in `J` on `QF` is 60 Status Points and 5,740 Asia Miles — not the 6,000 the Cathay rule
would give. The scheme travels on the airline and is an argument to every zone fact rather than an
assumption anywhere, and it is the reason an accrual returns `fixed(70)` or `pct(125)` instead of a
number.

**The marketing carrier picks the table and the operator picks the card.** A `QF` flight number flown
on an Emirates aircraft reads the `QF` rows. A `CX` flight number is priced twice over: on Cathay
metal Economy splits into Flex, Essential and Light, and on a partner's it earns the Codeshare card
instead — which Premium Economy, Business and First do not have at all, so a codeshare in a premium
cabin is unknown here rather than quietly priced off the Cathay-operated figure. A Cathay flight
number with no operator named cannot be answered, because those two rates are what it is between.

**Where the input cannot say which of several rates applies, the answer is the spread.** Cathay
lists the same economy booking classes — `Y,B,H,K`, then `M,L,V`, then `S,N,Q,O` — under Flex,
Essential *and* Light with different earn against each, so a ticket in `K` has genuinely bought one
of three things and the class cannot tell them apart. Give a `fareFamily` and the answer is a number;
leave it out and it is `40 to 70 Status Points`, with the register saying why. Never a midpoint: no
combination of the traveller's actual fares can produce one.

It is a narrower problem than the grid makes it look, and it is Cathay's own Economy alone: no
partner publishes a fare brand, so a family left set in a picker is quietly irrelevant there rather
than an error. Within that Economy, `Y` is full-fare and therefore the flexible fare whatever the
grid lists it under. That is the only place in either programme where a fact not on the published
page decides an answer, so it is a predicate of its own — `cx_class_settled/3` — and the register
prints its reason instead of claiming the table said so. `B`, `H` and `K` are not settled that way
and stay a range.

**The fare group is the unit of earning, not the booking class.** Every class in a group earns
identically, and the group is the carrier's own — `JL` Business group B is `(J, C, D, I)` at 125%
while group G is `(X)` at 70%, a threefold spread inside one cabin. The membership comes from each
carrier's published fare groups and not from the sampling, which matters because the earlier capture
derived it from the calculator's one representative class per group: the representative is sometimes
not even a member of the group it names, so it both invented classes and dropped real ones on two
airlines. That is also why a class the table does not name is refused rather than priced off its
neighbour — a substitution here would be wrong by up to three times.

**Two airlines price the same class differently by whether the sector stays inside one country**, so
`(airline, cabin, class)` is not a key for them: `JL` Economy `Y` is group F at 100% abroad and
group H at 50% at home. Scope narrows in two places either side of the cabin, and the order is what
makes both right — a card scoped to the other reach is never a candidate at all, but the *preference*
for an exactly-scoped card over an `all` one runs after the cabin, because a domestic business ticket
in `J` is a business ticket even though the domestic economy group also lists `J`.

**A band nobody sampled is not a zero, and a real zero is not a gap.** The partner tables are the
calculator's own responses to 26,780 queries over 1,752 city pairs, sampled 23 to 90 pairs per
airline rather than enumerated, so 106 of the 936 cells were never seen. Those carry no Status Points
rate at all and reach the reader as `an unknown number of Status Points` beside a mileage figure that
*is* known, since the miles come off the distance rather than off the band. Two fare groups were
never sampled at any distance and have no percentage either, which the report says in those terms
rather than as a route it does not cover. Nine carriers — exactly the non-oneworld partners — earn a
measured zero everywhere, which prints as the `0` it is. Where they meet, the zone label says which:
`Zone 1 (1-750 miles) — Air New Zealand was sampled in zones 5 only, so this band was never
observed`.

**An itinerary that names a cabin has said more than it looks like it has.** Section 5(b) publishes
the class an Explorer fare books into, so a sector with no `bookingClass` is priced off the fare's
own class rather than refused, and the register says which code it used. Economy comes out as `L` —
what 5(b) actually says an economy Explorer fare books into — and not `Y`, which is the conventional
shorthand for the cabin and a different, much better-earning class. On the Qantas table `L` is
Discount Economy where `Y` is Flexible Economy, so presuming `Y` would overstate the earn by roughly
double, and wrong-high is the bad direction for an estimate. Only the *applicable* codes are used,
never the alternates 5(b)'s notes permit in a stated case: those turn on what the flight offers,
which is a seat map rather than a tariff.

**And the fare basis picks which of them, not the cabin.** 5(b) heads its two business columns
"Business — DONE\*" and "Business — IONE3", which are fare bases rather than cabins: a `DONE4` fare
books into the DONE column, and the IONE3 column describes a fare this itinerary is not. Reading the
cabin's columns instead returns `D` *and* `I`, which on Qantas' own table are Business and Discount
Business — so every classless `QF` business sector used to come back undecided over an ambiguity the
fare basis printed at the top of the same report had already settled. The register now says which
fare it read: `no class given; section 5(b) books a DONE4 fare into D on this carrier`.

Where one column still leaves two categories, the answer is the spread rather than a refusal —
Malaysia files `A` in both Business and First, so a classless First fare there is `8,125 to 9,750
Qantas Points`. That is the same kernel path Cathay's undeclared fare brands take. Rule 5(b) itself
keeps the cabin's wider projection and must: a ticket presented in either business column is booked
in a code the rule names, whatever basis this validator reports.

## Geography

Four taxonomies, none of them the same cut of the world, and each of them its own table. Aliasing
any pair would invent violations or invent earn wherever they disagree, and they disagree a lot.

`prolog/data/earn/cx/zones.pl` is the **fourth**: two band schemes rather than one, because Cathay's
own flights band at 750/2,750/5,000/7,500 miles and its partners band at 750/2,750/**3,700**/5,000/
7,500. Reading a partner against Cathay's bands returns a plausible number from the wrong row on
every sector between 2,751 and 5,000 miles, which is why the scheme is an argument to every zone
fact rather than an assumption anywhere. Cathay's second band splits again by region — the same 751
to 2,750 miles, on the enhanced card if either endpoint is in one of seven countries and the
standard one otherwise. No distance decides that, which is why the route basis a programme resolves
takes the endpoints and not just a distance. Four city pairs defy the distance rule outright and are
applied before it.

`prolog/data/earn/qff/regions.pl` is the **third** geography taxonomy here, and deliberately its own
table. Qantas splits West Coast from East Coast USA/Canada, which the fare rule does not; it files
Santiago, Dallas and Tel Aviv as regions of their own; and one of its regions, "Southeast Asia or
Northern Africa", spans three of the fare rule's six continents — it reaches Kenya, Uganda, Somalia
and the Seychelles at one end and Egypt, Libya and Morocco, which Rule 3015 puts in Europe/Middle
East, at the other. A test asserts the two stay independent, so a later contributor cannot tidy up by
aliasing one to the other.

`prolog/data/generated/airports.pl` holds 4,161 airports with scheduled service and an IATA code,
built from the [OurAirports](https://davidmegginson.github.io/ourairports-data/airports.csv) CSV:

```sh
curl -o /tmp/airports.csv https://davidmegginson.github.io/ourairports-data/airports.csv
swipl -g main -t halt prolog/tools/build_airports.pl -- /tmp/airports.csv
```

Regeneration is manual and the output is committed, so upstream geography changes arrive as a
reviewable diff. The CSV's own `continent` column is **not used** — it is physical geography, and
the fare rule's continents are IATA areas. It files Honolulu under Oceania (4(b) needs it in North
America), Dubai and Amman under Asia (the rule needs Europe/Middle East), and Casablanca under
Africa (the rule needs Europe). `data/countries.pl` carries the fare-rule taxonomy;
`data/overrides.pl` holds only what a country-level table cannot express.

Europe/Middle East is one continent made of two zones, and the difference is load-bearing in three
places: 4(c)(b) permits an origin–destination surface gap *within the Middle East*, section 12
prices *sectors within the Middle East* separately, and 4(e)'s closing sentence bars Mauritius and
South Africa when travel is to and from *Europe* in both directions — the zone, named two lines
after the same rule says "Europe/Middle East" in full.

Two words in that sentence carry it. *Europe* means the zone, so a Gulf gateway is not a Europe
gateway. *Both directions* means the two crossings of the Africa border, the one in and the one
out — not a count of crossings anywhere in the journey. Either word read wrong rejects an itinerary
that gets ticketed: at continent granularity an Africa excursion flown in and out through the Gulf
fails, and on a count of Europe arrivals a journey fails over an unrelated Asia-to-Paris sector.
`mut_europe_both_ways` and `mut_europe_both_ways_gulf` are the same journey differing in one point
and must land on opposite verdicts; `osl_africa_gulf_gateway` is the one with the unrelated second
Europe arrival, and it is valid.

Several hundred city names are non-ASCII, which costs two things. The generated file declares
`:- encoding(utf8)` rather than trusting the locale of whoever loads it, and the typeahead in
[`prolog/src/fold.pl`](prolog/src/fold.pl) matches on an accent-folded copy of both sides, so
`sao paulo` finds São Paulo and `zurich` finds Zürich — the cities whose spelling is hardest to
reproduce being exactly the ones a search is most needed for. The fold table is explicit rather than
derived from Unicode normalisation, because the letters that are not an ASCII letter with a mark on
top — ø, æ, ð, þ, dotless ı, ł — need a table either way. A test asserts it covers every character
in the generated airport table, so regenerating that table with a new letter fails the suite rather
than quietly dropping a city out of reach of the search.

## Which sectors are actually flown

A fifth operation, `network`, beside `validate`, `routing`, `earn` and `ruleset`. It reads
`prolog/data/generated/services.pl` — 5,618 directed nonstop sectors and 82 dated windows, extracted
from 933 Wikipedia airport articles pinned at a revision each — and reports, per segment, whether the
snapshot holds that sector.

**It produces no violation, and that is the whole design.** Rule 3015 says nothing about whether a
flight exists, so there would be no clause to put beside the finding in a register whose entire
premise is that every entry cites one. The evidence is a different kind, too: a wiki snapshot of
stated age, in which absence is far weaker than presence. Mixing it into the register would make
`verdict` mean two incommensurable things at once — exactly the reason earning is a separate
operation, and the same boundary drawn twice.

Five statuses, and the last two are what keep the panel honest. `flown(Season)`, `windowed(When)`
and `absent` are the table speaking. `carrier_unknown` and `not_applicable` are not: a routing leg
written `//` is a surface sector the traveller covers themselves, and a segment naming no airline
has nothing to look up. Without those two, every surface leg and every carrier-less segment would
read as an unflyable sector — reporting a gap in the *input* as a gap in the *network*.

The lookup uses the **operating** carrier where there is one, because the source's rows are
operating-carrier rows: Wikipedia excludes codeshares for the secondary carrier by convention.
Looking up the marketing carrier on a codeshare would ask about a row that was never there and
report `absent` for a sector flown daily. Where only a marketing carrier is known — which is every
routing string, since the notation carries one carrier per leg — the lookup uses that and the reply
says which it used, so a reader can weigh the answer.

Three values for `Season`, not two. Seasonal marking is incomplete upstream, so collapsing `unknown`
into `year_round` would silently promote unmarked seasonal service into year-round service — the
data-layer form of letting `indeterminate` read as a pass. Edges are directed and asymmetry is
*reported*, never repaired: symmetrising would manufacture edges nothing sourced.

The table costs 37 KB in `web/rtw.pvm` (479 KB → 517 KB) for 202 KB of source, which is why it ships
in the image rather than being fetched separately. Acquisition is
[`PLANS/07-wikipedia-extraction.md`](PLANS/07-wikipedia-extraction.md); the schema, the query surface
and the reasoning above are [`PLANS/06-flown-network.md`](PLANS/06-flown-network.md).

## The web UI

The user-facing description is in [`README.md`](README.md#web-ui); this is what the page does *not*
do, and why.

Neither direction of the grammar is implemented in the browser: reading a routing is the `validate`
operation's job and writing one is `routing`'s. A copy of the grammar in JavaScript would be the one
nothing tests, and with both directions in Prolog the suite can assert that a routing survives the
round trip.

**The answer is two columns on a wide screen**: the verdict, the rules, the map and the connections
table on the left, earning on the right. Stacked, the scroll is the sum of both; beside, it is the
taller of the two, and nothing had to be hidden to get there. It keeps both sub-columns on the
Segments tab too, at a lower viewport threshold, because the answer is wider there — it has the whole
page rather than sharing it with the sidebar, so the width at which two readable columns fit differs
by exactly the sidebar. Both are page layout, which is what viewport queries are for; neither panel
cares how wide the other is.

**The Segments tab takes the page, and the answer goes under it.** It used to widen the form to half
the width, which was measured against the wrong thing: a seven-segment table wants 878px with no
clock and 1,262px with dates and times, and half of a 1,680px page is 814px. The page was reflowing
into two equal columns to hand the table a column it then scrolled inside anyway. Full width fits it
at either setting with nothing to scroll, and it costs the answer nothing it was using.

That is still a change of shape, so it is animated — but by the browser, not by hand. `show()` runs
the class toggle inside `document.startViewTransition`, and the form, the report and the earning
panel each carry a `view-transition-name`, which is what turns "three panels teleport" into "three
panels travel". Only the named boxes animate: the root snapshot has its animation removed, because
nothing outside them moves and cross-fading it only makes the text underneath shimmer. Neither at
boot — a deep link into the Segments tab would animate from a layout that was never on screen — nor
under `prefers-reduced-motion`, nor in a browser without the API, where the switch is simply instant.

**Validating scrolls to the answer, but only when the answer is out of the way.** Under the
full-width Segments table, and on any screen too narrow for two columns, the report renders below a
form taller than the viewport — so pressing the button produced a verdict off the bottom of the
window and a page that looked like it had done nothing. The test is the report panel's top edge:
above the fold, or far enough down that only the verdict band would fit, and it scrolls. On a wide
screen in the Routing tab the report is already beside the form and nothing moves, because scrolling
a page whose answer is on screen is moving the reader for nothing. It scrolls before earning is
asked rather than after, so the scroll is not queued behind a second round trip; and it is off for
the one validation nobody asked for, the linked itinerary that validates itself at boot — a page
that scrolls away from its own form before the reader has touched anything is a page that moved on
its own.

**A column fills down like a spreadsheet's.** A ticket is mostly one carrier, one booking class and
one kind of connection repeated down a column, and typing that seven times is seven chances at a typo
the validator will then faithfully report. The focused cell carries a handle; dragging it copies the
value into the rows it crosses, and <kbd>Ctrl</kbd>+<kbd>D</kbd> does the same to the last segment,
because a mouse-only gesture is no gesture at all for some readers.

Two rules keep it honest. It is offered only on the columns that describe the *ticket* — carrier,
class, fare family, kind of connection — and never on the ones that identify a *sector*: an airport,
a flight number or a departure time filled down a column can only produce a journey nobody could fly,
and a gesture whose only outcome is wrong data should not be offered. And it writes only where typing
would be allowed, which it decides by reading the `disabled` attribute the markup already sets rather
than keeping a second copy of the rule that a surface sector has no carrier and the last segment has
no arrival to describe. A second copy is the one that goes out of date.

**It fills sideways too, between the two carrier columns and nowhere else.** The same argument, one
axis over: on a sector nobody codeshared the marketing and operating codes are the same code, so one
is already the answer for the other. No other pair of neighbouring columns is like that — a booking
class beside a flight number beside an airport are three different kinds of thing, and a value
dragged between them could only be wrong — so the sideways fill is a property of a named group of
columns rather than of the gesture. Dragging both ways at once fills the rectangle, which is what a
spreadsheet does and what a whole ticket on one carrier wants. There is no keyboard twin: filling
down replaces up to fifteen typings with one key and is worth taking <kbd>Ctrl</kbd>+<kbd>D</kbd>
from the browser for, while filling across replaces exactly one, and the key a spreadsheet would use
for it is the browser's reload.

**Validating leaves the reader somewhere they did not choose to be, so there is a way back.** A
button floats over the answer while the form is off screen, saying which of the two ways in it goes
back to, and it disappears the moment the form is on screen again — which on a wide screen, where
the form is a sidebar beside the answer, is always, so it never appears there at all. It is driven
by an IntersectionObserver on the form rather than by a scroll position, because the question is
where the form is and not how far the page has scrolled: switching tabs changes the answer with no
scrolling at all. The root is shrunk by six rems from the top, which is not a fudge — the reveal
scroll lands the report's top on the window's top, and the report's top *is* the form's bottom, so
the exact test put the form's last pixel on the line where a browser may call it visible and the
button never came. Clicking it puts focus on the open tab rather than on the section: focusing a
section needs a `tabindex` and draws the focus ring around the whole panel, which is a great deal of
accent for "you are here".

**Opening a tab converts what is in the other one.** They are two ways of writing one journey, so a
reader who fills in the table and presses Routing means "show me that as a routing" — which is what
the tab is for. It used to be a button next to Clear, which asked them to notice that the two tabs
might be showing different itineraries and to remember to say so; the button is gone. Neither
direction is implemented in the browser: composing calls the `routing` operation, and reading calls
`validate` and keeps only the annotations, because pressing a tab is not asking for a verdict.

The conversion is started after the switch and never awaited, so the tab opens at once and fills in
a beat later — a tab that waited on the worker before showing anything would make the cheapest thing
on the page feel like the most expensive.

**And it converts only when the two disagree**, which is the whole of what makes this safe. The
guard is the routing text plus a signature over the table, and the signature covers only the columns
a routing has notation for — the kind of sector, the two places, the marketing carrier, the stop, the
origin, and whether the clock is on. A date or a flight number typed into a table the routing still
describes exactly is not a disagreement. Counting it as one would send the table back through the
parser on the way to a tab the reader only wanted to look at, and hand back the same journey with the
date deleted. The clock is in the signature for the opposite reason: with times on, the validator
reads a transfer off the ground time, so turning the clock off changes what the routing would say
even though no cell moved. A link that arrives carrying both a routing and a table is recorded as
already in agreement, because it was written by a page where they agreed.

When composing fails — a point that is neither a transfer nor a stopover, a carrier code that is also
an airport code — the message goes on the tab the reader just opened, and a routing field still
holding the *previous* composition is cleared: it describes a journey the table no longer contains,
and nobody typed it. Anything the reader typed themselves stays, because that is theirs.

**Column headings carry their own expansions.** Thirteen columns is what forces `Mkt`, `Op` and
`Cls`, and an abbreviation the reader has to guess at is worse than a narrow column. Each one has a
CSS tooltip rather than a native `title`, which waits a second and renders in the OS's type at the
OS's size. Hover is the only way to *see* it and that is not a gap in the non-pointer path: generated
content is in the accessibility tree, so the heading reads as "MKT, marketing carrier — whose code is
on the ticket" whether or not anything is hovered, and every field under it says it again in its own
`aria-label`. Making the headings focusable to add a keyboard path would put four new tab stops in
front of the fields and give nothing that is not already said twice.

**Earning is the only thing in the second column.** The connections table had a panel of its own
there, which was a border and a heading spent on announcing that a table is a table. It is evidence
for the verdict — a stopover the clock and the ticket disagree about is *why* a count came out the
way it did — so it belongs in the report, under the map it shares coordinates with, collapsed
because it answers a question asked after the verdict rather than with it. Earning stayed a panel
because it is a different question and not evidence for anything above it: it runs no fare rules, an
itinerary that cannot be sold can still be priced, and one that is perfectly valid can be
unpriceable.

**The map is in the report and not in the panel beside it.** It reads as the evidence for the lines
above it — a repeated sector, a continent entered twice, a surface gap — which is a thing to look at
while reading them rather than after scrolling past a register. It sat in the second column for one release
because stacked it is the tallest element on the page and had been coming between the reader and
everything printed after it; the two-column layout is what actually solved that, and once the columns
existed the map belonged with the rules it illustrates.

**Rules the input cannot answer are not called out separately.** They used to have a dashed block of
their own under the violations, on the grounds that an absence should not be rendered in the same
register as a satisfied rule. But every one of them already appears in the check register reading
`not run`, with the same explanation in its own words — the suite asserts that no skipped rule lacks
a check covering it — so the block was a second copy of a list one disclosure away, sitting between
the verdict and the map in the space a reader crosses most often.

**A programme is a section, not a tickbox.** Choosing which programmes to price before seeing any of
them is a choice made in the dark, and the answer to "where should I credit this ticket?" is the
comparison itself. So every registered programme is always priced and always shows its totals; what
a section holds is the detail behind one. A membership tier is inside the programme that publishes
it, because a tier is a fact about the traveller's standing with one airline and not a page-wide
setting — which also means the control appears exactly when the validator says that programme has
tiers, and never otherwise. The register inside a section starts where the section does, flush with
the disclosure marker rather than hanging under the programme's name: indented past the marker it
read as a sub-point of the name, and the indent was spending width on nothing — the column it pushed
right is two digits wide.

**The help panel is the one modal, and it is a `<dialog>`.** Modals are usually the lazy answer, and
everything else on this page is a section you can scroll to or a disclosure you can open. Help is the
exception on its own terms: it explains the page rather than being part of it, so it has no place in
the reading order, and a reader who opens it has nothing else to do until they close it — which is
what a modal actually models. Being a native `<dialog>` opened with `showModal()`, the browser
supplies the parts usually written badly by hand: the rest of the page goes inert, Escape closes it,
focus returns to the button that opened it, and `::backdrop` is a real element to style. What is left
in JavaScript is the button, the light-dismiss, and filling in the figures.

Two details worth recording. Preflight's `margin: 0` on everything silently removes the `margin: auto`
the UA stylesheet uses to centre a modal dialog, which puts the box in the top-left corner; putting it
back is the whole of the positioning. And the dialog is a flex column with a scrolling middle rather
than one scrolling box, so the title and both ways out stay on screen however far down the reader is —
a modal whose only exit has scrolled away is how modals earned their reputation.

What the panel *says* splits the same way the rest of the page does. What a round-the-world fare is,
and what this tool is for, is prose and the page's to write. Every figure in it — the continent and
flight counts, the stopover minimum, the stay limit, the cabins, the carrier count, the routing
grammar — comes from `/api/ruleset`, for the same reason the page hardcodes no rule. One row was cut
for that reason: the ruleset publishes traffic conferences by continent *key* and not by display name,
and the page has no business title-casing `europe_middle_east` into a name of its own. It states how
many conferences there are; a report prints them properly, because a report carries its own name
table.

There are no tiles, and that is the point. A slippy map over OpenStreetMap would put the page back
on the network — the same reason the fonts and the stylesheet are bundled — and street-level tiles
carry nothing legible at the only zoom a round-the-world route is ever viewed at. `d3-geo` plus the
Natural Earth 110m land outline is 55 KB of data, renders as vectors that scale for free, and needs
no runtime beyond the browser. The projection is equirectangular and cut at the antimeridian: a
closed loop around the globe cannot be drawn on a rectangle without one cut somewhere, and the
Pacific is where every round-the-world map puts it.

The URL parameters are listed in [`README.md`](README.md#web-ui). Two of them are shaped the way
they are on purpose.

`b` and `f` are positional and one character each for the same reason the routing is left readable:
a routing has no notation for a booking class, so a class typed against one is authored data on a
derived row, and writing the whole table to `s` to carry two letters would bury a legible link under
two kilobytes of base64. Editing only those two fields therefore leaves the rows derived.

`/` is legal in a query string, so it is left unencoded — most of what keeps a routing link
readable. Rows filled in from a parsed routing are *derived* and deliberately not written to `s`:
the routing regenerates them exactly, and storing them too would bury a readable link under two
kilobytes of base64. The flag clears the moment the table is edited directly, because from then on
it holds a date or a flight number the routing cannot express. Updates use `replaceState`, since at
one history entry per keystroke the back button would become an undo key.

**The theme is one `color-scheme` declaration.** Every token is a `light-dark(light, dark)` pair, so
the two values that have to stay related sit on the same line, and the browser's own furniture
(scrollbars, form controls, the canvas behind the page) switches with the page. A small inline script
in `<head>` applies a stored choice before first paint; it is the only script on the page that is not
deferred.

The page hardcodes no rule data — version, segment limits, city codes and the routing grammar all
come from the validator's own `ruleset` reply.

**The build's freshness check works because `npm run wasm` is idempotent**, and that took
arranging: a SWI saved state is a ZIP archive and records the time it was written, so two builds of
identical sources differ in every compressed byte. Rather than compare bytes, the build records a
digest of its inputs in `web/rtw.build.json` and does nothing when they already match — which moves
the question from "are these bytes what we would produce now" to "was this built from these
sources". `npm run wasm -- --force` rebuilds regardless.

## In the browser: WebAssembly

```
web/app.js ──> RTWApi.{validate,routing,earn,ruleset,programs,…}  web/api.js
                            │  postMessage
                            ▼
                      web/worker.js ──> vendor/swipl-bundle-no-data.js + rtw.pvm
                            │
                            ▼
                 rtw_call(Op, InText, Status, OutText)         prolog/wasm.pl
                            │
                            ▼
              the same load.pl, the same rules, the same io/json_out.pl
```

[`prolog/wasm.pl`](prolog/wasm.pl) is the counterpart of [`prolog/server.pl`](prolog/server.pl) — the
same six operations under the same names, the same error mapping, the same status codes, and no rule
logic in either. Both are renderers of the same terms.

**It is one backend, not two.** The service still answers `/api/validate` and the rest for
programmatic callers, but the page never calls them. A page that chose between a local and a remote
validator would have two code paths to keep in step and a class of bugs that appears on only one of
them; this way the published site and the container render identically, because they are running the
same thing.

**Three properties of the WebAssembly build shaped the code.**

* *No cross-origin isolation is required.* The build uses neither `SharedArrayBuffer` nor pthreads, so
  it needs no COOP/COEP headers — which matters because GitHub Pages cannot set them. This was the one
  thing that could have ruled the approach out, and it does not.
* *A saved image has no autoloading.* Only what was compiled in exists; a goal composed in the browser
  cannot reach library predicates, and even `member/2` raises an existence error. So `rtw_call/4` is
  the only way in: the browser names an operation, never a goal. The constraint enforces a boundary
  worth having anyway.
* *`library(http/json)` is absent* — the HTTP package is not part of the build. `library(json)` is,
  and carries the same predicates; `cli.pl` already chose between them with `exists_source/1`, and
  `wasm.pl` uses the same conditional rather than a second spelling.

**The two engines are not the same version.** `swipl-wasm` currently builds SWI 10.1.10; the container
runs 10.0.2; CI's apt supplies 9.x. Nothing in the suite can see that, so
[`prolog/test/test_wasm.mjs`](prolog/test/test_wasm.mjs) does: it drives every fixture through
`rtw_call/4` on both engines and compares the **whole reply**, not just the verdict — a few thousand
characters of message prose, ordering and evidence per fixture. All 57 agree. It is the counterpart of
the HTTP round-trip test in `test_json.pl`: same purpose, different second renderer.

The comparison is *structural*: both replies are parsed and compared field by field, and the first
disagreement is reported as a path such as `checks[9].detail`. It cannot be textual, because the
`library(json)` / `library(http/json)` split means whichever module is present decides whether a
space follows a comma — a fact about a pretty-printer, not about the fare. Array order, every
message, every piece of evidence and the presence of every key are all still compared exactly.

```sh
npm run wasm          # build web/rtw.pvm and the vendored engine
npm run test:wasm     # 57 fixtures, wasm against native
```

## Why the server is built the way it is

Put a reverse proxy in front for TLS, HTTP/2 and slow-client buffering. Beyond that, three things
the server does deliberately, each of which was a production problem:

- **The UI is read into the program at load time**, not opened per request. A path resolved with
  `prolog_load_context/2` is fixed at *compile* time, so a saved state or an image built anywhere
  but the deployment directory served 404s for a file sitting right there. Reading at compile time
  is the fix rather than the disease: what gets baked in is the content, not a path that will not
  exist later. It also leaves no filesystem access in the request path, which is what lets the
  container run read-only. Every asset — page, stylesheet, scripts, both fonts, and now a 2.5 MB
  Prolog engine and a 416 KB image — is held as a *string* of bytes and written back verbatim, so
  one code path serves text and woff2 alike; the font and vendor handlers resolve nothing from disk,
  so there is no traversal to defend against. A string rather than the code list this used to be,
  and the difference is not stylistic: a code list costs about seventy-five times the size of the
  file it came from, so reading the WebAssembly bundle that way peaked at 194 MB of RSS against
  19 MB as a string. The suite asserts a font still round-trips byte for byte.
- **A 500 says nothing about the failure.** The term and its backtrace go to stderr, where systemd
  and Docker collect them; the client gets a fixed message. Returning the raw term is the hazard
  `library(http/http_error)` exists to warn about. Every other status still describes the caller's
  own request back to them.
- **Validation has its own thread pool.** It is the only expensive handler and the only one under a
  time limit. Sharing the default five workers means five slow requests stop `/api/health`
  answering, and a load balancer then pulls the instance for something that is not an outage. A full
  queue is refused with 503 rather than accumulated; both sizes are in
  [`prolog/data/limits.pl`](prolog/data/limits.pl).

## Tests

```sh
swipl -g run_tests -t halt prolog/test/run_tests.pl
```

Nine suites, in descending value, plus a tenth that needs node as well and runs on its own:

1. **Mutation tests** — each fixture is the golden itinerary with exactly one rule broken, asserting
   that exactly the expected rule ids fire. This catches false negatives and rules that over-fire on
   legal itineraries at the same time, and it verifies rule independence.
2. **Golden fixtures** — a classic LHR round-the-world, an Africa excursion, a South America
   excursion with a surface sector, and a South West Pacific origin using the 4(g) transoceanic
   surface exception. All must stay silent.
3. **Routings and declared stops** — the golden itinerary written as a routing string and again as
   segments with declared stops must reach the same verdict as the dated one. Also the grammar
   itself, the precedence between a declaration and the clock, and that routing mode names the
   rules it cannot check instead of passing them. Composition is asserted as a round trip: parse a
   routing, annotate it, write it back out, and get the same string — which is the property that
   justifies `route_out.pl` being Prolog instead of thirty lines of JavaScript.
4. **The check register** — that a satisfied cap states its number, that a breached one cannot read
   as a pass, and the load-bearing one: across every fixture, no rule can fire without a check
   covering it. That is what stops a rule being added without a measurement and the register
   quietly claiming coverage it does not have.
5. **Metropolitan cities and carrier codes** — that an airport can be found from its city as well as
   the reverse, that no airport sits in two cities, and that the rules written in cities see them:
   `LHR-JFK` out and `LGW-JFK` back is one city pair flown twice. Also the one place the notation is
   genuinely ambiguous — `HAC` is an airline and an airport — asserting that a routing reads it as
   the airport and that composing one for an itinerary flown on it is refused rather than corrupted.
6. **Geography units** — every place the fare rule and physical geography disagree, plus that the
   generated airport table declares its own encoding: several hundred city names are non-ASCII, and
   a build under a non-UTF-8 locale would otherwise load them corrupt and serve them that way.
7. **Serialization and HTTP round trip** — the JSON body must report the same verdict and rule ids
   the text renderer prints, which is what keeps the two renderers from drifting, plus the request
   size, segment and timeout guards, and the static assets: a stylesheet or map bundle that 404s
   leaves the UI degraded rather than failing loudly, and a font re-encoded on the way out arrives
   corrupt with no error raised, so it is compared byte for byte against what the server holds.
8. **Earn conformance** — run over *every* registered loyalty programme, and the thing that makes
   adding a third one cheap. No orphan rows and no unpriceable buckets; every declared currency
   produced by some accrual and no accrual pricing a currency nobody declared; every rate an
   expression the evaluator knows; surface sectors earning nothing; an unnamed operating carrier
   undecided rather than zero in every programme and every currency; and asking for two programmes
   at once matching asking for each on its own. Nothing in the file names a programme.
9. **Earn numbers** — hand-computed values with the published row named in a comment above each, and
   the same mutation idea as the rule suite: change one booking class and assert exactly one column
   moves. Also the great-circle distance against four known city pairs; that a sector near a band edge
   is flagged while one in the middle of a band is not; that HKG-NRT and HKG-SIN fall in different
   Cathay zones despite sitting in the same mileage band, which is the one place a distance is not
   enough; and that Asia Miles are exactly a hundred Status Points on every Cathay row and on no
   partner row — both halves, because the first version of that capture stated the relationship as a
   general invariant and recommended it as a checksum, which was wrong.

```sh
npm run test:wasm
```

10. **The two engines agree** — the page runs a different SWI-Prolog from the container (10.1.10
    against 10.0.2), and no plunit test can see that. Every fixture is driven through `rtw_call/4` on
    both, for every operation that takes an itinerary, and the **whole reply** compared field by
    field rather than the verdict alone: message prose, ordering and evidence included. 57 fixtures
    × `validate` and `earn` — all 114 agree. It needs both engines present, which is why it is a node
    script rather than a unit.

`npm run check:contrast` is separate and does not need SWI: it scores every colour pair in the
palette against WCAG 2.2, including the 3:1 minimum for the boundary of a control.

Some rules cannot fire alone: a two-segment itinerary is below the 4(h) minimum and is necessarily
also short of continents, stopovers and a traffic-conference cycle. Those tests still assert an
exact set, just a set of more than one.

4(f)'s "no more than 4 international transfers from the one country" is the sharpest of these. A
fifth transfer costs either a fifth pair of intra-continental legs, which breaches 4(h), or a third
intercontinental crossing, which breaches 4(e) — so those two caps between them hold the reachable
maximum at exactly the 4 that 4(f) permits, and `mut_intl_transfers` asserts the pair. Four is
comfortably reachable and gets flown: `doh_transfers` is a Gulf-hub itinerary sitting on 4(f), 4(e)
and 4(h) simultaneously, and it is valid.

Every rule id has a fixture.
