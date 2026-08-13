# Getting the network out of Wikipedia

## What this is

The acquisition half of [`06-flown-network.md`](06-flown-network.md). That plan owns the fact shape,
the query surface and the tests; this one owns how the data gets here. It produces a hand-verified
seed list, a pinned revision manifest, a committed corpus of extracted table sections, and the
parsed edge list.

Deliverable: `prolog/tools/build_services.mjs`, in Node to match `build_image.mjs` and the two earn
builders — the repo already uses Node for generation and nothing else.

| Artifact | Committed? |
|---|---|
| `prolog/data/network/seeds.json` | yes — hand-verified |
| `prolog/data/network/revisions.json` | yes — the pin |
| `prolog/data/network/sources/*.wiki` | yes — the extracted table sections |
| `prolog/data/network/carrier_aliases.json` | yes — the delta over `carriers.pl` |
| `prolog/data/generated/services.pl` | yes — the output |
| `prolog/data/generated/services.rejects.json` | yes — a reviewed artifact, not a log |

## Why crawl rather than enumerate

`Lists_of_airports` is an index of indexes: hub → per-country list → article, three hops through
pages formatted inconsistently across ~200 countries, arriving at every airport on earth when
roughly 900 are wanted.

The airline destination lists are a better seed. The union of the destination-list articles for the
members and their affiliates is, by construction, the set of airports carrying at least one oneworld
edge: any airport at either end of such a route appears in at least one carrier's list. Two hops
from a seed set small enough to verify by hand.

Those articles are useless as route data — destination sets, not pairs, by WikiProject convention.
They are used **only** as an enumeration. The route data comes from the airport articles they link
to.

---

## Phase A — Seeds

`prolog/data/network/seeds.json`, written by hand. Do not generate it: article titles are
inconsistent, and a seed that 404s silently removes a member's whole network from the corpus.

**The carrier set comes from `prolog/src/carriers.pl:19`**, not from memory:

```prolog
carriers([aa, as, at, ay, ba, cx, fj, ib, jl, mh, nu, qf, qr, rj, ul, wy]).
```

That is Alaska, American, Royal Air Maroc, Finnair, British Airways, Cathay Pacific, Fiji Airways,
Iberia, Japan Airlines, Malaysia Airlines, **Japan Transocean Air**, Qantas, Qatar Airways, Royal
Jordanian, SriLankan and Oman Air. **Hawaiian is not a member of this ruleset** and must not be
seeded — it appears nowhere in `carriers.pl`, so seeding it pulls in a network no Explorer fare may
be flown on. Japan Transocean Air (`nu`) *is* eligible under 4(j); it is excluded only from
`ticketing_stock/1`, meaning it may be flown but may not issue the ticket, and `build_qff_tables.mjs`
already carries it in its own `ELIGIBLE` array. Dropping it loses the Japan domestic sectors that are
the entire reason it is in the rule.

A test asserts the seed file's carrier set equals `carriers:eligible_carriers/1`, so the list is
typed once. Getting this wrong is the highest-cost mistake available here, because it is invisible in
the output: you get a table, it just describes a different alliance.

Two things the run must refuse to paper over:

- **Every seed resolves** to a non-redirect article with a non-empty link set, or the run aborts
  naming the seed. A silently-empty seed costs the most and shows up the latest.
- **Where a member has no destination-list article** — likely for the smaller members — the seed
  names whatever article does carry its destinations, and says so in a `note` field. It is never
  simply omitted.

Add affiliate lists only where a separate article exists. The convention is that a parent's list
includes its regional subsidiaries' destinations, which is what makes affiliate coverage work at
all — but that is an assumption, so verify it once with a specific check: a known Envoy-only or
SkyWest-only US airport must appear in the enumerated set. If it does not, affiliates need their own
seeds and the count in Phase C will show it.

## Phase B — Enumerate

```
action=query&generator=links&titles=<seed>
  &gplnamespace=0&gpllimit=max
  &prop=info&formatversion=2&redirects=1
```

Paginate on `continue`/`gplcontinue`. Roughly one to three requests per seed.

**Do not combine `generator=links` with `prop=revisions&rvprop=content` here.** Requesting content
pins the page limit to 50 regardless of `gpllimit`, so the combined form either errors or silently
truncates the generator's output — which looks like a short destination list rather than a bug. Two
passes, always. Two passes also let you dedupe before fetching, which matters: the seeds overlap
heavily (every member links to LHR, JFK, HKG), so deduplication cuts the content fetch by more than
half.

`redirects=1` makes the API return a `redirects` array of from→to pairs. Capture it — destination
cells in Phase D link through redirects constantly, and this is the map that resolves them.

## Phase C — Filter, fetch, and commit the sections

Destination lists link to both city and airport articles (rows read "Sydney — Kingsford Smith"), so
roughly half the enumerated pages are not airports. Filter by whether the title carries a Wikidata
P238 (IATA airport code), from one SPARQL query for items with P238 and an enwiki sitelink, cached
to a committed JSON file. That same map is what Phase D needs to resolve destination cells, so it
serves both purposes.

