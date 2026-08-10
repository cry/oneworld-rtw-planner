# oneworld Explorer validator — implementation plan

## Context

`oneworld-rtw-planner` contains two documents and no code: `parsed-rules-aug-2026.md` (the
transcribed text of oneworld Explorer fare Rule 3015, version 27 FEB 26) and
`PLANS/01-initial-implementation.md` (the design rationale for a SWI-Prolog validator).

The goal is an engine that answers **"is this round-the-world itinerary a valid oneworld Explorer
fare?"** and, when it isn't, names every rule broken and why. Scope is validation + explanation
only — no itinerary generation or optimization.

This plan turns that design into an ordered build. It keeps the design document's two load-bearing
decisions intact — rules as *violation generators* (§2) and a single eager *annotation pass* (§3) —
and changes three things to serve the stated endgame of an HTTP service behind a web UI:

1. **JSON is the canonical input format from day one.** The design doc used Prolog fact files. Fact
   files are loaded by consulting them into a module, which mutates the global database and is not
   safe under SWI's multithreaded HTTP server. JSON in, JSON out, with a fact-file reader retained
   only as a convenience for hand-written test fixtures.
2. **The HTTP server goes up early**, on a one-rule vertical slice, so serialization and concurrency
   are settled while there is almost nothing to serialize. Every later rule lands in a service that
   already works.
3. **Generated airport data is committed to git**, so a clone runs offline and geography drift shows
   up as a reviewable diff.

`swipl` 10.0.2 is installed at `/opt/homebrew/bin/swipl`; the OurAirports CSV is reachable
(~12.7 MB). No third-party Prolog packs are needed — `library(http/*)`, `library(csv)`,
`library(aggregate)` and `plunit` are all in the SWI distribution.

---

## Architecture

Three layers, with a single contract between them.

```
JSON dict ──json_in──┐
                     ├──> raw spec ──itinerary:normalize──> Itin ──annotate──> A
fact file ─facts_in──┘                                                          │
                                                                    validate:validate/2
                                                                                │
                                                    report(Verdict, Violations, Fare)
                                                                                │
                                                      ┌─────────────────────────┴──────┐
                                                 explain (text, CLI)          json_out (dict, HTTP)
```

**The `report/3` term is the contract.** CLI and HTTP are two renderers of the same term; neither
layer contains rule logic. Everything below the contract is pure — no `assertz`, no tabling, no
global state — which is what makes the validator safe to call concurrently from server worker
threads. Reference data (airports, limits, surcharges) is static and consulted once at load.

### Repository layout

```
prolog/
  load.pl                    % consults src + data; entry point for tests
  cli.pl                     % swipl prolog/cli.pl -- validate <file> | serve
  server.pl                  % HTTP handlers
  src/
    itinerary.pl             % raw spec -> canonical Itin; input-level errors
    annotate.pl              % the derived-facts pass
    geo.pl                   % airport -> country/region -> continent -> TC
    carriers.pl              % eligible carriers, affiliates, codeshare policy
    pricing.pl               % continent count -> fare basis; §12 surcharges
    validate.pl              % findall driver + multifile violation/2 registry
    explain.pl               % report -> human text
    io/
      json_in.pl             % JSON dict -> raw spec
      json_out.pl            % report -> JSON dict
      facts_in.pl            % fact file -> raw spec (fixtures only)
  data/
    generated/airports.pl    % committed, built from OurAirports CSV
    overrides.pl             % fare-rule continent overrides
    limits.pl                % every numeric cap, versioned
    surcharges.pl            % §12 matrix
    transcon.pl              % §4(k) Column A / Column B states
    au_pairs.pl              % §4(l) Australian city pairs
  tools/build_airports.pl    % CSV -> data/generated/airports.pl (run manually)
  test/
    fixtures/*.json          % golden itineraries
    test_*.pl                % plunit suites
```

### Rules as violation generators

Each rule is a clause of a `multifile violation/2` that **succeeds when the rule is broken** and
binds a violation term. Backtracking enumerates every violation of every rule in one pass, each
carrying its own evidence:

