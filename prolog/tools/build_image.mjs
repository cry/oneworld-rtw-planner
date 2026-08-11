// build_image.mjs -- compile the validator for the browser.
//
//   npm run wasm
//
// Produces the two files web/worker.js needs, plus a stamp, all committed:
//
//   web/rtw.pvm                        the rules, compiled
//   web/vendor/swipl-bundle-no-data.js the Prolog engine
//   web/rtw.build.json                 what the image was built from
//
// This is the only part of the repository that needs npm at build time, and
// nothing needs it at runtime -- the same arrangement as web/app.css and
// web/map.js, and for the same reason: the output is committed so that a clone
// runs, and `docker build` works, without a network.
//
// The stamp exists because a saved state is a ZIP archive, and a ZIP records the
// time it was written. Two builds of identical sources therefore differ in every
// compressed byte, which would make `git diff --exit-code -- web/` -- the check
// that stops a stale image shipping rules that are not the ones in the source
// tree -- fail on every run, and would leave the working tree dirty after any
// build. So the digest of the inputs is recorded instead, and a build whose
// inputs already match does nothing. That makes the whole thing idempotent, and
// moves the staleness question from "are these bytes what we would produce now"
// to "was this built from these sources", which is the question actually worth
// asking. Pass --force to rebuild anyway.
//
// Two swipl-wasm bundles appear below and they are not interchangeable.
// `swipl-bundle.js` carries the standard Prolog library, so it is the one that
// can *compile* an image. `swipl-bundle-no-data.js` does not, because an image
// already contains everything it needs -- which is what makes the pair smaller
// than shipping the library separately: ~1.3 MB over the wire against ~2.0 MB.
// swipl-wasm's own loadImageDefault.js pairs them the same way.

import SWIPL from 'swipl-wasm/dist/swipl/swipl-bundle.js';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PROLOG = path.resolve(HERE, '..');
const REPO = path.resolve(PROLOG, '..');
const WEB = path.join(REPO, 'web');
const VENDOR_SRC = path.join(REPO, 'node_modules', 'swipl-wasm', 'dist', 'swipl',
                             'swipl-bundle-no-data.js');
const IMAGE = path.join(WEB, 'rtw.pvm');
const VENDOR = path.join(WEB, 'vendor', 'swipl-bundle-no-data.js');
const STAMP = path.join(WEB, 'rtw.build.json');

// The test suite and this directory are left out of the image. Neither is
// reachable from wasm.pl, so including them would only add plunit and the
// fixture corpus to every page load.
const SKIP = new Set(['test', 'tools']);

function sources(dir, found = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!SKIP.has(entry.name)) sources(path.join(dir, entry.name), found);
    } else if (entry.name.endsWith('.pl')) {
      found.push(path.join(dir, entry.name));
    }
  }
  return found;
}

function die(message) {
  console.error(`wasm — ${message}`);
  process.exit(1);
}

const files = sources(PROLOG).sort();
const bytes = files.reduce((n, f) => n + fs.statSync(f).size, 0);

// The engine version is part of the digest: the same sources compiled by a
// different swipl-wasm are a different image, and bumping the dependency has to
// count as a change.
const engineVersion = createRequire(import.meta.url)('swipl-wasm/package.json').version;
const digest = (() => {
  const hash = crypto.createHash('sha256');
  hash.update(`swipl-wasm ${engineVersion}\n`);
  for (const file of files) {
    hash.update(`${path.relative(REPO, file)}\n`);
    hash.update(fs.readFileSync(file));
  }
  return hash.digest('hex');
})();

const force = process.argv.includes('--force');
const stamped = fs.existsSync(STAMP)
  ? JSON.parse(fs.readFileSync(STAMP, 'utf8'))
  : null;

if (!force && stamped?.sources === digest && fs.existsSync(IMAGE) && fs.existsSync(VENDOR)) {
  console.log(`wasm — up to date (${files.length} Prolog files, swipl-wasm ${engineVersion})`);
  process.exit(0);
}

console.log(`wasm — ${files.length} Prolog files, ${(bytes / 1024).toFixed(0)} KB`);

// The sources are written into the Emscripten filesystem under the same relative
// paths they have in the repository, so every `use_module` inside them resolves
// exactly as it does natively and no path in the source tree has to know it is
// being compiled for a browser.
const Module = await SWIPL({
  arguments: ['-q', '-f', '/dev/null'],
  preRun: [(m) => {
    for (const file of files) {
      const rel = path.join('prolog', path.relative(PROLOG, file));
      let dir = '';
      for (const part of path.dirname(rel).split(path.sep)) {
        dir = dir ? `${dir}/${part}` : part;
        try { m.FS.mkdir(dir); } catch { /* already there */ }
      }
      m.FS.writeFile(rel, fs.readFileSync(file, 'utf8'));
    }
  }],
});

const consulted = Module.prolog
  .query("catch((consult('prolog/wasm.pl'), R = ok), E, (print_message(error, E), R = error))")
  .once();
if (consulted.R !== 'ok') die('prolog/wasm.pl did not load; see the errors above.');

// A consult that printed warnings still reports ok, so the image is proved by
// using it rather than by reading the build log: a validation that does not come
// back 200 here would otherwise ship as a page that loads and then fails on the
// first itinerary anyone types.
const smoke = Module.prolog.query('rtw_call(validate, In, Status, Out)', {
  In: JSON.stringify({ route: 'LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR',
                       cabin: 'business' }),
}).once();
if (!smoke || smoke.Status !== 200) die(`smoke test returned ${smoke && smoke.Status}: ${smoke && smoke.Out}`);
if (JSON.parse(smoke.Out).verdict !== 'valid') die('smoke test itinerary did not validate.');

// qsave.pl warns `library(shlib): No such file` under WebAssembly. It is looking
// for the loader for foreign libraries, which this build has none of, and the
// image is complete without it.
Module.prolog.query("qsave_program('rtw.pvm', [toplevel(halt), stand_alone(false)])").once();

const image = Module.FS.readFile('rtw.pvm');
fs.mkdirSync(path.dirname(VENDOR), { recursive: true });
fs.writeFileSync(IMAGE, image);
fs.copyFileSync(VENDOR_SRC, VENDOR);
fs.writeFileSync(STAMP,
                 `${JSON.stringify({ sources: digest, swiplWasm: engineVersion }, null, 2)}\n`);

const engine = fs.statSync(VENDOR_SRC).size;
console.log(`wasm — web/rtw.pvm ${(image.length / 1024).toFixed(0)} KB, ` +
            `web/vendor/swipl-bundle-no-data.js ${(engine / 1024).toFixed(0)} KB`);
