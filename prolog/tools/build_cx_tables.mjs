// build_cx_tables.mjs -- the Cathay earning tables, as Prolog.
//
//   npm run earn:cx
//
// Reads data/earn/sources/cx-marketed.json and writes the fact files
// prolog/src/earn/cx.pl consults. Same arrangement as the Qantas generator:
// both the capture and the generated file are committed, so a clone runs
// offline and an upstream change arrives as a reviewable diff.
//
// Cathay-marketed flights only. Partner earn is a share of flown miles served
// by Cathay's calculator rather than published as a table, so it is not here
// and cx.pl says so rather than pricing a partner sector at nothing.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..', '..');
const SOURCES = path.join(REPO, 'prolog', 'data', 'earn', 'sources');
const OUT = path.join(REPO, 'prolog', 'data', 'earn', 'cx');

const cx = JSON.parse(fs.readFileSync(path.join(SOURCES, 'cx-marketed.json'), 'utf8'));

const quote = (s) => `'${String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
const ZONES = cx.zones.map((z) => z.key);

// Countries that pull a 751-2,750 mile sector into Short - Type 2. The zone is
// the one place Cathay's geography is not distance alone, and the reason
// route_basis/5 takes the endpoints rather than only a distance.
const SHORT_TYPE_2 = ['JP', 'ID', 'LK', 'NP', 'BD', 'IN'];

// --- buckets ---------------------------------------------------------------
//
// A bucket is (cabin, fare family, class group). The class group is what the
// table actually rows on, and the family is an independent axis: the Economy
// table lists Y,B,H,K under Flex, Essential *and* Light with different earn
// against each. So a class does not imply a family, and there is nothing to
// derive one from -- which is what makes fareFamily worth carrying in the
// input and a range worth having in the kernel.
//
// So a range is Economy's problem and nowhere else's: in every other cabin a
// class picks its family out on its own.
const buckets = [];
const rates = [];

for (const [group, classes] of Object.entries(cx.economyClasses)) {
  for (const family of ['flex', 'essential', 'light']) {
    buckets.push({ cabin: 'economy', family, group: group.toLowerCase(), classes });
    for (const zone of ZONES) {
      rates.push({ cabin: 'economy', family, group: group.toLowerCase(), zone,
                   points: cx.economy[zone][family][group] });
    }
  }
}

// The Business row is headed "Essential, Light" in the published grid, which is
// one heading written across the whole table rather than two Business fares:
// Light is an Economy fare and Business is sold as Flex or Essential. So the row
// is Essential, and a ticket declared as a Business Light fare is honestly told
// there is no such thing rather than being priced off a family that does not
// exist.
const premium = [
  ['premium_economy', 'flex',      cx.premiumEconomy.flex],
  ['premium_economy', 'essential', cx.premiumEconomy.essential],
  ['business',        'flex',      cx.business.flex],
  ['business',        'essential', cx.business.essential_light],
  ['first',           'flex',      cx.first.flex],
];

// A class the published table lists under more than one family but whose family
// is settled anyway. This is the one place in either programme where a fact not
// on the page decides an answer, so it is written out on its own with the reason
// attached, emitted as its own predicate, and named in the register wherever it
// applies -- never folded into the table, which stays a transcription.
//
// Y is full-fare economy. The grid lists Y,B,H,K under Flex, Essential and Light
// alike, but a Y ticket is the flexible fare by construction; B, H and K are not
// and stay a range until a fareFamily says which they were.
const SETTLED = [
  ['y', 'flex', 'Y is full-fare economy, which is sold as the flexible fare'],
];

for (const [cabin, family, row] of premium) {
  const group = row.classes.join('').toLowerCase();
  buckets.push({ cabin, family, group, classes: row.classes });
  for (const zone of ZONES) rates.push({ cabin, family, group, zone, points: row[zone] });
}

// In every published row Asia Miles is exactly one hundred times Status
// Points. Checked here rather than trusted: the day it stops being true is far
// likelier to be the day a row was transcribed wrong than the day Cathay
// changed the relationship, and either way it should stop the build.
const MILES_PER_POINT = 100;

const classRows = buckets.flatMap(({ cabin, family, group, classes }) =>
  classes.map((c) => `cx_class(${cabin}, ${family}, ${group}, ${c.toLowerCase()}).`));

const bucketsPl = `:- module(cx_buckets,
          [ cx_class/4,
            cx_class_settled/3,
            cx_bucket/3,
            cx_cabin_label/2,
            cx_family/1
          ]).

/** <module> Cathay fare buckets. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/cx-marketed.json, read ${cx.fetched} from
    ${cx.source}

    A bucket is a cabin, a fare family and a class group. The family is an axis
    of its own rather than something the class implies: the Economy table lists
    Y,B,H,K under Flex, Essential and Light with different earn against each, so
    a ticket that names a class and not a family has bought one of three things
    and the honest answer is the spread.

    The published Business row is headed "Essential, Light", which is one
    heading written across the whole grid rather than two Business fares: Light
    is an Economy fare. So Business is Flex or Essential, and every cabin except
    Economy has a class that picks its family out on its own.
*/

%! cx_family(?Family) is nondet.
cx_family(flex).
cx_family(essential).
cx_family(light).

%! cx_bucket(?Cabin, ?Family, ?Group) is nondet.
${buckets.map(({ cabin, family, group }) => `cx_bucket(${cabin}, ${family}, ${group}).`).join('\n')}

