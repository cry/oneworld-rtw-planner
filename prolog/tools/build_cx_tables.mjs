// build_cx_tables.mjs -- the Asia Miles earning tables, as Prolog.
//
//   npm run earn:cx
//
// Reads the two captures under data/earn/sources/ and writes the fact files
// prolog/src/earn/cx.pl consults. Same arrangement as the Qantas generator:
// both the capture and the generated file are committed, so a clone runs
// offline and an upstream change arrives as a reviewable diff.
//
//   asia-miles-lookup.csv   157 rows, one per (airline, cabin, class group,
//                           fare brand), with six banded Status Points values
//                           packed into one column
//   asia-miles-rules.csv    long/EAV: models, bands, boundaries, the region
//                           rule, the zero-point carriers, the CX city-pair
//                           overrides, per-airline sampling coverage
//   asia-miles-parsing-guide.md   what the columns mean, and how the data was
//                           obtained -- captured verbatim beside them
//
// Two earning models live in these tables and the difference is the thing most
// likely to be got wrong, so it is worth restating where the code is:
//
//   * Cathay's own flights earn fixed Status Points per zone and Asia Miles at
//     exactly a hundred times the points. Five distance bands, and the second
//     splits in two by region, giving six cards.
//   * Every partner earns fixed Status Points per zone and Asia Miles as a
//     *percentage of the sector distance*. Six distance bands, with an extra
//     boundary at 3,700 miles that Cathay's own table does not have.
//
// Applying either model's band set to the other airline group is a silent wrong
// answer rather than an error, which is why the scheme is carried on every row
// and asserted below rather than inferred at lookup time.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..', '..');
const SOURCES = path.join(REPO, 'prolog', 'data', 'earn', 'sources');
const OUT = path.join(REPO, 'prolog', 'data', 'earn', 'cx');

const LOOKUP = 'asia-miles-lookup.csv';
const RULES = 'asia-miles-rules.csv';
const GUIDE = 'asia-miles-parsing-guide.md';

const quote = (s) => `'${String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
const die = (msg) => { throw new Error(msg); };

// --- reading the captures ---------------------------------------------------

// RFC-4180 enough for these two files: quoted fields, doubled quotes inside
// them, no embedded newlines. Written out rather than pulled in, because a
// dependency that parses CSV is a dependency the offline build has to carry.
function parseCsv(text) {
  const rows = [];
  for (const line of text.replace(/^﻿/, '').split('\n')) {
    if (line.trim() === '') continue;
    const cells = [];
    let cell = '';
    let quoted = false;
    for (let i = 0; i < line.length; i++) {
      const c = line[i];
      if (quoted) {
        if (c === '"' && line[i + 1] === '"') { cell += '"'; i++; }
        else if (c === '"') quoted = false;
        else cell += c;
      } else if (c === '"') quoted = true;
      else if (c === ',') { cells.push(cell); cell = ''; }
      else cell += c;
    }
    cells.push(cell);
    rows.push(cells);
  }
  const [header, ...body] = rows;
  return body.map((cells) => Object.fromEntries(header.map((h, i) => [h.trim(), (cells[i] ?? '').trim()])));
}

const read = (name) => fs.readFileSync(path.join(SOURCES, name), 'utf8');
const lookup = parseCsv(read(LOOKUP));
const rules = parseCsv(read(RULES));
const guide = read(GUIDE);

// Checked before anything is written, not after: a guard that fires at the end
// has already left the generated tables on disk.
if (!/parsing guide \(v3\)/.test(guide)) die(`${GUIDE} is not the v3 guide these tables were built from`);

const ruleRows = (type) => rules.filter((r) => r.record_type === type);
const ruleValue = (type, key) => {
  const row = ruleRows(type).find((r) => r.key === key);
  if (!row) die(`${RULES} has no ${type} row keyed ${key}`);
  return row;
};

const SNAPSHOT = ruleValue('scope', 'snapshot_date').value;
const SOURCE_URL = `https://${ruleValue('scope', 'source').value}`;
// Stated in the guide rather than the CSVs, and it is the one date that decides
// whether a Cathay figure is the current one.
const EFFECTIVE_FROM = '2025-08-20';

