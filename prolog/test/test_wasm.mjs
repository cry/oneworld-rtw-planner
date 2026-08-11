// test_wasm.mjs -- the browser build answers what the native one answers.
//
//   npm run test:wasm
//
// The page runs a second Prolog: SWI compiled to WebAssembly, at a different
// version from the one the container runs. Everything else in the suite checks
// what the rules mean; this checks that they mean it in both engines, which is
// the one property no plunit test can see.
//
// Both sides are driven through rtw_call/4, so the comparison covers the whole
// path a browser takes -- JSON in, itinerary, annotation, every rule, JSON out --
// rather than a verdict alone. A report is a few thousand characters of message
// prose, ordering and evidence, and comparing all of it means a rule whose
// wording or evidence differs between engines fails here rather than being
// noticed by a reader months later.
//
// The comparison is *structural*, not textual, and that distinction is the whole
// reason this file has a diff routine in it. SWI moved JSON out of the HTTP
// package at version 10: on 9.x wasm.pl falls back to library(http/json), which
// puts a space after a comma where library(json) does not. Comparing the text
// therefore asserts a property of whichever pretty-printer happened to be
// present, and CI -- where apt supplies 9.x -- reported all 54 fixtures as
// differing when not one of them meant anything different. Whitespace between
// JSON pairs is not a fact about the fare, so it is parsed away before anything
// is compared. Everything that does carry meaning survives: array order, every
// message, every piece of evidence, and the presence or absence of every key.
//
// It is the counterpart of the HTTP round-trip test in test_json.pl: same
// purpose, different second renderer.

import SWIPL from 'swipl-wasm/dist/swipl/swipl-bundle-no-data.js';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..', '..');
const FIXTURES = path.join(HERE, 'fixtures');
const IMAGE = path.join(REPO, 'web', 'rtw.pvm');

// One line per fixture: the name, a tab, and the reply. width(0) in rtw_call/4
// keeps a reply on one line, which is what makes a line-oriented comparison
// safe -- some of these messages are long enough that atom_json_dict would
// otherwise wrap them.
const BASELINE_GOAL = `
    forall(( member(D, ['${FIXTURES}/']), atom_concat(D, '*.json', P),
             expand_file_name(P, Fs), member(F, Fs) ),
           ( setup_call_cleanup(open(F, read, S),
                                read_string(S, _, Text), close(S)),
             rtw_call(validate, Text, _, Out),
             file_base_name(F, Base),
             format("~w\\t~w~n", [Base, Out]) ))`;

function fail(message) {
  console.error(`test:wasm — ${message}`);
  process.exit(1);
}

// The first place two replies disagree, as a path into the report. Reports run to
// a few thousand characters and are identical for most of their length, so the
// earlier version of this printed 300 characters of agreement and left the reader
// to find the difference by eye. A path and the two values is what is actually
// wanted: `violations[0].message` says which rule to go and read.
function firstDifference(a, b, path = '') {
  const here = path || '(root)';
  if (a === null || b === null || typeof a !== 'object' || typeof b !== 'object') {
    return a === b ? null : { path: here, native: a, wasm: b };
  }
  if (Array.isArray(a) !== Array.isArray(b)) {
    return { path: here, native: typeName(a), wasm: typeName(b) };
  }
  if (Array.isArray(a)) {
    if (a.length !== b.length) {
      return { path: `${here}.length`, native: a.length, wasm: b.length };
    }
    for (let i = 0; i < a.length; i++) {
      const found = firstDifference(a[i], b[i], `${path}[${i}]`);
      if (found) return found;
    }
    return null;
  }
  // Key order in an object carries no meaning in JSON, and Prolog dicts are held
  // sorted anyway, so only the set of keys and their values are compared.
  const keys = [...new Set([...Object.keys(a), ...Object.keys(b)])].sort();
  for (const key of keys) {
    if (!(key in a) || !(key in b)) {
      return { path: `${path ? `${path}.` : ''}${key}`,
               native: key in a ? a[key] : '(absent)',
               wasm: key in b ? b[key] : '(absent)' };
    }
    const found = firstDifference(a[key], b[key], `${path ? `${path}.` : ''}${key}`);
    if (found) return found;
  }
  return null;
}

function typeName(value) {
  return Array.isArray(value) ? 'array' : value === null ? 'null' : typeof value;
}

function show(value) {
  const text = typeof value === 'string' ? value : JSON.stringify(value);
  return String(text).length > 200 ? `${String(text).slice(0, 200)}…` : String(text);
}

if (!fs.existsSync(IMAGE)) fail('web/rtw.pvm is missing; run `npm run wasm` first.');

let baselineText;
try {
  baselineText = execFileSync('swipl',
                              ['-q', '-g', BASELINE_GOAL, '-t', 'halt',
                               path.join(REPO, 'prolog', 'wasm.pl')],
                              { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
} catch (error) {
  fail(`could not run native swipl for the baseline: ${error.message}`);
}

const native = new Map(
  baselineText.trim().split('\n').map((line) => {
    const tab = line.indexOf('\t');
    return [line.slice(0, tab), line.slice(tab + 1)];
  }),
);

const Module = await SWIPL({
  arguments: ['-q', '-x', 'image.pvm'],
  preRun: [(m) => m.FS.writeFile('image.pvm', fs.readFileSync(IMAGE))],
});

const names = fs.readdirSync(FIXTURES).filter((f) => f.endsWith('.json')).sort();
if (names.length !== native.size) {
  fail(`native run covered ${native.size} fixtures but ${names.length} are on disk`);
}

const differing = [];
for (const name of names) {
  const answer = Module.prolog
    .query('rtw_call(validate, In, Status, Out)',
           { In: fs.readFileSync(path.join(FIXTURES, name), 'utf8') })
    .once();
  if (!answer) {
    differing.push([name, { path: '(reply)', native: 'a report', wasm: 'the query failed' }]);
    continue;
  }
  let mine, theirs;
  try {
    theirs = JSON.parse(native.get(name));
    mine = JSON.parse(answer.Out);
  } catch (error) {
    differing.push([name, { path: '(json)', native: 'parseable', wasm: error.message }]);
    continue;
  }
  const found = firstDifference(theirs, mine);
  if (found) differing.push([name, found]);
}

if (differing.length) {
  console.error(`test:wasm — ${differing.length} of ${names.length} fixtures differ:\n`);
  for (const [name, diff] of differing) {
    console.error(`  ${name} — ${diff.path}`);
    console.error(`    native: ${show(diff.native)}`);
    console.error(`    wasm:   ${show(diff.wasm)}\n`);
  }
  process.exit(1);
}

// SWI reports its version as one integer: 100110 is 10.1.10.
function swiVersion(n) {
  return `${Math.floor(n / 10000)}.${Math.floor(n / 100) % 100}.${n % 100}`;
}

const wasmVersion = swiVersion(Module.prolog.query('current_prolog_flag(version, V)').once().V);
const nativeVersion = swiVersion(Number(
  execFileSync('swipl', ['-q', '-g', 'current_prolog_flag(version, V), write(V)', '-t', 'halt'],
              { encoding: 'utf8' }).trim()));

console.log(`test:wasm — ${names.length} fixtures identical ` +
            `(wasm SWI ${wasmVersion} against native SWI ${nativeVersion})`);
