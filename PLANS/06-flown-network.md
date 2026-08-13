# The network the fare can be flown on

## The problem

The validator answers "may this itinerary be sold as an Explorer fare". It cannot answer "is there
a flight", because it has no model of which sectors exist. That is why it can check a routing and
not propose one: `validate:violation/2` succeeds when a rule is *broken*, which makes it a checker
and not something you can run backwards.

This plan adds the missing model — a committed table of "carrier C flies A to B nonstop" — and the
narrow query surface over it. **It delivers data, not search.** Generating itineraries is the next
piece of work and is deliberately out of scope here; the note at the end says what it will need
beyond this table.

Acquisition is [`07-wikipedia-extraction.md`](07-wikipedia-extraction.md). The two documents meet
at the fact shape in Phase 0, and the shape is decided here: the extractor's convenience does not
get to choose it.

## Why Wikipedia, and why not a schedule API

Every generated file in this repository is committed, and a fresh clone runs offline. OAG, Cirium
and AeroDataBox all forbid redistributing their data, so none of them can supply a committed table
at all. Wikipedia's airport articles are CC BY-SA, which permits it.

The **airport**-side tables (`== Airlines and destinations ==`) are the source. The **airline**-side
articles are not: WikiProject convention there is to list destinations without routing, which gives
a set of cities rather than a set of pairs. They are used in 07 only to enumerate which airport
articles to read.

Three properties of the airport tables happen to line up with the tariff:

- Codeshares are excluded by convention for the secondary carrier, so rows are close to
  operating-carrier semantics — which is what 4(j) is written in.
- Regional affiliates get their own rows, preserving exactly the distinction `affiliate/3` and
  `permitted_operator/2` already encode.
- Seasonal service is annotated separately, so it need not be guessed.

## Non-goals

- No path search, itinerary generation or optimisation.
- No fare pricing, availability or booking-class data.
- No frequency, day-of-week, equipment or minimum-connect time. The honest output of a search over
  this table is a *routing string*, not a dated itinerary.
- No network access at validation time, at page load, or in the Docker build.
- No carriers outside the 4(j) member and affiliate lists.

---

## Phase 0 — the fact shape

Settle this first and record the reasoning in the generated file's header, because everything
downstream is shaped by it.

```prolog
:- encoding(utf8).

% service(Carrier, From, To, Season)
%   Carrier — IATA designator satisfying carriers:carrier_code/1
%   From/To — IATA codes present in data/generated/airports.pl
%   Season  — year_round | seasonal | unknown
service(ba, lhr, jfk, year_round).
service(ay, hel, rvn, seasonal).

% service_window(Carrier, From, To, begins(Date)) — or ends(Date).
%   Only where the article carries a dated annotation. Dates are ISO 8601.
service_window(qf, per, jnb, begins('2027-03-15')).
```

**Not `route/4`, and not `routes.pl`.** In this repository "route" and "routing" already mean the
fare-construction string — `src/io/route_in.pl`, `src/io/route_out.pl`, `annotated_route/2`,
`route_help/1`, `rtw_call(routing, …)`, the `{"route": …}` JSON key — and `r04_routing.pl` is
tariff section 4, not pathfinding. A `route/4` predicate holding graph edges would collide with all
of it. The file is `prolog/data/generated/services.pl`, the module over it is `src/network.pl`, and
the npm script is `services`.

**Lowercase unquoted atoms**, matching everything else: `airport(lhr, 'GB', 'GB-ENG', 'London', …)`,
`carriers([aa, as, …])`, `affiliate(ba, cj, 'BA CityFlyer')`. `'BA'` and `ba` are different atoms,
so an uppercase table would load cleanly and join with nothing — every lookup against `airport/6`,
`eligible_carrier/1` and `place_key/2` silently failing. Only ISO country and region codes are
uppercase here, and no code in this table is one.

Four decisions to write into the header:

1. **Edges are directed.** LHR's table listing BA→JFK and JFK's listing BA→LHR produce two facts.
   Genuine one-way scheduled service is rare, so asymmetry is a data-quality signal — reported, never
   silently repaired. Symmetrising would manufacture edges nothing sourced, which is the failure mode
   `.impeccable.md` principle 5 names.
2. **`unknown` is not `year_round`.** Seasonal marking upstream is known to be incomplete. Collapsing
   the two would promote unmarked seasonal service into year-round service, which is the data
   equivalent of letting `indeterminate` read as a pass.
3. **Future and terminated service is recorded but excluded from `service/4`.** A `[begins …]`
   annotation yields a `service_window/4` fact and no `service/4` fact. A sector that starts next
   March cannot be ticketed today.
4. **Charter and cargo are excluded entirely.**

