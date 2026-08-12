# Asia Miles earning — parsing guide (v2)

Spec for `asia_miles_earning_lookup.csv` and `asia_miles_rules_and_coverage.csv`.
Together they answer: *for a flight on Cathay Pacific or any of its 25 partners, how many Status
Points and Asia Miles does it earn?*

Supersedes v1, which covered Cathay only and contained an error (see §9).

UTF-8, comma-delimited, RFC-4180 quoted. Strip the BOM before matching the first header cell.

> Captured verbatim. The two CSVs are committed beside it as `asia-miles-lookup.csv` and
> `asia-miles-rules.csv`; the file names in this guide are the ones it was written with.

---

## 1. The two earning models

This is the single most important thing to internalise. **Cathay and its partners work differently.**

| | Cathay Pacific (CX) | All 25 partners |
|---|---|---|
| Status Points | Fixed value per distance band | Fixed value per distance band |
| Asia Miles | **Fixed value** = points × 100 | **Percentage of sector distance** |
| Distance bands | 750 / 2750 / 5000 / 7500 | 750 / 2750 / **3700** / 5000 / 7500 |
| Band count | 5 (+ a region split in band 2 → 6 cards) | 6 |
| Fare brands | Economy has 4 (Light/Essential/Flex/Codeshare) | None |

Two consequences that will bite a careless parser:

1. `asia_miles = status_points × 100` holds **only for CX**. On QF, HKG–SYD in Business is 60 points
   but 5,740 miles, not 6,000.
2. **Partners have an extra distance boundary at 3,700 miles that CX does not have.** Using the CX
   band set on a partner produces wrong answers for any sector between 2,751 and 5,000 miles.

---

## 2. `asia_miles_earning_lookup.csv`

157 rows. Grain: one row per **(airline × cabin × booking-class group × fare brand)**. Status points
for all six bands are packed into a single column.

| Column | Notes |
|---|---|
| `airline_code` | IATA, e.g. `CX`, `QF` |
| `airline_name` | Display name |
| `zone_scheme` | `CX` or `PARTNER`. **Determines how to read `status_points_by_zone`** — see §3 |
| `cabin` | `Economy`, `Premium Economy`, `Business`, `First` |
| `booking_classes` | Space-separated classes sharing this row. Split on whitespace and match exactly |
| `fare_brand` | CX Economy: `Economy Light` / `Economy Essential` / `Economy Flex` / `Codeshare`. Everywhere else, equals the cabin |
| `operated_by` | See §5 |
| `status_points_by_zone` | Six values, semicolon-separated, zones 1→6 in order. `?` means **unobserved** — see §6 |
| `asia_miles_basis` | `status_points_x100` (CX) or `percent_of_distance` (partners) |
| `asia_miles_value` | `100` for CX (the multiplier). For partners, the percentage. One row carries a conditional value — see §5 |

### Reading `status_points_by_zone`

It is always six semicolon-separated positions, but **the positions mean different things** depending
on `zone_scheme`:

```
zone_scheme = PARTNER          zone_scheme = CX
  1: 0-750 mi                    1: 0-750 mi
  2: 751-2750                    2: 751-2750, standard region
  3: 2751-3700                   3: 751-2750, enhanced region
  4: 3701-5000                   4: 2751-5000
  5: 5001-7500                   5: 5001-7500
  6: 7501+                       6: 7501+
```

CX position 3 is **not** a distance band — it is the enhanced-region variant of band 2. Treating the
two schemes identically is the most likely source of a silent wrong answer.

---

## 3. `asia_miles_rules_and_coverage.csv`

Long/EAV: `record_type, key, value, notes`. Filter on `record_type`.

| `record_type` | Use |
|---|---|
| `model` | Which earning model each airline group uses |
| `band` | Zone boundary definitions for both schemes |
| `boundary` | Per-cutoff reliability, `CLEAN` or `FUZZY`, with observed brackets |
| `rule` | Global invariants and the CX region rule |
| `zero_points` | **9 airlines that earn no Status Points at all** |
| `override` | CX city pairs that defy the distance rule. Apply before the distance lookup |
| `unresolved_code` | Airport codes with no published location |
| `note` | Contextual, e.g. TGV Air rail stations |
| `coverage` | Per-airline sampling coverage. Read this before trusting a `?` |
| `validation` | Reproduction evidence |
| `scope` | Limits |

