# Routing-only validation

## The problem

The validator as built took precise flight dates and times, and used them for one thing above all:
deciding whether each intermediate point is a stopover or a transfer. That classification is what
rule 8 counts, so without timestamps rule 8 was `indeterminate` and so was the verdict.

But that is inference. A traveller planning a round-the-world already *knows* which points are
stopovers — it is the plan. Making them invent plausible timestamps to express it is asking for the
wrong information, and the timestamps then get used for rules 6 and 7 as though they were real.

## What was added

Two ways to say directly what the timestamps were being used to infer, and one honest account of
what is then left unchecked.

### 1. Declared stop kinds

`"stop": "transfer" | "stopover"` on a segment, describing the point it *arrives* at.
`layover`, `connection` and `transit` are accepted for `transfer` — those are the words people use,
and rejecting them on a vocabulary technicality would be pointless friction.

Precedence, in `annotate:effective_kind/4`:

1. **A surface sector wins.** 4(g) surface travel is at the passenger's own expense and breaks the
   flown journey whatever it is called.
2. **Otherwise a declaration wins over the clock.** The traveller knows what was booked, and a
   routing-only itinerary has no clock to read.
3. **Otherwise the ground time decides**, as before, and `indeterminate` if there is none.

Where a declaration and the clock disagree, rule 8 reports `stop_kind_conflict` as a warning. It is
not resolved in silence because which source is believed changes the stopover count, and the report
would otherwise give no clue which one the verdict rests on. The point carries both classifications
into the JSON (`declaredKind`, `derivedKind`, `surfaceAdjacent`) so a client can show the source.

### 2. Routing strings

`NYC-BA-X/LON-QR-BKK//SIN-QF-SYD-QF-X/LAX-AA-NYC` — fare-construction notation, which already
carries exactly this information: `X/` is a transit point and its absence is a stopover.

| Notation | Meaning |
|---|---|
| `-`, whitespace, `,` | separates points |
| `X/JFK`, `XJFK` | transfer |
| `JFK` | stopover |
| `A//B` | that leg is a surface sector |
| two-character token | the carrier of the leg that follows |

Length disambiguates: airline designators are two characters, place codes are three. So `XIY` is
Xi'an, not a transfer at `IY`, and nothing needs escaping.

`io/route_in.pl` produces the same `rseg/10` terms `io/json_in.pl` does, so both forms meet at
`build_itinerary/6` and no rule knows which was used. That is what makes the routing form a genuine
second front end rather than a separate, weaker validator, and the test suite asserts the golden
itinerary written both ways reaches the same verdict.

Metropolitan city codes (`data/cities.pl`) resolve to a representative airport in `itinerary.pl`,
so both front ends get them. Aliasing rather than inventing a new kind of place is deliberate:
every use the validator makes of a code is geography or identity, geography is identical across a
city's airports, and aliasing is what lets 4(i) see `NYC-LON` and `JFK-LHR` as one sector.

### 3. `mode`, and a not-checked registry

An itinerary carries `mode`: `full` (default for `segments`) or `routing` (default for `route`).
Routing mode refuses timestamps outright rather than discarding them, because quietly dropping them
would make rules 6 and 7 look unanswerable when the data to answer them was supplied.

Rules 6 and 7 need a calendar and a routing has none. Reporting them `indeterminate` would make
*every* routing-only check indeterminate and drain that severity of its meaning, so a second
registry was added alongside `violation/2`:

```prolog
:- multifile validate:not_checked/2.     % not_checked(+A, -nc(RuleId, Citation, Reason))
```

The distinction the two registries draw:

- `indeterminate` — "you left out something this rule needs".
- not checked — "this rule is not answerable from the kind of input you gave".

Neither is a pass. `report/3` became `report/4` so the list travels with the verdict, and both
renderers print it — the CLI as a `Not checked` block, the JSON as `notChecked`, the UI as a dashed
panel under the violations. A client that renders `verdict` without it claims coverage the report
does not give.

Rule 6 is listed only when the origin is in TC1, since that is the only case where it would have
applied; listing it for a London origin would be noise.

## Also changed

`4(j)`'s `marketing_carrier_missing` warning was aggregated into one violation naming all the
segments. A routing given without carriers would otherwise bury its real violations under one
warning per sector, and "no carriers were given" is one fact, not sixteen.

## Files

New: `data/cities.pl`, `src/io/route_in.pl`, `test/test_route.pl`, and five fixtures
(`route_classic`, `route_all_transfers`, `route_surface`, `stops_declared`, `mut_stop_conflict`).

Changed: `itinerary.pl` (`build_itinerary/6`, `stop` field, city resolution), `annotate.pl`
(classification precedence), `validate.pl` (`report/4`, `not_checked/2`), `explain.pl`,
`io/json_in.pl` (`route`, `mode`, `stop`), `io/json_out.pl`, `geo.pl` (`resolve_place/2`),
`r06`/`r07` (mode guards), `r08` (conflict warning), `r04` (aggregated warning), `cli.pl`
(`route` subcommand), `web/index.html`.

Not changed: every rule module except those five. The classification contract in `annotate.pl` was
already the only thing rule 8 depended on, which is why widening its evidence base reached the whole
ruleset without touching it.
