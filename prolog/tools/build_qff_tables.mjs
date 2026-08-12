// build_qff_tables.mjs -- the Qantas Frequent Flyer earning tables, as Prolog.
//
//   npm run earn:qff
//
// Reads the captures under prolog/data/earn/sources/ and writes the fact files
// prolog/src/earn/qff.pl consults. Both the capture and the generated file are
// committed, for the same reason data/generated/airports.pl is: a clone runs
// offline, and an upstream change arrives as a reviewable diff rather than as a
// different answer from the same source tree.
//
// The earning tables have no version and no clause numbers -- unlike the fare
// rule, which has both -- so the URL and the date each capture was read are the
// whole of the provenance available. They are written into source.pl and travel
// with every number this programme produces.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..', '..');
const SOURCES = path.join(REPO, 'prolog', 'data', 'earn', 'sources');
const OUT = path.join(REPO, 'prolog', 'data', 'earn', 'qff');

const read = (name) => JSON.parse(fs.readFileSync(path.join(SOURCES, name), 'utf8'));

const categories = read('qff-categories.json');
const bands = read('qff-bands.json');
const regionDefs = read('qff-region-definitions.json');
const regions = read('qff-regions.json');

// The fare rule's sixteen eligible carriers, and nothing else. Qantas publishes
// earn categories for airlines an Explorer fare may not be flown on at all --
// Air France, Emirates, WestJet -- and a table row for a carrier 4(j) excludes
// is a row no itinerary this validator accepts can ever reach.
const ELIGIBLE = ['aa', 'as', 'at', 'ay', 'ba', 'cx', 'fj', 'ib', 'jl',
                  'mh', 'nu', 'qf', 'qr', 'rj', 'ul', 'wy'];

const COLUMNS = categories.columns;

// Which scope key each capture field becomes, and how src/earn/qff.pl decides
// whether it applies to a segment. `residual` applies when no `sector` scope of
// the same carrier did; `region` cannot be decided without the region tables,
// so a segment that could fall either side of one is priced only where the two
// rows agree -- see fare_bucket/4.
const SCOPES = {
  all: 'all',
  all_other: 'all_other',
  within_fiji: 'within_fiji',
  within_japan: 'within_japan',
  international: 'international',
  domestic: 'domestic',
  long_haul: 'long_haul',
  named_routes: 'named_routes',
};

const quote = (s) => `'${String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;

function rows() {
  const out = [];
  const unpublished = [];
  for (const code of ELIGIBLE) {
    let entry = categories.carriers[code];
    if (!entry) throw new Error(`no earn categories captured for ${code}`);
    if (entry.sameAs) entry = { ...categories.carriers[entry.sameAs], name: entry.name };
    for (const [field, scope] of Object.entries(SCOPES)) {
      const classes = entry[field];
      if (!classes) continue;
      if (typeof classes === 'string') {
        unpublished.push([code, scope, classes]);
        continue;
      }
      // QF publishes ten columns rather than six; its extra discount and
      // flexible grades are not reachable on a partner-marketed Explorer
      // sector, so only the six shared with the partner table are kept.
      const columns = entry.columns || COLUMNS;
      classes.forEach((letters, i) => {
        const column = columns[i];
        if (letters === '-' || !COLUMNS.includes(column)) return;
        for (const letter of letters) {
          out.push([code, scope, letter.toLowerCase(), column]);
        }
      });
    }
  }
  return { out, unpublished };
}

const { out: categoryRows, unpublished } = rows();

// A class in two categories under one scope would make the earn ambiguous and
// is far likelier to be a transcription slip than a real publication.
const seen = new Map();
for (const [carrier, scope, letter, column] of categoryRows) {
  const key = `${carrier}/${scope}/${letter}`;
  if (seen.has(key) && seen.get(key) !== column) {
    throw new Error(`${key} is in two categories: ${seen.get(key)} and ${column}`);
  }
  seen.set(key, column);
}

const categoriesPl = `:- module(qff_categories,
          [ earn_category/4,
            earn_category_unpublished/3,
            earn_scope/2,
            earn_categories/1
          ]).