// --- zones ------------------------------------------------------------------
//
// The six positions of `status_points_by_zone` mean different things under the
// two schemes, and position 3 is where they part company: on a partner it is a
// distance band of its own (2,751-3,700), on Cathay it is the *region* variant
// of band 2. Nothing downstream is allowed to treat the two schemes alike, so
// the scheme is part of every zone fact.
const ZONES = {
  cx: [
    { pos: 1, low: 1,    high: 750,  region: 'any',      label: '1-750 miles' },
    { pos: 2, low: 751,  high: 2750, region: 'standard', label: '751-2,750 miles' },
    { pos: 3, low: 751,  high: 2750, region: 'enhanced', label: '751-2,750 miles, enhanced region' },
    { pos: 4, low: 2751, high: 5000, region: 'any',      label: '2,751-5,000 miles' },
    { pos: 5, low: 5001, high: 7500, region: 'any',      label: '5,001-7,500 miles' },
    { pos: 6, low: 7501, high: null, region: 'any',      label: '7,501 miles or above' },
  ],
  partner: [
    { pos: 1, low: 1,    high: 750,  region: 'any', label: '1-750 miles' },
    { pos: 2, low: 751,  high: 2750, region: 'any', label: '751-2,750 miles' },
    { pos: 3, low: 2751, high: 3700, region: 'any', label: '2,751-3,700 miles' },
    { pos: 4, low: 3701, high: 5000, region: 'any', label: '3,701-5,000 miles' },
    { pos: 5, low: 5001, high: 7500, region: 'any', label: '5,001-7,500 miles' },
    { pos: 6, low: 7501, high: null, region: 'any', label: '7,501 miles or above' },
  ],
};

// Checked against the capture rather than trusted: these two lines are the
// difference between a right answer and a plausible one on every sector between
// 2,751 and 5,000 miles.
const declaredEdges = (key) => ruleValue('band', key).value.split('/').map((s) => Number(s.trim()));
const edgesOf = (scheme) => ZONES[scheme].map((z) => z.high).filter((h) => h !== null);
for (const [scheme, key] of [['cx', 'CX_boundaries'], ['partner', 'partner_boundaries']]) {
  const declared = declaredEdges(key);
  const derived = [...new Set(edgesOf(scheme))].sort((a, b) => a - b);
  if (declared.join() !== derived.join()) {
    die(`${scheme} boundaries ${derived.join('/')} do not match the capture's ${declared.join('/')}`);
  }
}

// The seven countries that pull a 751-2,750 mile Cathay sector onto the enhanced
// card. The capture names them; the ISO codes are this file's transcription, and
// the count is asserted so a name that stops matching cannot quietly drop one.
const COUNTRY_CODES = {
  Japan: 'JP', India: 'IN', Bangladesh: 'BD', 'Sri Lanka': 'LK',
  Nepal: 'NP', Kazakhstan: 'KZ', Indonesia: 'ID',
};
const enhancedCountries = ruleValue('rule', 'CX_zone2_enhanced').value
  .split(',').map((s) => s.trim())
  .map((name) => COUNTRY_CODES[name] ?? die(`no ISO code for the enhanced-region country "${name}"`));
if (enhancedCountries.length !== 7) die(`expected 7 enhanced-region countries, got ${enhancedCountries.length}`);

// City pairs that defy the distance rule. Cathay publishes no reason for any of
// them; they are simply what its calculator returns, so they are applied before
// the distance is looked at rather than reconciled with it.
const overrides = ruleRows('override').map((r) => {
  const pairs = r.key.split('/').map((s) => s.trim().split('-'));
  const pos = Number(/CX Zone (\d)/.exec(r.value)?.[1] ?? die(`cannot read a zone from "${r.value}"`));
  const standard = /2-standard/.test(r.value);
  if (standard && pos !== 2) die(`override "${r.key}" names zone 2-standard but zone ${pos}`);
  return { pairs, pos, why: r.notes };
});

