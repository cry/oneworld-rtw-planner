// build_services.mjs -- the flown network, out of Wikipedia's airport articles.
//
//   npm run services              # --pinned: parse the committed sections, no network
//   npm run services -- --refresh # the crawl: rewrite the sections, then emit
//
// The acquisition half of PLANS/07-wikipedia-extraction.md. The fact shape it
// emits is fixed by Phase 0 of PLANS/06-flown-network.md and is not this
// generator's to choose.
//
// WHY IT ENUMERATES FROM airports.pl RATHER THAN FROM DESTINATION LISTS
//
// PLANS/07 phases A and B seeded the crawl from each member's "List of X
// destinations" article. That design is abandoned, and the reason is worth
// keeping: `List of American Airlines destinations` now redirects to `American
// Airlines` -- the list was deleted -- and there is no list article at all for
// SriLankan or Japan Transocean Air. A seed set that cannot cover the largest
// member is not a seed set. So the enumeration is taken from the two things
// that do not move: Wikidata's P238 (IATA airport code) with an enwiki
// sitelink, intersected with the 4,161 codes already in
// data/generated/airports.pl. That intersection is both the fetch set and --
// the same map, serving twice -- what resolves a destination cell's wikilink
// to a code.
//
// WHY THE SECTIONS ARE COMMITTED
//
// data/network/sources/*.wiki holds the extracted `Airlines and destinations`
// section of every article that yielded a oneworld row, exactly as
// data/earn/sources/ holds the earning-table captures. A fresh clone rebuilds
// services.pl from them with the network unplugged, and an upstream change
// arrives as a reviewable diff rather than as a different answer from the same
// source tree. Only the section is kept, never the whole article: it is the
// part anything downstream reads and roughly a tenth of the bytes.
//
// WHY A ROW CAN BE REFUSED
//
// Everything this file cannot resolve cleanly goes to
// data/generated/services.rejects.json under an enumerated reason code, and the
// run aborts if anything lands in the unclassified bucket. A best-effort fact
// is worse than a missing one here: a missing sector costs a trip nobody plans,
// an invented one costs an itinerary that validates and then will not ticket.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..', '..');
const NETWORK = path.join(REPO, 'prolog', 'data', 'network');
const SOURCES = path.join(NETWORK, 'sources');
const GENERATED = path.join(REPO, 'prolog', 'data', 'generated');
const AIRPORTS = path.join(GENERATED, 'airports.pl');
const CARRIERS = path.join(REPO, 'prolog', 'src', 'carriers.pl');

const WIKIDATA_FILE = path.join(NETWORK, 'wikidata_iata.json');
const REDIRECTS_FILE = path.join(NETWORK, 'redirects.json');
const ALIASES_FILE = path.join(NETWORK, 'carrier_aliases.json');
const REVISIONS_FILE = path.join(NETWORK, 'revisions.json');
const OUT_PL = path.join(GENERATED, 'services.pl');
const OUT_REJECTS = path.join(GENERATED, 'services.rejects.json');

const API = 'https://en.wikipedia.org/w/api.php';
const SPARQL = 'https://query.wikidata.org/sparql';

// Wikimedia blocks generic agents outright, and asks that a client name the
// project and a way to reach whoever runs it. maxlag=5 on every call is the
// other half: it makes the API refuse rather than add load when the cluster is
// behind, and this client then waits.
const UA = 'oneworld-rtw-planner/1.0 (https://github.com/cry/oneworld-rtw-planner; build_services.mjs) node-fetch';

const SPARQL_QUERY = `SELECT ?iata ?article WHERE {
  ?item wdt:P238 ?iata .
  ?article schema:about ?item ; schema:isPartOf <https://en.wikipedia.org/> .
}`;

// ---------------------------------------------------------------------------
// arguments

const argv = process.argv.slice(2);
const REFRESH = argv.includes('--refresh');
const PINNED = !REFRESH;
const CACHE = (argv.find((a) => a.startsWith('--cache=')) || '').slice(8);
const LIMIT = Number((argv.find((a) => a.startsWith('--limit=')) || '').slice(8)) || 0;
const ONLY = (argv.find((a) => a.startsWith('--only=')) || '').slice(7)
  .split(',').map((s) => s.trim().toLowerCase()).filter(Boolean);

if (argv.some((a) => a.startsWith('--') && !/^--(refresh|pinned|cache=|limit=|only=)/.test(a))) {
  console.error('usage: node prolog/tools/build_services.mjs [--refresh|--pinned] [--cache=DIR] [--limit=N] [--only=lhr,jfk]');
  process.exit(2);
}

// ---------------------------------------------------------------------------
// the two tables this generator is not allowed to restate

// airports.pl is the authority on what an airport is: it is built from
// OurAirports and filtered to scheduled service. A destination cell resolving
// to a code that is not in it is a reject, not a new airport.
function readAirports() {
  const text = fs.readFileSync(AIRPORTS, 'utf8');
  return new Set([...text.matchAll(/^airport\(([a-z0-9]+),/gm)].map((m) => m[1]));
}

// The carrier vocabulary comes from src/carriers.pl and nowhere else. A fresh
// table restating carrier_name/2 and affiliate/3 would be a third copy of the
// vocabulary and the one that drifts, so this reads the Prolog source.
function readCarriers() {
  const text = fs.readFileSync(CARRIERS, 'utf8');
  const names = new Map();      // display name -> designator
  const codes = new Set();      // everything carrier_code/1 accepts
  const eligible = [];

  const list = text.match(/^carriers\(\[([^\]]*)\]\)\./m);
  if (!list) throw new Error('carriers.pl: no carriers/1 list');
  for (const c of list[1].split(',').map((s) => s.trim())) { eligible.push(c); codes.add(c); }

  for (const m of text.matchAll(/^carrier_name\(([a-z0-9]+),\s*'((?:[^'\\]|\\.)*)'\)\./gm)) {
    names.set(unquote(m[2]), m[1]);
  }
  for (const m of text.matchAll(/^affiliate\(([a-z0-9]+),\s*([a-z0-9]+),\s*'((?:[^'\\]|\\.)*)'\)\./gm)) {
    names.set(unquote(m[3]), m[2]);
    codes.add(m[2]);
  }
  // carrier_code(jq). and carrier_code(qq). -- the two QF operators 4(j) names
  // as exceptions. The clauses with bodies do not match this pattern.
  for (const m of text.matchAll(/^carrier_code\(([a-z0-9]+)\)\.$/gm)) codes.add(m[1]);

  if (eligible.length !== 16) throw new Error(`carriers.pl: expected 16 eligible carriers, got ${eligible.length}`);
  return { names, codes, eligible };
}

