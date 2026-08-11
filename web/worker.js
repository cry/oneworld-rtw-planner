'use strict';

/* The validator, running in a worker.
 *
 * vendor/swipl-bundle-no-data.js is SWI-Prolog compiled to WebAssembly, and
 * rtw.pvm is this repository's Prolog compiled into an image it can boot from.
 * Both are built by `npm run wasm`. What runs here is the same rules the HTTP
 * service runs -- not a translation of them -- which is the whole reason for
 * going this way round rather than reimplementing the fare in JavaScript.
 *
 * It is a worker rather than main-thread code for two reasons. Compiling ~2.5 MB
 * of WebAssembly blocks whatever thread it happens on, and Prolog queries here
 * are synchronous with no way to interrupt one from inside; a worker can simply
 * be terminated. That is how the page bounds a runaway validation, and it is
 * stricter than the time limit the server applies to the same work.
 *
 * A classic worker, not a module worker: the bundle is a plain script that
 * assigns a global and detects WorkerGlobalScope itself, and importScripts is
 * how it expects to be loaded.
 */

importScripts('./vendor/swipl-bundle-no-data.js');

let prolog = null;

// Paths are relative to this file so the page works under a subpath -- GitHub
// Pages serves a project repository from /<repo>/, not from the root.
async function boot() {
  const image = await fetch(new URL('./rtw.pvm', self.location.href));
  if (!image.ok) throw new Error(`could not fetch rtw.pvm (${image.status})`);
  const bytes = new Uint8Array(await image.arrayBuffer());

  // -x boots from the image instead of loading a library from disk, which is
  // why no swipl-web.data is shipped: the image already contains everything.
  const Module = await SWIPL({
    arguments: ['-q', '-x', 'image.pvm'],
    preRun: [(m) => m.FS.writeFile('image.pvm', bytes)],
  });
  prolog = Module.prolog;
}

const ready = boot();

// Every call goes through rtw_call/4 and names an operation rather than a goal.
// That is not only a boundary worth having: a saved image has no autoloading, so
// a goal composed here could not reach library predicates even if we wanted it
// to. See the note at the top of prolog/wasm.pl.
function call(op, body) {
  const answer = prolog
    .query('rtw_call(Op, In, Status, Out)', { Op: op, In: JSON.stringify(body ?? {}) })
    .once();
  if (!answer || answer.Status === undefined) {
    throw new Error(`rtw_call(${op}, ...) did not answer`);
  }
  return { status: answer.Status, data: JSON.parse(answer.Out) };
}

self.onmessage = async (event) => {
  const { id, op, body } = event.data;
  try {
    await ready;
    const { status, data } = call(op, body);
    // The Prolog side reports a bug in a rule as a 500 carrying the exception
    // term. There is no server-side log to send it to, so the console is where
    // it goes; the page shows the message without it.
    if (status === 500 && data.detail) console.error(`[rtw] ${op}: ${data.detail}`);
    self.postMessage({ id, ok: status < 400, status, data });
  } catch (error) {
    self.postMessage({
      id,
      ok: false,
      status: 0,
      data: { error: 'validator_unavailable', message: error.message },
    });
  }
};