/** <module> Qantas Frequent Flyer earn categories. GENERATED -- do not edit.

    Built by prolog/tools/build_qff_tables.mjs from
    data/earn/sources/qff-categories.json, read ${categories.fetched} from
    ${categories.source}

    Which category a segment earns in, from the marketing carrier and the class
    it is sold in. The category is then priced by data/earn/qff/bands.pl.

    Only the sixteen carriers Rule 3015 4(j) permits are here; Qantas publishes
    categories for airlines an Explorer fare may not be flown on at all.

    Rows superseded by a later effective date are dropped rather than carried,
    because nothing yet reads an effective date -- see PLANS/05, phase 4. The
    dates that were in force at the capture are recorded in source.pl.
*/

%! earn_scope(?Scope, ?Kind) is nondet.
%  How a scope is decided for a segment. \`always\` applies to everything,
%  \`sector\` is decided from the two endpoints, \`residual\` applies when no
%  sector scope of the same carrier did, and \`region\` needs the region tables
%  that phase 2 adds -- until then a segment that could fall either side of one
%  is priced only where the candidate rows agree.
earn_scope(all,           always).
earn_scope(international, sector).
earn_scope(domestic,      sector).
earn_scope(within_fiji,   sector).
earn_scope(within_japan,  sector).
earn_scope(all_other,     residual).
earn_scope(long_haul,     region).
earn_scope(named_routes,  region).

%! earn_categories(-Categories) is det.
%  The six columns of the partner earning table, in published order.
earn_categories([${COLUMNS.join(', ')}]).

%! earn_category(?Carrier, ?Scope, ?Class, ?Category) is nondet.
${categoryRows.map(([c, s, l, col]) => `earn_category(${c}, ${s}, ${l}, ${col}).`).join('\n')}

%! earn_category_unpublished(?Carrier, ?Scope, ?Reason) is nondet.
%  A row the table names but does not fill in. It is not an absence of earn:
%  it is an earn this table cannot state, so it must reach the reader as
%  undecided rather than as nothing.
${unpublished.map(([c, s, r]) => `earn_category_unpublished(${c}, ${s}, ${quote(r)}).`).join('\n')}
`;

// --- the mileage bands -----------------------------------------------------

const CURRENCIES = [['points', 'points'], ['status_credits', 'credits']];

function bandFacts() {
  const facts = [];
  const edges = [];
  bands.bands.forEach((band, i) => {
    const lower = i === 0 ? 1 : bands.bands[i - 1].max + 1;
    const key = band.max === null ? `band(${lower}, inf)` : `band(${lower}, ${band.max})`;
    if (band.max !== null) edges.push(band.max);
    facts.push({ key, lower, upper: band.max, band });
  });
  return { facts, edges };
}

const { facts: bandRows, edges } = bandFacts();

const rate = (band, field, i) => {
  const row = band[field];
  return row === null || row[i] === null ? 'none' : `fixed(${row[i]})`;
};

