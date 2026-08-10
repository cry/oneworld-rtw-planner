# oneworld-rtw-planner

A SWI-Prolog engine that answers **"is this round-the-world itinerary a valid oneworld Explorer
fare?"** — and when it isn't, names every rule broken and why. Validation and explanation only; it
does not generate or optimise itineraries.

The ruleset is oneworld Explorer, Tariff RWR2 Rule 3015, version 27 FEB 26, transcribed in
[`parsed-rules-aug-2026.md`](parsed-rules-aug-2026.md). Every violation cites the clause it came
from, so any answer can be audited against that text.

## Requirements

SWI-Prolog 9 or later (`brew install swi-prolog`). No third-party packs — the HTTP server, CSV
reader and plunit all ship with SWI. The airport table is committed, so a fresh clone runs offline.

## Use

```sh
# validate one itinerary, human-readable
swipl prolog/cli.pl -- validate prolog/test/fixtures/lhr_classic.json

# the same report as JSON
swipl prolog/cli.pl -- validate prolog/test/fixtures/mut_dup_sector.json --json

# run the HTTP service
swipl prolog/cli.pl -- serve --port 8080
```

Exit codes: `0` valid, `1` invalid or indeterminate, `2` malformed input, `3` internal error.

```
INVALID — 1 violation
  [4(i)]       error           Sector NRT-HKG flown twice in the same direction (segments 4 and 6).
Fare basis: DONE3 (3 continents, business)
```

### HTTP API

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/validate` | itinerary JSON in, report JSON out |
| `GET` | `/api/ruleset` | version, limits, free-segment caps, carriers, continents, fare-basis and surcharge tables |
| `GET` | `/api/airports?q=&limit=` | typeahead over the airport table, with coordinates |
| `GET` | `/api/health` | status and ruleset version |

Errors come back as `{"error": ..., "message": ...}`: `400 invalid_request` for malformed input,
`413 request_too_large`, `503 timeout`, `500 internal_error`. Request bodies are capped at 128 KB
and 100 segments, and each validation runs under a 10-second limit — all three in
[`prolog/data/limits.pl`](prolog/data/limits.pl) alongside the fare caps.

`/api/ruleset` exists so a web UI never hardcodes rule data. Every validate response also carries an
`annotations` object — the derived route, the collapsed continent and traffic-conference sequences,
and each connection's ground time and stopover classification — so a UI can draw the itinerary and
show *why* a rule fired rather than only printing its message.

```sh
curl -s -X POST localhost:8080/api/validate \
     -H 'content-type: application/json' \
     --data @prolog/test/fixtures/lhr_classic.json | jq .
```

### Itinerary format

```json
{
  "origin": "LHR",
  "cabin": "business",
  "passengers": [{ "type": "adult" }],
  "segments": [
    { "n": 1, "type": "flight", "from": "LHR", "to": "JFK",
      "marketingCarrier": "BA", "operatingCarrier": "BA", "flight": "BA117",
      "dep": "2026-09-01T10:25", "arr": "2026-09-01T13:30" },
    { "n": 2, "type": "surface", "from": "GRU", "to": "GIG" }
  ]
}
```

Only `segments[].{from,to}` are required. `cabin` defaults to economy, `origin` to the departure
point of segment 1, `type` to `flight`, and `carrier` is shorthand for both carrier fields. Times
are **local wall-clock** times; a zone designator is accepted and discarded.

`carrier` sets both carrier fields; `marketingCarrier` on its own leaves the operator unknown rather
than assuming there is no codeshare.

Missing information degrades honestly rather than silently passing: absent timestamps make the
stopover rules `indeterminate` and the verdict `indeterminate`, and an absent operating carrier
makes 4(j) a `warning`. Warnings alone leave a verdict of `valid`.

Because the times are local, an eastbound trans-Pacific sector legitimately arrives at an earlier
clock time than it departed — NRT 17:00 to LAX 10:00 the same day. Only a regression wider than the
span of world time zones is treated as a data error.

## How it works

Three layers with one contract between them:

```
JSON ──json_in──> itinerary ──annotate──> A ──validate──> report(Verdict, Violations, Fare)
                                                                    │
                                                    ┌───────────────┴────────────┐
                                                explain (text)            json_out (HTTP)
```

**Rules are violation generators.** Each rule is a clause of `validate:violation/2` that *succeeds
when the rule is broken* and binds a term describing the breakage. A naive
`valid(I) :- rule1(I), rule2(I), ...` would give a bare "no"; inverting it means backtracking
enumerates every violation of every rule in one pass, each carrying its own evidence.

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

## Tests

```sh
swipl -g run_tests -t halt prolog/test/run_tests.pl
```

Four suites, in descending value:

1. **Mutation tests** — each fixture is the golden itinerary with exactly one rule broken, asserting
   that exactly the expected rule ids fire. This catches false negatives and rules that over-fire on
   legal itineraries at the same time, and it verifies rule independence.
2. **Golden fixtures** — a classic LHR round-the-world, an Africa excursion, a South America
   excursion with a surface sector, and a South West Pacific origin using the 4(g) transoceanic
   surface exception. All must stay silent.
3. **Geography units** — every place the fare rule and physical geography disagree.
4. **Serialization and HTTP round trip** — the JSON body must report the same verdict and rule ids
   the text renderer prints, which is what keeps the two renderers from drifting, plus the request
   size, segment and timeout guards.

Some rules cannot fire alone: a two-segment itinerary is below the 4(h) minimum and is necessarily
also short of continents, stopovers and a traffic-conference cycle. Those tests still assert an
exact set, just a set of more than one.

## Scope

Checked: 4(a)–4(l), 6, 7, 8, 15, 19, and the section 0 continent-count to fare-basis mapping.

Not checked, because they are not decidable from an itinerary: capacity limitations, GDS fare
amounts, booking-class availability, group travel, and voluntary-change fees.