```prolog
validate(Itin, report(Verdict, Violations, Fare)) :-
    annotate(Itin, A),
    findall(V, violation(A, V), Vs),
    sort(Vs, Sorted),                       % dedupes; sorts by rule id
    order_for_display(Sorted, Violations),  % severity, then first segment
    ( Violations == [] -> Verdict = valid ; Verdict = invalid ),
    pricing:fare(A, Fare).

v(RuleId, Citation, Severity, Message, Evidence)
```

`Severity` is `error`, `warning` (depends on carrier discretion), or `indeterminate` (cannot be
decided from the input — e.g. stopover-vs-transfer with no timestamps). An itinerary that produces
only `indeterminate` violations reports verdict `indeterminate`, never `valid`. Rules never
hardcode numbers; every cap comes from `data/limits.pl`. Each clause carries its `Citation`
(`'4(h)'`, `'8'`) pointing back at `parsed-rules-aug-2026.md`.

### Two rule interactions to encode deliberately

Both come from the design doc's §4 and are where a naive implementation goes wrong.

**4(a) + 4(b) + 4(c) collapse into one invariant.** One crossing of each ocean, plus continuous
forward direction between TC1–TC2–TC3, plus termination at origin, together force the *collapsed
traffic-conference sequence* to be exactly `[T0,T1,T2,T0]` where `[T0,T1,T2]` is a rotation of
`[tc1,tc2,tc3]` or of its reverse. Check that one property; 4(a) and 4(b) both fall out with a far
better message than checking crossings and direction separately.

**4(b) is TC-level; 4(e) is continent-level.** TC1 = {North America, South America}, TC2 =
{Europe–Middle East, Africa}, TC3 = {Asia, South West Pacific}. So a South America excursion never
leaves TC1 and an Africa excursion never leaves TC2 — neither breaks forward direction. What bounds
them is 4(e)'s allowance of *two* intercontinental departures/arrivals in North America, in Asia,
and in Europe/Middle East (the last only for travel to/from/via Africa). Encoding these at the wrong
level makes every legal side-trip look like a violation.

### No timezone database is required

This is worth stating because it looks like the plan's biggest hidden dependency and isn't one.
Itinerary timestamps are **local** times. Ground time at an intermediate point is the gap between an
arrival and the next departure *at the same airport*, so subtracting two local timestamps is
correct without any tz lookup (DST introduces at most a 1 h error against 4 h / 24 h thresholds —
acceptable, and noted in code). Rules 6 and 7 compare timestamps at different airports but only at
day and month granularity, where local time is likewise fine. So: `parse_time/3` with `iso_8601`,
no tz table, no `library(tzdata)` equivalent.

---

## Data model

### JSON input (canonical)

```json
{
  "rulesetVersion": "27FEB26",
  "origin": "LHR",
  "cabin": "business",
  "passengers": [{"type": "adult"}, {"type": "child", "age": 7}],
  "segments": [
    {"n": 1, "type": "flight", "from": "LHR", "to": "JFK",
     "marketingCarrier": "BA", "operatingCarrier": "BA", "flight": "BA117",
     "dep": "2026-09-01T10:25", "arr": "2026-09-01T13:30"},
    {"n": 2, "type": "surface", "from": "GRU", "to": "GIG"}
  ]
}
```

Everything except `origin`, `cabin` and `segments[].{type,from,to}` is optional. Missing timestamps
produce `indeterminate` violations on the stopover-dependent rules; a missing `operatingCarrier`
produces a `warning` on 4(j) rather than an error. `passengers` drives rule 19 only.

Input problems split two ways, deliberately:

- **Malformed** (not an object, `segments` not a list, unparseable date) → HTTP 400 with an error
  list; the CLI prints it and exits 2.
- **Well-formed but unresolvable** (unknown IATA code, non-contiguous `n`, arrival before
  departure) → a normal `v(input_error, input, error, ...)` violation inside the report, so the UI
  renders it inline next to the rule violations rather than as a separate failure mode.

### JSON output