// Which zones each airline was actually sampled in. A `?` in the lookup is only
// honest if this says the band was never observed, so the two are checked
// against each other below.
const coverage = Object.fromEntries(ruleRows('coverage').map((r) => {
  const zones = /^all \d/.test(r.value)
    ? [1, 2, 3, 4, 5, 6]
    : [...r.value.matchAll(/(\d)(?:-(\d))?/g)].flatMap(([, a, b]) => {
        const from = Number(a);
        const to = b === undefined ? from : Number(b);
        return Array.from({ length: to - from + 1 }, (_, i) => from + i);
      });
  if (zones.length === 0) die(`cannot read zones from coverage "${r.value}" for ${r.key}`);
  return [r.key, { zones, summary: r.value, detail: r.notes }];
}));

const zeroPoints = ruleRows('zero_points').filter((r) => r.key !== '_pattern').map((r) => r.key);

// --- rows -------------------------------------------------------------------

const atom = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');

// Fare groups the carrier defines and the sampling never reached, so neither the
// points nor the percentage is known. Two of them, and they are the reason a card
// can exist with no rate at all -- which src/earn/cx.pl reports as its own answer
// rather than letting it read as a route the table does not cover.
const unsampledGroups = ruleRows('unobserved_group').map((r) => {
  const m = /^(\S+)\s+(.+?)\s+group\s+(\S+)$/.exec(r.key)
    ?? die(`cannot read an airline, cabin and group from "${r.key}"`);
  return { airline: atom(m[1]), cabin: atom(m[2]), group: atom(m[3]), note: r.notes };
});


// A brand is what the calculator calls the rate card. It is a real axis only on
// Cathay's own Economy, where the same booking classes sit under Flex, Essential
// and Light with different earn against each; everywhere else the brand is just
// the cabin repeated, and there is nothing for a traveller to choose.
const CX_ECONOMY_BRANDS = ['economy_flex', 'economy_essential', 'economy_light', 'codeshare'];
// What a caller may put in `fareFamily`, and the brand each one names. Codeshare
// is deliberately absent: it is decided by who operates the flight, not by what
// was bought.
const FAMILIES = [['flex', 'economy_flex'], ['essential', 'economy_essential'], ['light', 'economy_light']];

// The fare group is the unit of earning, not the booking class: every class in a
// group earns identically, and the group code is the carrier's own. It is part of
// the card key rather than a derived label, because two groups on one airline can
// carry the same classes under different scopes -- and because the class list came
// out of the carrier's published fare groups rather than out of the sampling,
// which is what makes it complete.
//
// Scope is the same domestic/international test the route basis already makes.
// Only JL and NU use it, and there it is load-bearing: JL Economy Y earns 100% on
// an international sector and 50% on a domestic one, so (airline, cabin, class)
// is not a key for them.
const SCOPES = ['all', 'domestic', 'international'];

const rows = lookup.map((r) => {
  const scheme = { CX: 'cx', PARTNER: 'partner' }[r.zone_scheme] ?? die(`unknown zone_scheme "${r.zone_scheme}"`);
  const classes = r.booking_classes.split(/\s+/).filter(Boolean);
  if (classes.length === 0) die(`row ${r.airline}/${r.cabin} lists no booking classes`);
  const points = r.status_points_by_zone.split(';').map((s) => s.trim());
  if (points.length !== 6) die(`row ${r.airline}/${r.cabin}/${r.booking_classes} has ${points.length} zone values, not 6`);
  if (!r.fare_group) die(`row ${r.airline}/${r.cabin}/${r.booking_classes} names no fare group`);
  if (!SCOPES.includes(r.scope)) die(`unknown scope "${r.scope}" on ${r.airline}/${r.cabin}/${r.fare_group}`);
  return {
    airline: atom(r.airline),
    airlineName: r.airline_name,
    scheme,
    cabin: atom(r.cabin),
    brand: atom(r.fare_brand),
    group: atom(r.fare_group),
    scope: r.scope,
    classesLabel: classes.join(' '),
    classes: classes.map((c) => c.toLowerCase()),
    operatedBy: r.operated_by,
    points: points.map((p) => (p === '?' ? null : Number(p))),
    milesBasis: r.asia_miles_basis,
    // A group that exists in the carrier's definitions but was never sampled has
    // no percentage either, which is a third thing again from a rate of nothing.
    milesValue: r.asia_miles_value === '?' ? null : r.asia_miles_value,
  };
});

