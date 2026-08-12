# Fetched earning tables

Raw captures of the two programmes' published earning tables, on the date each file records. The
Qantas ones were read out of the pages' own DOM or transcribed by hand; the Asia Miles ones were
derived from the calculator's own API, which is why they arrive as CSV with a guide beside them
rather than as a transcription of a grid. They are the input to the generators under
`prolog/tools/`, which turn them into the `.pl` fact files the kernel reads; both the capture and
the generated file are committed, so an upstream change arrives as a reviewable diff.

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
| `asia-miles-lookup.csv` | 157 cards over 26 airlines: cabin, class group and fare brand to six banded Status Points values and a miles rule | the Cathay miles calculator's API |
| `asia-miles-rules.csv` | the two band schemes, boundary reliability, the enhanced-region rule, the nine zero-point carriers, four city-pair overrides, per-airline sampling coverage | the same |
| `asia-miles-parsing-guide.md` | what the two CSVs mean and how they were obtained, captured verbatim | written against the sampling run |

One table is **not** here and the programme that needs it cannot be finished without it:

* **Cathay's membership tiers**, and the bonus each one pays.

Three of the 25 partners have no card for the very code section 5(b) books an Explorer fare into —
`JL` and `NU` are missing `D` and `L`, `MH` is missing `I` and `L` — so those sectors cannot be
priced. A sampled city pair only observes the classes it actually sells, which is the likeliest
explanation, and the only fix is more sampling. `prolog/test/test_earn.pl` holds the list exactly, so
a fourth appearing is a regression and one disappearing means a re-sample filled it in.

Cathay partner earn used to be the other. It is served by the calculator rather than published as a
grid, and the two CSVs above are that calculator's own responses — 26,780 of them over 1,752 city
pairs, which is why they carry a sampling-coverage table and why a band nobody sampled reaches the
report as undecided rather than as a number. Cathay's own rows were enumerated in full; the partners
were sampled 23 to 90 pairs each.

Two of these were transcribed by hand rather than read out of the page, and each says so in its own
`via` field: `qff-metal.json` and `qff-tiers.json`. The Qantas site refused the scraper on both
pages. That is worth knowing when checking a figure, which is why the note travels into the report
rather than staying here.
