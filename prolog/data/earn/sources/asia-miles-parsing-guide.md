# Asia Miles earning — parsing guide (v3)

Spec for `asia_miles_earning_lookup.csv` and `asia_miles_rules_and_coverage.csv`.
Together they answer: *for a flight on Cathay Pacific or any of its 25 partners, how many Status
Points and Asia Miles does it earn?*

Supersedes v2, whose booking-class lists for JL and NU were wrong, and v1 before it (see §9).

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

157 rows. Grain: one row per **(airline × cabin × fare group × scope × fare brand)**. Status points
for all six bands are packed into a single column.

| Column | Notes |
|---|---|
| `airline_code` | IATA, e.g. `CX`, `QF` |
| `airline_name` | Display name |
| `zone_scheme` | `CX` or `PARTNER`. **Determines how to read `status_points_by_zone`** — see §3 |
| `cabin` | `Economy`, `Premium Economy`, `Business`, `First` |
| `fare_group` | The carrier's RBD group code. **This is the real unit of earning** — see §2b |
| `booking_classes` | Space-separated classes in this group. Split on whitespace and match exactly |
| `scope` | `all`, `domestic` or `international`. Only JL and NU use anything but `all` — see §2b |
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

## 2b. Fare groups and scope — and a trap in the source API

**Earning is priced per fare group, not per booking class.** Each airline defines RBD groups (`A`, `B`,
`F`, `G`, `H`, `J`…) and every class in a group earns identically. `fare_group` carries that code;
`booking_classes` is its membership.

This matters if you ever rebuild this data. The `calculates` endpoint returns only **one representative
class per group**, and that representative is sometimes **not even a member of the group it names** —
JL Business group `G` returns `bookingClass: "H"`, but the official membership is `(X)`. Deriving class
lists from `calculates` alone produces both missing and phantom classes. The authoritative membership
lives in the page model at `miles-and-points-calculator.model.json`, under `fareGroups.rbdGroups`.

### Scope

`JL` and `NU` price the same class differently by sector scope, so `(airline, cabin, booking_class)` is
**not a unique key** for them:

- `JL` Economy `Y` earns 100% internationally (group F), but the domestic group H prices `J` and `Y` at 50%
- `JL` First `F` earns 150% via group A, and 125% domestic via group B

Resolve scope (both airports in the same country, or not) before matching, and expect two candidate
rows. For all other airlines `scope` is `all` and the key is unique.

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
   booking_classes.
   -> exactly one row : continue
   -> zero rows       : CLASS_NOT_IN_TABLE. Stop. Do NOT fall back to
                        another class in the same cabin, and do NOT
                        assume zero. See section 6a.

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

## 6a. Missing values and how to read them

Class membership is now taken from the carrier's published fare groups rather than from sampling, so
the class lists are complete. What can still be missing is a *value*.

| State | Meaning | Where it shows |
|---|---|---|
| `UNOBSERVED` | Class is known, but this distance band was never sampled | `?` in `status_points_by_zone` |
| `0` | Measured or inferred zero | Literal `0`, the nine non-oneworld carriers |
| `CLASS_NOT_IN_TABLE` | Class is in no fare group for this airline | Row absent entirely |

Two fare groups exist in the carrier definitions but were never observed, so both their percentage and
their points are unknown: **`OS` Economy group H `(T, L)`** and **`LX` Economy group H `(T, L)`**.

Never substitute a neighbouring class within a cabin. Multipliers differ by up to 2x — JL Business
group B is 125% while group G is 70% — so guessing is worse than failing.

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

10. **`(airline, cabin, class)` is not unique for JL and NU.** Scope splits them. Match on `scope` too,
    or accept multiple candidates and disambiguate on the domestic/international test — see §2b.

11. **Never rebuild class lists from the `calculates` endpoint.** It returns one representative class per
    group, sometimes not even a member of that group. Use `fareGroups.rbdGroups` from the page model.

---

## 9. Corrections to earlier versions

**v1 → v2.** v1 asserted `asia_miles = status_points × 100` as a general invariant and recommended it as
a parser checksum. It is specific to the Cathay table; every partner breaks it. v1 also described partner
premium-cabin earning as unresolvable, conflating a CX-numbered ticket on partner metal (genuinely
unpublished) with a partner-numbered ticket (resolvable via that airline's own table).

**v2 → v3.** v2 derived booking-class lists from the API's representative `bookingClass` field. For `JL`
and `NU` this both **omitted real classes and invented phantom ones**. JL Business was published as
classes `C` and `H`; the correct groups are `(J, C, D, I)` at 125% and `(X)` at 70%. The *rates* were
right in every case — only the class labels were wrong. All 24 other airlines were unaffected, and CX's
groupings independently match the page model exactly.

v2 also had no `scope` column, so JL and NU domestic fares were unrepresentable, and it wrongly recorded
`JL` Business `D` as a genuine absence when it was an artefact of this defect.

---

## 10. Worked examples

**A. QF 127, HKG→SYD, Business, class `J`.**
Partner scheme. Distance 4,592 mi → band 4 (3,701–5,000).
Row `QF / Business / group B / J C D I` → points `15;25;45;60;75;85` → position 4 = **60**.
Miles = 4,592 × 125% = **5,740**. Matches the live calculator.

**A2. JL LAX→NRT, Business, class `D`.**
Distance 5,438 mi → band 5. `D` is in JL Business **group B** `(J, C, D, I)` at 125%.
Points `15;25;45;60;75;?` → position 5 = **75**. Miles = 5,438 × 125% = **6,798**. Matches.
The same route in class `X` (group G, 70%) gives **25** / 3,807 — a 3x spread inside one cabin.

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
| Class expansion through fare groups | 127,232 / 127,232, zero missing classes |
| Held-out pair JL LAX–NRT incl. class `D` | matches the rendered calculator |
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

### Partial re-verification, 2026-08-19

The CX table was audited cell by cell against Cathay's published change notice, *Changes to Status
Points and Asia Miles earnings on flights*. All 84 published Status Points cells and all 84 Asia Miles
cells reproduce exactly, as do the eight booking-class groups and the CX zone structure. Two things did
not line up, and both were re-read from the live calculator:

- **Kazakhstan.** The notice names six enhanced-region countries — Japan, Indonesia, Sri Lanka, Nepal,
  Bangladesh, India — and omits Kazakhstan, which this capture has. The calculator sides with the
  capture: HKG–ALA returns 35/25/18 across Flex, Essential and Light, which is the enhanced column.
  The published list is the short one. Seven stands.
- **ALA–TSE.** Recorded as CX Zone 4 with a note reading "earns the 5001-7500 card", which is Zone 5.
  The note was right: the calculator returns 70/60/38 for Economy Flex. Corrected to Zone 5.

Also worth knowing for a rebuild: Cathay still files Astana under the retired code **TSE**, while
`data/generated/airports.pl` carries the current **NQZ**. `kernel.pl` resolves coordinates before it
consults a city-pair override, so an override written under a code the geography does not know never
fires at all — it reads as an undecided sector rather than as the exception it is. The generator now
translates retired codes and fails the build on an override it cannot reach.

Not re-verified: the partner tables, and every CX cell outside the published notice (the codeshare
card, which the calculator shows as Economy Light and which the notice does not publish at all).