## Phase 1 — acquisition

Owned by [`07-wikipedia-extraction.md`](07-wikipedia-extraction.md). Its contract with this plan is
the shape above plus the reject discipline: the extractor emits only rows it parsed cleanly, and
everything else goes to a reviewed rejects file rather than into the table as a best effort.

## Phase 2 — carrier reconciliation

Wikipedia's operator strings have to become designators. **Two-thirds of that table already exists**
in `prolog/src/carriers.pl`: `carrier_name/2` maps all sixteen member names ('British Airways' →
`ba`) and `affiliate/3` maps the fourteen affiliate names with their designators ('BA CityFlyer' →
`cj`, 'Envoy Air' → `mq`). A fresh table restating those would be a third copy of the vocabulary and
the one that drifts.

So `prolog/data/network/carrier_aliases.json` holds **only the delta** — spellings Wikipedia uses
that those two tables do not:

```json
{
  "aliases":  { "Japan Transocean Air (JTA)": "nu", "Iberia Regional": "yw" },
  "brands":   { "American Eagle": ["mq", "oh", "pt", "yx", "oo"] },
  "excluded": ["Fly Play", "Condor"]
}
```

A **brand** covers several operating certificates. Where the table cannot say which one flew,
the fact records the operating carrier as *unknown* rather than asserting `aa`. 4(j) already degrades
to a warning on an absent operating carrier; feeding it a wrong one is worse than feeding it nothing.

The file is JSON because the generator is Node. A Prolog test reads the same file and asserts every
designator it can produce satisfies `carriers:carrier_code/1` — that assertion is what stops the two
halves drifting, and it is cheap because both halves name the same file.

## Phase 3 — emit

`prolog/data/generated/services.pl`, with:

- `:- encoding(utf8).` first, matching `airports.pl`. Codes are ASCII; the header comment carries
  article titles, which are not.
- A header recording the manifest's article and revision counts, the extraction date, the four
  decisions above, and the CC BY-SA attribution — modelled on `web/fonts/NOTICE.md`, which is how
  this repo already handles a licence that travels with a file.
- Facts sorted canonically by `(Carrier, From, To)`, so a `--refresh` diff is reviewable.

Add `npm run services`. Whether it joins `npm run build` depends on Phase 6 of
[`07`](07-wikipedia-extraction.md): because `--pinned` reads only committed sources and opens no
socket, it *can* join, and then `pages.yml`'s `git status --porcelain` check covers a hand-edited
`services.pl` the same way it already covers `prolog/data/earn/`. `--refresh` never joins — it is
the step that talks to Wikimedia, and CI's green must not depend on a third party's uptime.

## Phase 4 — tests

New file `prolog/test/test_network.pl` (**not** `test_routes.pl`; `test_route.pl` is the routing
*grammar* suite), registered in `prolog/load.pl` and `prolog/test/run_tests.pl`.

1. **Referential integrity.** Every code in `services.pl` satisfies `geo:airport_known/1`; every
   carrier satisfies `carriers:carrier_code/1`. These are the two ways the table can be internally
   wrong.
2. **Coverage floor.** Each of the sixteen eligible carriers has at least one sector; each member's
   principal hubs have at least *N*; the total fact count is within a stated band. This is what fails
   loudly when a `--refresh` drops a hub's table, which is the regression actually worth catching.
3. **A hand-verified sample.** `prolog/test/fixtures/flyable.json` — a few dozen sectors checked by
   hand against a timetable — every one asserted present.
4. **Season values are exhaustive.** No fact carries a `Season` outside the three atoms.
5. **Asymmetry is reported, not enforced.** Count one-directional edges; fail only above a threshold.
   A handful is normal; hundreds means a section stopped parsing.
6. **Windowed service is absent from `service/4`.** No `service_window/4` subject is also a current
   edge.
7. **Encoding is declared**, matching the existing geography test.

**Do not assert that the existing fixtures are flyable.** They are rule-exercising constructions,
not ticketable itineraries: across the 58 files in `prolog/test/fixtures/` the 114 distinct sectors
include `AA JFK-ZZZ` (`zzz` is not an airport — it is the unknown-airport fixture), `UA JFK-LAX`
(deliberately an ineligible carrier), six sectors with no carrier at all, and pairs invented to
reach a rule (`AY CDG-NBO`, `JL MIA-NRT`, `AA BKK-JFK`, `AS JFK-ANC`, `QR NRT-KHI`, `MH ICN-SIN`).
Such a test fails on day one, acquires an exclusion list, and the exclusion list then absorbs every
genuine extraction regression it was meant to catch. Tests 2 and 3 give the same signal truthfully.

