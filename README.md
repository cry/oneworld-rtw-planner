# oneworld-rtw-planner

A SWI-Prolog engine that answers **"is this round-the-world itinerary a valid oneworld Explorer
fare?"** — and when it isn't, names every rule broken and why. Validation and explanation only; it
does not generate or optimise itineraries.

The ruleset is oneworld Explorer, Tariff RWR2 Rule 3015, version 27 FEB 26, transcribed in
[`parsed-rules-aug-2026.md`](parsed-rules-aug-2026.md). Every violation cites the clause it came
from, so any answer can be audited against that text.

There are three ways to run it: a CLI, an HTTP service, and a **static page that carries the
validator with it** — the same Prolog compiled to WebAssembly, so the browser runs the rules rather
than asking a server about them. That page needs no server at all and is what gets published to
GitHub Pages. See [In the browser](#in-the-browser).

## Requirements

SWI-Prolog 9 or later (`brew install swi-prolog`). No third-party packs — the HTTP server, CSV
reader and plunit all ship with SWI. The airport table is committed, so a fresh clone runs offline.

Node is needed only to rebuild the generated files — the stylesheet, the map bundle, the WebAssembly
pair and the loyalty earning tables — and only if you edit them: all are committed. Running, testing
and deploying the validator never touch npm, and neither does the page once it is built. See
[Web UI](#web-ui).

## Use

```sh
# run the service and open the UI at http://localhost:8080
swipl prolog/cli.pl -- serve --port 8080

# validate one itinerary, human-readable
swipl prolog/cli.pl -- validate prolog/test/fixtures/lhr_classic.json

# the same report as JSON
swipl prolog/cli.pl -- validate prolog/test/fixtures/mut_dup_sector.json --json

# list every rule that was measured, not just the ones that were broken
swipl prolog/cli.pl -- validate prolog/test/fixtures/lhr_classic.json --checks

# check a routing with no dates at all
swipl prolog/cli.pl -- route "NYC-BA-X/LON-QR-BKK//SIN-QF-SYD-QF-X/LAX-AA-NYC" --cabin business

# what the same ticket would earn, in every registered loyalty programme
swipl prolog/cli.pl -- earn prolog/test/fixtures/lhr_classes.json
```

### Routings

Most of the ruleset is about *where* the journey goes, not when. So an itinerary can be given the
way a fare is actually written down, with no dates anywhere:

```
NYC-BA-X/LON-QR-BKK//SIN-QF-SYD-QF-X/LAX-AA-NYC
```

| Notation | Meaning |
|---|---|
| `-` | separates points; whitespace and commas do too |
| `X/JFK`, `XJFK` | a transfer at that point |
| `JFK` | a stopover — that is what the absence of `X/` means |
| `A//B` | that leg is a 4(g) surface sector, at the passenger's own expense |
| `BA` between two points | the carrier of the leg that follows |

Length tells the token kinds apart — airline designators are two characters and place codes are
three — so `XIY` is Xi'an rather than a transfer at `IY`, and nothing needs escaping. A handful of
4(j) affiliates do carry three-letter designators; those are read as carriers only when no airport
or city answers to the same code. `HAC` is both Hokkaido Air System and Hachijojima, so a routing
reads it as the airport, and composing a routing for an itinerary flown on HAC is refused rather
than written down as a string that would parse back into a different journey.

Metropolitan city codes (`NYC`, `LON`, `TYO`, …) are listed at
[`prolog/data/cities.pl`](prolog/data/cities.pl) and served from `/api/ruleset`. The table runs
both ways. Forwards, a city code resolves to a representative airport, so `NYC-LON` and `JFK-LHR`
are the same journey. Backwards, an airport knows the metropolitan area it belongs to — which is
what 4(i) is actually written in ("the same city pairs / sectors cannot be flown more than once")
and what 4(c) and 4(d) mean by a point. So `LON-NYC` flown out of Heathrow and back into Gatwick is
one city pair flown twice, a stop at Gatwick on a journey that began at Heathrow is travel via the
origin, and finishing at Gatwick is finishing at home rather than an origin-destination surface
sector. Airports that IATA holds as their own city are deliberately absent from the table — Paris
Beauvais, Westchester, Kitchener/Waterloo — because grouping places the fare rule keeps separate
invents violations, which is the more expensive way to be wrong.

Where there is a real gap, it is checked against 4(c)'s seven permitted relations and named in the
report, but it is **not** counted toward 4(h)'s maximum of 16. 4(h) does say "including surface
segments between any 2 airports", and the gap is between 2 airports — but the segments it has in
view are 4(g)'s intermediate ones, which are sectors of the journey, and the gap is the part of the
world the ticket deliberately does not cover. Counting it would cap an open-jaw journey at 15
flights while a closed loop gets 16, a penalty for using 4(c) that no clause in 4(c) or 4(h)
describes. Held itineraries agree: a 16-flight `CAI-…-DOH` closed by a 4(c)(b) Middle East open jaw
prices, and it cannot if the gap counts.

The same information can be given per segment instead, as `"stop": "transfer" | "stopover"` on the
segment that *arrives* at the point (`layover`, `connection` and `transit` are accepted for
`transfer`). A declaration outranks the clock — the traveller knows what was booked — but not a
surface sector, and where the two disagree the disagreement is reported as a warning rather than
resolved in silence.

An itinerary carries a `mode`: `full` (the default, and the only one that accepts times) or
`routing`. Routing mode has no calendar, so rules 6 and 7 have nothing to measure and are named in
the report's `notChecked` list. That is a different thing from `indeterminate`, which means data
this rule needs was left out; neither is a pass, and the CLI and UI render both.

```
$ swipl prolog/cli.pl -- route "LHR-BA-X/JFK-AA-X/LAX-QF-X/SYD-QF-X/SIN-BA-LHR"
INVALID — 1 error
  [8]          error           The journey has 0 stopovers. It needs at least 2.
Not checked — 1 rule this input cannot answer:
  [7]          Return travel from the last stopover must commence within 12 months of departure, …
Checks — 1 failed, 16 ok, 1 not run, 7 n/a. Re-run with --checks to list them.
```

### What it earns

A separate question, answered by a separate operation over the same annotated itinerary. It runs no
fare rules — a journey that cannot be sold can still be priced for what it would earn, and one that
is perfectly valid can be unpriceable.

```
$ swipl prolog/cli.pl -- earn prolog/test/fixtures/lhr_classes.json
Qantas Frequent Flyer
  25,500 Qantas Points, 660 Status Credits
  [1]   LHR-JFK     ok         4,000 Qantas Points, 100 Status Credits
                               Business (all flights) · 2,501 to 3,500 miles · 3,442 mi
  [2]   JFK-LAX     ok         3,125 Qantas Points, 100 Status Credits
                               Business (all flights) · East Coast USA/Canada and West Coast USA/Canada · 2,469 mi
  …
  These figures are an estimate. The airline's own calculator is authoritative.
  bands table read 2026-08-11 from https://www.qantas.com/en-au/frequent-flyer/calculators/…
```

Every line says which category it resolved, from which row, which route basis priced it and how far
the sector was measured to be — the earn register, and the counterpart of the check register above.
It is on by default, unlike the check register, because a points figure carries an air of having
been *calculated*, and this one was looked up in a table with no version, no clause numbers and no
notice period. The fetch date follows the totals for the same reason.

**A sector is priced off the most specific row that covers it** — a named region pair first, then
Intra-USA Short Haul, which is a region group that is itself banded on distance, then the "All other
flights" mileage bands. That middle case is why the route basis a programme returns is opaque to the
kernel rather than being "a region pair, else a band".

**A sector within 1.5% of a band edge says so.** What an airline bands on is ticketed mileage, which
is not a great-circle distance; everywhere except near an edge the two agree well inside the width of
a band, and near an edge is exactly where a good-enough answer stops being good enough. The edges are
asked for per *basis*, so a region pair — which never looked at the distance — is never flagged.

**Where the input cannot say which of several rates applies, the answer is the spread.** Cathay
lists the same economy booking classes — `Y,B,H,K`, then `M,L,V`, then `S,N,Q,O` — under Flex,
Essential *and* Light with different earn against each, so a ticket in `K` has genuinely bought one
of three things and the class cannot tell them apart. Give a `fareFamily` and the answer is a number;
leave it out and it is `18 to 35 Status Points`, with the register saying why. Never a midpoint: no
combination of the traveller's actual fares can produce one.

It is a narrower problem than the grid makes it look. Outside Economy the class picks the family out
on its own, and inside it `Y` is full-fare and therefore the flexible fare whatever the grid lists it
under. That last one is the only place in either programme where a fact that is not on the published
page decides an answer, so it is a predicate of its own — `cx_class_settled/3` — and the register
prints its reason instead of claiming the table said so. `B`, `H` and `K` are not settled that way
and stay a range.

**An itinerary that names a cabin has said more than it looks like it has.** Section 5(b) publishes
the class an Explorer fare books into, so a sector with no `bookingClass` is priced off the fare's
own class rather than refused, and the register says which code it used. Economy comes out as `L` —
what 5(b) actually says an economy Explorer fare books into — and not `Y`, which is the conventional
shorthand for the cabin and a different, much better-earning class. On the Qantas table `L` is
Discount Economy where `Y` is Flexible Economy, so presuming `Y` would overstate the earn by roughly
double, and wrong-high is the bad direction for an estimate. Only the *applicable* codes are used,
never the alternates 5(b)'s notes permit in a stated case: those turn on what the flight offers,
which is a seat map rather than a tariff.

**A membership tier changes the answer, and says where.** `"members": {"qff": {"tier": "gold"}}`
adds Qantas' status bonus — 50% at Silver, 75% at Gold, 100% at Platinum. It reaches Qantas Points
and not Status Credits, which is the currency's own `bonus_applies` flag rather than a conditional
anywhere; and it is a benefit of flying Qantas rather than of holding a card, so the same journey
carries a bonus on one sector and none on the next. Each figure shows the split —
`23,625 Qantas Points (13,500 + 10,125 Gold)`. A tier the programme does not publish is refused
rather than quietly priced at the base rate, which a member who mistyped it could not otherwise tell
from having no status at all.

**Nothing that could not be priced is reported as zero.** A sector whose class was not given, whose
operating carrier is unnamed, or whose category depends on a table that is not loaded, comes back
`undecided`, and the journey total then reads "0 Qantas Points or more (5 sectors unpriced)" rather
than a smaller number that looks complete. A rate a table publishes as a dash is a third thing again
— "no Status Credits", which is a fact, not a gap.

More than one programme can be asked at once, and the reply carries sub-totals per programme and
**no ranking between them**: a mile and a Status Point are not commensurable without a valuation,
valuations are opinions, and every number here traces to a row. See
[`PLANS/05-loyalty-earning.md`](PLANS/05-loyalty-earning.md) for the design and what is still
missing.

### What passed, and by how much

"No rule was broken" is a claim about coverage that a reader has no way to audit, and the number a
cap was cleared by is what a fare-construction tool is actually asked. So every report carries a
**check register** alongside the violations: one line per rule, stating what it measured.

```
$ swipl prolog/cli.pl -- validate prolog/test/fixtures/lhr_classic.json --checks
VALID
Checks — 18 ok, 7 n/a:
  [4(e)]       ok        Intercontinental sectors              Each continent has a limit on flig…
  [4(h)]       ok        Segment count                         The journey has 7 segments. The ru…
  [4(i)]       ok        Repeated sectors                      The journey flies 7 sectors. It fl…
  [4(l)]       n/a       Australian city pairs                 The journey has no flight inside A…
  [5(b)]       n/a       Booking codes                         No segment states the class it is …
  [7]          ok        Maximum stay                          16 days pass between the first fli…
  [8]          ok        Stopovers                             The journey has 4 stopovers. It ne…
```

Every line is written to be read once. Short sentences, one fact each, common words, and the
continents spelled the way a person says them rather than the way the table keys them —
`europe_middle_east` is a key, "Europe & Middle East" is a place. The report carries its own table
of those names so the page never has to guess at one or wait for a second request before it can
render the first report.

A check clause states the measurement and nothing else. Its outcome — `ok`, `failed`, `flagged`,
`undecided`, `not run`, `n/a` — is derived by the driver from the violations the same run produced,
so the register cannot contradict the verdict above it, and a rule cannot be marked satisfied by
forgetting to check it. The suite asserts the other half: no rule can fire without a check covering
it.

The four ways a rule can come out other than pass or fail are distinct on purpose. `undecided` is
data the input left out, `not run` is a rule the input *mode* cannot answer, and `n/a` is a rule the
itinerary never engages — 4(l) with no Australian sectors is not a restriction cleared. The register
is withheld entirely when the input has errors: caps measured over an itinerary that did not parse
describe a journey nobody submitted.

### Web UI

The page in [`web/`](web/) is served at `/` by `swipl prolog/cli.pl -- serve`, and is also a static
site that works with no server behind it at all — see [In the browser](#in-the-browser). The report
is the page: on a wide screen the form takes a sidebar and the answer takes the rest. There are two
ways to enter a journey, on two tabs, because they are different jobs rather than one job at two
levels of detail:

* **Routing** — one line, `LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-QR-LHR`, handed over as
  `{"route": …}` for Prolog to parse. A routing that parses fills the Segments tab in, using the
  validator's own reading of it, so it can be refined without retyping. The field wraps rather than
  scrolling sideways, which the grammar allows for free — whitespace is a separator, so a routing
  broken across lines parses exactly as one line does.
* **Segments** — the flight-by-flight table, handed over as `{"mode": …, "segments": […]}`, with
  airport typeahead (accent-folded, so `sao paulo` finds São Paulo and `belem` finds Belém), a
  per-segment stop-kind column, a booking class, a fare family, and a switch for whether dates and
  times are supplied at all. With no clock the time columns are hidden rather than offered and then
  refused; the fare-family column is hidden the same way when no registered earning programme prices
  one, which the page learns from the validator rather than deciding for itself. **Show as routing**
  sends the table through the `routing` operation and writes it back out as one line. This is the
  one view a sidebar cannot hold — eleven columns — so opening it widens the form to an equal share
  of the page and closing it gives the width back.

Neither direction of the grammar is implemented in the browser: reading a routing is the `validate`
operation's job and writing one is `routing`'s. A copy of the grammar in JavaScript would be the one
nothing tests, and with both directions in Prolog the suite can assert that a routing survives the
round trip.

Cabin and passengers sit above the tabs: they describe the fare, not the routing, and survive
switching. The report panel gives the verdict, the fare basis, each violation with its citation and
evidence, the rules the input could not answer, an expandable **Rules evaluated** register of every
check and what it measured, and how every connection was classified and by which source. The
register is collapsed by default — it is four times the length of the verdict it supports — and
`ok` is the quietest thing in it, since on a valid itinerary it is every row and colouring them all
would leave nothing for the one that is not. Editing the form after a verdict marks the report as out of date rather than leaving a stale
answer looking current.

**The earning panel** sits under the report, because earning is a different question answered by a
different operation: an itinerary that cannot be sold can still be priced for what it would earn, and
one that is perfectly valid can be unpriceable. It shows a total per programme and, per segment, the
figure with the row it was read off underneath — the earn register, and the counterpart of the check
register. A programme picker above it is built from the validator's own list, so the page names no
programme, no currency and no fare family of its own; unticking one re-prices without re-validating,
since the itinerary did not change. Programmes are listed, never ranked: a mile and a Status Point
are not commensurable without a valuation, and a valuation is an opinion.

**The route map** under Connections is drawn by [`web/map.src.js`](web/map.src.js) from the
coordinates already in `annotations`: a great-circle arc per segment, dashed for a surface sector,
filled markers for stopovers and hollow ones for transfers. Hovering a connection lights up the same
airport on the map.

There are no tiles, and that is the point. A slippy map over OpenStreetMap would put the page back
on the network — the same reason the fonts and the stylesheet are bundled — and street-level tiles
carry nothing legible at the only zoom a round-the-world route is ever viewed at. `d3-geo` plus the
Natural Earth 110m land outline is 55 KB of data, renders as vectors that scale for free, and needs
no runtime beyond the browser. The projection is equirectangular and cut at the antimeridian: a
closed loop around the globe cannot be drawn on a rectangle without one cut somewhere, and the
Pacific is where every round-the-world map puts it.

**The itinerary lives in the URL**, so a routing can be pasted into a message and come back as a
validated report. Opening a link populates the form, picks the right tab, and validates.

| Parameter | Holds |
|---|---|
| `r` | the routing box, verbatim |
| `s` | the segment table, base64url JSON — only when it was typed rather than parsed from `r` |
| `t=s` | the Segments tab was the one being looked at |
| `c`, `p` | cabin and passengers, only when not the default |
| `b`, `f` | booking class and fare family, one character per segment, `-` for a gap |
| `g` | the earning programmes, only when not all of them |
| `m` | membership tiers, as `qff:gold`, comma-separated |

```
?r=LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR
?r=LON-BA-NYC-AA-X/DFW-AA-LAX-QF-SYD//MEL-QF-X/SIN-BA-LON&c=economy&p=adult%2Bchild
?r=LHR-CX-HKG-CX-NRT-JL-LAX-BA-LHR&b=DKJD&f=-F
```

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

**Colour scheme** is a three-way control in the header: Auto, Light, Dark. Auto follows the OS and
stores nothing, so a machine that has never been told otherwise keeps tracking it. The whole theme
is one `color-scheme` declaration — every token is a `light-dark(light, dark)` pair, so the two
values that have to stay related sit on the same line, and the browser's own furniture (scrollbars,
form controls, the canvas behind the page) switches with the page. A small inline script in
`<head>` applies a stored choice before first paint; it is the only script on the page that is not
deferred.

The page hardcodes no rule data — version, segment limits, city codes and the routing grammar all
come from the validator's own `ruleset` reply.

**Building.** Four files under `web/` are generated and **committed**, for the same reason
`data/generated/airports.pl` is: a clone runs offline and any change shows up as a reviewable diff.
Nothing at runtime, and nothing in the Docker build, needs node.

| Generated | From | By |
|---|---|---|
| `web/app.css` | `web/app.src.css` | Tailwind CLI |
| `web/map.js` | `web/map.src.js` + `d3-geo`, `topojson-client`, `world-atlas` | esbuild |
| `web/rtw.pvm` | every `.pl` under `prolog/`, via `prolog/wasm.pl` | `prolog/tools/build_image.mjs` |
| `web/vendor/swipl-bundle-no-data.js` | the `swipl-wasm` package | copied verbatim |
| `web/rtw.build.json` | a digest of the above two inputs | `prolog/tools/build_image.mjs` |
| `prolog/data/earn/qff/*.pl` | the captures in `prolog/data/earn/sources/` | `prolog/tools/build_qff_tables.mjs` |
| `prolog/data/earn/cx/*.pl` | the same | `prolog/tools/build_cx_tables.mjs` |

```sh
npm install                # once
npm run build              # rebuild all four
npm run css                # or just the stylesheet
npm run map                # or just the map bundle
npm run wasm               # or just the WebAssembly pair
npm run earn:qff           # or just the Qantas earning tables
npm run earn:cx            # or just the Cathay earning tables
npm run css:watch          # leave running while working on styles
npm run check:contrast     # WCAG check over the palette, no browser needed
npm run test:wasm          # the browser build answers what the native one answers
```

If you change a class in `web/index.html` or `web/app.js` and forget to rebuild, the page renders
without that style; if you change a rule and forget, the page validates against the *old* rules,
which is the worse of the two because nothing looks wrong. `npm run build` followed by
`git status --porcelain -- web/` catches both, and the Pages workflow refuses to deploy without it.

That check works because `npm run wasm` is idempotent: a SWI saved state is a ZIP archive and records
the time it was written, so two builds of identical sources differ in every compressed byte. Rather
than compare bytes, the build records a digest of its inputs in `web/rtw.build.json` and does nothing
when they already match — which moves the question from "are these bytes what we would produce now"
to "was this built from these sources". `npm run wasm -- --force` rebuilds regardless.

The server reads `web/` into memory **at load time**, so a change to any of these files normally
needs a restart to show up. `--dev` turns that off:

```sh
swipl prolog/cli.pl -- serve --dev        # or: RTW_DEV_ASSETS=1 swipl prolog/daemon.pl …
```

Each request then re-reads the file from the build directory and replies `Cache-Control: no-store`,
so an edit plus a browser reload is the whole loop. It prints a warning at startup, falls back to
the copy in the program if a file has gone, and is off unless you ask for it — the path it re-reads
from is the one baked in at compile time, which is right on the machine that compiled it and
nowhere else. **Do not set it in production**: reading the page into the program is what lets the
container run read-only with no filesystem access in the request path.

Both fonts are bundled under [`web/fonts/`](web/fonts/) rather than fetched from a CDN: the service
is meant to run offline and read-only, and a font request would be the only outbound call the page
makes. They are OFL-licensed; see [`web/fonts/NOTICE.md`](web/fonts/NOTICE.md).

Exit codes: `0` valid, `1` invalid or indeterminate, `2` malformed input, `3` internal error.

```
INVALID — 1 error
  [4(i)]       error           Sector NRT-HKG flown twice in the same direction (segments 4 and 6).
Fare basis: DONE3 (3 continents, business)
```

## In the browser

The page does not ask a server whether an itinerary is valid. It runs the validator itself: SWI-Prolog
compiled to WebAssembly, loading an image built from the same `.pl` files the container runs. Nothing
is reimplemented in JavaScript, and there is no second copy of a rule to fall out of step with the
first.

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

**What it costs.** About 1.3 MB gzipped, in two files:

| File | Raw | Gzipped |
|---|---|---|
| `web/vendor/swipl-bundle-no-data.js` | 2.5 MB | 865 KB |
| `web/rtw.pvm` | 416 KB | (already compressed) |

The image carries the Prolog library with it, which is why the stock `swipl-web.data` is not shipped
at all — that is what makes this pair about 700 KB smaller than serving the sources plus the standard
library. It boots in roughly 50 ms; a sixteen-segment itinerary then validates in about a
millisecond, which is faster than the round trip it replaces.

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

### GitHub Pages

`web/` is the site. It has no build output that is not committed and no absolute paths, so it can be
served from anywhere — including `https://<user>.github.io/<repo>/`, which is why every path on the
page is relative: an absolute `/app.css` works behind the service and 404s under a project subpath.

[`.github/workflows/pages.yml`](.github/workflows/pages.yml) runs the Prolog suite, rebuilds every
generated file, refuses to continue if the result differs from what was committed, runs the parity
test and the contrast check, then publishes `web/`. The freshness check is the one that matters: a
stale `rtw.pvm` would publish rules that are not the ones in the source tree, and nothing downstream
would notice.

Pages has to be pointed at Actions once, by hand: **Settings → Pages → Build and deployment →
Source: GitHub Actions**.

To look at the static site locally, serve the directory with anything:

```sh
python3 -m http.server 8000 --directory web      # then http://localhost:8000/
```

## Deployment

The service is what you deploy when something other than a browser needs to ask — the HTTP API below
is the only way to validate an itinerary from a script, a scheduler or another service. It serves the
same page as the static site, and that page runs the same WebAssembly validator either way; the
container is not doing the validating for it.

`cli.pl serve` is for development: it parks the main thread on a message that never arrives, so a
`SIGTERM` kills work in flight. Production uses [`prolog/daemon.pl`](prolog/daemon.pl), which is
`library(http/http_unix_daemon)` plus the application. That supplies the whole daemon CLI —
`--port --ip --user --group --workers --pidfile --fork --syslog --https --certfile --keyfile` — and
the signal handling: SIGINT/SIGTERM shut down without abandoning in-flight requests, SIGHUP reloads,
SIGUSR1 reopens logs.

### Docker

Build. The airport table is committed, so the build needs no network and nothing is compiled:

```sh
docker build -t rtw-validator .
```

Run. The first form is enough to try it; the second is how to deploy it:

```sh
# quick look — the UI is then at http://localhost:8080
docker run --rm -p 8080:8080 rtw-validator

# hardened: no root, no writable filesystem, no capabilities
docker run -d --name rtw -p 8080:8080 \
  --read-only --cap-drop=ALL --security-opt no-new-privileges \
  --restart unless-stopped \
  rtw-validator
```

Everything after the image name is passed to the daemon, so `CMD` is the place to change the port
or the worker count. Note that `-p` maps the *host* port to the container's, so both must change
together:

```sh
docker run -d --name rtw -p 9000:9000 rtw-validator --port=9000 --workers=32
```

Operate it:

```sh
docker logs -f rtw                                     # stderr: startup, 500s with backtraces
docker inspect --format '{{.State.Health.Status}}' rtw # the built-in HEALTHCHECK
curl -fsS localhost:8080/api/health
docker stop rtw && docker start rtw                    # SIGTERM is handled; stop returns in ~0.5s
docker build -t rtw-validator . && docker rm -f rtw    # rebuild after a change, then run again
```

The image carries the CLI too, so it can validate a file without a server:

```sh
docker run --rm -i --entrypoint swipl rtw-validator \
  /app/prolog/cli.pl -- route "NYC-BA-X/LON-QR-SIN-QF-SYD-QF-X/LAX-AA-NYC"
```

**Building on Apple Silicon for an x86 host** — the image is architecture-specific, and a `linux/arm64`
image will not start on a `linux/amd64` server:

```sh
docker buildx build --platform linux/amd64 -t rtw-validator:amd64 --load .
```

Access logging is off unless `RTW_HTTP_LOG` names a file — a reverse proxy usually logs this better,
and merely loading `library(http/http_log)` would otherwise write `httpd.log` into the working
directory. To turn it on, give the container somewhere writable, since the root filesystem is not.
The `mode=1777` matters: a bare `--tmpfs` mounts root-owned and the server runs as uid 10001, and
`library(http/http_log)` swallows the resulting permission error rather than failing loudly.

```sh
docker run -d --name rtw -p 8080:8080 --read-only --tmpfs /var/log:mode=1777 \
  -e RTW_HTTP_LOG=/var/log/rtw-http.log rtw-validator
```

The two environment variables the image reads are `RTW_HTTP_LOG` above and `RTW_DEV_ASSETS`, which
should never be set here: it makes the server re-read the UI from disk on every request, which is
the one thing the read-only, no-filesystem-in-the-request-path design exists to avoid. See
[Web UI](#web-ui).

The image runs as uid 10001 with every capability dropped, has no writable path, and ships neither
the test suite nor the fixtures. `HEALTHCHECK` polls `/api/health` every 30 s. The base image is
pinned to `swipl:10.0.2` rather than `:stable`, which moves; `docker buildx imagetools inspect
swipl:10.0.2` gives a digest if you want the build pinned harder than that.

### systemd

Use `Type=simple` with `--no-fork` — **not** `Type=forking`, which would wait for a parent that
never exits:

```ini
[Service]
Type=simple
User=rtw
WorkingDirectory=/opt/rtw
ExecStart=/usr/bin/swipl --stack-limit=512m prolog/daemon.pl --no-fork --port=8080 --workers=16
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
```

Only the parent needs to be root, and only to bind a privileged port; `--user` drops privileges
afterwards.

### Why the server is built the way it is

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

### HTTP API

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/validate` | itinerary JSON in, report JSON out |
| `POST` | `/api/routing` | itinerary JSON in, `{"route": …}` out — the same journey written as a routing, no rules run |
| `POST` | `/api/earn` | itinerary plus `programs` in, points and status currency out, no rules run |
| `GET` | `/api/programs` | the registered loyalty programmes, their currencies, and where each table was read |
| `GET` | `/api/ruleset` | version, limits, free-segment caps, carriers, city codes, routing grammar, continents, fare-basis and surcharge tables |
| `GET` | `/api/airports?q=&limit=` | typeahead over the airport table, accent-folded, with coordinates |
| `GET` | `/api/health` | status and ruleset version |
| `GET` | `/` | the bundled web UI |

Errors come back as `{"error": ..., "message": ...}`: `400 invalid_request` for malformed input,
`413 request_too_large`, `503 timeout`, `500 internal_error`. Request bodies are capped at 128 KB
and 100 segments, and each validation runs under a 10-second limit — all three in
[`prolog/data/limits.pl`](prolog/data/limits.pl) alongside the fare caps.

`/api/ruleset` exists so a web UI never hardcodes rule data, and `/api/programs` is its counterpart
on the earning side for the same reason: the page names no programme, no currency and no table. Every validate response carries a
`checks` array — `{rule, citation, label, outcome, detail}` per rule measured, see
[What passed, and by how much](#what-passed-and-by-how-much) — and an
`annotations` object — the derived route, the collapsed continent and traffic-conference sequences,
each connection's ground time and stopover classification, `annotations.names` (the display name for
every continent and traffic conference, so a client never has to invent one from the atom), and
`annotations.routing`, the whole journey written back out as a routing string — so a UI can draw the
itinerary and show *why* a rule fired rather than only printing its message.

```sh
curl -s -X POST localhost:8080/api/validate \
     -H 'content-type: application/json' \
     --data @prolog/test/fixtures/lhr_classic.json | jq .

# a dated itinerary, written back out as a routing
curl -s -X POST localhost:8080/api/routing \
     -H 'content-type: application/json' \
     --data @prolog/test/fixtures/lhr_classic.json
# {"route":"LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR"}
```

`/api/routing` is a separate endpoint rather than a flag on validate because it answers a different
question and runs no rules. It composes from the annotation pass, so a stop worked out from a
two-hour connection and one declared `X/` come out the same way, and the routing reaches the same
verdict as the itinerary it came from.

It refuses, with `400` and the segment numbers, when a point is neither a transfer nor a stopover: a
routing has no notation for "unknown", and a bare code means stopover, so guessing would change the
itinerary's meaning. `annotations.routing` is `null` in the same case.

### Itinerary format

```json
{
  "origin": "LHR",
  "cabin": "business",
  "mode": "full",
  "passengers": [{ "type": "adult" }],
  "segments": [
    { "n": 1, "type": "flight", "from": "LHR", "to": "JFK",
      "marketingCarrier": "BA", "operatingCarrier": "BA", "flight": "BA117",
      "dep": "2026-09-01T10:25", "arr": "2026-09-01T13:30", "stop": "stopover",
      "bookingClass": "D" },
    { "n": 2, "type": "surface", "from": "GRU", "to": "GIG" }
  ]
}
```

or, for the routing form:

```json
{ "route": "NYC-BA-X/LON-QR-SIN-QF-SYD-QF-X/LAX-AA-NYC", "cabin": "business" }
```

Only `segments[].{from,to}` and one of `segments`/`route` are required — giving both is an error,
since there would be no principled way to choose between them if they disagreed. `cabin` defaults to
economy, `origin` to the departure point of segment 1, `type` to `flight`, and `mode` to `full` for
`segments` and `routing` for `route`. Times are **local wall-clock** times; a zone designator is
accepted and discarded. `stop` on the last segment is ignored — the journey ends there, so there is
no intermediate point to describe.

`carrier` is shorthand that fills both carrier fields; `marketingCarrier` on its own leaves the
operator unknown rather than assuming there is no codeshare.

`bookingClass` is the single RBD letter the segment is sold in, and it is what rule 5(b) reads.
`fareFamily` is the carrier's branded fare — Cathay's `flex`, `essential` or `light` — which no fare
rule reads at all and which one loyalty programme cannot price a sector without. Both are optional
and neither affects any other rule. A missing `bookingClass` is *not* filled in for rule 5(b), which
checks the class that was booked and would otherwise report a pass it never checked; only the earning
side reads the tariff to fill the gap, and only because an estimate may.

`members` is optional and read by nothing but the earning side:

```json
"members": { "qff": { "tier": "gold" } }
``` Which 5(b) row it is read against is decided by the
*marketing* carrier — 5(b) is about the code the fare is sold in, and the seller is who sells it,
unlike 4(j), which turns on who operates.

Missing information degrades honestly rather than silently passing: a connection with neither a
timestamp nor a declared stop kind makes rule 8 `indeterminate` and the verdict `indeterminate`, and
an absent operating carrier makes 4(j) a `warning`. A journey that touches Cuba with no carrier
named anywhere makes rule 15 `indeterminate` for the same reason: the restriction is about who
flies it, the sector that puts most itineraries into Cuba is American, and "it does not use
American or Alaska" is not something the report may say about an input that named nobody. Warnings
alone leave a verdict of `valid`.
Routing mode relaxes which rules *apply*, never the standard of evidence for the ones that do.

Because the times are local, an eastbound trans-Pacific sector legitimately arrives at an earlier
clock time than it departed — NRT 17:00 to LAX 10:00 the same day. Only a regression wider than the
span of world time zones is treated as a data error.

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

## Geography

`prolog/data/earn/cx/zones.pl` is the **fourth**: five zones of pure distance and a sixth,
Short - Type 2, which is the *same* 751-to-2,750-mile band as Short - Type 1 and is separated from it
only by whether the sector is to or from Japan, Indonesia, Sri Lanka, Nepal, Bangladesh or India. No
distance decides it, which is why the route basis a programme resolves takes the endpoints and not
just a distance.

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
   enough; and that Asia Miles are exactly a hundred Status Points in every row of the table, since
   the day that stops being true is far likelier to be the day a row was mistranscribed.

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

## Scope

Checked: 4(a)–4(l), 5(b), 6, 7, 8, 15, 19, and the section 0 continent-count to fare-basis mapping.

Not checked, because they are not decidable from an itinerary: capacity limitations, GDS fare
amounts, group travel, and voluntary-change fees.

5(b) is checked only where the itinerary says what class it was sold in, which is optional — see
`bookingClass` in [Itinerary format](#itinerary-format). With no class anywhere the register says it
had nothing to read, which is deliberately not `indeterminate`: a routing is a fare notation with
nowhere to write a booking code, and treating that as missing data would make every routing
undecidable over a field the notation cannot express.

Where a class *is* given, three outcomes are possible, because 5(b) has three kinds of class in it.
The applicable code for the cabin passes. Anything the table does not name for that carrier is an
error. In between sit the codes its notes permit conditionally — a lower cabin's own code, `Y` on a
First fare, `B` (or `H` on AA) on a DONE Business fare, and `A` on QR for services within the Middle
East — and those are flagged rather than refused, because every one of them turns on what the
*flight* offers. "For flights where First or Business Class is not offered or available, passengers
may travel in a lower class" makes a business fare ticketed in `L` legal on an aircraft with no
business cabin and illegal on one that has it, and an itinerary carries the route, not the seat map.

One rule is checked but cannot be decided, and says so. Rule 19's real trigger is an infant
*reaching* two years old between departure and the end of the journey, and the input carries an age
rather than a date of birth — so a one-year-old who turns two next month and one who turned one
last week are the same value here. On a fare whose journey may run a full twelve months that is a
live case, and the consequence is a full child fare bought retroactively for the whole trip, so an
infant stated as 1 draws a warning rather than silence. Supplying a date of birth would make it
decidable; nothing else would.

### What the ticket earns

Not part of Rule 3015 at all, and a separate operation for that reason — see
[What it earns](#what-it-earns) and [`PLANS/05-loyalty-earning.md`](PLANS/05-loyalty-earning.md).
Two programmes are registered. Qantas Frequent Flyer is priced off its published region pairs and
mileage bands; Cathay off its distance zones, for Cathay-marketed flights only. Effective dating,
Cathay's partner earn and tier bonuses are the phases still to come, and the tables that have not
been captured yet are listed in
[`prolog/data/earn/sources/README.md`](prolog/data/earn/sources/README.md).

Deliberately out of scope in both programmes: award bookings, which earn nothing; Qantas Loyalty
Bonus, Points Club and lifetime credits; Cathay's non-oneworld partners; miles from anything that is
not a flight; and any ranking of one programme against another, since a mile and a Status Point are
not commensurable without a valuation and a valuation is an opinion.

There is deliberately no "too many continents" rule: the fare table stops at six and the continent
list has exactly six members, so it could never fire. What it would have been reaching for — that
the fare table covers every count the geography can produce — is asserted as a test instead.
