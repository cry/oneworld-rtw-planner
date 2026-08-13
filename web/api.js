'use strict';

/* The seam between the page and the validator.
 *
 * app.js used to call four HTTP endpoints. It now calls the operations below,
 * which are the same ones, answered by Prolog running in a worker on this
 * machine rather than by Prolog running in a container. Replies keep the shape
 * app.js already handled -- {ok, status, data}, with the same status codes and
 * the same error bodies -- so the page's error handling did not have to be
 * rewritten to suit a new transport.
 *
 * There is one backend, not two. The service still serves /api/validate and the
 * rest for programmatic callers, but the page never calls them: a page that
 * chose between a local and a remote validator would have two code paths to keep
 * in step and a class of bugs that only appear on one of them.
 *
 * Exposed as a global to match map.js. index.html loads plain scripts.
 */

const RTWApi = (() => {
  // Well above the 10 s the service allows itself for the same work. This is a
  // backstop for a query that will not finish, not a performance budget: a
  // sixteen-segment itinerary validates in about a millisecond once the worker
  // is up.
  const CALL_TIMEOUT_MS = 30000;

  let worker = null;
  let nextId = 1;
  const pending = new Map();

  function start() {
    // Resolved against the document, so the page works under a subpath.
    worker = new Worker(new URL('worker.js', document.baseURI));
    worker.onmessage = (event) => {
      const { id, ...reply } = event.data;
      const waiting = pending.get(id);
      if (!waiting) return;
      pending.delete(id);
      clearTimeout(waiting.timer);
      waiting.resolve(reply);
    };
    // An error here is the worker failing to start at all -- a missing file, or
    // a browser that will not run workers from this origin. Every call in flight
    // is waiting on a reply that is no longer coming, so they are all told.
    worker.onerror = (event) => {
      failAll(event.message || 'The validator could not be started.');
    };
  }

  function failAll(message) {
    for (const [id, waiting] of pending) {
      clearTimeout(waiting.timer);
      pending.delete(id);
      waiting.resolve({
        ok: false,
        status: 0,
        data: { error: 'validator_unavailable', message },
      });
    }
  }

  // A Prolog query cannot be interrupted from inside, so the way to stop one is
  // to discard the worker running it. The next call starts a fresh one, which
  // costs the boot again -- about 50 ms plus a cached fetch.
  //
  // The fetched-once replies go with the worker that answered them. They are
  // memoised on the promise rather than on the value, so one that was still in
  // flight when the worker was discarded stays cached as the failure it resolved
  // to -- and the page would then describe the ruleset and the programme list as
  // unavailable for the rest of its life, even though the very next validate()
  // brings a working worker up.
  function restart(message) {
    if (worker) worker.terminate();
    worker = null;
    once.clear();
    failAll(message);
  }

  function call(op, body) {
    if (!worker) start();
    const id = nextId++;
    return new Promise((resolve) => {
      const timer = setTimeout(
        () => restart('The validator did not finish this itinerary in time.'),
        CALL_TIMEOUT_MS,
      );
      pending.set(id, { resolve, timer });
      worker.postMessage({ id, op, body });
    });
  }

  // Neither the ruleset nor the programme list can change within a page load, so
  // each is fetched once and shared. The ruleset doubles as the readiness signal:
  // everything else the page does is gated on it, and by the time it answers the
  // worker has booted the image.
  const once = new Map();
  function cached(op) {
    if (!once.has(op)) once.set(op, call(op, {}));
    return once.get(op);
  }

  return {
    ruleset: () => cached('ruleset'),
    programs: () => cached('programs'),
    ready: () => cached('ruleset').then(() => undefined),
    validate: (itinerary) => call('validate', itinerary),
    routing: (itinerary) => call('routing', itinerary),
    earn: (itinerary) => call('earn', itinerary),
    airports: (q, limit) => call('airports', { q, limit }),
  };
})();