const bandsPl = `:- module(qff_bands,
          [ partner_band/3,
            band_accrual/3,
            band_edges/1,
            band_label/2
          ]).

/** <module> Qantas Frequent Flyer partner mileage bands. GENERATED -- do not edit.

    Built by prolog/tools/build_qff_tables.mjs from
    data/earn/sources/qff-bands.json, read ${bands.fetched} from
    ${bands.source}

    The "All other flights" table: what a partner-marketed sector earns per
    one-way flight, by distance and earn category, when no region pair in the
    published table covers it. Phase 2 adds the region pairs, which take
    precedence; these are the fallback and the only basis phase 1 resolves.

    Base rate throughout -- no tier bonus, which is applied by the kernel from
    data/earn/qff/tiers.pl.
*/

%! partner_band(?Band, ?LowMiles, ?HighMiles) is nondet.
%  Inclusive at both ends; \`inf\` is the open top of the table.
${bandRows.map(({ key, lower, upper }) =>
  `partner_band(${key}, ${lower}, ${upper === null ? 'inf' : upper}).`).join('\n')}

%! band_label(?Band, ?Label) is nondet.
%  How the band is written in the register, matching the published table.
${bandRows.map(({ key, lower, upper }) => {
  const label = upper === null
    ? `${lower.toLocaleString('en-US')} miles and above`
    : lower === 1
      ? `up to ${upper.toLocaleString('en-US')} miles`
      : `${lower.toLocaleString('en-US')} to ${upper.toLocaleString('en-US')} miles`;
  return `band_label(${key}, ${quote(label)}).`;
}).join('\n')}

%! band_edges(-Edges) is det.
%  Every boundary in this table, for the near-a-boundary warning in
%  src/earn/distance.pl.
band_edges([${edges.join(', ')}]).

%! band_accrual(?Band, ?Category, ?Rates) is nondet.
${bandRows.flatMap(({ key, band }) =>
  COLUMNS.map((column, i) =>
    `band_accrual(${key}, ${column},\n              [ rate(points, ${rate(band, 'points', i)}),\n                rate(status_credits, ${rate(band, 'credits', i)}) ]).`)
).join('\n')}
`;

// --- the regions and the region-pair table ---------------------------------

// Every label that appears as a group heading or a row heading in
// qff-regions.json, against what it means. Most come straight from the
// definitions page; the rest are a city or a country standing for itself, which
// the page leaves undefined because it does not need defining.
//
// This is the repository's *third* geography taxonomy and it has to stay its own
// table. Qantas splits West Coast from East Coast USA/Canada, which the fare
// rule does not; it files Santiago, Dallas and Tel Aviv as regions of their own;
// and its "Northern Africa" reaches Kenya, Uganda, Somalia and the Seychelles.
// data/countries.pl already had to diverge from OurAirports' continent column
// for the same kind of reason, and aliasing one of these tables to another would
// invent violations or invent points.
const NAMED = Object.fromEntries(
  Object.entries(regionDefs.countryRegions).map(([key, r]) => [r.label, { key, countries: r.countries }])
    .concat(Object.entries(regionDefs.cityRegions).map(([key, r]) =>
      [r.label, { key, places: r.places.map((p) => p.toLowerCase()) }])));

const union = (...keys) => keys.flatMap((k) => regionDefs.countryRegions[k].countries);