```json
{
  "verdict": "invalid",
  "rulesetVersion": "27FEB26",
  "violations": [
    {"rule": "dup_sector", "citation": "4(i)", "severity": "error",
     "message": "Sector LHR-JFK flown twice in the same direction (segments 1 and 9).",
     "evidence": {"segments": [1, 9], "pair": "LHR-JFK"}}
  ],
  "fare": {"continents": 4, "cabin": "business", "fareBasis": "DONE4",
           "surchargesUsd": 0, "childDiscount": {...}},
  "annotations": {"continentSequence": ["europe_middle_east", "north_america", "..."],
                  "tcSequence": ["tc2", "tc1", "tc3", "tc2"],
                  "stopovers": [{"airport": "JFK", "segmentAfter": 2, "groundHours": 71.5}]}
}
```

`annotations` is included because a web UI wants to draw the route and show *why* a rule fired, not
just the message. `json_out.pl` holds one generic `evidence_json/2` converting the evidence list of
`Key(Value)` terms into an object (atoms → strings, `A-B` → `"A-B"`, lists → arrays).

### HTTP endpoints (`prolog/server.pl`)

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/validate` | body = itinerary JSON, response = report JSON |
| GET | `/api/ruleset` | version, limits, free-segment caps, carrier list, continent table, fare-basis matrix — so the UI has no hardcoded rule data |
| GET | `/api/airports?q=&limit=` | typeahead over the committed airport table; returns IATA, city, country, continent |
| GET | `/api/health` | status + ruleset version |

Built on `library(http/thread_httpd)` + `library(http/http_dispatch)` + `library(http/http_json)`,
with `library(http/http_cors)` so a UI on another origin can call it, and
`library(http/http_unix_daemon)` available for a production `--port`/`--user` launch.

---

## Build order

**M0 — skeleton.** `load.pl`, `data/limits.pl` with `ruleset_version/1` and every cap from §4(h),
§8, §4(f), plunit wired and green on an empty suite.

**M1 — geography (the long pole).** `tools/build_airports.pl` reads the OurAirports CSV with
`library(csv)`, filters to `scheduled_service = yes`, non-empty `iata_code`, and
`type ∈ {large_airport, medium_airport}`, and emits `airport(lhr, 'GB', 'GB-ENG', 'London').` into
`data/generated/airports.pl` (~5k facts, committed). `iso_region` is the key field — it is what
makes the sub-country splits work. The CSV's own `continent` column is *geographic, not the fare
rule's continent*, and must not be used; `geo.pl` layers the rule's definitions on top via
`overrides.pl`: Algeria/Morocco/Tunisia → Europe zone; Egypt/Libya/Sudan → Middle East zone;
Kazakhstan/Kyrgyzstan/Tajikistan/Turkmenistan/Uzbekistan → Asia; Russia split at the Urals by
`iso_region`; Caribbean/Central America/Panama → North America; Hawaii (`US-HI`) → North America but
flagged for 4(b). `transcon.pl`, `au_pairs.pl` and `surcharges.pl` stay separate tables because they
use different taxonomies from the continent list and conflating them is the easy bug. Land the
geography unit tests here. Realistically this data curation is the majority of the total effort.

**M2 — vertical slice.** `io/json_in.pl` → `itinerary.pl` → `annotate.pl` → `validate.pl` with a
single rule (4(h) segment count) → `explain.pl` → `cli.pl validate`. Proves the driver, the
violation shape and the text renderer end to end.

**M3 — HTTP on the slice.** `io/json_out.pl` + `server.pl` + `cli.pl serve`, all four endpoints,
with one rule implemented. Settles serialization and concurrency now rather than later; every
subsequent milestone is then visible over HTTP for free.

**M4 — rule 4 in full.** TC-cycle invariant first (4(a)/(b)/(c)), then 4(e) with
`intercont_allowance/3`, then (d), (f), (g), (h) free-segment caps, (i), (j), (k), (l).

**M5 — the remaining rules + pricing.** 6 (10-day minimum for TC1 origins), 7 (12 months), 8
(≥2 stopovers, ≤2 in origin continent), 9, 15 (Cuba + AA/AS), 19 (child/infant, informational), and
`pricing.pl` (continent count → fare basis, §12 surcharge estimate, the SWP↔Europe "counts as via
Asia" clause, and <3 continents as an error).

**M6 — test suite and hardening.** Full mutation suite, golden fixtures, request size limits,
per-request timeout, structured error responses.

### Rule coverage

Mechanically checkable: 4(a)–4(l), 6, 7, 8, 15, 19, and the §0 continent-count → fare-basis
mapping. Explicitly out of scope because they are not mechanically decidable from an itinerary:
capacity limitations, GDS fare amounts, booking-class availability, group travel, voluntary-change
fees.

---

## Verification

```sh
# full test suite
swipl -g run_tests -t halt prolog/load.pl

