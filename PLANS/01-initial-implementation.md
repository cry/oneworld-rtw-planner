# oneworld Explorer itinerary validator (SWI-Prolog)

## Context

`oneworld-rtw-planner` is currently an empty repo (a README and `parsed-rules-aug-2026.md`, the
transcribed text of oneworld Explorer fare Rule 3015, version 27 FEB 26).

The goal is an engine that answers: **"is this round-the-world itinerary a valid oneworld Explorer
fare?"** — and when it isn't, says exactly which rules were broken and why. The original idea was
Erlang; the actual requirement is *declarative rule definition over a routing expressed as facts*,
which is Prolog's home ground. Scope is deliberately **validation + explanation only** — no
itinerary generation or optimization.

Why this fits Prolog well: most of Rule 3015 is relational constraints over a short list of
segments plus a geography table. Rules like 4(i) ("same sector not flown twice in the same
direction") are one clause with two goals and a nondeterministic search that finds *every*
offending pair for free. The geography reference data is literally a fact base.

Where it doesn't fit, stated up front: **Prolog failure is silent**, so a naive
`valid(I) :- rule1(I), rule2(I), ...` gives a bare "no" with no explanation. The architecture below
inverts this (§2) — it is the single most important design decision here. Also, the
violation-finding encoding does **not** run backwards; if itinerary *generation* is ever wanted,
that's a separate constructive layer or a move to ASP (clingo), not a free consequence of this
design.

**Toolchain:** SWI-Prolog. Not currently installed — `brew install swi-prolog` (Homebrew 6.0.15 is
present). SWI over Scryer because we need CSV ingest, `plunit`, dicts, and `library(aggregate)`;
Scryer is purer but the reference-data pipeline would be painful.

---

## 1. Repository layout

```
prolog/
  load.pl                    % entry point: consults src + data
  cli.pl                     % swipl prolog/cli.pl -- validate <file>
  src/
    itinerary.pl             % load fact files -> canonical itinerary term
    annotate.pl              % the derived-facts pass (§3)
    geo.pl                   % airport -> country/region -> continent -> TC
    carriers.pl              % eligible carriers, affiliates, codeshare policy
    pricing.pl               % continent count -> fare basis; §12 surcharges
    validate.pl              % findall driver + rule registry
    explain.pl               % violation term -> human text
    rules/
      r04_routing.pl         % rule 4 (a)-(l)  <- the bulk of the work
      r06_min_stay.pl
      r07_max_stay.pl
      r08_stopovers.pl
      r09_transfers.pl
      r15_sales.pl
  data/
    generated/airports.pl    % built from OurAirports CSV
    overrides.pl             % continent overrides the fare rule requires
    limits.pl                % every numeric cap, versioned
    surcharges.pl            % §12 matrix
    transcon.pl              % §4(k) Column A / Column B states
    au_pairs.pl              % §4(l) Australian city pairs
  tools/
    build_airports.pl        % CSV -> data/generated/airports.pl
  test/
    fixtures/*.pl            % golden itineraries
    test_*.pl                % plunit suites
```

---

## 2. Core design: rules as violation generators

Each rule is a clause of a `multifile` predicate that **succeeds when the rule is broken**, and
binds a violation term describing the breakage. The driver collects all solutions:

```prolog
%! validate(+Itin, -Report) is det.
validate(Itin, report(Verdict, Violations, Fare)) :-
    annotate(Itin, A),
    findall(V, violation(A, V), Vs),
    sort(Vs, Violations),
    ( Violations == [] -> Verdict = valid ; Verdict = invalid ),
    pricing:fare(A, Fare).
```

This is what buys complete explanations: backtracking enumerates every violation of every rule in
one pass, and each carries its own evidence. Violation shape:

```prolog
v(RuleId, Citation, Severity, Message, Evidence)
%  e.g. v(dup_sector, '4(i)', error,
%         'Sector LHR-JFK flown twice in the same direction (segments 1 and 9).',
%         [segments([1,9]), pair(lhr-jfk)])
```

`Severity` is `error` (definitely invalid), `warning` (probably invalid, or depends on carrier
discretion), or `indeterminate` (**cannot be decided from the input** — e.g. stopover-vs-transfer
when timestamps are missing). Emitting `indeterminate` rather than silently passing is important:
an itinerary entered without times must not be reported as clean.

Two representative rules, to show the style:

```prolog
% 4(i) — same city pair not flown twice in the same direction.
violation(A, v(dup_sector, '4(i)', error, Msg, [segments([I,J]), pair(F-T)])) :-
    ann_flight(A, I, F, T), ann_flight(A, J, F, T), I < J,
    format(atom(Msg), 'Sector ~w-~w flown twice in the same direction (segments ~w and ~w).',
           [F,T,I,J]).

% 4(h) — total segment count, including surface sectors.
violation(A, v(seg_count, '4(h)', error, Msg, [count(N), max(Max)])) :-
    ann_segment_count(A, N), limit(max_segments, Max), N > Max,
    format(atom(Msg), 'Itinerary has ~w segments; the maximum is ~w.', [N, Max]).
```

Rules never hardcode numbers — every cap comes from `limits.pl` (§6).

---

## 3. The annotation pass

`annotate/2` runs **once**, before any rule, and decorates the raw itinerary with everything the
rules need. Without this, ~25 rules each re-derive continents and connection times; with it, every
rule body stays two or three goals long.

Annotation computes, per segment: origin/destination country, ISO region, continent, traffic
conference, surface-vs-flight, `intercontinental/1`, and ocean crossing (`atlantic`/`pacific`/
`none`). Per intermediate point: ground time and `stopover`/`transfer`/`indeterminate`. Per
itinerary: the collapsed continent sequence, the collapsed TC sequence, per-continent
intra-continental flight counts, and per-continent intercontinental arrival/departure counts.

**Stopover classification** (the fare rule never defines this; using the agreed convention):
ground time > 24h on international connections, > 4h on US/Canada domestic connections. Missing
timestamps yield `indeterminate`, which propagates into rules 8 and 4(f) as `indeterminate`
violations rather than silent passes.

Annotation is eager and pure — it returns a term, and rules pattern-match against it. No tabling,
no `assertz`, so the validator is reentrant if it's ever put behind an HTTP service.

---

## 4. Two rule interactions worth encoding deliberately

These came out of reading the rule text and are the two places a naive implementation goes wrong.

**(a) Rules 4(a) + 4(b) + 4(c) collapse into one strong invariant.** "One crossing of each ocean"
plus "continuous forward direction between TC1–TC2–TC3" plus "must terminate at the point of
origin" together force the **collapsed traffic-conference sequence** to be exactly a 3-cycle:
`[T0,T1,T2,T0]` where `[T0,T1,T2]` is a rotation of `[tc1,tc2,tc3]` or of its reverse. Check that
one property and 4(a) and 4(b) both fall out, with a much better error message than checking
crossings and direction separately.

**(b) 4(b) is a TC-level rule; 4(e) is a continent-level rule.** The mapping matters:

| TC | Continents |
|---|---|
| TC1 | North America, South America |
| TC2 | Europe–Middle East, Africa |
| TC3 | Asia, South West Pacific |

So a South America excursion (NA→SA→NA) never leaves TC1, and an Africa excursion
(Europe→Africa→Europe) never leaves TC2 — neither breaks the forward-direction rule. What
constrains them instead is 4(e)'s allowance of *two* intercontinental departures/arrivals in North
America, in Asia, and in Europe/Middle East (the last only when travel is to/from/via Africa).
Encoding these at the wrong level makes every legal side-trip look like a violation.

`intercont_allowance/3` therefore reads the itinerary to decide the Europe/ME allowance:

```prolog
intercont_allowance(_, north_america, 2).
intercont_allowance(_, asia, 2).
intercont_allowance(A, europe_middle_east, 2) :- ann_visits(A, africa), !.
intercont_allowance(_, _, 1).
```

---

## 5. Geography reference data

Built by `tools/build_airports.pl` from the OurAirports CSV
(`https://davidmegginson.github.io/ourairports-data/airports.csv`). Confirmed columns:
`type, continent, iso_country, iso_region, municipality, scheduled_service, iata_code`.

Ingest filters to `scheduled_service = yes`, non-empty `iata_code`, and
`type ∈ {large_airport, medium_airport}`, then emits:

```prolog
airport(lhr, 'GB', 'GB-ENG', 'London').
```

`iso_region` is the key field — it is what makes the sub-country splits possible.

The CSV's own `continent` column is **geographic, not the fare rule's continent**, and must not be
used directly. `geo.pl` layers the rule's definitions on top, driven by `overrides.pl`:

| Override | Fare-rule continent | Source |
|---|---|---|
| Algeria, Morocco, Tunisia | Europe–Middle East (Europe zone) | §0 Continents |
| Egypt, Libya, Sudan | Europe–Middle East (Middle East zone) | §0 Continents |
| Kazakhstan, Kyrgyzstan, Tajikistan, Turkmenistan, Uzbekistan | Asia | §0 Continents |
| Russia | split at the Urals by `iso_region` | §0 Continents |
| Caribbean, Central America, Panama | North America | §0 Continents |
| Hawaii (`US-HI`) | North America, but flagged for 4(b) | §4(b) |

Three further tables, kept separate because they use *different* taxonomies from the continent
list and conflating them is a common bug:

- `transcon.pl` — §4(k) Column A / Column B US states, matched on `iso_region`; plus the
  Alaska (`US-AK`) one-in/one-out rule.
- `au_pairs.pl` — §4(l) Australian city pairs (BME/DRW/KTA/PER sets).
- `surcharges.pl` — §12 needs regions the continent list doesn't have at all: South East Asia,
  South Asian Subcontinent, Japan/Korea, French Polynesia, Australia vs. rest-of-SWP.

Realistically **this data curation is the majority of the effort**, not the engine.

---

## 6. Ruleset versioning

The document is stamped 27 FEB 26 and these fares are reissued periodically. Every numeric cap and
table lives in `data/`, tagged with a version, so a future edition is a data change plus tests
rather than a rewrite:

```prolog
ruleset_version('27FEB26').
limit(min_segments, 3).
limit(max_segments, 16).
limit(min_stopovers, 2).
limit(max_stopovers_origin_continent, 2).
limit(max_intl_transfers_per_country, 4).
free_segments(north_america, 6).
free_segments(_, 4).
```

Each rule clause carries its `Citation` (`'4(h)'`, `'8'`, …) pointing back at
`parsed-rules-aug-2026.md`, so any rule can be audited against the source text.

---

## 7. Input format

Itineraries are Prolog fact files — human-writable, and directly the "routing expressed as facts"
model:

```prolog
:- module(itin_lhr_classic, []).
origin(lhr).
cabin(business).
seg(1, flight,  lhr, jfk, ba, 'BA117', date(2026,9,1,10,25),  date(2026,9,1,13,30)).
seg(2, flight,  jfk, gru, aa, 'AA929', date(2026,9,4,21,05),  date(2026,9,5,08,45)).
seg(3, surface, gru, gig, -,  -,      -,                     -).
```

`itinerary.pl` loads these in an isolated module and normalizes them into the canonical term, so
rules never touch the global database. A JSON front door can be added later against the same
canonical term.

---

## 8. Rule coverage checklist

Every rule in `parsed-rules-aug-2026.md` that is mechanically checkable:

| Rule | Check | Notes |
|---|---|---|
| 4(a) | One Atlantic + one Pacific crossing | via TC-cycle invariant (§4a) |
| 4(b) | Forward TC direction; Hawaii backtracking | intra-continent backtracking is legal |
| 4(c) | Terminates at origin; permitted origin/dest surface sectors | 7 listed exceptions |
| 4(d) | Origin point not revisited mid-journey | |
| 4(e) | Intercontinental dep/arr per continent | allowance table (§4b) |
| 4(e) | Europe-both-directions excludes Mauritius/South Africa | |
| 4(f) | One intl dep/arr from origin country; USA exception; ≤4 intl transfers per country | US–Canada not international |
| 4(g) | Surface sectors; no transoceanic surface | SWP-origin exception |
| 4(h) | 3–16 segments; per-continent free segment caps | surface sectors count to the 16 |
| 4(i) | No repeated sector in the same direction | |
| 4(j) | Carrier eligibility, affiliates, codeshare policy | `warning` if operating carrier unknown |
| 4(k) | One transcontinental US flight; one flight to/from Alaska | |
| 4(l) | Australian city-pair limits | |
| 6 | 10-day minimum for TC1 origins | first vs. last international sector |
| 7 | 12 months from departure to return from last stopover | |
| 8 | ≥2 stopovers; ≤2 in continent of origin | depends on §3 classification |
| 15 | Cuba + AA/AS ticketing conflict | |
| 19 | Child/infant discount arithmetic | informational output |
| §0 | Continent count → fare basis; SWP↔Europe counts as via Asia | informational, but <3 continents is an error |

Explicitly **out of scope** (not mechanically decidable): capacity limitations, GDS fare amounts,
booking-class availability, group travel, voluntary-change fees.

---

## 9. Testing

`plunit`, run with `swipl -g run_tests -t halt prolog/load.pl`.

1. **Golden valid fixtures** — a handful of realistic itineraries (a classic
   LHR→JFK→…→HKG→LHR; one with a South America excursion; one with an Africa excursion; one
   SWP-origin using the transoceanic-surface exception) asserted to produce zero violations.
2. **Mutation tests** — the highest-value suite. Take a valid fixture, break exactly one rule
   (duplicate a sector, add a 17th segment, reverse a TC hop, add a third stopover in the origin
   continent), and assert that **exactly** the expected rule id fires. This catches both false
   negatives and rules that over-fire on legal itineraries, and it verifies rule independence.
3. **Geography unit tests** — Casablanca is Europe, Cairo is Middle East, Panama City is North
   America, Tashkent is Asia, Honolulu is North America but Hawaii-flagged, `US-CA`→`US-NY` is
   transcontinental.
4. **Indeterminacy tests** — a fixture with no timestamps yields `indeterminate` on the stopover
   rules and is *not* reported valid.

---

## 10. Build order

1. `brew install swi-prolog`; skeleton, `load.pl`, `plunit` wired up and running green on nothing.
2. `tools/build_airports.pl` + `overrides.pl` + `geo.pl`, with the §9.3 geography tests. This is
   the long pole — do it first and get it right.
3. `itinerary.pl` + `annotate.pl` + one trivial rule (4(h) segment count) end to end, so the
   `findall` driver and `explain.pl` output are proven.
4. Rule 4 in full — the TC-cycle invariant first (§4a), then 4(e) (§4b), then the rest.
5. Rules 6, 7, 8, 9, 15, 19 + `pricing.pl` (continent count → fare basis, surcharge estimate).
6. `cli.pl` and the mutation-test suite.

---

## Verification

```sh
brew install swi-prolog

# full test suite
swipl -g run_tests -t halt prolog/load.pl

# validate a single itinerary, human-readable output
swipl prolog/cli.pl -- validate prolog/test/fixtures/lhr_classic.pl

# expected shape for an invalid itinerary:
#   INVALID — 2 violations
#     [4(i)]  error   Sector LHR-JFK flown twice in the same direction (segments 1 and 9).
#     [8]     error   Itinerary has 1 stopover; a minimum of 2 is required.
#   Fare basis: DONE4 (4 continents, Business)
```

End-to-end confidence comes from §9.2: every mutation of a known-good itinerary must surface
exactly the rule it broke, and the golden fixtures must stay silent.