const unquote = (s) => s.replace(/\\'/g, "'").replace(/\\\\/g, '\\');

// ---------------------------------------------------------------------------
// HTTP, serial and polite

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function get(url, accept) {
  for (let attempt = 0; ; attempt++) {
    let res, body;
    try {
      res = await fetch(url, { headers: { 'User-Agent': UA, Accept: accept } });
      if (res.status === 429 || res.status === 503) {
        if (attempt >= 8) throw new Error(`${res.status} from ${url}`);
        const wait = Number(res.headers.get('retry-after')) * 1000 || 5000 * (attempt + 1);
        await sleep(wait);
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status} from ${url}`);
      // A dropped connection mid-body raises here rather than at fetch(), so
      // the read is inside the retry too.
      body = await res.text();
    } catch (e) {
      if (attempt >= 5) throw e;
      await sleep(3000 * (attempt + 1));
      continue;
    }
    let json;
    try { json = JSON.parse(body); } catch { throw new Error(`non-JSON reply from ${url}: ${body.slice(0, 200)}`); }
    // maxlag comes back as a 200 with an error object on some paths.
    if (json.error && json.error.code === 'maxlag') {
      if (attempt >= 8) throw new Error(`maxlag persisted: ${json.error.info}`);
      await sleep(5000 * (attempt + 1));
      continue;
    }
    if (json.error) throw new Error(`API error ${json.error.code}: ${json.error.info}`);
    return json;
  }
}

const apiUrl = (params) =>
  `${API}?${new URLSearchParams({ format: 'json', formatversion: '2', maxlag: '5', ...params })}`;

// ---------------------------------------------------------------------------
// Phase 1 -- the Wikidata title -> IATA map

async function fetchWikidata() {
  const url = `${SPARQL}?${new URLSearchParams({ query: SPARQL_QUERY })}`;
  const json = await get(url, 'application/sparql-results+json');
  const titles = {};
  let skipped = 0;
  for (const row of json.results.bindings) {
    const code = String(row.iata.value).trim().toLowerCase();
    const article = String(row.article.value);
    // Only real three-letter IATA codes; Wikidata carries a handful of
    // airfield idents and one blank-node artefact under the same property.
    if (!/^[a-z]{3}$/.test(code)) { skipped++; continue; }
    const title = titleFromUrl(article);
    if (!title) { skipped++; continue; }
    // A code with two articles is normally an airport and the air base it grew
    // out of. Both are kept: the fetch set drops the one with no destinations
    // table, and a destination cell may legitimately link to either.
    if (titles[title] && titles[title] !== code) continue;
    titles[title] = code;
  }
  const sorted = {};
  for (const k of Object.keys(titles).sort()) sorted[k] = titles[k];
  const out = {
    source: SPARQL,
    fetched: today(),
    query: SPARQL_QUERY,
    note: 'English Wikipedia article title -> IATA airport code, from Wikidata property P238 '
        + 'restricted to items with an enwiki sitelink. This is both the enumeration (intersected '
        + 'with data/generated/airports.pl it gives the articles to fetch) and the resolver for the '
        + 'wikilinks in a destinations cell. Codes that are not three letters are dropped.',
    titles: sorted,
  };
  fs.writeFileSync(WIKIDATA_FILE, JSON.stringify(out, null, 2) + '\n');
  console.log(`services — wikidata: ${Object.keys(sorted).length} titles, ${skipped} rows dropped`);
  return out;
}

function titleFromUrl(url) {
  const m = /^https?:\/\/en\.wikipedia\.org\/wiki\/(.+)$/.exec(url);
  if (!m) return null;
  try { return decodeURIComponent(m[1]).replace(/_/g, ' '); } catch { return null; }
}

const today = () => new Date().toISOString().slice(0, 10);

// ---------------------------------------------------------------------------
// Phase 2 -- fetch the articles and extract the section

// The section, not the article. Everything below works on wikitext, so the
// first job is to find `== Airlines and destinations ==` and its extent.
const HEADING = /^(={2,6})\s*(.*?)\s*\1\s*$/gm;

function headings(text) {
  const out = [];
  HEADING.lastIndex = 0;
  let m;
  while ((m = HEADING.exec(text))) {
    out.push({ level: m[1].length, title: m[2], start: m.index, end: m.index + m[0].length });
  }
  return out;
}

const DESTINATIONS_HEADING = /^airlines?\s*(?:and|&|&amp;)\s*destinations?$/i;

//! extractSection(+Wikitext) is the `Airlines and destinations` section whole,
//  heading included, or null. The Passenger/Cargo split is left to the parser
//  so that the committed capture is a section as it appeared rather than this
//  generator's reading of it.
function extractSection(text) {
  const hs = headings(text);
  const i = hs.findIndex((h) => DESTINATIONS_HEADING.test(h.title));
  if (i < 0) return null;
  const start = hs[i].start;
  let end = text.length;
  for (let j = i + 1; j < hs.length; j++) {
    if (hs[j].level <= hs[i].level) { end = hs[j].start; break; }
  }
  return text.slice(start, end).replace(/\s+$/, '') + '\n';
}

async function fetchArticles(fetchSet, cacheDir) {
  const cache = new Map();
  const cacheFile = cacheDir ? path.join(cacheDir, 'articles.ndjson') : null;
  if (cacheFile && fs.existsSync(cacheFile)) {
    for (const line of fs.readFileSync(cacheFile, 'utf8').split('\n')) {
      if (!line.trim()) continue;
      const row = JSON.parse(line);
      cache.set(row.title, row);
    }
    console.log(`services — cache: ${cache.size} articles already fetched`);
  }
  if (cacheDir) fs.mkdirSync(cacheDir, { recursive: true });

  const wanted = fetchSet.filter((t) => !cache.has(t));
  const batches = [];
  for (let i = 0; i < wanted.length; i += 50) batches.push(wanted.slice(i, i + 50));

  let done = 0;
  for (const batch of batches) {
    const json = await get(apiUrl({
      action: 'query',
      prop: 'revisions',
      rvprop: 'ids|content',
      rvslots: 'main',
      titles: batch.join('|'),
    }), 'application/json');

    const q = json.query || {};
    // titles= normalises and follows nothing; a redirect among the fetch set
    // comes back under `redirects`, so map the reply back to what was asked.
    const back = new Map();
    for (const n of q.normalized || []) back.set(n.to, n.from);
    for (const r of q.redirects || []) back.set(r.to, back.get(r.from) || r.from);

    for (const page of q.pages || []) {
      const asked = back.get(page.title) || page.title;
      if (page.missing || !page.revisions || !page.revisions[0]) {
        const row = { title: asked, missing: true };
        cache.set(asked, row);
        if (cacheFile) fs.appendFileSync(cacheFile, JSON.stringify(row) + '\n');
        continue;
      }
      const rev = page.revisions[0];
      const content = rev.slots.main.content || '';
      const row = {
        title: asked,
        resolved: page.title,
        pageid: page.pageid,
        revid: rev.revid,
        section: extractSection(content),
      };
      cache.set(asked, row);
      if (cacheFile) fs.appendFileSync(cacheFile, JSON.stringify(row) + '\n');
    }
    // A title that came back under no page at all (rare, but it must not look
    // like a silently empty article).
    for (const t of batch) if (!cache.has(t)) cache.set(t, { title: t, missing: true });

    done += batch.length;
    if (done % 500 < 50) console.log(`services — fetched ${done}/${wanted.length}`);
    await sleep(120);
  }
  return cache;
}

// ---------------------------------------------------------------------------
// wikitext

//! stripComments removes `<!-- ... -->`. The template's rows are separated by
//  bare comments, and the section leads with shouted editorial notices that
//  contain pipes and brackets.
const stripComments = (s) => s.replace(/<!--[\s\S]*?-->/g, '');

//! stripRefs removes `<ref …/>` and `<ref …>…</ref>`. Every one of them
//  contains a {{cite}} template, so nothing below can scan braces until they
//  are gone.
const stripRefs = (s) => s
  .replace(/<ref[^<>]*\/\s*>/gi, '')
  .replace(/<ref\b[^<>]*>[\s\S]*?<\/ref\s*>/gi, '')
  .replace(/<\/?ref\b[^<>]*>/gi, '');

//! depthScan walks wikitext tracking `{{…}}`, `[[…]]` and `{|…|}` so that a
//  pipe inside a link or a citation is never mistaken for a field separator.
function* scan(s) {
  let brace = 0, link = 0, table = 0;
  for (let i = 0; i < s.length; i++) {
    const two = s.slice(i, i + 2);
    if (two === '{{') { brace++; yield { i, c: two, depth: brace + link + table, open: true }; i++; continue; }
    if (two === '}}') { if (brace) brace--; yield { i, c: two, depth: brace + link + table, open: false }; i++; continue; }
    if (two === '[[') { link++; yield { i, c: two, depth: brace + link + table, open: true }; i++; continue; }
    if (two === ']]') { if (link) link--; yield { i, c: two, depth: brace + link + table, open: false }; i++; continue; }
    if (two === '{|') { table++; i++; continue; }
    if (two === '|}') { if (table) table--; i++; continue; }
    yield { i, c: s[i], depth: brace + link + table };
  }
}

//! templateExtent(+Text, +Start) is the index just past the `}}` closing the
//  template that opens at Start. Refs and nested templates carry braces, which
//  is why this is a balanced scan and not a regex.
function templateExtent(text, start) {
  let depth = 0;
  for (let i = start; i < text.length; i++) {
    if (text.startsWith('{{', i)) { depth++; i++; continue; }
    if (text.startsWith('}}', i)) { depth--; i++; if (depth === 0) return i + 1; continue; }
  }
  return -1;
}

const DEST_TEMPLATES = /\{\{\s*(?:airport[ _-]destination[ _-]list|airport-dest-list|airport[ _]dest[ _]list)\s*(?=[|\n}])/gi;

//! destinationTemplates(+SectionText) is every `{{Airport destination list}}`
//  in the text, as bodies with the template name stripped.
function destinationTemplates(text) {
  const out = [];
  DEST_TEMPLATES.lastIndex = 0;
  let m;
  while ((m = DEST_TEMPLATES.exec(text))) {
    const end = templateExtent(text, m.index);
    if (end < 0) { out.push({ body: null, broken: true }); break; }
    out.push({ body: text.slice(m.index + m[0].length, end - 2) });
    DEST_TEMPLATES.lastIndex = end;
  }
  return out;
}

//! rowChunks(+Body) splits a template body into rows at every top-level `|`
//  that starts a line -- the structure the `<!-- -->` separators impose -- and
//  each row into its top-level fields. Two fields is the usual shape; the
//  variants that are not are resolved by the caller, which has the vocabulary
//  needed to tell an operator field from a destinations field.
//
//  This runs on text the comments and refs have already been removed from. It
//  has to: `<!-- --> | [[Asiana Airlines]] | …` on one line is common, and
//  splitting before the comment goes leaves that row glued to the one above it,
//  which then swallows the next airline's name as a destination.
function rowChunks(body) {
  const starts = [];
  let atLineStart = true;
  for (const t of scan(body)) {
    if (t.c === '\n') { atLineStart = true; continue; }
    if (t.c === ' ' || t.c === '\t') continue;
    if (t.c === '|' && t.depth === 0 && atLineStart) starts.push(t.i);
    atLineStart = false;
  }
  const chunks = [];
  for (let k = 0; k < starts.length; k++) {
    chunks.push(topFields(body.slice(starts[k] + 1, k + 1 < starts.length ? starts[k + 1] : body.length)));
  }
  // A row wrapped across two lines with no separator -- `| [[Airline]]` and its
  // destinations underneath -- arrives as two one-field chunks. Rejoin them.
  const merged = [];
  for (let k = 0; k < chunks.length; k++) {
    if (chunks[k].length !== 1) { merged.push(chunks[k]); continue; }
    if (!chunks[k][0].trim()) continue;
    if (k + 1 < chunks.length && chunks[k + 1].length === 1 && chunks[k + 1][0].trim()) {
      merged.push([chunks[k][0], chunks[k + 1][0]]);
      k++;
      continue;
    }
    merged.push([chunks[k][0], '']);
  }
  return merged;
}

function topFields(chunk) {
  const cuts = [];
  for (const t of scan(chunk)) if (t.c === '|' && t.depth === 0) cuts.push(t.i);
  const out = [];
  let from = 0;
  for (const c of cuts) { out.push(chunk.slice(from, c)); from = c + 1; }
  out.push(chunk.slice(from));
  return out;
}

//! looksLikeOperator decides whether a field past the second is another
//  airline's row packed onto the same line or the sortable template's third
//  "Refs" column. The discriminator is the vocabulary already loaded: a field
//  whose first wikilink is not an airport article is naming something else, and
//  in this template the only other thing a row names is an operator.
function looksLikeOperator(field, ctx) {
  const t = clean(field);
  if (!t.trim()) return false;
  for (const p of linkParts(t)) {
    if (p.target === undefined) continue;
    return !ctx.titles.has(normaliseTitle(p.target));
  }
  return false;
}

//! clean strips the decoration PLANS/07 phase D names: refs, comments,
//  `{{efn|…}}`, `<br />`, and every other template except `{{nowrap|X}}`,
//  which is unwrapped because it wraps the operator name itself.
function clean(s) {
  let t = stripRefs(stripComments(s));
  t = t.replace(/<br\s*\/?>/gi, ' ');
  t = t.replace(/<\/?(?:small|span|div|sup|b|i|u)\b[^<>]*>/gi, '');
  // Unwrap nowrap/nobr, drop everything else. Innermost-first so that a
  // {{efn|…{{cite}}…}} disappears whole.
  for (let guard = 0; guard < 20; guard++) {
    const before = t;
    t = t.replace(/\{\{\s*(?:nowrap|nobold|nobr)\s*\|([^{}]*)\}\}/gi, '$1');
    t = t.replace(/\{\{[^{}]*\}\}/g, '');
    if (t === before) break;
  }
  return t;
}

//! linkParts splits a run of text into an alternating stream of plain text and
//  `[[Target|Display]]` links. Every annotation this parser reads -- the
//  `Seasonal:` labels and the `(begins …)` windows -- lives in the text
//  between links, never inside one, so this split is what makes it safe to use
//  ordinary regexes on the rest.
function linkParts(s) {
  const parts = [];
  let i = 0, text = '';
  while (i < s.length) {
    if (s.startsWith('[[', i)) {
      const end = s.indexOf(']]', i);
      if (end < 0) break;
      const inner = s.slice(i + 2, end);
      const bar = inner.indexOf('|');
      parts.push({ text });
      text = '';
      parts.push({
        target: bar < 0 ? inner : inner.slice(0, bar),
        display: bar < 0 ? inner : inner.slice(bar + 1),
      });
      i = end + 2;
      continue;
    }
    text += s[i];
    i++;
  }
  parts.push({ text });
  return parts;
}

//! normaliseTitle applies the article-title rules a lookup has to match:
//  underscores are spaces, an anchor is not part of the title, a leading colon
//  is not either, and the first letter is always capitalised by MediaWiki.
function normaliseTitle(t) {
  let s = String(t).replace(/&nbsp;/g, ' ').replace(/_/g, ' ').trim();
  s = s.replace(/^:/, '').split('#')[0].trim();
  s = s.replace(/\s+/g, ' ');
  if (!s) return s;
  return s[0].toUpperCase() + s.slice(1);
}

// ---------------------------------------------------------------------------
// seasons and windows

// A bolded run label splits a destinations cell. Only these are understood;
// anything else bolded-and-colonned reaches the rejects rather than being
// guessed at, which is what keeps the enumeration from rotting.
function classifyLabel(raw) {
  const l = raw.toLowerCase().replace(/[^a-z ]/g, ' ').replace(/\s+/g, ' ').trim();
  if (/charter/.test(l)) return { kind: 'charter' };
  if (/^seasonal$/.test(l)) return { kind: 'season', season: 'seasonal' };
  if (/^seasonal\b/.test(l)) return { kind: 'season', season: 'seasonal' };
  if (/^(all year|year round|regular|scheduled)\b/.test(l)) return { kind: 'season', season: 'year_round' };
  return { kind: 'unknown', label: raw };
}

// Bold with the colon inside it -- '''Seasonal:''' -- and bold with the colon
// outside -- '''Seasonal''': -- are both in use, sometimes in the same article.
// The bare form is matched only for the labels this parser already knows, so
// that stray prose ending in a colon does not silently open a run.
const LABEL_RE = /'{2,5}\s*([^'\n:]{1,60}?)\s*(?::\s*'{2,5}|'{2,5}\s*:)|(?:^|[;.\s>])(Seasonal charter|Seasonal|Charter)\s*:/gi;

const MONTHS = {
  january: 1, february: 2, march: 3, april: 4, may: 5, june: 6, july: 7,
  august: 8, september: 9, october: 10, november: 11, december: 12,
  jan: 1, feb: 2, mar: 3, apr: 4, jun: 6, jul: 7, aug: 8, sep: 9, sept: 9, oct: 10, nov: 11, dec: 12,
};

//! isoDate reads the two orders Wikipedia uses -- "18 October 2026" and
//  "October 18, 2026". A date with no day cannot be written as ISO 8601
//  without inventing one, so it is refused rather than rounded.
function isoDate(text) {
  const t = text.replace(/&nbsp;/g, ' ').trim();
  let m = /^(\d{1,2})\s+([A-Za-z]+),?\s+(\d{4})$/.exec(t);
  if (m && MONTHS[m[2].toLowerCase()]) return fmt(m[3], MONTHS[m[2].toLowerCase()], m[1]);
  m = /^([A-Za-z]+)\.?\s+(\d{1,2}),?\s+(\d{4})$/.exec(t);
  if (m && MONTHS[m[1].toLowerCase()]) return fmt(m[3], MONTHS[m[1].toLowerCase()], m[2]);
  m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(t);
  if (m) return t;
  return null;
}
const fmt = (y, mo, d) => `${y}-${String(mo).padStart(2, '0')}-${String(d).padStart(2, '0')}`;

// `[begins 15 March 2027]` is what PLANS/07 describes; `(begins 15 March
// 2027)` is what the articles actually carry, and both appear. `resumes` and
// `starts` are the same claim in other words.
const WINDOW_RE = /[[(]\s*(begins|begin|starts|start|resumes|resume|ends|end|terminates|until|from|suspended)\b([^)\]]*)[)\]]/i;
const WINDOW_RE_G = new RegExp(WINDOW_RE.source, 'gi');

function readWindow(text) {
  const m = WINDOW_RE.exec(text);
  if (!m) return null;
  const verb = m[1].toLowerCase();
  const rest = m[2].trim();
  // "(suspended until 25 October 2026)" is a start date written the other way
  // round, and is worth keeping as one. "(suspended)" on its own is not a date
  // and cannot become a window.
  if (verb === 'suspended') {
    const until = /^until\s+(.+)$/i.exec(rest);
    const when = until && isoDate(until[1].trim());
    return when ? { kind: 'begins', date: when } : { kind: 'suspended' };
  }
  const kind = /^(ends|end|terminates|until)$/.test(verb) ? 'ends' : 'begins';
  const date = isoDate(rest);
  if (!date) return { kind: 'unparsed', raw: m[0] };
  return { kind, date };
}

// ---------------------------------------------------------------------------
// the parse

const REASONS = {
  operator_not_oneworld:
    'The operator string resolves to no carrier in the 4(j) vocabulary. Recorded as distinct '
    + 'operator names with counts rather than one entry per destination: what a reviewer checks '
    + 'here is whether any of these names is really a member or an affiliate under another '
    + 'spelling, and the row-level detail adds nothing to that question.',
  operator_brand_ambiguous:
    'The operator is a brand covering several operating certificates -- "American Eagle" is flown '
    + 'by Envoy, PSA, Piedmont, Republic and SkyWest -- so the table cannot say which one flew. '
    + 'PLANS/06 phase 2: the operating carrier is unknown, never guessed, and an unknown operating '
    + 'carrier is not a carriers:carrier_code/1, so no fact is emitted.',
  operator_unparsed:
    'The operator cell held no name at all: an empty cell, or nothing left after the refs and '
    + 'templates were stripped.',
  charter_or_cargo:
    'A charter or cargo run. PLANS/06 phase 0 decision 4 excludes both entirely.',
  run_label_unrecognised:
    'A bolded label split the cell into a run this parser does not understand. The destinations '
    + 'after it are refused rather than filed under a guessed season.',
  destination_not_a_link:
    'A destinations cell with no wikilink in it, or text between the links that names a place '
    + 'without linking it. There is no target to resolve, so there is nothing to look up.',
  destination_unresolved:
    'The wikilink target is not in the Wikidata P238 map even after redirect resolution: a city '
    + 'article, a disambiguation page, a red link, or an airport with no IATA code in Wikidata.',
  destination_not_in_airports:
    'The target resolved to an IATA code that data/generated/airports.pl does not carry. That file '
    + 'is built from OurAirports and filtered to scheduled service, and it is the authority on what '
    + 'an airport is here.',
  destination_is_the_article:
    'A row listing the airport whose article it is as one of its own destinations. A self-loop is '
    + 'never a sector.',
  window_date_unparsed:
    'A "begins" or "ends" annotation whose date could not be written as ISO 8601 -- usually a month '
    + 'and a year with no day. Both the window and the current-service fact are withheld: the '
    + 'sector is either not flying yet or about to stop.',
  service_suspended:
    'The article marks the destination suspended. Not currently flyable, and no date to record.',
};

function newRejects() {
  const out = {};
  for (const k of Object.keys(REASONS)) out[k] = [];
  out.unclassified = [];
  return out;
}

//! parseArticle turns one committed section into rows of facts and rejects.
//  Everything it returns is keyed on the article's own IATA code, which is the
//  From of every fact it produces: an `Airlines and destinations` table is a
//  list of where you can go from here.
function parseArticle({ code, title, section }, ctx) {
  const facts = [];
  const windows = [];
  const rejects = [];
  let oneworldRows = 0;

  const reject = (reason, extra) => rejects.push({ airport: code, article: title, ...extra, reason });

  for (const part of passengerParts(section)) {
    // Comments and refs go before anything else looks at the structure: a ref
    // is full of braces and pipes, and a `<!-- -->` sits on the same line as
    // the row that follows it about as often as on its own.
    const text = stripRefs(stripComments(part));
    for (const tpl of destinationTemplates(text)) {
      if (!tpl.body) { reject('operator_unparsed', { detail: 'unbalanced {{Airport destination list}}' }); continue; }
      for (const fields of rowChunks(tpl.body)) {
        let i = 0;
        while (i < fields.length) {
          let destinations = fields[i + 1] === undefined ? '' : fields[i + 1];
          let k = i + 2;
          while (k < fields.length && !looksLikeOperator(fields[k], ctx)) {
            destinations += ' ' + fields[k];
            k++;
          }
          const opText = clean(fields[i]);
          const op = resolveOperator(opText, ctx);
          i = k;
          if (op.kind === 'empty') {
            if (opText.trim() || destinations.trim()) {
              reject('operator_unparsed', { operator: opText.trim().slice(0, 120) });
            }
            continue;
          }
          if (op.kind === 'brand') {
            oneworldRows++;
            reject('operator_brand_ambiguous', { operator: op.name, certificates: op.codes.join('/') });
            continue;
          }
          if (op.kind === 'none') {
            reject('operator_not_oneworld', { operator: op.name });
            continue;
          }
          oneworldRows++;
          readCell(destinations, op.code, code, ctx, facts, windows, reject);
        }
      }
    }
  }
  return { facts, windows, rejects, oneworldRows };
}

//! passengerParts takes the `Passenger` subsection where one exists and skips
//  `Cargo` and `Charter` outright. Where there is no subsection at all the
//  whole section is the passenger table.
function passengerParts(section) {
  const hs = headings(section);
  if (hs.length <= 1) return [section];
  const top = hs[0].level;
  const subs = [];
  for (let i = 1; i < hs.length; i++) {
    if (hs[i].level <= top) break;
    let end = section.length;
    for (let j = i + 1; j < hs.length; j++) if (hs[j].level <= hs[i].level) { end = hs[j].start; break; }
    subs.push({ title: hs[i].title, text: section.slice(hs[i].end, end) });
  }
  if (!subs.length) return [section];
  const passenger = subs.filter((s) => /passenger/i.test(s.title));
  if (passenger.length) return passenger.map((s) => s.text);
  const lead = section.slice(hs[0].end, hs[1].start);
  const rest = subs.filter((s) => !/cargo|freight|charter|former|statistic|traffic|incident/i.test(s.title));
  return [lead, ...rest.map((s) => s.text)];
}

//! resolveOperator maps a cell to a designator. The candidates are the link's
//  display text and its target, in that order and both with any parenthetical
//  qualifier removed: `[[Iberia (airline)|Iberia]]` is named by its display
//  and `[[Cathay Pacific|Cathay Cargo]]` by its target, so both have to be
//  tried. carrier_name/2 and affiliate/3 answer for most of them;
//  carrier_aliases.json holds only what they do not.
function resolveOperator(text, ctx) {
  const parts = linkParts(text);
  const candidates = [];
  for (const p of parts) {
    if (p.target === undefined) continue;
    candidates.push(p.display, p.target, p.target.replace(/\s*\([^()]*\)\s*$/, ''));
  }
  const bare = parts.filter((p) => p.text !== undefined).map((p) => p.text).join(' ')
    .replace(/'{2,5}/g, '').trim();
  if (bare) candidates.push(bare);

  const seen = new Set();
  let name = null;
  for (const raw of candidates) {
    if (raw === undefined || raw === null) continue;
    const c = String(raw).replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
    if (!c || seen.has(c)) continue;
    seen.add(c);
    if (name === null) name = c;
    const key = c.toLowerCase();
    if (ctx.excluded.has(key)) return { kind: 'none', name: c };
    if (ctx.brands.has(key)) return { kind: 'brand', name: c, codes: ctx.brands.get(key) };
    const code = ctx.operators.get(key);
    if (code) return { kind: 'code', code, name: c };
  }
  if (name === null) return { kind: 'empty' };
  return { kind: 'none', name };
}

//! readCell walks one destinations cell. It is a stream of links with text
//  between them, and the text carries everything that modifies the links: a
//  bolded `Seasonal:` opens a run, a `(begins …)` attaches backwards to the
//  destination it follows and nothing else.
function readCell(cellRaw, carrier, from, ctx, facts, windows, reject) {
  const cell = clean(cellRaw);
  const parts = linkParts(cell);
  let season = 'year_round';
  let run = 'ok';
  let pending = null;   // the link waiting to see whether an annotation follows

  const flush = (annotation) => {
    if (!pending) return;
    const { target } = pending;
    pending = null;
    if (run === 'charter') { reject('charter_or_cargo', { carrier, target }); return; }
    if (run === 'unknown') { reject('run_label_unrecognised', { carrier, target, label: runLabel }); return; }
    const to = resolveDestination(target, ctx);
    if (!to.code) { reject(to.reason, { carrier, target, ...(to.detail ? { detail: to.detail } : {}) }); return; }
    if (to.code === from) { reject('destination_is_the_article', { carrier, target }); return; }
    if (annotation) {
      if (annotation.kind === 'suspended') { reject('service_suspended', { carrier, to: to.code, target }); return; }
      if (annotation.kind === 'unparsed') { reject('window_date_unparsed', { carrier, to: to.code, detail: annotation.raw }); return; }
      windows.push({ carrier, from, to: to.code, kind: annotation.kind, date: annotation.date });
      return;
    }
    facts.push({ carrier, from, to: to.code, season });
  };

  let runLabel = null;
  let residue = '';
  for (const part of parts) {
    if (part.target !== undefined) { flush(null); pending = part; continue; }
    const text = part.text || '';
    // Only the fragment before the first separator can annotate the link just
    // read; past a comma or a line break the text belongs to what comes next.
    const cut = text.search(/[,;\n]/);
    const head = cut < 0 ? text : text.slice(0, cut);
    const tail = cut < 0 ? '' : text.slice(cut);
    const window = readWindow(head);
    flush(window);

    LABEL_RE.lastIndex = 0;
    let m;
    const scanned = head + tail;
    let left = scanned;
    while ((m = LABEL_RE.exec(scanned))) {
      const label = (m[1] || m[2] || '').trim();
      if (!label) continue;
      left = left.replace(m[0], ' ');
      const c = classifyLabel(label);
      if (c.kind === 'charter') { run = 'charter'; }
      else if (c.kind === 'season') { run = 'ok'; season = c.season; }
      else { run = 'unknown'; runLabel = label; }
    }
    // Whatever is left once the links, the run labels and the annotations are
    // accounted for. A destinations cell is a list of wikilinks by convention,
    // so prose here means a place named without linking it -- there is nothing
    // to resolve, and guessing from the words is exactly what PLANS/07 refuses.
    residue += ' ' + left;
  }
  flush(null);
  const rest = residue.replace(WINDOW_RE_G, ' ').replace(/[\s,;.:|()[\]'"*&/–—-]+/g, ' ').trim();
  if (/[A-Za-zÀ-ɏ]{3,}/.test(rest)) {
    reject('destination_not_a_link', { carrier, detail: rest.slice(0, 160) });
  }
}

function resolveDestination(target, ctx) {
  const t = normaliseTitle(target);
  if (!t) return { reason: 'destination_not_a_link' };
  if (/^(file|image|category|wikt|s|w):/i.test(t)) return { reason: 'destination_not_a_link' };
  let code = ctx.titles.get(t);
  if (!code) {
    const via = ctx.redirects.get(t);
    if (via) code = ctx.titles.get(normaliseTitle(via));
  }
  if (!code) return { reason: 'destination_unresolved' };
  if (!ctx.airports.has(code)) return { reason: 'destination_not_in_airports', detail: code };
  return { code };
}

// ---------------------------------------------------------------------------
// emit

function emit(articles, ctx, manifest) {
  const facts = [];
  const windows = [];
  const rejects = newRejects();
  const operatorCounts = new Map();
  let contributing = 0;

  for (const a of articles) {
    const r = parseArticle(a, ctx);
    if (r.facts.length || r.windows.length) contributing++;
    facts.push(...r.facts);
    windows.push(...r.windows);
    for (const rj of r.rejects) {
      const { reason, ...rest } = rj;
      if (reason === 'operator_not_oneworld') {
        const k = rest.operator || '(none)';
        operatorCounts.set(k, (operatorCounts.get(k) || 0) + 1);
        continue;
      }
      (rejects[reason] || rejects.unclassified).push({ reason, ...rest });
    }
  }

  // --- reconcile ---------------------------------------------------------
  //
  // A pair with a window is not a current edge (PLANS/06 phase 0 decision 3),
  // and the suite asserts the two sets do not overlap. A pair seen with two
  // different seasons is `unknown` rather than either: collapsing it would be
  // choosing, and decision 2 exists precisely so that "not known" has somewhere
  // to go.
  const windowed = new Set();
  const windowRows = new Map();
  for (const w of windows) {
    windowed.add(`${w.carrier}\0${w.from}\0${w.to}`);
    windowRows.set(`${w.carrier}\0${w.from}\0${w.to}\0${w.kind}\0${w.date}`, w);
  }

  const seasons = new Map();
  for (const f of facts) {
    const key = `${f.carrier}\0${f.from}\0${f.to}`;
    if (windowed.has(key)) continue;
    const prev = seasons.get(key);
    if (prev === undefined) seasons.set(key, f.season);
    else if (prev !== f.season) seasons.set(key, 'unknown');
  }

  const serviceRows = [...seasons.entries()]
    .map(([k, season]) => { const [c, f, t] = k.split('\0'); return { carrier: c, from: f, to: t, season }; })
    .sort(cmp);
  const windowOut = [...windowRows.values()].sort((a, b) => cmp(a, b) || a.kind.localeCompare(b.kind) || a.date.localeCompare(b.date));

  // --- the rejects file --------------------------------------------------
  const rejectDoc = {
    _comment:
      'Every row prolog/tools/build_services.mjs refused, grouped by an enumerated reason with a '
      + 'count. A reviewed artifact rather than a log: "every entry has been read by a human" does '
      + 'not survive a few thousand rows, but every reason class does, and the run aborts if '
      + 'anything reaches the unclassified bucket. Rebuilt by `npm run services`.',
    generated: manifest.snapshot,
    totals: {},
    reasons: {},
  };
  const unclassified = rejects.unclassified.length;
  for (const [reason, entries] of Object.entries(rejects)) {
    if (reason === 'unclassified' && !entries.length) continue;
    if (reason === 'operator_not_oneworld') continue;
    if (!entries.length) { rejectDoc.reasons[reason] = { why: REASONS[reason], count: 0, entries: [] }; continue; }
    const sorted = entries
      .map(({ reason: _r, ...rest }) => rest)
      .sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b)));
    rejectDoc.totals[reason] = sorted.length;
    rejectDoc.reasons[reason] = {
      why: REASONS[reason] || 'UNCLASSIFIED -- the run should have aborted.',
      count: sorted.length,
      entries: sorted.length > 400 ? sorted.slice(0, 400) : sorted,
      ...(sorted.length > 400 ? { entriesShown: 400 } : {}),
    };
  }
  const ops = [...operatorCounts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
  rejectDoc.totals.operator_not_oneworld = ops.reduce((n, [, c]) => n + c, 0);
  rejectDoc.reasons.operator_not_oneworld = {
    why: REASONS.operator_not_oneworld,
    count: rejectDoc.totals.operator_not_oneworld,
    distinctOperators: ops.length,
    operators: Object.fromEntries(ops),
  };
  // Reorder totals so the file reads the same way every run.
  rejectDoc.totals = Object.fromEntries(Object.entries(rejectDoc.totals).sort((a, b) => a[0].localeCompare(b[0])));
  rejectDoc.reasons = Object.fromEntries(Object.entries(rejectDoc.reasons).sort((a, b) => a[0].localeCompare(b[0])));

  fs.writeFileSync(OUT_REJECTS, JSON.stringify(rejectDoc, null, 2) + '\n');

  if (unclassified) {
    throw new Error(`${unclassified} rejects reached the unclassified bucket; see ${OUT_REJECTS}`);
  }
  if (!serviceRows.length) {
    throw new Error('no service/4 facts were produced; refusing to write a table src/network.pl cannot load');
  }

  fs.writeFileSync(OUT_PL, servicesPl(serviceRows, windowOut, manifest, contributing));
  return { serviceRows, windowOut, rejectDoc, contributing };
}

const cmp = (a, b) =>
  a.carrier.localeCompare(b.carrier) || a.from.localeCompare(b.from) || a.to.localeCompare(b.to);

function servicesPl(rows, windows, manifest, contributing) {
  const head = `% Generated by prolog/tools/build_services.mjs -- do not edit by hand.
%
%   npm run services              % re-emit from the committed sections
%   npm run services -- --refresh % re-crawl, then re-emit
%
% Which sectors are flown, and by whom. Read out of the
% "Airlines and destinations" section of ${manifest.articles} English Wikipedia airport
% articles, pinned at ${manifest.revisions} revisions and captured on ${manifest.snapshot} under
% prolog/data/network/sources/. ${contributing} of those articles contributed at least
% one fact below; the rest are kept because they carry a oneworld row this
% generator refused, and refusals are reviewed in
% data/generated/services.rejects.json rather than thrown away.
%
%   service(Carrier, From, To, Season)
%     Carrier -- an IATA designator satisfying carriers:carrier_code/1
%     From/To -- IATA codes present in data/generated/airports.pl
%     Season  -- year_round | seasonal | unknown
%
%   service_window(Carrier, From, To, begins(Date)) -- or ends(Date), ISO 8601.
%
% Lowercase unquoted atoms throughout, matching airport/6 and carriers/1.
% 'BA' and ba are different atoms, so an uppercase table would load cleanly and
% join with nothing.
%
% THE FOUR DECISIONS THIS TABLE IS SHAPED BY (PLANS/06 phase 0)
%
% 1. Edges are directed. LHR's article listing BA->JFK and JFK's listing
%    BA->LHR produce two facts. Genuine one-way scheduled service is rare, so
%    asymmetry is a data-quality signal -- reported by the suite, never
%    silently repaired. Symmetrising would manufacture edges nothing sourced.
%
% 2. \`unknown\` is not \`year_round\`. Seasonal marking upstream is known to be
%    incomplete, and collapsing the two would promote unmarked seasonal service
%    into year-round service. An unmarked run is \`year_round\` because that is
%    what the article asserts; a pair two articles disagree about is
%    \`unknown\`, which is the only honest answer available.
%
% 3. Future and terminated service is recorded but excluded from service/4. A
%    "(begins 15 March 2027)" annotation yields service_window/4 and no
%    service/4 fact: a sector that starts next March cannot be ticketed today,
%    and one that ends in October should not outlive its own table.
%
% 4. Charter and cargo are excluded entirely.
%
% ATTRIBUTION
%
% The route data below is derived from English Wikipedia and is used under the
% Creative Commons Attribution-ShareAlike 4.0 International licence
% (https://creativecommons.org/licenses/by-sa/4.0/). Each contributing
% article, its revision id and the date it was read are recorded in
% prolog/data/network/revisions.json, and the extracted sections themselves are
% committed under prolog/data/network/sources/ so that the derivation can be
% checked. Wikipedia is not the author of this file and does not endorse it.
% The IATA codes joining the two halves come from Wikidata (CC0). See
% web/fonts/NOTICE.md for how this repository handles a licence that has to
% travel with a file.
%
% Article titles are non-ASCII in places and the header above carries none of
% them, but the encoding is declared rather than left to the locale of whoever
% loads the file, exactly as airports.pl does.

:- encoding(utf8).

%! service_manifest(?Key, ?Value) is nondet.
%  The snapshot's stated age and size. Fact counts are deliberately absent:
%  src/network.pl measures those from the loaded table, and a second copy here
%  would be the one that drifts.
service_manifest(snapshot, '${manifest.snapshot}').
service_manifest(articles, ${manifest.articles}).
service_manifest(revisions, ${manifest.revisions}).

%! service(?Carrier, ?From, ?To, ?Season) is nondet.
`;
  const body = rows.map((r) => `service(${r.carrier}, ${r.from}, ${r.to}, ${r.season}).`).join('\n');
  const winHead = `

%! service_window(?Carrier, ?From, ?To, ?When) is nondet.
%  Service the article dates into the future or out of it. Never also a
%  service/4 fact -- see decision 3 above.
`;
  const win = windows.map((w) => `service_window(${w.carrier}, ${w.from}, ${w.to}, ${w.kind}('${w.date}')).`).join('\n');
  return head + body + '\n' + (win ? winHead + win + '\n' : '');
}

// ---------------------------------------------------------------------------
// pinned: read what is committed

function loadPinned() {
  if (!fs.existsSync(REVISIONS_FILE)) {
    throw new Error(`${REVISIONS_FILE} is missing: run \`npm run services -- --refresh\` once to build the corpus`);
  }
  const manifest = JSON.parse(fs.readFileSync(REVISIONS_FILE, 'utf8'));
  const articles = manifest.articles.map((a) => ({
    code: a.code,
    title: a.title,
    section: fs.readFileSync(path.join(SOURCES, a.file), 'utf8'),
  }));
  return { manifest, articles };
}

function context() {
  const airports = readAirports();
  const carriers = readCarriers();
  const wd = JSON.parse(fs.readFileSync(WIKIDATA_FILE, 'utf8'));
  const redirects = fs.existsSync(REDIRECTS_FILE)
    ? JSON.parse(fs.readFileSync(REDIRECTS_FILE, 'utf8')).redirects : {};
  const aliasDoc = fs.existsSync(ALIASES_FILE) ? JSON.parse(fs.readFileSync(ALIASES_FILE, 'utf8')) : {};

  const titles = new Map();
  for (const [t, c] of Object.entries(wd.titles)) titles.set(normaliseTitle(t), c);

  // carrier_name/2 and affiliate/3 first, then the alias delta on top.
  const operators = new Map();
  for (const [name, code] of carriers.names) operators.set(name.toLowerCase(), code);
  for (const [name, code] of Object.entries(aliasDoc.aliases || {})) operators.set(name.toLowerCase(), String(code).toLowerCase());

  for (const [, code] of operators) {
    if (!carriers.codes.has(code)) throw new Error(`carrier_aliases.json maps to ${code}, which is not a carriers:carrier_code/1`);
  }

  const brands = new Map();
  for (const [name, codes] of Object.entries(aliasDoc.brands || {})) {
    for (const c of codes) if (!carriers.codes.has(String(c).toLowerCase())) {
      throw new Error(`carrier_aliases.json brand ${name} names ${c}, which is not a carriers:carrier_code/1`);
    }
    brands.set(name.toLowerCase(), codes.map((c) => String(c).toLowerCase()));
  }
  const excluded = new Set((aliasDoc.excluded || []).map((s) => s.toLowerCase()));

  return {
    airports,
    carriers,
    titles,
    redirects: new Map(Object.entries(redirects).map(([k, v]) => [normaliseTitle(k), v])),
    operators,
    brands,
    excluded,
  };
}

// ---------------------------------------------------------------------------
// refresh

async function refresh() {
  fs.mkdirSync(NETWORK, { recursive: true });
  fs.mkdirSync(SOURCES, { recursive: true });

  await fetchWikidata();

  const airports = readAirports();
  const wd = JSON.parse(fs.readFileSync(WIKIDATA_FILE, 'utf8'));
  const byCode = new Map();
  for (const [title, code] of Object.entries(wd.titles)) {
    if (!airports.has(code)) continue;
    if (!byCode.has(code)) byCode.set(code, []);
    byCode.get(code).push(title);
  }
  let codes = [...byCode.keys()].sort();
  if (ONLY.length) codes = codes.filter((c) => ONLY.includes(c));
  if (LIMIT) codes = codes.slice(0, LIMIT);
  const fetchSet = codes.flatMap((c) => byCode.get(c).slice().sort());
  const unreached = [...airports].filter((c) => !byCode.has(c));
  console.log(`services — fetch set: ${fetchSet.length} articles over ${codes.length} of ${airports.size} airports `
            + `(${unreached.length} airports have no enwiki article carrying P238)`);

  const cacheDir = CACHE ? path.resolve(REPO, CACHE) : null;
  const fetched = await fetchArticles(fetchSet, cacheDir);

  // Pass one: parse everything to find out which articles carry a oneworld row
  // and which link targets need resolving. The redirect map is deliberately
  // emptied first, so that the file written below is complete on its own rather
  // than an increment on whatever a previous run happened to leave behind --
  // otherwise --pinned in a fresh clone resolves fewer targets than the run
  // that produced it did, and the difference shows up as rejects nobody caused.
  const ctx = context();
  ctx.redirects = new Map();
  const candidates = [];
  for (const code of codes) {
    for (const title of byCode.get(code).slice().sort()) {
      const row = fetched.get(title);
      if (!row || row.missing || !row.section) continue;
      candidates.push({ code, title, section: row.section, pageid: row.pageid, revid: row.revid });
    }
  }
  console.log(`services — ${candidates.length} articles carry an "Airlines and destinations" section`);

  const keep = [];
  const unresolved = new Set();
  for (const a of candidates) {
    const r = parseArticle(a, ctx);
    if (!r.oneworldRows) continue;
    keep.push(a);
    for (const rj of r.rejects) if (rj.reason === 'destination_unresolved') unresolved.add(normaliseTitle(rj.target));
  }
  console.log(`services — ${keep.length} articles carry at least one oneworld row; ${unresolved.size} link targets to resolve`);

  // Batch-resolve the unknown targets through redirects=1 before rejecting
  // them. Destination cells link through redirects constantly:
  // [[Accra International Airport]] is a redirect to [[Kotoka International
  // Airport]], and only the latter carries P238.
  const redirects = {};
  const list = [...unresolved].sort();
  for (let i = 0; i < list.length; i += 50) {
    const batch = list.slice(i, i + 50);
    const json = await get(apiUrl({ action: 'query', titles: batch.join('|'), redirects: '1' }), 'application/json');
    const q = json.query || {};
    const norm = new Map((q.normalized || []).map((n) => [n.to, n.from]));
    for (const r of q.redirects || []) redirects[norm.get(r.from) || r.from] = r.to;
    await sleep(120);
  }
  fs.writeFileSync(REDIRECTS_FILE, JSON.stringify({
    _comment:
      'Wikilink targets in the destination cells that the Wikidata P238 map did not know, resolved '
      + 'once through the MediaWiki API with redirects=1 and committed so that --pinned never has to '
      + 'ask again. [[Accra International Airport]] is a redirect to [[Kotoka International Airport]], '
      + 'and only the latter carries the code.',
    source: API,
    fetched: today(),
    redirects: Object.fromEntries(Object.entries(redirects).sort((a, b) => a[0].localeCompare(b[0]))),
  }, null, 2) + '\n');
  console.log(`services — ${Object.keys(redirects).length} of ${list.length} unknown targets were redirects`);

  // Write the sections. One file per article, named for the airport; a second
  // article for the same code (an airport and the air base it grew out of) gets
  // a suffix rather than overwriting the first.
  const seen = new Map();
  const entries = [];
  for (const a of keep) {
    const n = (seen.get(a.code) || 0) + 1;
    seen.set(a.code, n);
    const file = n === 1 ? `${a.code}.wiki` : `${a.code}-${n}.wiki`;
    // Citations are dropped before the section is written, not merely before it
    // is parsed. They are 68% of the captured bytes -- 16.7 MB against 5.4 MB --
    // and stripRefs discards every one of them anyway, so committing them would
    // put eleven megabytes in the tree that no output depends on.
    //
    // The point is the diff, not the disk. This corpus is committed for the same
    // reason data/earn/sources/ is: an upstream change should arrive as something
    // a human reads. A route added at Heathrow is a one-line diff; the same
    // article's citation churn -- access-dates bumped, archive URLs rotated,
    // {{cite web}} reformatted -- is thousands of lines a year that mean nothing
    // here, and would bury the one line that does.
    //
    // Provenance does not depend on these bytes. revisions.json pins the exact
    // revid, so the verbatim text is a fetch away and can be checked against
    // this file whenever someone doubts it. That is the same trade
    // data/earn/sources/ already makes: those captures are transcriptions of
    // published tables, not screenshots of them.
    fs.writeFileSync(path.join(SOURCES, file), stripRefs(a.section));
    entries.push({ code: a.code, title: a.title, pageid: a.pageid, revid: a.revid, file });
  }
  entries.sort((a, b) => a.file.localeCompare(b.file));

  for (const f of fs.readdirSync(SOURCES)) {
    if (f.endsWith('.wiki') && !entries.some((e) => e.file === f)) fs.unlinkSync(path.join(SOURCES, f));
  }

  fs.writeFileSync(REVISIONS_FILE, JSON.stringify({
    _comment:
      'The pin. Every article whose "Airlines and destinations" section is committed under sources/, '
      + 'with the revision it was read at. --pinned parses only these files and opens no socket, so a '
      + 'fresh clone rebuilds services.pl with the network unplugged. Route data (c) its Wikipedia '
      + 'contributors, CC BY-SA 4.0.',
    api: API,
    snapshot: today(),
    licence: 'CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)',
    articles: entries,
  }, null, 2) + '\n');

  console.log(`services — wrote ${entries.length} sections to ${path.relative(REPO, SOURCES)}`);
}

// ---------------------------------------------------------------------------

async function main() {
  if (REFRESH) await refresh();

  const { manifest, articles } = loadPinned();
  const ctx = context();
  const revisions = new Set(manifest.articles.map((a) => a.revid)).size;
  const result = emit(articles, ctx, {
    snapshot: manifest.snapshot,
    articles: manifest.articles.length,
    revisions,
  });

  const perCarrier = new Map();
  for (const r of result.serviceRows) perCarrier.set(r.carrier, (perCarrier.get(r.carrier) || 0) + 1);
  const line = ctx.carriers.eligible.map((c) => `${c} ${perCarrier.get(c) || 0}`).join('  ');

  console.log(`services — ${result.serviceRows.length} service/4 over ${perCarrier.size} carriers, `
            + `${result.windowOut.length} service_window/4, from ${result.contributing} of ${manifest.articles.length} articles`);
  console.log(`services — ${line}`);
  const others = [...perCarrier.keys()].filter((c) => !ctx.carriers.eligible.includes(c)).sort();
  if (others.length) console.log(`services — affiliates and exceptions: ${others.map((c) => `${c} ${perCarrier.get(c)}`).join('  ')}`);
  console.log(`services — rejects: ${Object.entries(result.rejectDoc.totals).map(([k, v]) => `${k} ${v}`).join(', ')}`);
}

main().catch((e) => { console.error(`services — ${e.message}`); process.exit(1); });