Cross-check the survivors against `airports.pl` in both directions:

- A code absent from `airports.pl` is a **reject**. That file is built from OurAirports and is the
  authority on what an airport is.
- An airport in `airports.pl` that no seed reached is **expected** — it is simply not a oneworld
  airport. Track the count anyway: a sudden jump means a seed stopped parsing.

Then fetch content, 50 pageids per request:

```
action=query&prop=revisions&rvprop=ids|content&rvslots=main&formatversion=2&pageids=…
```

About 20–25 requests; roughly 65 across B and C. Serial. A few minutes.

**Etiquette, which is not optional:** a descriptive `User-Agent` naming the project with a contact
URL (Wikimedia blocks generic agents), `maxlag=5` so the client backs off under cluster load, and no
parallelism. There is no deadline here.

**Then write the extracted sections to `prolog/data/network/sources/`, one file per article, and
commit them.** Only the `Airlines and destinations` section, not the whole article: roughly an order
of magnitude smaller than 900 full pages, and the part anything downstream reads. This mirrors
`prolog/data/earn/sources/` exactly — captures with provenance, committed, so the transform that
consumes them is reproducible without a network. Carry that directory's `README.md` convention too:
what was fetched, from where, when.

This is what makes the two modes in Phase E honest. Without it, `--pinned` still needs the network
and reproducibility rests on Wikimedia serving old revisions indefinitely, which is a weaker promise
than the one every other generated file in this repo makes.

## Phase D — Extract

Per airport article:

- Take the `Airlines and destinations` section. Where a `Passenger` subsection exists, take only
  that; skip `Cargo` outright.
- Rows are an operator cell and a destinations cell.

Wikitext handling that otherwise produces silent garbage:

- `[[Target|Display]]` — take **Target**, never Display. Name matching fails on exactly the
  multi-airport cities that matter most.
- Resolve every target through the Phase B redirect map before looking up P238.
- Strip `<ref>…</ref>`, `{{efn|…}}`, `<br />`, `{{nowrap|…}}`.
- A `Seasonal:` label splits a cell into two runs carrying different `Season` values.
- Bracketed `[begins 15 March 2027]` / `[ends 30 October 2026]` annotations attach to the preceding
  destination only, and yield `service_window/4` rather than `service/4`.
- `{{Airline hub}}` / `{{Airline focus}}` are decoration; discard.
- Charter and cargo lines are excluded.
- Operator strings resolve through `carrier_aliases.json` on top of `carrier_name/2` and
  `affiliate/3` — see Phase 2 of [`06`](06-flown-network.md). A brand covering several certificates
  yields an *unknown* operating carrier, never a guessed one.

**Refuse rather than guess.** A destinations cell that does not parse into a clean list of wikilinks,
an operator naming a carrier absent from the mapping, a link resolving to a city article rather than
an airport — all go to the rejects file with page title, row and reason. None go into `services.pl`
as a best effort.

Each reject carries an **enumerated reason code**, and the file is grouped by reason with counts.
"Every entry has been read by a human" does not survive a few thousand rows; every *reason class*
does. The run aborts if the unclassified bucket is non-empty, which is what keeps the enumeration
from rotting into a catch-all.

## Phase E — Modes

Two flags, and the first must never silently do the second:

- **`--pinned`** — parse and emit from the committed sections under `prolog/data/network/sources/`.
  **No network access at all.** Byte-identical output from unchanged sections and an unchanged parser
  is the acceptance test. This is the mode CI and a fresh clone run, which is why it can join
  `npm run build` and inherit `pages.yml`'s staleness check, exactly as `prolog/data/earn/` does.
- **`--refresh`** — rerun Phases B–C from the seeds, rewrite the sections and the manifest, then emit.
  The only path that opens a socket, and the only path that changes what the world says. Run by hand,
  never in CI.

If a revid 404s during a `--refresh` (page deleted or revision-deleted), **fail** with the title and
revid. Do not fall back to the current revision — that fallback is what would quietly turn a pinned
build back into a live scrape at exactly the moment an article was moved or vandalised.

The seeds need pinning too. A member joining or leaving the alliance changes the corpus, and that
should appear as a deliberate `--refresh` in the diff rather than arriving on its own.

---

## Acceptance criteria

- `--pinned` makes no network calls and produces byte-identical `services.pl` on repeat runs;
  `git status --porcelain -- prolog/data/` is clean after.
- Every seed resolved; the run aborts rather than proceeding on a missing one.
- The seed carrier set equals `carriers:eligible_carriers/1`, asserted by a test.
- Every reject carries an enumerated reason; the unclassified bucket is empty; every reason class has
  been read.
- The committed sections, the manifest and the rejects file are all in the tree, and a fresh clone can
  rebuild `services.pl` from them with the network unplugged.

## Interface to the Prolog side

The only output contract is `services.pl` in the shape fixed by Phase 0 of
[`06-flown-network.md`](06-flown-network.md) — lowercase atoms, `service/4` and `service_window/4`,
three season values. If that schema changes it changes there, and this plan follows. The extractor's
convenience does not decide the fact shape.