const LABELS = {
  ...NAMED,
  // Australian gateways, which the earning table groups by city rather than by
  // any region the definitions page names.
  'Sydney, Melbourne, Brisbane, Gold Coast': { key: 'sydney_melbourne_brisbane_gold_coast', places: ['syd', 'mel', 'bne', 'ool'] },
  Perth:    { key: 'perth',    places: ['per'] },
  Adelaide: { key: 'adelaide', places: ['adl'] },
  Cairns:   { key: 'cairns',   places: ['cns'] },
  // Gulf gateways, once as a group and once each as a destination.
  'Dubai, Doha, Muscat': { key: 'dubai_doha_muscat', places: ['dxb', 'doh', 'mct'] },
  Dubai:  { key: 'dubai',  places: ['dxb'] },
  Doha:   { key: 'doha',   places: ['doh'] },
  Muscat: { key: 'muscat', places: ['mct'] },
  'Tel Aviv': { key: 'tel_aviv', places: ['tlv'] },
  Dallas: { key: 'dallas', places: ['dfw'] },
  Santiago: { key: 'santiago', places: ['scl'] },
  'Los Angeles': { key: 'los_angeles', places: ['lax'] },
  'New York, Newark or Boston': { key: 'new_york_and_boston', places: ['nyc', 'bos'] },
  // The one row that says "East Coast USA" rather than "East Coast USA/Canada".
  // Read as the American members of that list: the difference is two Canadian
  // cities, and widening a region invents earn where narrowing it only withholds
  // it -- the same way round data/cities.pl decides a doubtful membership.
  'East Coast USA': { key: 'east_coast_usa', places: ['bos', 'clt', 'chi', 'mia', 'nyc', 'mco', 'was'] },
  // Countries standing for themselves.
  'Hong Kong': { key: 'hong_kong', countries: ['HK'] },
  Malaysia:    { key: 'malaysia',  countries: ['MY'] },
  Thailand:    { key: 'thailand',  countries: ['TH'] },
  Japan:       { key: 'japan',     countries: ['JP'] },
  Singapore:   { key: 'singapore', countries: ['SG'] },
  China:       { key: 'china',     countries: ['CN'] },
  'Sri Lanka': { key: 'sri_lanka', countries: ['LK'] },
  Fiji:        { key: 'fiji',      countries: ['FJ'] },
  'New Zealand': { key: 'new_zealand', countries: ['NZ'] },
  'New Zealand or Papua New Guinea': { key: 'new_zealand_or_papua_new_guinea', countries: ['NZ', 'PG'] },
  'Hong Kong, Thailand and Japan': { key: 'hong_kong_thailand_japan', countries: ['HK', 'TH', 'JP'] },
  'Southeast Asia or Northern Africa': { key: 'southeast_asia_or_northern_africa', countries: union('southeast_asia', 'northern_africa') },
  // Both endpoints in the USA, and then banded on distance -- the one group in
  // the region table that is itself a mileage table.
  'Intra-USA Short Haul': { key: 'intra_usa', countries: ['US'] },
};

const BAND_ROWS = { 'Up to 400 miles': [1, 400], '401 to 750 miles': [401, 750] };

function regionKey(label) {
  const entry = LABELS[label];
  if (!entry) throw new Error(`no region definition for "${label}"`);
  return entry;
}

const usedRegions = new Map();
const pairRows = [];
const bandPairRows = [];
const pairEdges = new Set();

for (const group of regions.groups) {
  const from = regionKey(group.from);
  usedRegions.set(from.key, from);
  for (const [rowLabel, row] of Object.entries(group.rows)) {
    if (group.mileageBands) {
      const [low, high] = BAND_ROWS[rowLabel];
      pairEdges.add(high);
      COLUMNS.forEach((column, i) => {
        bandPairRows.push({ from: from.key, band: `band(${low}, ${high})`, column, row, i });
      });
      continue;
    }
    const to = regionKey(rowLabel);
    usedRegions.set(to.key, to);
    COLUMNS.forEach((column, i) => {
      pairRows.push({ from: from.key, to: to.key, column, row, i });
    });
  }
}

const label = (entry) =>
  Object.entries(LABELS).find(([, v]) => v.key === entry.key)[0];