---

## 4. Lookup algorithm

```
INPUT: marketing_airline, origin, destination, cabin, booking_class,
       fare_brand (CX Economy only), operated_by
OUTPUT: status_points, asia_miles

1. If marketing_airline is not one of the 26 -> UNSUPPORTED.
   The marketing carrier is the airline on the flight number, NOT the operator.

2. CX ONLY — check overrides first.
   Look up {origin}-{destination} in the override records.
   If found -> zone := override.value, GOTO 5.

3. distance := published sector mileage (see §7).

4. ZONE
   if scheme == PARTNER:
        <=750 -> 1;  <=2750 -> 2;  <=3700 -> 3;
        <=5000 -> 4; <=7500 -> 5;  else 6
   if scheme == CX:
        <=750  -> 1
        <=2750 -> 3 if either endpoint is in Japan, India, Bangladesh,
                     Sri Lanka, Nepal, Kazakhstan or Indonesia
                -> 2 otherwise
        <=5000 -> 4; <=7500 -> 5; else 6

5. ROW
   Filter on airline_code, cabin, fare_brand, and booking_class within
   booking_classes -> exactly one row.

6. POINTS
   pts := status_points_by_zone[zone]
   if pts == "?" -> UNOBSERVED (do not guess; check the coverage records)

7. MILES
   if asia_miles_basis == status_points_x100: miles := pts * 100
   else:                                      miles := round(distance * pct / 100)
```

Rounding is ordinary half-up on the final mile. Verified within ±1 mile on all 26,780 observations.

---

## 5. Operator handling

Three distinct situations, routinely conflated:

1. **CX-numbered on Cathay metal.** Economy splits into three fare families; the other cabins have a
   single card. `operated_by = Cathay Pacific operated`.
2. **CX-numbered on partner metal.** Economy has a `Codeshare` brand, numerically identical to
   `Economy Light` in every band. Premium Economy, Business and First publish **no** codeshare rate —
   return UNKNOWN rather than falling through to the Cathay-operated figure.
3. **Partner-numbered.** Use that airline's own rows. Nothing about the CX table applies.

### The one conditional percentage

`AA` Business carries `asia_miles_value = "150 domestic / 125 international"`. American is the only
airline whose multiplier varies. Domestic means **both airports in the same country** — not "inside
the USA"; AKL–CHC counts as domestic New Zealand. Verified 90/90 with zero violations. Parse this
field by splitting on `/` and selecting on a country comparison.

---

## 6. The nine zero-point airlines

`AC` `CA` `NZ` `OS` `PG` `LA` `LH` `ZH` `LX` earn Asia Miles but **zero Status Points** on every
observed sector. Their `status_points_by_zone` is `0;0;0;0;0;0` throughout.

These are exactly the **non-oneworld** partners. Every oneworld member in the list earns points. That
pattern is a useful sanity check but is an inference, not something the calculator states.

For these carriers the zeros in unobserved bands are inferred rather than measured, on the basis that
the airline earns nothing anywhere. That is flagged in the source data as `inferred`.

---

## 7. Where distance comes from

Cathay uses **published sector mileage**, which is not in either CSV. Two ways to obtain it:

1. **Great-circle** between the airports. Agrees with Cathay on 100% of 745 validated pairs to within
   6%, and is fine except very close to a band boundary.
2. **Exactly**, from the API: on any partner, the highest-earning Economy class earns exactly 100% of
   sector distance. Query that pair and read the miles. This is the authoritative figure and the way
   to settle a boundary case.

---

## 8. Gotchas

1. **Don't apply the CX band set to a partner.** The 3,700 boundary exists only for partners.
2. **Don't apply `×100` to a partner.** It is a CX-only artefact.
3. **`?` is not zero.** It means that band was never observed for that airline. Nine airlines have
   substantial gaps — `NZ` was only observed in band 5, `OS` only in band 1. Check `coverage`.