## Phase 5 — the query surface, and a fifth operation

`prolog/src/network.pl`, deterministic and side-effect free, first-argument indexed:
`serves/3`, `destinations/3`, `carriers_between/3`, and `manifest/1` for the snapshot date and
counts. It *includes* `services.pl` the way `geo.pl` includes `airports.pl`, so the facts get
indexing without a layer of indirection.

**Whether a sector is flown is not a fare-rule violation.** This repository already drew that
boundary once, for earning: "Not part of Rule 3015 at all, and a separate operation for that
reason." Rule 3015 says nothing about whether a flight exists; the evidence here is a wiki snapshot
of stated age; and absence of an edge is much weaker evidence than presence. Putting it in the
violation register would place a wiki-sourced claim beside clause-cited ones, in a register whose
whole design is that every entry cites a clause, and would make `verdict` mean two things.

So flyability is its own operation, `network`, beside `validate`, `routing`, `earn` and `ruleset`:

```prolog
network_report(Sectors, Coverage, Manifest)
```

with one entry per segment carrying `flown(Season)`, `absent`, `windowed(When)`,
`carrier_unknown`, or `not_applicable` for a surface sector — asking whether a surface sector is
flown is meaningless, since the traveller covers it themselves. Where marketing and operating
carriers differ, the lookup uses the operating carrier and the entry says which one it used; the
table's rows are operating-carrier rows.

That means all five of the places an operation lives: `rtw_do(network, …)` in `prolog/wasm.pl`, the
handler in `prolog/server.pl`, `prolog/src/io/network_out.pl`, a method in `web/api.js`, an op in
`web/worker.js`, and a case in `prolog/test/test_wasm.mjs`. The parity test exists to prove the two
engines answer the same; a new operation is exactly what it is for. Extend `ruleset_json/1` with the
manifest date and fact count, so the page never hardcodes them — the same treatment `limits` and
`cityCodes` already get.

## Phase 6 — measure before shipping it to the browser

`prolog/tools/build_image.mjs` sweeps every `.pl` under `prolog/` except `test/` and `tools/`, and
anything reachable from `load.pl` is compiled into `web/rtw.pvm`, which every visitor downloads. For
scale: `airports.pl` is 4,161 facts / 278 KB of source and the whole image today is 479 KB. A
services table of comparable order roughly doubles it, and the earlier estimate of "about four
thousand facts" is likely low — Envoy, PSA, Republic and SkyWest each carry hundreds of US regional
pairs, and directed edges double whatever the undirected count is.

Count first, then choose: accept the size, keep `network.pl` out of `load.pl` and fetch the table
separately in the browser, or ship members only and defer affiliates. Record the choice and the
measured numbers in `DESIGN.md` beside the existing WebAssembly cost table. Do not design the query
surface around a number nobody has measured.

---

## Acceptance criteria

- `npm run services -- --pinned` regenerates `services.pl` byte-identically from the committed
  sections, with no network access, and `git status --porcelain -- prolog/data/` is clean after.
- The full suite passes, including the coverage floor and the hand-verified sample.
- `npm run wasm && npm run test:wasm` — the image is current and both engines answer `network`
  identically.
- `swipl prolog/cli.pl -- validate 'LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR'`
  returns the verdict it returns today. Adding a network table must change no verdict; the
  separation in Phase 5 is what makes that true.
- No new runtime dependency; a fresh offline clone still runs.

## Known limitations, to be written into the README

- The table reflects the pinned revisions, not today. It is a snapshot with a stated age, and the
  manifest says how old each article's contribution is.
- Seasonal marking is incomplete upstream. `unknown` means unknown.
- Vandalism propagates. The mitigations are the reviewable diff and the ability to pin one article
  back to a known-good revision without freezing the rest.
- **Absence is weaker evidence than presence.** A missing sector costs a trip nobody plans; an
  invented sector costs an itinerary that validates and then will not ticket. This is why `absent`
  is reported by its own operation and never as a violation.

## What generation will need beyond this

Stated here so the next plan's scope is set correctly. The edge list is not the hard part.
`violation/2` cannot be run backwards, so a generator needs its own constraint model over the
continent sequence (section 0 picks the fare basis from the continent count), the stopover budget
(`free_segments/2` and rule 8) and the section 4 routing constraints, with this table supplying only
which sectors are available to it. Dates are absent from this model, so the honest output is a
routing string — which `src/io/route_in.pl` already parses, `src/io/route_out.pl` already composes,
and the suite already round-trips. `src/earn/distance.pl` provides `sector_distance/3` for ranking.

The realistic first milestone is **completing a partial routing** — given an origin and a set of
must-visit points, find sectors that close it legally — not generating from nothing.