# regenerate airport data (manual, then commit the diff)
swipl -g main -t halt prolog/tools/build_airports.pl -- /tmp/airports.csv

# validate one itinerary, human-readable
swipl prolog/cli.pl -- validate prolog/test/fixtures/lhr_classic.json

# run the service
swipl prolog/cli.pl -- serve --port 8080
curl -s localhost:8080/api/health
curl -s localhost:8080/api/ruleset | jq .limits
curl -s -X POST localhost:8080/api/validate \
     -H 'content-type: application/json' \
     --data @prolog/test/fixtures/dup_sector.json | jq .
```

Expected CLI shape for an invalid itinerary:

```
INVALID — 2 violations
  [4(i)]  error   Sector LHR-JFK flown twice in the same direction (segments 1 and 9).
  [8]     error   Itinerary has 1 stopover; a minimum of 2 is required.
Fare basis: DONE4 (4 continents, Business)
```

Four test suites, in descending value:

1. **Mutation tests** — the highest-value suite. Take a valid fixture, break exactly one rule
   (duplicate a sector, add a 17th segment, reverse a TC hop, add a third stopover in the origin
   continent), and assert that **exactly** the expected rule id fires. Catches both false negatives
   and rules that over-fire on legal itineraries, and it verifies rule independence.
2. **Golden valid fixtures** — a classic LHR→JFK→…→HKG→LHR; one with a South America excursion; one
   with an Africa excursion; one SWP-origin using the 4(g) transoceanic-surface exception — each
   asserted to produce zero violations.
3. **Geography units** — Casablanca is Europe, Cairo is Middle East, Panama City is North America,
   Tashkent is Asia, Honolulu is North America but Hawaii-flagged, `US-CA`→`US-NY` is
   transcontinental.
4. **Indeterminacy** — a fixture with no timestamps yields `indeterminate` on the stopover rules and
   is *not* reported valid.

Plus an HTTP round-trip test from M3 onward: start the server on an ephemeral port in a plunit
setup, POST each fixture, and assert the JSON report matches the report term the CLI produces —
which is what keeps the two renderers from drifting.

---

## Deviations taken during implementation

Recorded here rather than silently: each is a small change to the plan above.

1. **Test entry point** is `prolog/test/run_tests.pl`, not `prolog/load.pl`. Loading the suites from
   `load.pl` would have put plunit and the fixture corpus into every server process.
2. **`data/countries.pl` replaced `data/overrides.pl` as the primary continent table.** The plan
   assumed the OurAirports `continent` column could be a base with overrides layered on. It cannot:
   that column is physical geography, and it disagrees with the fare rule for the whole Middle East,
   for North Africa, and for Hawaii. The base is now an explicit IATA-area table; `overrides.pl`
   holds only what a country-level table cannot express (the Urals split, the Hawaii flag).
3. **The airport filter keeps every type**, not just large and medium. Karratha (4(l) city-pair
   table) is a medium airport and Broome is large, but size-filtering drops real scheduled points
   for no benefit; the filter is scheduled service plus an IATA code. 4,161 airports.
4. **Rule 9 has no module.** "Unlimited online/interline transfers permitted" is a permission with
   nothing to check; the carriers themselves are checked by 4(j).
5. **Evidence terms carry display-form (upper-case) IATA codes.** Codes are held lower-case
   internally so they can be table keys; every message and every JSON field shows them upper-case.