// The card key has to be unique or two published rows would collapse into one.
for (const [key, group] of Object.entries(Object.groupBy(rows, (r) =>
    `${r.airline}/${r.cabin}/${r.brand}/${r.group}/${r.scope}`))) {
  if (group.length > 1) die(`${key} appears ${group.length} times; the card key is not unique`);
}

for (const row of rows) {
  if (row.points.some((p) => p !== null && !Number.isInteger(p))) {
    die(`row ${row.airline}/${row.group} has a non-integer Status Points value`);
  }
  const cov = coverage[row.airline.toUpperCase()];
  if (!cov) die(`no coverage record for ${row.airline.toUpperCase()}`);
  // Coverage is per airline and a `?` is per cell, so the two only constrain
  // each other in one direction: a zone the airline was never sampled in cannot
  // hold a measured number. The converse does not hold and must not be asserted
  // -- Japan Airlines was sampled in zones 1 to 5 and still has a hole at zone 6
  // on every card, and its domestic groups were never sampled above zone 2.
  for (const [i, p] of row.points.entries()) {
    if (p !== null && p !== 0 && !cov.zones.includes(i + 1)) {
      die(`${row.airline.toUpperCase()} zone ${i + 1} carries a rate but ${RULES} says it was never sampled`);
    }
  }
  if (row.scheme === 'cx' && row.milesBasis !== 'status_points_x100') {
    die(`Cathay row ${row.group}/${row.brand} does not use the x100 rule`);
  }
  if (row.scheme === 'partner' && row.milesBasis !== 'percent_of_distance') {
    die(`partner row ${row.airline}/${row.group} does not price miles off the distance`);
  }
  if (row.scheme === 'cx' && row.cabin === 'economy'
      ? !CX_ECONOMY_BRANDS.includes(row.brand)
      : false) {
    die(`unexpected Cathay Economy brand "${row.brand}"`);
  }
  if (row.scope !== 'all' && !['jl', 'nu'].includes(row.airline)) {
    die(`${row.airline.toUpperCase()} uses scope "${row.scope}"; only JL and NU are supposed to`);
  }
  // A card with no percentage must have no points either, or it would be priced
  // in one currency and silently unpriced in the other for no stated reason.
  if (row.milesValue === null && row.points.some((p) => p !== null)) {
    die(`${row.airline.toUpperCase()}/${row.cabin}/${row.group} has points but no percentage`);
  }
}

// Cathay is the only airline with more than one brand per cabin, and Economy is
// the only cabin it has them in. Asserted rather than assumed, because a second
// airline growing a brand axis would turn a single answer into a range without
// anything else in the pipeline noticing.
for (const [key, group] of Object.entries(Object.groupBy(rows, (r) => `${r.airline}/${r.cabin}/${r.group}/${r.scope}`))) {
  const brands = new Set(group.map((r) => r.brand));
  if (brands.size > 1 && !key.startsWith('cx/economy/')) {
    die(`${key} has ${brands.size} fare brands; only Cathay's own Economy is supposed to`);
  }
}

const airlines = [];
for (const row of rows) {
  if (!airlines.some((a) => a.code === row.airline)) {
    airlines.push({ code: row.airline, name: row.airlineName, scheme: row.scheme });
  }
}
if (airlines.length !== Number(ruleValue('scope', 'airlines').value)) {
  die(`the lookup has ${airlines.length} airlines; the capture says ${ruleValue('scope', 'airlines').value}`);
}

// The x100 rule, checked rather than trusted. The day it stops holding of a
// Cathay row is far likelier to be the day a row was transcribed wrong than the
// day Cathay changed the relationship, and either way it should stop the build.
const MILES_PER_POINT = 100;

