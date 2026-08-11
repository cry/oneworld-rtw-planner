# The validator in the browser

## The problem

Running the validator meant running a container. The page in `web/` was a client: it posted an
itinerary to `/api/validate` and rendered what came back. That is a reasonable shape, but it makes
the cheapest possible thing — showing someone whether their routing works — depend on a service
somebody has to host, watch and pay for.

The obvious alternative, reimplementing the rules in JavaScript, is the one thing this repository
exists not to do. The rules are subtle enough that the argument for Prolog is the whole design, and a
second implementation would be the one with no tests behind it and no citations in its messages.

## What was built

SWI-Prolog compiles to WebAssembly. So the same `.pl` files the container runs are compiled into an
image the browser boots, and the page validates locally with no server behind it. `web/` became a
static site that GitHub Pages can publish as it stands.

```
web/app.js ──> RTWApi.{validate,routing,ruleset,airports}      web/api.js
                            │  postMessage
                            ▼
                      web/worker.js ──> vendor/swipl-bundle-no-data.js + rtw.pvm
                            │
                            ▼
                 rtw_call(Op, InText, Status, OutText)         prolog/wasm.pl
                            │
                            ▼
              the same load.pl, the same rules, the same io/json_out.pl
```

`prolog/wasm.pl` is the counterpart of `prolog/server.pl`: the same four operations under the same
names, the same error mapping, the same status codes, and no rule logic in either. Both are renderers
of one `report/3` term.

### One backend, not two

The page always uses WebAssembly, including when it is served by the container. The service keeps its
four endpoints for programmatic callers, but the page never calls them.

The alternative — probe for a server, fall back to WebAssembly — was rejected. It buys the container
a faster first load and costs a second code path in the browser, permanently, plus a class of bug
that appears on only one of the two. Being able to say the published site and the container are
running the same thing is worth more than the download.

## What the measurements decided

Three of them, taken before any of this was written.

**The approach was viable at all.** The build uses neither `SharedArrayBuffer` nor pthreads, so it
needs no COOP/COEP headers — and GitHub Pages cannot set them. Had it needed cross-origin isolation,
none of this would have been possible on Pages.

**An image beat shipping the sources.** All 33 files consult in 97 ms, so shipping them was viable;
but `qsave_program` produces a 416 KB image that boots in ~50 ms and, because it carries the Prolog
library with it, makes the stock `swipl-web.data` unnecessary. The pair is ~1.3 MB gzipped against
~2.0 MB for sources plus the standard library.

**`server.pl`'s asset table had to change.** It held each file as a code list, which costs about
seventy-five times the file size: reading the 2.5 MB engine that way peaked at 194 MB of RSS, against
19 MB as a string. The page cannot be served without that engine, so the table now holds strings.
Binary round-trips exactly — the suite already asserted a font arrives byte for byte, and still does.

## What the WebAssembly build constrains

**A saved image has no autoloading.** Only what was compiled in exists. A goal composed in the
browser cannot reach library predicates — even `member/2` raises an existence error. Hence
`rtw_call/4` as the single entry point: the browser names an operation, never a goal. The constraint
enforces a boundary worth having anyway, and it is why every library `wasm.pl` needs is imported at
build time, where a mistake fails the build rather than the first request.

**`library(http/json)` is absent** — the HTTP package is not in the build. `library(json)` is, and
carries the same predicates. `cli.pl` already chose between them with `exists_source/1`; `wasm.pl`
uses the same conditional rather than inventing a second spelling.

## The drift that had to be guarded

**Two engines.** `swipl-wasm` builds SWI 10.1.10; the container runs 10.0.2; CI's apt supplies 9.x.
No plunit test can see a difference between them, so `prolog/test/test_wasm.mjs` drives every fixture
through `rtw_call/4` on both and compares the *whole reply* — message prose, ordering, evidence — not
the verdict alone. All 54 agree.

That comparison started out textual, and CI caught the mistake on the first run: all 54 fixtures
reported as differing, none of them meaningfully. SWI moved JSON out of the HTTP package at version
10, so on 9.x `wasm.pl` takes its `library(http/json)` fallback — which puts a space after a comma
where `library(json)` does not. Comparing text asserted a property of whichever pretty-printer
happened to be installed. The fix was to parse both replies and compare them field by field, which
keeps everything that carries meaning (array order, messages, evidence, the presence of every key)
and drops the one thing that does not. The failure report improved with it: it now names the first
differing path, such as `checks[9].detail`, instead of printing 300 characters of agreement.

Pinning CI to a 10.x would have hidden this instead of fixing it, and would have stopped CI
exercising the fallback branch at all.

**Stale artifacts.** `web/rtw.pvm` is committed, like `app.css`, `map.js` and `airports.pl`, so that
`docker build` and a fresh clone work offline. The cost is that it is a compiled copy of the rules
that can fall behind them, and unlike a stale stylesheet a stale image looks completely normal while
validating against the wrong rules. `.github/workflows/pages.yml` rebuilds every generated file and
refuses to deploy if the result differs from what was committed.

That gate needed one thing the artifact could not give it. A SWI saved state is a ZIP archive, and a
ZIP records the time it was written, so two builds of identical sources differ in nearly every byte —
which would have failed the check on every run and left the working tree dirty after any build. So
the build is content-addressed instead: it records a digest of its inputs (the Prolog sources and the
`swipl-wasm` version) in `web/rtw.build.json` and does nothing when they already match. The question
becomes "was this built from these sources" rather than "are these bytes what we would produce now",
which is the one actually worth asking.

**One shared refactor.** The prose explaining why an itinerary cannot be written as a routing lived
in `server.pl`. Two front ends now need it, so `no_routing_message/2` and its two helpers moved into
`src/io/route_out.pl`, which is where the notation's limits are already described. Copying them would
have been the beginning of the drift this design is trying to avoid.

## Also changed

* Every path in `index.html` and `app.src.css` is relative. Pages serves a project repository from
  `/<repo>/`, where an absolute `/app.css` 404s; relative paths resolve identically under both.
* `renderError` no longer prints `HTTP <status>`, and the copy about reaching "the service" now
  describes a validator that failed to start. There is no longer an HTTP request to describe.
* `npm run build` covers all four generated files; `npm run wasm` and `npm run test:wasm` are the
  new pieces.

## Not done

* **No offline manifest.** The site works from cache once loaded, but there is no service worker
  making that a promise.
* **The vendored engine is a copy of an npm package.** `web/vendor/swipl-bundle-no-data.js` is 2.5 MB
  of committed third-party JavaScript. It changes only when `swipl-wasm` is bumped, and committing it
  is what keeps the Docker build offline, but it is the largest thing in the repository.
