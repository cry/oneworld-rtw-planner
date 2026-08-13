# Getting the network out of Wikipedia

## What this is

The acquisition half of [`06-flown-network.md`](06-flown-network.md). That plan owns the fact shape,
the query surface and the tests; this one owns how the data gets here. It produces a title-to-code
map, a pinned revision manifest, a committed corpus of extracted table sections, and the parsed edge
list.

Deliverable: `prolog/tools/build_services.mjs`, in Node to match `build_image.mjs` and the two earn
builders — the repo already uses Node for generation and nothing else.

| Artifact | Committed? |
|---|---|
| `prolog/data/network/wikidata_iata.json` | yes — the title → IATA map |
| `prolog/data/network/revisions.json` | yes — the pin |
| `prolog/data/network/sources/*.wiki` | yes — the extracted table sections |
| `prolog/data/network/carrier_aliases.json` | yes — the delta over `carriers.pl` |
| `prolog/data/generated/services.pl` | yes — the output |
| `prolog/data/generated/services.rejects.json` | yes — a reviewed artifact, not a log |

## How the airport articles are enumerated

> **Revised during implementation.** This section originally seeded from the members' destination-list
> articles and reached the airport articles through `generator=links`. That design is abandoned, and
> the reason is worth keeping: checked against the live API,
> `List of American Airlines destinations` **redirects to `American Airlines`** — the list was
> deleted — and no such article has ever existed for SriLankan Airlines or Japan Transocean Air. The
> seed hop could not cover the largest member of the alliance, and its failure mode was exactly the
> one Phase A was written to guard against, arriving from a direction the guard did not face.

Enumerate from `airports.pl` instead, which removes the hop rather than repairing it:

1. One SPARQL query to Wikidata for items with **P238** (IATA airport code) and an enwiki sitelink,
   giving a title → IATA map. Committed as `prolog/data/network/wikidata_iata.json`. That map is also
   what resolves destination cells in Phase D, so it earns its place twice.
2. Intersect with the 4,161 codes in `prolog/data/generated/airports.pl` — which is already the
   authority on what an airport is, and already the set every emitted fact must join against.
3. That intersection is the fetch set.

This is **complete by construction**: it cannot miss an airport because an article was deleted,
renamed or never written, and it needs no redirect map from seeds, no per-seed abort, and no
tracking of "airports no seed reached". It costs more fetching — the whole airport set rather than
the roughly 900 that carry a oneworld edge — which is a few dozen extra requests, paid once per
`--refresh`, by a tool run by hand. Only the articles that yield at least one oneworld row are
committed under `sources/`, so the corpus in the tree stays the same size either way.

The airline destination-list articles are not used at all. They were never route data — destination
sets, not pairs, by WikiProject convention — and with the enumeration coming from `airports.pl` they
have no remaining job.

---

## Phase A — The carrier vocabulary

With the seed hop gone there is no seed file, but the thing Phase A actually protected still needs
protecting: **which carriers count**. That is the filter applied at parse time instead — a row whose
operator does not resolve to a 4(j) designator is not emitted.

**The carrier set comes from `prolog/src/carriers.pl:19`**, not from memory:

```prolog
carriers([aa, as, at, ay, ba, cx, fj, ib, jl, mh, nu, qf, qr, rj, ul, wy]).
```

That is Alaska, American, Royal Air Maroc, Finnair, British Airways, Cathay Pacific, Fiji Airways,
Iberia, Japan Airlines, Malaysia Airlines, **Japan Transocean Air**, Qantas, Qatar Airways, Royal
Jordanian, SriLankan and Oman Air. **Hawaiian is not a member of this ruleset** — it appears nowhere
in `carriers.pl`, so admitting it would pull in a network no Explorer fare may be flown on. Japan
Transocean Air (`nu`) *is* eligible under 4(j); it is excluded only from `ticketing_stock/1`, meaning
it may be flown but may not issue the ticket, and `build_qff_tables.mjs` already carries it in its own
`ELIGIBLE` array. Dropping it loses the Japan domestic sectors that are the entire reason it is in
the rule.