// The one conditional percentage in the whole table. American's Business miles
// are 150% where both airports are in the same country and 125% otherwise --
// which is a fact about the sector, so it reaches the accrual as part of the
// route basis rather than as a special case in the resolver.
function milesExpr(row) {
  if (row.scheme === 'cx') return null;   // priced per zone, below
  if (row.milesValue === null) return [];  // never sampled; see the check above
  const parts = row.milesValue.split('/').map((s) => s.trim());
  if (parts.length === 1) return [['any', Number(parts[0])]];
  return parts.map((part) => {
    const [pct, reach] = part.split(/\s+/);
    if (!['domestic', 'international'].includes(reach)) die(`unknown reach "${reach}" in "${row.milesValue}"`);
    return [reach, Number(pct)];
  });
}

const card = (row) =>
  `fare(${row.airline}, ${row.cabin}, ${row.brand}, ${row.group}, ${row.scope})`;

const rateFacts = [];
const unpricedFacts = [];
let inferredZeros = 0;
let unobserved = 0;
let unpricedCards = 0;
for (const row of rows) {
  const cov = coverage[row.airline.toUpperCase()];
  const miles = milesExpr(row);
  if (miles !== null && miles.length === 0) {
    const note = unsampledGroups.find((g) =>
      g.airline === row.airline && g.cabin === row.cabin && g.group === row.group);
    if (!note) die(`${row.airline.toUpperCase()}/${row.cabin}/${row.group} has no percentage and ${RULES} does not say why`);
    unpricedFacts.push(`cx_unpriced(${card(row)}, ${quote(note.note)}).`);
    unpricedCards++;
    continue;
  }
  for (const zone of ZONES[row.scheme]) {
    const points = row.points[zone.pos - 1];
    if (points === null) unobserved++;
    if (points === 0 && !cov.zones.includes(zone.pos)) inferredZeros++;
    const reaches = row.scheme === 'cx'
      ? [['any', `fixed(${points * MILES_PER_POINT})`]]
      : miles.map(([reach, pct]) => [reach, `pct(${pct})`]);
    for (const [reach, milesRate] of reaches) {
      const rates = [];
      // A `?` is not a zero and must not be written as one. Leaving the currency
      // out of the row is what makes the kernel report it undecided, which is
      // the only honest thing to say about a band nobody sampled.
      if (points !== null) rates.push(`rate(status_points, fixed(${points}))`);
      rates.push(`rate(asia_miles, ${milesRate})`);
      rateFacts.push(`cx_rate(${card(row)}, ${zone.pos}, ${reach}, [${rates.join(', ')}]).`);
    }
  }
}

// --- writing ----------------------------------------------------------------

const provenance = (extra) => `    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/${LOOKUP} and ${RULES},
    snapshot ${SNAPSHOT} of
    ${SOURCE_URL}

    See data/earn/sources/${GUIDE} for what the columns mean
    and how the figures were obtained.
${extra ? `\n${extra}\n` : ''}`;

const airlinesPl = `:- module(cx_airlines,
          [ cx_airline/3,
            cx_zero_points/1,
            cx_coverage/4
          ]).

/** <module> The 26 airlines Asia Miles publishes earning for. GENERATED -- do not edit.

${provenance(`    The scheme is the load-bearing column. Cathay's own flights are priced off
    a table of fixed amounts; every partner earns Asia Miles as a percentage of
    the distance flown, off a band set with one more boundary in it. Nothing may
    read a rate without first reading the scheme.`)}*/

%! cx_airline(?Code, ?Name, ?Scheme) is nondet.
%  Scheme is \`cx\` or \`partner\`.
${airlines.map((a) => `cx_airline(${a.code}, ${quote(a.name)}, ${a.scheme}).`).join('\n')}

%! cx_zero_points(?Code) is nondet.
%  Earns Asia Miles and no Status Points at all, on every sector. These nine are
%  exactly the non-oneworld partners, which is a useful sanity check and an
%  inference rather than something the calculator states -- so the list is the
%  data and the pattern is only this comment.
${zeroPoints.map((c) => `cx_zero_points(${atom(c)}).`).join('\n')}

%! cx_coverage(?Code, ?Zones, ?Summary, ?Detail) is nondet.
%  Which distance zones this airline was actually sampled in. Cathay was
%  enumerated exhaustively; the partners were sampled 23-90 city pairs each, so a
%  rate outside these zones was never seen. src/earn/cx.pl says so on the sector
%  rather than leaving the reader to assume the table is complete.
${Object.entries(coverage).map(([code, c]) =>
  `cx_coverage(${atom(code)}, [${c.zones.join(', ')}], ${quote(c.summary)}, ${quote(c.detail)}).`).join('\n')}
`;

