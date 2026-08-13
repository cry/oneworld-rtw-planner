# The flown network, as captured

The input to `prolog/tools/build_services.mjs`, which turns it into
`prolog/data/generated/services.pl`. Both the capture and the generated file are committed, for
the same reason `prolog/data/earn/sources/` and `data/generated/airports.pl` are: a fresh clone
runs offline, and an upstream change arrives as a reviewable diff rather than as a different
answer from the same source tree.

```
npm run services                 # --pinned. Parses sources/ and emits. No network at all.
npm run services -- --refresh    # Re-crawls, rewrites sources/ and the two manifests, then emits.
```

`--pinned` is the mode CI and a fresh clone run, and repeat runs are byte-identical. `--refresh`
is the only path that opens a socket and the only one that changes what the world says; run it by
hand, never in CI, because a green build must not depend on a third party's uptime.

| File | What it is |
|---|---|
| `wikidata_iata.json` | English Wikipedia article title → IATA code, from Wikidata P238 restricted to items with an enwiki sitelink. 8,344 titles. |
| `redirects.json` | The wikilink targets in the destination cells that P238 did not know, resolved once through the API with `redirects=1`. |
| `carrier_aliases.json` | The delta over `prolog/src/carriers.pl` — only the operator spellings `carrier_name/2` and `affiliate/3` do not already cover. |
| `revisions.json` | The pin: every committed section with its page id, revision id and the date it was read. |
| `sources/*.wiki` | The extracted `Airlines and destinations` section of each of those articles, one file per airport, named for its IATA code. |

## Why the enumeration comes from `airports.pl` and not from destination lists

`PLANS/07-wikipedia-extraction.md` phases A and B seeded the crawl from each member's
*List of X destinations* article. That design is abandoned and the reason is worth keeping:
`List of American Airlines destinations` now **redirects to `American Airlines`** — the list was
deleted — and there is no list article at all for SriLankan or for Japan Transocean Air. A seed
set that cannot cover the largest member is not a seed set.

So the enumeration is taken from the two things that do not move. Wikidata's P238 gives 8,344
enwiki articles carrying an IATA code; intersected with the 4,161 codes in
`data/generated/airports.pl` that is 4,081 airports and 4,200 articles, which is the fetch set.
The same map then resolves the wikilinks inside a destinations cell, so it serves twice.

80 codes in `airports.pl` have no enwiki article carrying P238 and are never fetched. 3,848 of
the fetched articles carry an `Airlines and destinations` section; **933 of those carry at least
one oneworld row, and only those 933 sections are committed.** An airport with no oneworld
service contributes nothing to the table and its section would be 16 MB of noise.

## Why only the section, and why the citations are not in it

One article is 100–250 KB; its `Airlines and destinations` section is 5–20 KB. The section is the
only part anything downstream reads.

The citations are then dropped from the section before it is written. They are **68% of the
captured bytes** — 16.7 MB against 5.4 MB — and the parser's `stripRefs` discards every one of them
anyway, so committing them would put eleven megabytes in the tree that no output depends on.

Size is the smaller half of the argument. The corpus is committed so that an upstream change
arrives as something a human reads, and citation churn is the enemy of that: access-dates bumped,
archive URLs rotated, `{{cite web}}` reflowed — thousands of lines a year that change no fact here,
with the one line that adds a route buried somewhere inside them. A `--refresh` diff should show
routes.

The honest cost is that `sources/` is a *transcription* of what was read rather than a byte-for-byte
copy of it, so it cannot by itself prove what the article said. It does not have to.
`revisions.json` pins the exact revid, so the verbatim wikitext is one request away and can be
diffed against this corpus whenever someone doubts it — and that is the same trade
`prolog/data/earn/sources/` already makes, where the captures are transcriptions of published
tables rather than screenshots of them.

Stripping was verified to be output-neutral: re-emitting from the stripped corpus produces a
byte-identical `services.pl` and `services.rejects.json`.

## The parse, and what it refuses

Rows are `{{Airport destination list}}` — a template, not a wikitable — and the extent is found by
a balanced brace scan because refs and nested templates are full of braces. The **link target** is
taken and never the display text: `[[Kotoka International Airport|Accra]]` is ACC, and the word
"Accra" would resolve to nothing on the multi-airport cities that matter most.

Everything the parser cannot resolve cleanly goes to `data/generated/services.rejects.json` under
an enumerated reason code, grouped with counts, and **the run aborts if anything reaches the
unclassified bucket**. That file is a reviewed artifact rather than a log: "every entry has been
read by a human" does not survive fourteen thousand rows, but every reason *class* does.

Two refusals are worth knowing about before reading the table:

* **`operator_brand_ambiguous`, 254 rows.** Every one of them is `American Eagle`, which is flown
  by Envoy, PSA, Piedmont, Republic and SkyWest. The table's rows are operating-carrier rows and
  the article cannot say which certificate flew, so the operating carrier is *unknown* — and an
  unknown operating carrier is not a `carriers:carrier_code/1`, so no fact is emitted. 4(j)
  already degrades to a warning on an absent operating carrier; feeding it a guess is worse than
  feeding it nothing. This is the single largest known gap in the table: AA's US regional network
  is almost entirely absent from it.
* **`operator_not_oneworld`, 13,905 rows over 867 distinct airline names.** Recorded as names with
  counts rather than one entry per destination, because what a reviewer checks here is whether any
  of those names is a member or an affiliate under a spelling the vocabulary misses, and the
  row-level detail adds nothing to that question.

## What this snapshot is not

* **It reflects the pinned revisions, not today.** `service_manifest(snapshot, Date)` says how old
  it is; `revisions.json` says it per article.
* **Seasonal marking is incomplete upstream.** `unknown` means unknown, and an unmarked run is
  recorded as the article states it rather than being second-guessed.
* **Vandalism propagates.** The mitigations are the reviewable diff and the ability to pin one
  article back to a known-good revision without freezing the rest.
* **Absence is much weaker evidence than presence.** A missing sector costs a trip nobody plans;
  an invented one costs an itinerary that validates and then will not ticket. That asymmetry is
  why every doubtful row here is dropped rather than guessed at, and why `src/network.pl` reports
  `absent` from its own operation instead of raising a violation.

## Licence

The route data in `sources/` is © its Wikipedia contributors and is used under
**CC BY-SA 4.0** (https://creativecommons.org/licenses/by-sa/4.0/). `revisions.json` names every
contributing article and the revision it was read at, which is the attribution the licence asks
for; `data/generated/services.pl` carries the same notice in its header, because that is the file
that travels. Wikipedia is not the author of the generated table and does not endorse it. The
title-to-code map in `wikidata_iata.json` comes from Wikidata and is CC0.
