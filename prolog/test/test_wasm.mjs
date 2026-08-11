// test_wasm.mjs -- the browser build answers what the native one answers.
//
//   npm run test:wasm
//
// The page runs a second Prolog: SWI compiled to WebAssembly, at a different
// version from the one the container runs (10.1.10 against 10.0.2). Everything
// else in the suite checks what the rules mean; this checks that they mean it in
// both engines, which is the one property no plunit test can see.
//
// Both sides are driven through rtw_call/4, so the comparison covers the whole
// path a browser takes -- JSON in, itinerary, annotation, every rule, JSON out --
// rather than a verdict alone. A report is a few thousand characters of message
// prose, ordering and evidence, and comparing them whole means a rule whose
// wording or evidence differs between engines fails here rather than being
// noticed by a reader months later.
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
  if (!answer) { differing.push([name, 'wasm query failed']); continue; }
  if (answer.Out !== native.get(name)) differing.push([name, answer.Out]);
}

if (differing.length) {
  console.error(`test:wasm — ${differing.length} of ${names.length} fixtures differ:\n`);
  for (const [name, got] of differing) {
    console.error(`  ${name}`);
    console.error(`    native: ${String(native.get(name)).slice(0, 300)}`);
    console.error(`    wasm:   ${String(got).slice(0, 300)}\n`);
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