A test asserts every designator the extractor can emit satisfies `carriers:carrier_code/1`, so the
list is typed once. Getting this wrong is the highest-cost mistake available here, because it is
invisible in the output: you get a table, it just describes a different alliance.

Affiliates need no special handling under the new enumeration. The airport tables give each operator
its own row, so an Envoy-only or SkyWest-only airport is reached like any other — it is in
`airports.pl`, so it is in the fetch set. Under the seed design this was an assumption that needed
checking; now it is not an assumption at all.

## Phase B — Resolve titles to codes

One SPARQL query, cached and committed:

```sparql
SELECT ?iata ?article WHERE {
  ?item wdt:P238 ?iata .
  ?article schema:about ?item ; schema:isPartOf <https://en.wikipedia.org/> .
}
```

Intersect the result with `airports.pl` and fetch that set. Two things still need the API:

- **Redirect resolution.** Destination cells link through redirects constantly —
  `[[Accra International Airport|Accra]]` is a redirect to `Kotoka International Airport`, which is
  the article Wikidata knows. Any link target absent from the P238 map is batch-resolved with
  `redirects=1` and retried before it is allowed to become a reject.
- **Nothing else.** In particular, do not combine a generator with `prop=revisions&rvprop=content`:
  requesting content pins the page limit to 50 regardless of the generator's limit, so the combined
  form either errors or silently truncates — which looks like a short result rather than a bug.

## Phase C — Fetch and commit the sections

The fetch set is fixed by Phase B, so there is nothing left to filter on the way in — the P238 map
and `airports.pl` have already decided it. What remains is to check the parse on the way out:

- A **destination cell** resolving to a code absent from `airports.pl` is a **reject**. That file is
  built from OurAirports and is the authority on what an airport is.
- An airport whose article carries no oneworld row is **expected** — it is simply not a oneworld
  airport, and most of the 4,161 are not. Track the count anyway: a sudden jump in it means a
  section stopped parsing rather than that the alliance shrank.

Fetch content 50 pageids or titles per request:

```
action=query&prop=revisions&rvprop=ids|content&rvslots=main&formatversion=2&pageids=…
```

Roughly 85 requests over the whole airport set, plus a handful for redirect resolution. Serial. A few
minutes, and a few hundred megabytes transferred — which is why only the extracted sections, not the
articles, are what get written to disk.

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
- Resolve every target through the Phase B redirect map before looking it up in the P238 map.
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
- **`--refresh`** — rerun Phases B–C from `airports.pl`, rewrite the sections and the manifest, then emit.
  The only path that opens a socket, and the only path that changes what the world says. Run by hand,
  never in CI.

If a revid 404s during a `--refresh` (page deleted or revision-deleted), **fail** with the title and
revid. Do not fall back to the current revision — that fallback is what would quietly turn a pinned
build back into a live scrape at exactly the moment an article was moved or vandalised.

The carrier vocabulary needs pinning too, and already is: it lives in `carriers.pl`. A member
joining or leaving the alliance changes which rows are emitted, and that should appear as a
deliberate edit there plus a `--refresh` in the diff rather than arriving on its own.

---

## Acceptance criteria

- `--pinned` makes no network calls and produces byte-identical `services.pl` on repeat runs;
  `git status --porcelain -- prolog/data/` is clean after.
- Every eligible carrier appears in the output; the run reports per-carrier counts so a member
  reduced to a handful of sectors is visible rather than merely present.
- Every designator the extractor can emit satisfies `carriers:carrier_code/1`, asserted by a test.
- Every reject carries an enumerated reason; the unclassified bucket is empty; every reason class has
  been read.
- The committed sections, the manifest and the rejects file are all in the tree, and a fresh clone can
  rebuild `services.pl` from them with the network unplugged.

## Interface to the Prolog side

The only output contract is `services.pl` in the shape fixed by Phase 0 of
[`06-flown-network.md`](06-flown-network.md) — lowercase atoms, `service/4` and `service_window/4`,
three season values. If that schema changes it changes there, and this plan follows. The extractor's
convenience does not decide the fact shape.