const zonesPl = `:- module(cx_zones,
          [ cx_zone/5,
            cx_zone_label/3,
            cx_zone_edges/2,
            cx_enhanced_country/1,
            cx_override/4,
            cx_boundary/3
          ]).

/** <module> The two distance-zone schemes. GENERATED -- do not edit.

${provenance(`    Six positions each, and position 3 is where they part company: on a partner
    it is a distance band of its own, 2,751 to 3,700 miles, and on Cathay it is
    the region variant of band 2 at the same 751 to 2,750 miles as position 2.
    A sector between 2,751 and 5,000 miles read against the wrong scheme returns
    a plausible number from the wrong row, which is why the scheme is an argument
    here and not an assumption anywhere.

    The fourth geography taxonomy in this repository, and independent of the
    other three: it is a seven-country list and a distance, where the fare rule,
    OurAirports and the Qantas earning regions each cut the world somewhere
    else.`)}*/

%! cx_zone(?Scheme, ?Position, ?Low, ?High, ?Region) is nondet.
%  Inclusive at both ends; \`inf\` is the open top of each scheme. Region is
%  \`any\`, or \`standard\`/\`enhanced\` for the Cathay pair that share a distance
%  band and are told apart by the endpoints.
${Object.entries(ZONES).flatMap(([scheme, zs]) => zs.map((z) =>
  `cx_zone(${scheme}, ${z.pos}, ${z.low}, ${z.high === null ? 'inf' : z.high}, ${z.region}).`)).join('\n')}

%! cx_zone_label(?Scheme, ?Position, ?Label) is nondet.
${Object.entries(ZONES).flatMap(([scheme, zs]) => zs.map((z) =>
  `cx_zone_label(${scheme}, ${z.pos}, ${quote(`Zone ${z.pos} (${z.label})`)}).`)).join('\n')}

%! cx_zone_edges(?Scheme, ?Edges) is nondet.
%  Where a great circle stops being a good enough stand-in for the airline's own
%  sector mileage -- see src/earn/distance.pl.
${Object.entries(ZONES).map(([scheme]) =>
  `cx_zone_edges(${scheme}, [${[...new Set(edgesOf(scheme))].sort((a, b) => a - b).join(', ')}]).`).join('\n')}

%! cx_boundary(?Miles, ?Reliability, ?Note) is nondet.
%  How well each cutoff is pinned down by the sampling behind these tables.
${ruleRows('boundary').map((r) => {
  const miles = Number(/^(\d+)/.exec(r.key)[1]);
  const reliability = /FUZZY/.test(r.notes) ? 'fuzzy' : 'clean';
  return `cx_boundary(${miles}, ${reliability}, ${quote(r.notes)}).`;
}).join('\n')}

%! cx_enhanced_country(?Country) is nondet.
%  Either endpoint in one of these pulls a 751-2,750 mile Cathay sector onto the
%  enhanced card. It is the one place a distance alone cannot decide a zone, and
%  the reason route_basis/5 is handed the segment rather than only a number.
${enhancedCountries.map((c) => `cx_enhanced_country('${c}').`).join('\n')}

%! cx_override(?From, ?To, ?Position, ?Why) is nondet.
%  City pairs whose card is not the one their distance predicts. Applied before
%  the distance is looked at. Cathay publishes no reason for any of them, so the
%  note is the observation rather than an explanation.
${overrides.flatMap(({ pairs, pos, why }) => pairs.map(([from, to]) =>
  `cx_override(${from.toLowerCase()}, ${to.toLowerCase()}, ${pos}, ${quote(why)}).`)).join('\n')}
`;

