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

This file is how to use it. [`DESIGN.md`](DESIGN.md) is why it is built the way it is — the rule
readings that are not obvious, the shape of the code, and what the test suite is actually for.

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

A report names the verdict, then every rule broken with the clause it came from, then the fare basis:

```
INVALID — 1 error
  [4(i)]       error           Sector NRT-HKG flown twice in the same direction (segments 4 and 6).
Fare basis: DONE3 (3 continents, business)
```

Exit codes: `0` valid, `1` invalid or indeterminate, `2` malformed input, `3` internal error.

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

A 4(c) origin–destination gap is checked against the seven relations that clause permits and named
in the report, but it is **not** counted toward 4(h)'s maximum of 16 segments — see
[Reading the rule](DESIGN.md#reading-the-rule-where-it-is-ambiguous).

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

**Which table prices a sector is decided by who sold it**, and the two registered programmes read
their tables in quite different ways — Qantas from region pairs and mileage bands, Asia Miles from
distance zones for Cathay's own flights and a percentage of the distance flown for its 25 partners.
[`DESIGN.md`](DESIGN.md#what-the-ticket-earns) sets out both models, why a class alone sometimes
cannot settle a rate, and how the answer says so.

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

Cabin and passengers sit above the tabs: they describe the fare, not the routing, and survive
switching. The report panel gives the verdict, the fare basis, each violation with its citation and
evidence, **the route drawn as a map**, and an expandable **Rules evaluated** register of every rule
measured and what it measured — including the ones this input could not answer, which read `not run`
there and are not called out separately above. The register is collapsed by default — it is four
times the length of the verdict it supports — and `ok` is the quietest thing in it, since on a valid
itinerary it is every row and colouring them all would leave nothing for the one that is not. Editing
the form after a verdict marks the report as out of date rather than leaving a stale answer looking
current.

**The earning panel** is its own panel, because earning is a different question answered by a
different operation: an itinerary that cannot be sold can still be priced for what it would earn, and
one that is perfectly valid can be unpriceable. Every registered programme gets a section, built from
the validator's own list, so the page names no programme, no currency, no fare family and no tier of
its own. The programme's name and its totals are the section's heading and are always on screen;
opening it adds everything that makes those totals checkable — the figure for each sector with the
row it was read off underneath, the estimate caveat, and the tables with the dates they were read.
That per-segment register is the earn register, the counterpart of the check register, and sectors
that could not be priced are grouped by the reason they could not, so a journey where nothing
resolved reads as one fact rather than as sixteen.

**A membership tier lives inside the programme that publishes it** — `"members": {"qff": {"tier":
"gold"}}` from a control in the Qantas section rather than a row of settings above the panel, because
it is a fact about the traveller's relationship with that one airline. Changing it re-prices without
re-validating, since the itinerary did not change. Programmes are listed, never ranked: a mile and a
Status Point are not commensurable without a valuation, and a valuation is an opinion.

**The route map** sits in the report, under the rules the journey broke, and is drawn by
[`web/map.src.js`](web/map.src.js) from the coordinates already in `annotations`: a great-circle arc
per segment, dashed for a surface sector, filled markers for stopovers and hollow ones for transfers.
Hovering a connection in the panel beside lights up the same airport on the map.

**The itinerary lives in the URL**, so a routing can be pasted into a message and come back as a
validated report. Opening a link populates the form, picks the right tab, and validates.

| Parameter | Holds |
|---|---|
| `r` | the routing box, verbatim |
| `s` | the segment table, base64url JSON — only when it was typed rather than parsed from `r` |
| `t=s` | the Segments tab was the one being looked at |
| `c`, `p` | cabin and passengers, only when not the default |
| `b`, `f` | booking class and fare family, one character per segment, `-` for a gap |
| `g` | which earning programme sections are open, only when not all of them |
| `m` | membership tiers, as `qff:gold`, comma-separated |

```
?r=LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR
?r=LON-BA-NYC-AA-X/DFW-AA-LAX-QF-SYD//MEL-QF-X/SIN-BA-LON&c=economy&p=adult%2Bchild
?r=LHR-CX-HKG-CX-NRT-JL-LAX-BA-LHR&b=DKJD&f=-F
```

**Colour scheme** is a three-way control in the header: Auto, Light, Dark. Auto follows the OS and
stores nothing, so a machine that has never been told otherwise keeps tracking it.

## Building

Everything below is generated and **committed**, for the same reason `data/generated/airports.pl`
is: a clone runs offline and any change shows up as a reviewable diff. Nothing at runtime, and
nothing in the Docker build, needs node.

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
npm run build              # rebuild everything in the table above
npm run css                # or just the stylesheet
npm run map                # or just the map bundle
npm run wasm               # or just the WebAssembly pair
npm run earn:qff           # or just the Qantas earning tables
npm run earn:cx            # or just the Asia Miles earning tables
npm run css:watch          # leave running while working on styles
npm run check:contrast     # WCAG check over the palette, no browser needed
npm run test:wasm          # the browser build answers what the native one answers
```

If you change a class in `web/index.html` or `web/app.js` and forget to rebuild, the page renders
without that style; if you change a rule and forget, the page validates against the *old* rules,
which is the worse of the two because nothing looks wrong. `npm run build` followed by
`git status --porcelain -- web/` catches both, and the Pages workflow refuses to deploy without it.

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

## In the browser

The page does not ask a server whether an itinerary is valid. It runs the validator itself: SWI-Prolog
compiled to WebAssembly, loading an image built from the same `.pl` files the container runs. Nothing
is reimplemented in JavaScript, and there is no second copy of a rule to fall out of step with the
first.

**What it costs.** About 1.3 MB gzipped, in two files:

| File | Raw | Gzipped |
|---|---|---|
| `web/vendor/swipl-bundle-no-data.js` | 2.5 MB | 865 KB |
| `web/rtw.pvm` | 416 KB | (already compressed) |

The image carries the Prolog library with it, which is why the stock `swipl-web.data` is not shipped
at all — that is what makes this pair about 700 KB smaller than serving the sources plus the standard
library. It boots in roughly 50 ms; a sixteen-segment itinerary then validates in about a
millisecond, which is faster than the round trip it replaces.

[`DESIGN.md`](DESIGN.md#in-the-browser-webassembly) covers what the WebAssembly build constrains,
and how the two engines are held to the same answers.

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
on the earning side for the same reason: the page names no programme, no currency and no table.
Every validate response carries a `checks` array — `{rule, citation, label, outcome, detail}` per
rule measured, see [What passed, and by how much](#what-passed-and-by-how-much) — and an
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

## Itinerary format

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
Which 5(b) row it is read against is decided by the *marketing* carrier — 5(b) is about the code the
fare is sold in, and the seller is who sells it, unlike 4(j), which turns on who operates. A missing
`bookingClass` is *not* filled in for rule 5(b), which checks the class that was booked and would
otherwise report a pass it never checked; only the earning side reads the tariff to fill the gap, and
only because an estimate may.

`fareFamily` is the carrier's branded fare — Cathay's `flex`, `essential` or `light`, which are the
only fare brands either programme prices — read by no fare rule at all, and the thing Cathay's own
Economy cannot be priced to a single number without. Both are optional and neither affects any other
rule.

`members` is optional and read by nothing but the earning side:

```json
"members": { "qff": { "tier": "gold" } }
```

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

## Tests

```sh
swipl -g run_tests -t halt prolog/test/run_tests.pl   # 263 tests, no node needed
npm run test:wasm                                     # the browser build against the native one
npm run check:contrast                                # WCAG over the palette, no browser needed
```

Ten suites; [`DESIGN.md`](DESIGN.md#tests) says what each is for and which of them are load-bearing.
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
East. Those pass too, and the register names the segments and the note they lean on; see
[Reading the rule](DESIGN.md#reading-the-rule-where-it-is-ambiguous) for why they are not warnings.

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
Two programmes are registered. Qantas Frequent Flyer is priced off both its published tables — its
own for Qantas-marketed sectors, the partner one for everything else — with its status bonus applied.
Asia Miles covers Cathay and its 25 partners off two different models: Cathay's own flights from a
table of fixed amounts, every partner as a percentage of the distance flown. Effective dating and
Cathay's tiers are what is left, and the tables that have not been captured are listed in
[`prolog/data/earn/sources/README.md`](prolog/data/earn/sources/README.md).

Deliberately out of scope in both programmes: award bookings, which earn nothing; Qantas Loyalty
Bonus, Points Club and lifetime credits; miles from anything that is not a flight; and any ranking of
one programme against another, since a mile and a Status Point are not commensurable without a
valuation and a valuation is an opinion. Nine of Asia Miles' partners are outside oneworld and so
cannot appear on an Explorer fare at all; they are priced anyway, because the table publishes them
and leaving rows out of a transcription is how a transcription stops being one.

[`DESIGN.md`](DESIGN.md) has the rest: how the rules are structured, the four geography taxonomies,
the earning kernel and its plugin protocol, the WebAssembly target, and the test suites.
