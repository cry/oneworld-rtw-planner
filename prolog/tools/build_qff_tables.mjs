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

const sourcePl = `:- module(qff_source, [qff_source/2, qff_note/1]).

/** <module> Where the Qantas tables were read, and when. GENERATED -- do not edit.

    The earning tables carry no version and no clause numbers, so this is the
    whole of the provenance a number can cite. It is printed with every earn
    report and served from /api/programs. See PLANS/05-loyalty-earning.md.
*/

%! qff_source(?Table, ?Source) is nondet.
qff_source(categories, source(${quote(categories.source)}, ${quote(categories.fetched)})).
qff_source(bands,      source(${quote(bands.source)}, ${quote(bands.fetched)})).

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
                            ['source.pl', sourcePl]]) {
  const file = path.join(OUT, name);
  const before = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null;
  if (before !== text) fs.writeFileSync(file, text);
  written.push(`${name}${before === text ? ' (unchanged)' : ''}`);
}

console.log(`earn:qff — ${categoryRows.length} category rows over ${ELIGIBLE.length} carriers, ` +
            `${bandRows.length} bands × ${COLUMNS.length} categories`);
console.log(`earn:qff — ${written.join(', ')}`);