const bucketsPl = `:- module(cx_buckets,
          [ cx_row/5,
            cx_class/6,
            cx_group_label/5,
            cx_brand_label/2,
            cx_cabin_label/2,
            cx_family/2,
            cx_codeshare_brand/2,
            cx_class_settled/3
          ]).

/** <module> Which rate card a ticket reads against. GENERATED -- do not edit.

${provenance(`    One row per (airline, cabin, fare group, scope, fare brand), which is the grain
    the calculator publishes. The fare group is the carrier's own code and the
    real unit of earning: every class in a group earns identically, and the
    membership comes from the carrier's published fare groups rather than from
    sampling -- so a class this file does not name is a class no group contains,
    not one nobody happened to observe.

    Scope is the domestic/international test, and only Japan Airlines and Japan
    Transocean use anything but \`all\`. There it decides the answer: JL Economy Y
    is group F at 100% on an international sector and group H at 50% on a
    domestic one, so (airline, cabin, class) is not a key for them.

    The brand is a real axis only on Cathay's own Economy: there the same booking
    classes sit under Flex, Essential and Light with different earn against each,
    so a ticket that names a class and not a family has genuinely bought one of
    three things and the honest answer is the spread. In every other cabin, and on
    every partner, the brand is the cabin repeated and a class picks its card out
    on its own.`)}*/

%! cx_row(?Airline, ?Cabin, ?Brand, ?Group, ?Scope) is nondet.
${rows.map((r) => `cx_row(${r.airline}, ${r.cabin}, ${r.brand}, ${r.group}, ${r.scope}).`).join('\n')}

%! cx_class(?Airline, ?Cabin, ?Brand, ?Group, ?Scope, ?Class) is nondet.
%  A faithful transcription: a class appears once per card that lists it.
${rows.flatMap((r) => r.classes.map((c) =>
  `cx_class(${r.airline}, ${r.cabin}, ${r.brand}, ${r.group}, ${r.scope}, ${c}).`)).join('\n')}

%! cx_group_label(?Airline, ?Cabin, ?Group, ?Scope, ?Label) is nondet.
%  The fare group's membership as the table writes it, so a figure can be checked
%  against the published row rather than against a key this file invented.
${[...new Map(rows.map((r) => [`${r.airline}/${r.cabin}/${r.group}/${r.scope}`, r]))
  .values()]
  .map((r) => `cx_group_label(${r.airline}, ${r.cabin}, ${r.group}, ${r.scope}, ${quote(r.classesLabel)}).`).join('\n')}

%! cx_brand_label(?Brand, ?Label) is nondet.
${[...new Map(rows.map((r) => [r.brand, r.brand === 'codeshare' ? 'Codeshare' : null])).keys()]
  .map((brand) => {
    const row = rows.find((r) => r.brand === brand);
    const label = brand === 'codeshare' ? 'Codeshare'
      : row.cabin === 'economy' && row.airline === 'cx' && brand !== 'economy'
        ? brand.split('_').map((w) => w[0].toUpperCase() + w.slice(1)).join(' ')
        : { economy: 'Economy', premium_economy: 'Premium Economy', business: 'Business', first: 'First' }[brand];
    return `cx_brand_label(${brand}, ${quote(label ?? die(`no label for brand ${brand}`))}).`;
  }).join('\n')}

%! cx_cabin_label(?Cabin, ?Label) is nondet.
cx_cabin_label(economy,         'Economy').
cx_cabin_label(premium_economy, 'Premium Economy').
cx_cabin_label(business,        'Business').
cx_cabin_label(first,           'First').

%! cx_family(?Family, ?Brand) is nondet.
%  What a caller may put in \`fareFamily\`, and the card it names. Codeshare is
%  deliberately not one of them: it is settled by who operates the flight rather
%  than by what was bought.
${FAMILIES.map(([family, brand]) => `cx_family(${family}, ${brand}).`).join('\n')}

%! cx_codeshare_brand(?Cabin, ?Brand) is nondet.
%  The card a Cathay flight number on partner metal reads against. Economy has
%  one and it is numerically identical to Economy Light in every band; the other
%  three cabins publish none, so a codeshare in them is unknown rather than
%  priced off the Cathay-operated figure.
${[...new Set(rows.filter((r) => r.brand === 'codeshare').map((r) => r.cabin))]
  .map((cabin) => `cx_codeshare_brand(${cabin}, codeshare).`).join('\n')}

%! cx_class_settled(?Class, ?Brand, ?Reason) is nondet.
%  The one place a fact that is not on the page decides an answer. Y is full-fare
%  economy and therefore the flexible fare whatever the grid lists it under; B, H
%  and K are not, and stay a range until a fareFamily says which they were.
%  src/earn/cx.pl reports this reason as the basis rather than claiming the table
%  settled it.
cx_class_settled(y, economy_flex, 'Y is full-fare economy, which is sold as the flexible fare').
`;

