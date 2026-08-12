# Fetched earning tables

Raw captures of the two programmes' published earning tables, read out of the pages' own DOM on the
date each file records. They are the input to the generators under `prolog/tools/`, which turn them
into the `.pl` fact files the kernel reads; both the capture and the generated file are committed,
so an upstream change arrives as a reviewable diff.

They are kept because the earning tables have no version and no clause numbers to cite — unlike the
fare rule, which has both. A URL and a fetch date is the whole of the provenance available, so it
travels with the numbers into `program_source/3` and into every earn report. See
[`PLANS/05-loyalty-earning.md`](../../../../PLANS/05-loyalty-earning.md).

| File | Table | Read from |
|---|---|---|
| `qff-categories.json` | carrier and RBD to Qantas Frequent Flyer earn category | the Qantas earn-category tables |
| `qff-regions.json` | region-pair rows, partner-marketed | the Qantas partner airline earning tables |
| `qff-bands.json` | the "All other flights" mileage bands | the same page |
| `qff-metal.json` | Qantas' own table: region pairs, Australian domestic bands and mileage bands, over ten earn categories | the Qantas and Jetstar earning tables |
| `qff-tiers.json` | the Qantas status bonus by tier | the Qantas earning-points page |
| `cx-marketed.json` | distance zone, cabin, fare family and class to Status Points and Asia Miles | Cathay's 20 August 2025 earnings change |

Two tables are **not** here and the programmes that need them cannot be finished without them:

* **Cathay partner earn** — a share of flown miles per marketing carrier and class. It is served by
  Cathay's calculator rather than published as a table, so it needs the calculator's own responses.
* **Cathay's membership tiers.**

Two of these were transcribed by hand rather than read out of the page, and each says so in its own
`via` field: `qff-metal.json` and `qff-tiers.json`. The Qantas site refused the scraper on both
pages. That is worth knowing when checking a figure, which is why the note travels into the report
rather than staying here.