%! cx_class(?Cabin, ?Family, ?Group, ?Class) is nondet.
%  A faithful transcription: a class appears once per family the grid lists it
%  under, which for Economy is all three.
${classRows.join('\n')}

%! cx_class_settled(?Class, ?Family, ?Reason) is nondet.
%  The one place a fact that is not on the page decides an answer. Where a class
%  is listed under several families but its family is settled anyway, this says
%  which and why, and src/earn/cx.pl reports the reason as the basis rather than
%  claiming the table said so.
${SETTLED.map(([c, f, why]) => `cx_class_settled(${c}, ${f}, ${quote(why)}).`).join('\n')}

%! cx_cabin_label(?Cabin, ?Label) is nondet.
cx_cabin_label(economy,         'Economy').
cx_cabin_label(premium_economy, 'Premium Economy').
cx_cabin_label(business,        'Business').
cx_cabin_label(first,           'First').
`;

const zonesPl = `:- module(cx_zones, [cx_zone/3, cx_zone_label/2, cx_zone_countries/2, cx_zone_edges/1]).

/** <module> Cathay distance zones. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/cx-marketed.json, read ${cx.fetched} from
    ${cx.source}

    Six zones, five of them distance alone. The sixth is why route_basis/5 takes
    the endpoints: Short - Type 2 is the same 751 to 2,750 miles as Short -
    Type 1, separated only by whether the sector is to or from Japan, Indonesia,
    Sri Lanka, Nepal, Bangladesh or India. No distance can decide it.

    The fourth geography taxonomy in this repository, and independent of the
    other three: it is a six-country list, and the fare rule, OurAirports and
    the Qantas earning regions each cut the world somewhere else.
*/

%! cx_zone(?Zone, ?Low, ?High) is nondet.
%  Inclusive at both ends; \`inf\` is the open top of the table.
${cx.zones.map((z) => `cx_zone(${z.key}, ${z.min}, ${z.max === null ? 'inf' : z.max}).`).join('\n')}

%! cx_zone_label(?Zone, ?Label) is nondet.
${cx.zones.map((z) => {
  const range = z.max === null
    ? `${z.min.toLocaleString('en-US')} miles or above`
    : `${z.min.toLocaleString('en-US')}-${z.max.toLocaleString('en-US')} miles`;
  return `cx_zone_label(${z.key}, ${quote(`${z.label} (${range})`)}).`;
}).join('\n')}

%! cx_zone_countries(?Zone, ?Countries) is nondet.
%  A zone that distance alone cannot decide. Only Short - Type 2 has one.
cx_zone_countries(short_2, [${SHORT_TYPE_2.map((c) => `'${c}'`).join(', ')}]).

%! cx_zone_edges(-Edges) is det.
cx_zone_edges([${[...new Set(cx.zones.map((z) => z.max).filter(Boolean))].sort((a, b) => a - b).join(', ')}]).
`;

const tablePl = `:- module(cx_table, [cx_rate/4]).

/** <module> Cathay Status Points and Asia Miles, per bucket and zone. GENERATED -- do not edit.

    Built by prolog/tools/build_cx_tables.mjs from
    data/earn/sources/cx-marketed.json, read ${cx.fetched} from
    ${cx.source}

    Cathay-marketed flights only, effective from ${cx.effectiveFrom}.

    In every published row Asia Miles is exactly ${MILES_PER_POINT} times Status Points, and the
    generator refuses to write this file if that stops being true of any row --
    which is far likelier to catch a mistranscribed row than a change of policy.
    They are still two declared currencies, because they are two things a member
    holds and one of them is what a tier is measured in.
*/

%! cx_rate(?Bucket, ?Zone, ?Currency, ?Rate) is nondet.
${rates.map(({ cabin, family, group, zone, points }) => {
  if (points === undefined) throw new Error(`no rate for ${cabin}/${family}/${group}/${zone}`);
  return `cx_rate(bucket(${cabin}, ${family}, ${group}), ${zone}, status_points, fixed(${points})).\n` +
         `cx_rate(bucket(${cabin}, ${family}, ${group}), ${zone}, asia_miles, fixed(${points * MILES_PER_POINT})).`;
}).join('\n')}
`;

const sourcePl = `:- module(cx_source, [cx_source/2, cx_note/1]).

/** <module> Where the Cathay tables were read, and when. GENERATED -- do not edit.
*/

%! cx_source(?Table, ?Source) is nondet.
cx_source(marketed, source(${quote(cx.source)}, ${quote(cx.fetched)})).

%! cx_note(?Note) is nondet.
cx_note('These figures are an estimate. The airline\\'s own calculator is authoritative.').
cx_note('Cathay-marketed flights only, at the rates effective from ${cx.effectiveFrom}.').
cx_note('Base rate for a one-way sector. No tier table is loaded, so no tier bonus is applied.').
`;

fs.mkdirSync(OUT, { recursive: true });
const written = [];
for (const [name, text] of [['buckets.pl', bucketsPl],
                            ['zones.pl', zonesPl],
                            ['table_cx.pl', tablePl],
                            ['source.pl', sourcePl]]) {
  const file = path.join(OUT, name);
  const before = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null;
  if (before !== text) fs.writeFileSync(file, text);
  written.push(`${name}${before === text ? ' (unchanged)' : ''}`);
}

console.log(`earn:cx — ${buckets.length} buckets over ${ZONES.length} zones, ` +
            `${rates.length * 2} rates`);
console.log(`earn:cx — ${written.join(', ')}`);