const tablePl = `:- module(cx_table, [cx_rate/4, cx_unpriced/2]).

/** <module> Status Points and Asia Miles, per card and zone. GENERATED -- do not edit.

${provenance(`    One fact per (card, zone position, reach), binding the rate list
    src/earn/kernel.pl expects. Cathay's own rows carry both currencies as fixed
    amounts, with Asia Miles at exactly ${MILES_PER_POINT} times the Status Points; a partner's
    carry fixed Status Points and Asia Miles as a percentage of the distance
    flown.

    A zone nobody sampled has no Status Points rate at all rather than a zero.
    That is the whole reason this file is generated with a hole in it: the kernel
    reports an absent rate as undecided, and 0 would be a claim the observations
    do not support. ${unobserved} of the ${rows.length * 6} cells are such holes.

    Reach is \`any\` except on American's Business card, the one row in the table
    whose percentage varies: 150% where both airports are in the same country and
    125% otherwise. That is a fact about the sector, so it arrives here as part of
    the route basis rather than as a special case in the resolver.`)}*/

%! cx_rate(?Card, ?Zone, ?Reach, ?Rates) is nondet.
${rateFacts.join('\n')}

%! cx_unpriced(?Card, ?Why) is nondet.
%  A fare group the carrier defines and the sampling never reached, so it has no
%  rate at any distance and no percentage either. Two of them, and they are a
%  different thing from a card whose rate is simply zero.
${unpricedFacts.join('\n')}
`;

const notes = [
  'These figures are an estimate. The airline\'s own calculator is authoritative.',
  `Cathay-marketed sectors are priced off the fixed table effective from ${EFFECTIVE_FROM}; partner-marketed sectors earn Asia Miles as a percentage of the distance flown.`,
  'Base rate for a one-way sector. No tier table is loaded, so no tier bonus is applied.',
  `Partner rates were sampled rather than enumerated, so a band nobody sampled is reported undecided rather than as a number. Cathay's own table was enumerated in full.`,
];

const sourcePl = `:- module(cx_source, [cx_source/2, cx_note/1]).

/** <module> Where the Asia Miles tables were read, and when. GENERATED -- do not edit.
*/

%! cx_source(?Table, ?Source) is nondet.
cx_source(earning, source(${quote(SOURCE_URL)}, ${quote(SNAPSHOT)})).

%! cx_note(?Note) is nondet.
${notes.map((n) => `cx_note(${quote(n)}).`).join('\n')}
`;

if (unpricedFacts.length !== unsampledGroups.length) {
  die(`${RULES} names ${unsampledGroups.length} never-sampled groups but ${unpricedFacts.length} cards have no rate`);
}

fs.mkdirSync(OUT, { recursive: true });
const written = [];
const files = [['airlines.pl', airlinesPl], ['zones.pl', zonesPl],
               ['buckets.pl', bucketsPl], ['table_cx.pl', tablePl], ['source.pl', sourcePl]];
for (const [name, text] of files) {
  const file = path.join(OUT, name);
  const before = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null;
  if (before !== text) fs.writeFileSync(file, text);
  written.push(`${name}${before === text ? ' (unchanged)' : ''}`);
}

console.log(`earn:cx — ${rows.length} cards over ${airlines.length} airlines, ${rateFacts.length} rate rows`);
console.log(`earn:cx — ${unobserved} unsampled cells left unpriced, ${inferredZeros} inferred zeros, ` +
            `${unpricedCards} cards never sampled at all`);
console.log(`earn:cx — ${written.join(', ')}`);