4. **`0` is not `?`.** Zero is a measured or inferred real value for the nine non-oneworld carriers.
5. **CX zone position 3 is a region variant, not a distance band.**
6. **Match `booking_class` exactly** after splitting `booking_classes` on whitespace. Do not substring-match:
   `A` would match inside `A F`.
7. **The 750-mile boundary is fuzzy** on great-circle (bracketed 749–756). The other four are clean.
8. **Marketing carrier, not operator,** selects the airline table. A QF-numbered flight on an
   Emirates aircraft uses the QF rows.
9. **Some codes are rail stations.** Ten French TGV Air codes appear as airports; geocoding them will fail.

---

## 9. Correction to v1

The previous guide asserted `asia_miles = status_points × 100` as a **general invariant** and
recommended it as a parser checksum. That was wrong — it is specific to the Cathay table, and every
partner breaks it. It survives here only as the CX rule.

v1 also described partner premium-cabin earning as unresolvable. That conflated a CX-numbered ticket
on partner metal (genuinely unpublished) with a partner-numbered ticket (resolvable via that airline's
own table, now included). §5 separates the two.

---

## 10. Worked examples

**A. QF 127, HKG→SYD, Business, class `J`.**
Partner scheme. Distance 4,592 mi → band 4 (3,701–5,000).
Row `QF / Business / C D I J` → points `15;25;45;60;75;85` → position 4 = **60**.
Miles = 4,592 × 125% = **5,740**. Matches the live calculator.

**B. CX 261, HKG→CDG, Economy, class `K`, Economy Flex, Cathay-operated.**
CX scheme. Distance 5,979 mi → band 5.
Row `CX / Economy / B H K Y / Economy Flex` → `25;30;35;48;70;90` → position 5 = **70**.
Miles = 70 × 100 = **7,000**. Matches.

**C. Same flight, partner metal (codeshare).**
Row `CX / Economy / B H K Y / Codeshare` → `10;15;18;30;40;50` → position 5 = **40** / 4,000 miles.

**D. LH, FRA→JFK, Business, class `C`.**
Row `LH / Business / C D J Z` → `0;0;0;0;0;0` → **0 points**. Miles = distance × 125%.

**E. NZ, AKL→SIN, Economy, class `B`.** Distance ~5,200 mi → band 5.
Points **0** (zero-point carrier). Miles = distance × 100%. Note NZ coverage is 3 pairs in band 5 only.

---

## 11. Validation

| Check | Result |
|---|---|
| Partner table reproduces observations (points) | 26,780 / 26,780 |
| Partner table reproduces observations (miles) | 26,780 / 26,780 within ±1 mile |
| Partner band fit under 750/2750/3700/5000/7500 | 1,828 / 1,828 keys single-valued |
| CX table reproduces its 324 cells | 324 / 324 |
| CX city-pair reproduction | 1,549 / 1,557 (8 misses = the 4 override pairs, both directions) |
| CX enhanced-region rule | 111/111 and 516/516, zero country-pair overlap |
| AA domestic/international rule | 90 / 90, zero violations |
| Distance derivation vs great-circle | 745 pairs, 100% agreement |
| UI cross-check | HKG–CDG on CX and HKG–SYD on QF both exact |

A parser is behaving correctly if it reproduces all five worked examples, returns UNKNOWN for a
CX-numbered Business ticket on partner metal, and returns UNOBSERVED rather than a number for
`NZ` in band 1.

---

## 12. Source and refresh

`https://api.cathaypacific.com/mpo-miles-services/v3/miles-calculator/` — `airports` and `calculates`
endpoints, backing the public calculator.

Snapshot 2026-08-11. Cathay revised CX rates effective 20 August 2025; partner tables carry no stated
effective date. Re-verify before relying on these for anything consequential.

Sampling: 1,752 city pairs, 26,780 observations. CX was enumerated exhaustively (1,593 pairs);
partners were sampled 23–90 pairs each, which is why coverage gaps exist.

Rate limits: roughly 3,000 requests per IP, then a block of about 15 minutes. Five concurrent requests
proved sustainable indefinitely; more will trip it.