const regionsPl = `:- module(qff_regions,
          [ region_places/2,
            region_countries/2,
            region_label/2,
            region_pair/4,
            region_pair_band/4,
            region_pair_edges/1
          ]).

/** <module> Qantas Frequent Flyer regions and region pairs. GENERATED -- do not edit.

    Built by prolog/tools/build_qff_tables.mjs from
    data/earn/sources/qff-region-definitions.json and qff-regions.json, read
    ${regions.fetched} from
    ${regions.source}

    The third geography taxonomy in this repository, and deliberately its own
    table. Qantas splits West Coast from East Coast USA/Canada, which the fare
    rule does not; it files Santiago, Dallas and Tel Aviv as regions of their
    own; and its "Northern Africa" reaches Kenya, Uganda, Somalia and the
    Seychelles. data/countries.pl already had to diverge from OurAirports'
    continent column for the same kind of reason. A test asserts these stay
    separate, so a later contributor cannot tidy up by aliasing one to another.

    A region is a set of places, a set of countries, or both. Places are matched
    on geo:place_key/2, so a region naming New York covers JFK, LGA, EWR and
    SWF -- which is what the published table means by a city.
*/

%! region_places(?Region, ?Places) is nondet.
${[...usedRegions.values()].filter((r) => r.places)
  .map((r) => `region_places(${r.key}, [${r.places.join(', ')}]).`).join('\n')}

%! region_countries(?Region, ?Countries) is nondet.
${[...usedRegions.values()].filter((r) => r.countries)
  .map((r) => `region_countries(${r.key}, [${r.countries.map((c) => `'${c}'`).join(', ')}]).`).join('\n')}

%! region_label(?Region, ?Label) is nondet.
${[...usedRegions.values()].map((r) => `region_label(${r.key}, ${quote(label(r))}).`).join('\n')}

%! region_pair(?From, ?To, ?Category, ?Rates) is nondet.
%  "Between X and Y", so the pair is symmetric and src/earn/qff.pl tries it
%  both ways round rather than this file listing each row twice.
${pairRows.map(({ from, to, column, row, i }) =>
  `region_pair(${from}, ${to}, ${column},\n            [ rate(points, ${rate(row, 'points', i)}),\n              rate(status_credits, ${rate(row, 'credits', i)}) ]).`).join('\n')}

%! region_pair_band(?Region, ?Band, ?Category, ?Rates) is nondet.
%  Intra-USA Short Haul: a group of the region table that is itself banded on
%  distance, with both endpoints in the one region. It is why route_basis/5
%  returns an opaque basis rather than "a region pair, else a band".
${bandPairRows.map(({ from, band, column, row, i }) =>
  `region_pair_band(${from}, ${band}, ${column},\n                 [ rate(points, ${rate(row, 'points', i)}),\n                   rate(status_credits, ${rate(row, 'credits', i)}) ]).`).join('\n')}

%! region_pair_edges(-Edges) is det.
region_pair_edges([${[...pairEdges].sort((a, b) => a - b).join(', ')}]).
`;

const sourcePl = `:- module(qff_source, [qff_source/2, qff_note/1]).

/** <module> Where the Qantas tables were read, and when. GENERATED -- do not edit.

    The earning tables carry no version and no clause numbers, so this is the
    whole of the provenance a number can cite. It is printed with every earn
    report and served from /api/programs. See PLANS/05-loyalty-earning.md.
*/

%! qff_source(?Table, ?Source) is nondet.
qff_source(categories, source(${quote(categories.source)}, ${quote(categories.fetched)})).
qff_source(bands,      source(${quote(bands.source)}, ${quote(bands.fetched)})).
qff_source(regions,    source(${quote(regions.source)}, ${quote(regions.fetched)})).
qff_source(region_definitions, source(${quote(regionDefs.source)}, ${quote(regionDefs.fetched)})).

%! qff_note(?Note) is nondet.
%  What a reader of these numbers has to be told alongside them.
qff_note('These figures are an estimate. The airline\\'s own calculator is authoritative.').
qff_note('Base rate for a one-way sector, before any tier bonus.').
${Object.entries(categories.carriers)
  .filter(([code, e]) => ELIGIBLE.includes(code) && e.effective)
  .map(([code, e]) => `qff_note('${code.toUpperCase()} categories are the rows in force from ${e.effective}; earlier rows are not carried.').`)
  .join('\n')}
`;

fs.mkdirSync(OUT, { recursive: true });
const written = [];
for (const [name, text] of [['categories.pl', categoriesPl],
                            ['bands.pl', bandsPl],
                            ['regions.pl', regionsPl],
                            ['source.pl', sourcePl]]) {
  const file = path.join(OUT, name);
  const before = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null;
  if (before !== text) fs.writeFileSync(file, text);
  written.push(`${name}${before === text ? ' (unchanged)' : ''}`);
}

console.log(`earn:qff — ${categoryRows.length} category rows over ${ELIGIBLE.length} carriers, ` +
            `${bandRows.length} bands × ${COLUMNS.length} categories, ` +
            `${pairRows.length / COLUMNS.length} region pairs over ${usedRegions.size} regions`);
console.log(`earn:qff — ${written.join(', ')}`);
