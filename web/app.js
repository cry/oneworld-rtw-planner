'use strict';

/* Behaviour for the validator page.
 *
 * Two ways in, one itinerary. The Routing tab sends {route: "..."} and lets the
 * validator parse it; the Segments tab sends {mode, segments: [...]}. Both go
 * through api.js to Prolog compiled to WebAssembly, running in a worker on this
 * machine -- see web/api.js for why there is one backend and not two.
 *
 * The grammar is not implemented here in either direction. Reading a routing is
 * the `validate` operation's job and writing one is `routing`'s, because a copy
 * of the grammar living in the browser would be the one nothing tests. Both
 * directions are Prolog, and the suite asserts that a routing survives the round
 * trip.
 *
 * Every class name below is written out in full rather than assembled from pieces,
 * because Tailwind generates CSS by scanning this file for literal strings.
 */

const EXAMPLES = {
  'Routing — classic LHR round-the-world (valid)': {
    cabin: 'business',
    route: 'LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-CX-BKK-QR-X/DOH-QR-LHR'
  },
  'Routing — every point a transfer (invalid, rule 8)': {
    cabin: 'business',
    route: 'LHR-BA-X/JFK-AA-X/LAX-JL-X/NRT-CX-X/HKG-CX-X/BKK-QR-X/DOH-QR-LHR'
  },
  'Routing — city codes and a surface sector (valid)': {
    cabin: 'business',
    route: 'LON-BA-NYC-AA-X/DFW-AA-LAX-QF-SYD//MEL-QF-X/SIN-BA-LON'
  },
  'Segments — classic LHR round-the-world (valid)': {
    origin: 'LHR', cabin: 'business',
    segments: [
      {type:'flight', from:'LHR', to:'JFK', carrier:'BA', flight:'BA117', dep:'2026-09-01T10:25', arr:'2026-09-01T13:30'},
      {type:'flight', from:'JFK', to:'LAX', carrier:'AA', flight:'AA33',  dep:'2026-09-05T08:00', arr:'2026-09-05T11:15'},
      {type:'flight', from:'LAX', to:'NRT', carrier:'JL', flight:'JL61',  dep:'2026-09-05T13:30', arr:'2026-09-06T17:00'},
      {type:'flight', from:'NRT', to:'HKG', carrier:'CX', flight:'CX521', dep:'2026-09-10T09:00', arr:'2026-09-10T13:00'},
      {type:'flight', from:'HKG', to:'BKK', carrier:'CX', flight:'CX709', dep:'2026-09-14T10:00', arr:'2026-09-14T12:00'},
      {type:'flight', from:'BKK', to:'DOH', carrier:'QR', flight:'QR833', dep:'2026-09-18T02:00', arr:'2026-09-18T05:00'},
      {type:'flight', from:'DOH', to:'LHR', carrier:'QR', flight:'QR3',   dep:'2026-09-18T08:00', arr:'2026-09-18T13:30'}
    ]
  },
  'Segments — same sector twice (invalid, 4(i))': {
    origin: 'LHR', cabin: 'business',
    segments: [
      {type:'flight', from:'LHR', to:'JFK', carrier:'BA', dep:'2026-09-01T10:25', arr:'2026-09-01T13:30'},
      {type:'flight', from:'JFK', to:'LAX', carrier:'AA', dep:'2026-09-05T08:00', arr:'2026-09-05T11:15'},
      {type:'flight', from:'LAX', to:'NRT', carrier:'JL', dep:'2026-09-05T13:30', arr:'2026-09-06T17:00'},
      {type:'flight', from:'NRT', to:'HKG', carrier:'CX', dep:'2026-09-10T09:00', arr:'2026-09-10T13:00'},
      {type:'flight', from:'HKG', to:'NRT', carrier:'CX', dep:'2026-09-12T14:00', arr:'2026-09-12T19:00'},
      {type:'flight', from:'NRT', to:'HKG', carrier:'CX', dep:'2026-09-14T09:00', arr:'2026-09-14T13:00'},
      {type:'flight', from:'HKG', to:'DOH', carrier:'QR', dep:'2026-09-18T02:00', arr:'2026-09-18T05:30'},
      {type:'flight', from:'DOH', to:'LHR', carrier:'QR', dep:'2026-09-18T08:00', arr:'2026-09-18T13:30'}
    ]
  },
  'Segments — doubles back to TC1 (invalid, 4(a)/4(b))': {
    origin: 'LHR', cabin: 'business',
    segments: [
      {type:'flight', from:'LHR', to:'JFK', carrier:'BA', dep:'2026-09-01T10:25', arr:'2026-09-01T13:30'},
      {type:'flight', from:'JFK', to:'LAX', carrier:'AA', dep:'2026-09-05T08:00', arr:'2026-09-05T11:15'},
      {type:'flight', from:'LAX', to:'NRT', carrier:'JL', dep:'2026-09-05T13:30', arr:'2026-09-06T17:00'},
      {type:'flight', from:'NRT', to:'HKG', carrier:'CX', dep:'2026-09-10T09:00', arr:'2026-09-10T13:00'},
      {type:'flight', from:'HKG', to:'BKK', carrier:'CX', dep:'2026-09-14T10:00', arr:'2026-09-14T12:00'},
      {type:'flight', from:'BKK', to:'JFK', carrier:'AA', dep:'2026-09-18T02:00', arr:'2026-09-18T14:00'},
      {type:'flight', from:'JFK', to:'LHR', carrier:'BA', dep:'2026-09-18T19:00', arr:'2026-09-19T07:00'}
    ]
  },
  'Segments — Africa excursion (valid, 4(e))': {
    origin: 'LHR', cabin: 'business',
    segments: [
      {type:'flight', from:'LHR', to:'JFK', carrier:'BA', dep:'2026-09-01T10:25', arr:'2026-09-01T13:30'},
      {type:'flight', from:'JFK', to:'LAX', carrier:'AA', dep:'2026-09-05T08:00', arr:'2026-09-05T11:15'},
      {type:'flight', from:'LAX', to:'NRT', carrier:'JL', dep:'2026-09-05T13:30', arr:'2026-09-06T17:00'},
      {type:'flight', from:'NRT', to:'HKG', carrier:'CX', dep:'2026-09-10T09:00', arr:'2026-09-10T13:00'},
      {type:'flight', from:'HKG', to:'DOH', carrier:'QR', dep:'2026-09-14T02:00', arr:'2026-09-14T05:30'},
      {type:'flight', from:'DOH', to:'NBO', carrier:'QR', dep:'2026-09-14T08:30', arr:'2026-09-14T13:00'},
      {type:'flight', from:'NBO', to:'LHR', carrier:'BA', dep:'2026-09-18T23:30', arr:'2026-09-19T06:00'}
    ]
  },
  'Segments — Sydney origin, surface across the Pacific (valid, 4(g))': {
    origin: 'SYD', cabin: 'economy',
    segments: [
      {type:'flight',  from:'SYD', to:'HKG', carrier:'QF', dep:'2026-09-01T09:20', arr:'2026-09-01T16:10'},
      {type:'flight',  from:'HKG', to:'DOH', carrier:'QR', dep:'2026-09-06T00:20', arr:'2026-09-06T04:05'},
      {type:'flight',  from:'DOH', to:'LHR', carrier:'QR', dep:'2026-09-10T08:00', arr:'2026-09-10T13:30'},
      {type:'flight',  from:'LHR', to:'JFK', carrier:'BA', dep:'2026-09-15T10:25', arr:'2026-09-15T13:30'},
      {type:'flight',  from:'JFK', to:'LAX', carrier:'AA', dep:'2026-09-20T08:00', arr:'2026-09-20T11:15'},
      {type:'surface', from:'LAX', to:'SYD'}
    ]
  },
  'Segments — no times at all (indeterminate)': {
    origin: 'LHR', cabin: 'business',
    segments: [
      {type:'flight', from:'LHR', to:'JFK', carrier:'BA'},
      {type:'flight', from:'JFK', to:'LAX', carrier:'AA'},
      {type:'flight', from:'LAX', to:'NRT', carrier:'JL'},
      {type:'flight', from:'NRT', to:'HKG', carrier:'CX'},
      {type:'flight', from:'HKG', to:'BKK', carrier:'CX'},
      {type:'flight', from:'BKK', to:'DOH', carrier:'QR'},
      {type:'flight', from:'DOH', to:'LHR', carrier:'QR'}
    ]
  }
};

const PAX = {
  'adult':        [{type:'adult'}],
  'adult+child':  [{type:'adult'}, {type:'child',  age: 7}],
  'adult+infant': [{type:'adult'}, {type:'infant', age: 1}],
  'child':        [{type:'child', age: 7}]
};

// Colour is looked up, never interpolated, so every class Tailwind must generate
// appears literally in this file.
const SEV = {
  error:         { noun: 'error',              text: 'text-err',   wash: 'bg-err-wash' },
  warning:       { noun: 'warning',            text: 'text-warn',  wash: 'bg-warn-wash' },
  indeterminate: { noun: 'undecidable check',  text: 'text-indet', wash: 'bg-indet-wash' }
};

const VERDICT = {
  valid:         { text: 'text-ok',    wash: 'bg-ok-wash',    border: 'border-ok' },
  invalid:       { text: 'text-err',   wash: 'bg-err-wash',   border: 'border-err' },
  indeterminate: { text: 'text-indet', wash: 'bg-indet-wash', border: 'border-indet' }
};

const KIND = {
  stopover:      'text-accent font-semibold',
  transfer:      'text-muted',
  indeterminate: 'text-indet font-semibold'
};

// The check register. `pass` is deliberately the quietest of the six: on a valid
// itinerary it is every row, and colouring them all green would leave nothing
// for the two that are not. An absence — n/a, not run — is dimmed rather than
// dressed up as a result.
const OUTCOME = {
  pass:           { word: 'ok',        text: 'text-muted', dim: false },
  fail:           { word: 'failed',    text: 'text-err',   dim: false },
  warning:        { word: 'flagged',   text: 'text-warn',  dim: false },
  indeterminate:  { word: 'undecided', text: 'text-indet', dim: false },
  not_checked:    { word: 'not run',   text: 'text-indet', dim: true },
  not_applicable: { word: 'n/a',       text: 'text-muted', dim: true }
};
const OUTCOME_ORDER = ['fail', 'indeterminate', 'warning', 'pass', 'not_checked', 'not_applicable'];

const $ = id => document.getElementById(id);
const esc = s => String(s).replace(/[&<>"]/g, c =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

let rows = [];
let view = 'routing';

// --- the two views ---------------------------------------------------------

const TABS = { routing: 'tab-routing', segments: 'tab-segments' };

function show(next, { focus = false } = {}) {
  view = next;
  for (const [name, id] of Object.entries(TABS)) {
    const on = name === next;
    const tab = $(id);
    tab.setAttribute('aria-selected', String(on));
    tab.tabIndex = on ? 0 : -1;
    $('panel-' + name).classList.toggle('hidden', !on);
    if (on && focus) tab.focus();
  }
  // The Routing tab is one text field and belongs in a sidebar. The Segments tab
  // is a thirteen-column table and does not, so the form takes half the width
  // while it is open. Toggling a class rather than restyling in place keeps the
  // two widths in the stylesheet where the rest of the layout lives.
  $('layout').classList.toggle('wide-form', next === 'segments');
  // The table is wider than its container and the browser keeps a scroll offset
  // from while the panel was hidden, which lands the reader mid-table with the
  // segment numbers off to the left. It only became visible once the class and
  // fare columns pushed the table over the width, but it was always there.
  if (next === 'segments') {
    const box = document.querySelector('#panel-segments .scroll-x');
    if (box) box.scrollLeft = 0;
  }
  syncUrl();
}

for (const [name, id] of Object.entries(TABS)) {
  $(id).addEventListener('click', () => show(name));
}

// Arrow keys move between tabs, which is what a tablist is expected to do. With
// exactly two of them every arrow is the same toggle.
$('tab-routing').parentElement.addEventListener('keydown', e => {
  const other = view === 'routing' ? 'segments' : 'routing';
  if (['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp'].includes(e.key)) show(other, { focus: true });
  else if (e.key === 'Home') show('routing', { focus: true });
  else if (e.key === 'End') show('segments', { focus: true });
  else return;
  e.preventDefault();
});

document.querySelectorAll('.jump-segments').forEach(b =>
  b.addEventListener('click', () => show('segments', { focus: true })));
document.querySelectorAll('.jump-routing').forEach(b =>
  b.addEventListener('click', () => show('routing', { focus: true })));

// Everything the page knows about earning programmes comes from the validator's
// own programme list -- the names, the currencies, the fare families and the
// provenance. The page names none of them, for the same reason it hardcodes no
// rule: a second copy is the one that goes out of date.
let PROGRAMS = [];
let FAMILIES = [];
// Which programme sections are expanded. Every programme is priced and every
// total is shown whatever this holds -- it decides how much of the detail behind
// a total is on screen, and nothing about what was asked. It used to be a set of
// tickboxes deciding which programmes to price at all, which made the reader
// choose before they had seen anything to choose between.
let opened = null;   // null until the list arrives; then a Set of programme ids
const tiers = new Map();   // programme id -> the member's tier, when they have one

// --- the segment table -----------------------------------------------------

const blank = () =>
  ({ type: 'flight', from: '', to: '', marketing: '', operating: '', flight: '',
     dep: '', arr: '', stop: '', class: '', family: '' });

const timesGiven = () => $('times').value === 'full';

function render() {
  const body = $('segments');
  body.innerHTML = '';
  $('segtable').classList.toggle('hide-when', !timesGiven());
  $('segtable').classList.toggle('hidden', rows.length === 0);
  $('segempty').classList.toggle('hidden', rows.length > 0);
  $('segcount').textContent = rows.length ? `(${rows.length})` : '';

  rows.forEach((r, i) => {
    const tr = document.createElement('tr');
    tr.className = 'border-b border-rule last:border-b-0';
    const surface = r.type === 'surface';
    const last = i === rows.length - 1;
    const off = surface ? 'disabled' : '';
    const opt = (v, label) => `<option value="${v}"${r.stop === v ? ' selected' : ''}>${label}</option>`;
    const fam = (v, label) => `<option value="${v}"${r.family === v ? ' selected' : ''}>${label}</option>`;

    tr.innerHTML = `
      <td class="mono py-1 pr-1 text-[11px] text-muted">${i + 1}</td>
      <td class="py-1 pr-2">
        <select class="field-select w-[5.9rem]" data-f="type" name="type-${i}" aria-label="Segment ${i + 1} type">
          <option value="flight"${surface ? '' : ' selected'}>flight</option>
          <option value="surface"${surface ? ' selected' : ''}>surface</option>
        </select></td>
      <td class="py-1 pr-2">
        <input class="code-input w-[5.4rem]" data-f="from" name="from-${i}" value="${esc(r.from)}"
               list="dl-${i}-from" autocomplete="off" aria-label="Segment ${i + 1} from">
        <datalist id="dl-${i}-from"></datalist></td>
      <td class="py-1 pr-2">
        <input class="code-input w-[5.4rem]" data-f="to" name="to-${i}" value="${esc(r.to)}"
               list="dl-${i}-to" autocomplete="off" aria-label="Segment ${i + 1} to">
        <datalist id="dl-${i}-to"></datalist></td>
      <td class="py-1 pr-2">
        <select class="field-select w-[8.4rem]" data-f="stop" name="stop-${i}" aria-label="Stop at arrival of segment ${i + 1}"
          ${last ? 'disabled title="The last segment ends the journey, so there is no intermediate point to describe."' : ''}>
          ${opt('', last ? '—' : (timesGiven() ? 'from times' : 'not stated'))}
          ${opt('transfer', 'transfer')}
          ${opt('stopover', 'stopover')}
        </select></td>
      <td class="py-1 pr-2">
        <input class="code-input w-[4rem]" data-f="marketing" name="marketing-${i}" value="${esc(r.marketing)}" ${off}
               aria-label="Segment ${i + 1} marketing carrier"></td>
      <td class="py-1 pr-2">
        <input class="code-input w-[4rem]" data-f="operating" name="operating-${i}" value="${esc(r.operating)}" ${off}
               aria-label="Segment ${i + 1} operating carrier"></td>
      <td class="py-1 pr-2">
        <input class="code-input w-[5.6rem]" data-f="flight" name="flight-${i}" value="${esc(r.flight)}" ${off}
               aria-label="Segment ${i + 1} flight number"></td>
      <td class="py-1 pr-2">
        <input class="code-input w-[2.9rem]" data-f="class" name="class-${i}" value="${esc(r.class)}" ${off}
               maxlength="1" aria-label="Segment ${i + 1} booking class"></td>
      <td class="c-fare py-1 pr-2">
        <select class="field-select w-[6.6rem]" data-f="family" name="family-${i}" ${off}
                aria-label="Segment ${i + 1} fare family">
          ${fam('', 'not stated')}${FAMILIES.map(f => fam(f, f)).join('')}
        </select></td>
      <td class="c-when py-1 pr-2">
        <input class="field mono w-[11.5rem] text-[12px]" type="datetime-local" data-f="dep" name="dep-${i}"
               value="${esc(r.dep)}" ${off} aria-label="Segment ${i + 1} departure"></td>
      <td class="c-when py-1 pr-2">
        <input class="field mono w-[11.5rem] text-[12px]" type="datetime-local" data-f="arr" name="arr-${i}"
               value="${esc(r.arr)}" ${off} aria-label="Segment ${i + 1} arrival"></td>
      <td class="py-1">
        <button class="del inline-flex size-6 items-center justify-center rounded-xs text-[15px] leading-none text-muted transition-colors duration-150 hover:bg-err-wash hover:text-err"
                aria-label="Remove segment ${i + 1}" title="Remove">&times;</button></td>`;

    tr.querySelectorAll('[data-f]').forEach(el => {
      el.addEventListener('input', () => {
        rows[i][el.dataset.f] = el.value;
        if (el.dataset.f === 'type') render();
      });
    });
    tr.querySelectorAll('input.code-input').forEach(el => {
      if (el.dataset.f === 'from' || el.dataset.f === 'to') {
        el.addEventListener('input', () => suggest(el, el.getAttribute('list')));
      }
    });
    tr.querySelector('.del').addEventListener('click', () => {
      segmentsDerived = false;
      rows.splice(i, 1);
      render();
    });
    body.appendChild(tr);
  });

  syncUrl();
}

// Debounced per input, not globally: every from/to field on the page shares this
// function, and one timer between them means tabbing to the next airport cancels
// the lookup for the one just typed. The sequence number drops a slow reply that
// lands after a newer one for the same field.
const typeahead = new WeakMap();
function suggest(input, listId) {
  const state = typeahead.get(input) || { timer: null, seq: 0 };
  typeahead.set(input, state);
  clearTimeout(state.timer);
  const q = input.value.trim();
  if (q.length < 2) return;
  const seq = ++state.seq;
  state.timer = setTimeout(async () => {
    try {
      const r = await RTWApi.airports(q, 8);
      if (seq !== state.seq || !r.ok) return;
      $(listId).innerHTML =
        r.data.results.map(a => `<option value="${esc(a.iata)}">${esc(a.city)}, ${esc(a.country)}</option>`).join('');
    } catch (e) { /* typeahead is a convenience; a failure is not worth reporting */ }
  }, 160);
}

// --- request and response --------------------------------------------------

function buildRequest(routeString) {
  const body = { cabin: $('cabin').value, passengers: PAX[$('pax').value] };

  if (routeString) {
    body.route = routeString;
    return body;
  }

  const routing = !timesGiven();
  body.mode = routing ? 'routing' : 'full';
  body.segments = rows.map((r, i) => {
    const s = { type: r.type, from: r.from.trim().toUpperCase(), to: r.to.trim().toUpperCase() };
    if (r.type === 'flight') {
      const mkt = r.marketing.trim(), op = r.operating.trim();
      // `carrier` is the server's shorthand for both fields; sending it only when
      // they genuinely match keeps the 4(j) "operator unknown" warning reachable
      // from the form.
      if (mkt && op && mkt.toUpperCase() === op.toUpperCase()) s.carrier = mkt;
      else { if (mkt) s.marketingCarrier = mkt; if (op) s.operatingCarrier = op; }
      if (r.flight.trim()) s.flight = r.flight.trim();
      if (r.class.trim()) s.bookingClass = r.class.trim().toUpperCase();
      if (r.family) s.fareFamily = r.family;
      // The server refuses times sent in routing mode rather than discarding them
      // behind the user's back, so they are withheld here.
      if (!routing) { if (r.dep) s.dep = r.dep; if (r.arr) s.arr = r.arr; }
    }
    if (r.stop && i < rows.length - 1) s.stop = r.stop;
    return s;
  });

  const origin = $('origin').value.trim();
  if (origin) body.origin = origin.toUpperCase();
  return body;
}

const buttons = () => [$('validate'), $('parse')];

// Cleared first so that re-validating an unchanged itinerary is still a change to
// the live region, and therefore still announced.
function announce(text) {
  $('announce').textContent = '';
  setTimeout(() => { $('announce').textContent = text; }, 60);
}

// A report describes the itinerary that was posted, not the one in the form. Once
// they diverge the report is marked rather than cleared: the previous verdict is
// still worth reading, it just is not an answer about what is on screen now.
let reported = false;

function markStale() {
  if (reported) $('stale').classList.remove('hidden');
}

function markFresh() {
  reported = true;
  $('stale').classList.add('hidden');
}

// A class or a fare family is authored data on a row that may still be derived:
// the routing regenerates every other cell exactly, and it has no notation for
// either of these. So editing one leaves the rows derived and the link readable,
// and the two values ride along in `b` and `f` instead of dragging the whole
// table into `s` as two kilobytes of base64.
const AUTHORED_ELSEWHERE = new Set(['class', 'family']);

for (const ev of ['input', 'change']) {
  document.getElementById('itinerary-heading').parentElement.addEventListener(ev, e => {
    if (e.target.closest('#panel-segments') && !AUTHORED_ELSEWHERE.has(e.target.dataset.f)) {
      segmentsDerived = false;
    }
    markStale();
    syncUrl();
  });
}

async function validate(routeString) {
  if (!routeString && rows.length === 0) {
    show('segments');
    return;
  }
  const body = buildRequest(routeString);
  buttons().forEach(b => { b.disabled = true; });
  $('status').textContent = 'validating…';
  try {
    const res = await RTWApi.validate(body);
    if (!res.ok) renderError(res.data, body);
    else {
      // A routing that parsed becomes rows in the Segments tab, using the
      // validator's own reading of it, so it can be refined without retyping.
      if (routeString) {
        adoptSegments(res.data.annotations);
        // A link may have carried classes for a routing whose rows only exist
        // now that it has been parsed.
        if (pendingClasses || pendingFamilies) { applyPositional(); render(); }
      }
      renderReport(res.data, body);
      // Earning is asked separately. It runs no fare rules, so it is answered
      // even when the verdict is invalid -- being unable to sell a ticket does
      // not stop it earning.
      //
      // Always from the rows, never from the routing string, even when the
      // routing is what was validated: a routing has no notation for a booking
      // class, and the rows adopted from it are the validator's own reading of
      // the same journey with the classes attached.
      await earn(rows.length ? buildRequest() : body);
    }
  } catch (e) {
    $('report').innerHTML = `
      <div class="p-4">
        <p class="verdict-word text-err">Unavailable</p>
        <p class="mt-1 text-[13px] text-muted">The validator did not answer. ${esc(e.message)}</p>
      </div>`;
  } finally {
    buttons().forEach(b => { b.disabled = false; });
    $('status').textContent = '';
  }
}

function renderError(data, body) {
  markFresh();
  $('context-panel').classList.add('hidden');
  $('context').innerHTML = '';
  announce(`Refused: ${data.message || data.error || 'error'}`);
  $('report').innerHTML = `
    <div class="settle">
      <div class="border-b border-rule bg-err-wash p-4">
        <p class="verdict-word text-err">${esc(String(data.error || 'error').replace(/_/g, ' '))}</p>
      </div>
      <p class="max-w-[68ch] p-4 text-[13.5px]">${esc(data.message || '')}</p>
      ${disclosure('Itinerary sent', JSON.stringify(body, null, 2))}
    </div>`;
}

function tally(violations) {
  return ['error', 'indeterminate', 'warning'].map(sev => {
    const n = violations.filter(v => v.severity === sev).length;
    return n ? `${n} ${SEV[sev].noun}${n === 1 ? '' : 's'}` : null;
  }).filter(Boolean).join(' · ');
}

function renderReport(data, body) {
  const v = data.violations || [];
  const fare = data.fare || {};
  const ann = data.annotations || {};
  const nc = data.notChecked || [];
  const checks = data.checks || [];
  const look = VERDICT[data.verdict] || VERDICT.indeterminate;
  // The one place the clean outcome is written, now that it is not also said
  // below the verdict. A live region should read out what the page shows, so
  // both take the same string.
  const counts = tally(v) || 'Every rule this input can answer is satisfied.';

  markFresh();
  announce(`${data.verdict}. ${counts}` +
           (nc.length ? ` ${nc.length} rule${nc.length === 1 ? '' : 's'} not checked.` : '') +
           (checks.length ? ` ${checks.length} rules evaluated.` : ''));

  $('report').innerHTML = `
    <div class="settle">
      <div class="border-b border-rule ${look.wash} p-4">
        <p class="verdict-word ${look.text}">${esc(data.verdict)}</p>
        <p class="mt-1.5 text-[12.5px] ${v.length ? look.text : 'text-muted'}">${esc(counts)}</p>
      </div>

      ${fareBlock(fare, ann)}
      ${violationList(v)}
      ${mapBlock(ann)}
      ${checkList(checks, v)}

      <div class="border-t border-rule">
        ${disclosure('Itinerary sent', JSON.stringify(body, null, 2))}
        ${disclosure('Full response', JSON.stringify(data, null, 2))}
      </div>
    </div>`;

  // How each point was classified, and the map, in their own panel so they can
  // sit beside the verdict rather than under it.
  const context = connections(ann);
  $('context').innerHTML = context;
  $('context-panel').classList.toggle('hidden', !context);

  drawMap(ann);
}

// Every registered programme, every time. Asking is cheap -- the validator is in
// this tab -- and a total the reader did not ask for is the only way they find
// out the ticket was worth crediting somewhere they had not thought of, which is
// the question having more than one programme is for.
async function earn(body) {
  const asked = { ...body };
  if (tiers.size) {
    asked.members = Object.fromEntries([...tiers].map(([id, tier]) => [id, { tier }]));
  }
  try {
    const res = await RTWApi.earn(asked);
    if (res.ok) renderEarn(res.data);
    else earnUnavailable(res.data.message || 'This itinerary could not be priced.');
  } catch (e) {
    earnUnavailable(`The validator did not answer. ${e.message}`);
  }
}

// --- earning ---------------------------------------------------------------

// A number the reader is meant to be able to check, so every one of them says
// which row it came from. Four shapes, and none of the three that is not a
// number may be shown as one: a range is two rates the input could not choose
// between, `no` is a rate the table publishes as nothing, and an unknown is a
// rate nobody stated. A 0 would misreport all three, and differently.
function amount(a, currencies, program) {
  const name = (currencies.find(c => c.key === a.currency) || {}).name || a.currency;
  if (a.known === 'range') return `${num(a.low)}–${num(a.high)} ${esc(name)}`;
  if (a.known === 'published_as_none') return `no ${esc(name)}`;
  if (a.known !== 'known') return `? ${esc(name)}`;
  // A figure with a status bonus in it shows the bonus. The base rate is what
  // the published table says and the bonus is what the member's card adds --
  // two facts from two sources, and a reader checking either needs both.
  if (a.bonus > 0) {
    return `${num(a.value)} ${esc(name)} <span class="text-muted">(${num(a.base)} + ${num(a.bonus)} ${esc(tierName(program, a.tier))})</span>`;
  }
  return `${num(a.value)} ${esc(name)}`;
}

function tierName(program, key) {
  const p = PROGRAMS.find(x => x.id === (program || {}).id);
  const t = ((p || {}).tiers || []).find(x => x.key === key);
  return t ? t.name : key;
}

const num = (n) => Number(n).toLocaleString('en-US');

function total(t, currencies) {
  const name = (currencies.find(c => c.key === t.currency) || {}).name || t.currency;
  // Nothing resolved at all. "0+" is arithmetically true and reads as a figure,
  // which is the one thing this total must not do when no sector was priced.
  if (t.lowerBound && t.high === 0) {
    return `<span class="text-muted">no ${esc(name)} priced</span>
            <span class="text-muted">(${t.unpricedSegments} ${t.unpricedSegments === 1 ? 'sector' : 'sectors'})</span>`;
  }
  const figure = t.amount === null ? `${num(t.low)}–${num(t.high)}` : num(t.amount);
  // The lower bound is said in the same breath as the number. A footnote would
  // let the total be read off the line above it, which is the whole failure this
  // is here to prevent.
  return t.lowerBound
    ? `<span class="mono font-semibold">${figure}+</span> ${esc(name)}
       <span class="text-muted">(${t.unpricedSegments} unpriced)</span>`
    : `<span class="mono font-semibold">${figure}</span> ${esc(name)}`;
}

const EARN_OUTCOME = {
  ok: { word: 'ok', cls: 'text-muted' },
  indeterminate: { word: 'undecided', cls: 'text-warn' },
  not_applicable: { word: 'n/a', cls: 'text-muted' },
};

// A reason that applies to six sectors is one fact, not six. Repeating it once
// per row pushed the priced sectors -- the ones a reader came for -- off the
// bottom of a panel filled with the same sentence, and made a journey where
// nothing could be priced look like six different problems. Sectors that could
// not be priced are grouped by the reason they could not, in the order the
// reason first appears, and the priced ones keep their own rows.
function earnGroups(segments) {
  const byReason = new Map();
  const out = [];
  for (const r of segments) {
    if (r.outcome === 'ok' || !r.reason) { out.push({ rows: [r] }); continue; }
    const key = `${r.outcome}\u0000${r.reason}`;
    const seen = byReason.get(key);
    if (seen) { seen.rows.push(r); continue; }
    const group = { rows: [r], reason: r.reason, outcome: r.outcome };
    byReason.set(key, group);
    out.push(group);
  }
  return out;
}

// Which sentences in this register would be printed more than once. Both of the
// prose fields are card-level facts wearing sector-level clothes: the bucket
// basis is read off the fare, which is one fare for the whole ticket, so it says
// the same thing on every priced row, and an assumption drawn from it repeats
// with it. Six copies of one sentence is not six facts, and it crowds out the
// figures a reader came for. Anything printed twice is printed once under the
// table instead, numbered in the order it first appears.
//
// Only what is actually rendered is counted. Sectors that could not be priced
// are already grouped by their reason, and a group prints its leader's prose
// once however many rows it holds; counting the segments behind it would number
// a sentence that appears on screen exactly once.
function earnFootnotes(groups) {
  const order = [], seen = new Map();
  for (const g of groups) {
    for (const text of [g.rows[0].bucketBasis, g.rows[0].assumption]) {
      if (!text) continue;
      if (!seen.has(text)) { seen.set(text, 0); order.push(text); }
      seen.set(text, seen.get(text) + 1);
    }
  }
  const notes = new Map();
  for (const text of order) if (seen.get(text) > 1) notes.set(text, notes.size + 1);
  return notes;
}

// The marker is what keeps a hoisted sentence traceable: it sits where the words
// were, against the thing they qualify, so the figure is still one step from its
// reason rather than none. An assumption keeps its warn colour even reduced to a
// digit, because the row still has a caveat on it and must still look like it.
const footMark = (n, cls) => `<sup class="ml-px text-[9px] ${cls}">${n}</sup>`;

function earnRows(p, groups, notes) {
  return `<table class="w-full border-collapse text-[12.5px]">
    <tbody>${groups.map(g => {
      const [r] = g.rows;
      const look = EARN_OUTCOME[r.outcome] || EARN_OUTCOME.indeterminate;
      const told = r.assumption ? notes.get(r.assumption) : undefined;
      const figures = r.amounts.length
        ? r.amounts.map(a => amount(a, p.currencies, p)).join(' · ')
        : `<span class="${look.cls}">${esc(r.reason || look.word)}</span>`;
      // The row it was read off, under the figure it produced. This is the earn
      // register, and it is on by default for the same reason the check register
      // exists: a number nobody can trace is worse than no number.
      const why = r.bucketBasis ? notes.get(r.bucketBasis) : undefined;
      const bucket = `${esc(r.bucket)}${
        !r.bucketBasis ? ''
          : why ? footMark(why, 'text-muted')
          : ` <span class="text-muted">(${esc(r.bucketBasis)})</span>`}`;
      const basis = r.outcome === 'ok'
        ? `${bucket}
           · ${esc(r.routeBasis)} · ${num(r.distanceMiles)} mi${
             r.nearBoundaryMiles ? ` <span class="text-warn">· within 1.5% of the ${num(r.nearBoundaryMiles)}-mile edge</span>` : ''}`
        : '';
      return `<tr class="border-t border-rule align-baseline">
        <td class="mono w-6 py-1 pr-1 text-[11px] text-muted">${g.rows.map(x => x.segment).join('<br>')}</td>
        <td class="mono w-[5.5rem] py-1 pr-2 text-[12px]">${g.rows.map(x => `${esc(x.from)}–${esc(x.to)}`).join('<br>')}</td>
        <td class="py-1">
          <div>${figures}${told ? footMark(told, 'text-warn') : ''}</div>
          ${basis ? `<div class="mt-0.5 text-[11.5px] text-muted">${basis}</div>` : ''}
          ${r.assumption && !told ? `<div class="mt-0.5 text-[11.5px] text-warn">${esc(r.assumption)}</div>` : ''}
        </td>
      </tr>`;
    }).join('')}</tbody></table>`;
}

// One programme, as a section that opens. The name and the totals are the
// summary and are therefore always on screen, whether or not it is open; a
// reader comparing two programmes is comparing exactly those two lines. What
// opening adds is everything that makes a total checkable — the per-segment
// register, the estimate caveat, the tables and their fetch dates — plus the
// one control that changes the figures, which belongs to the programme that
// publishes the tiers and not to a row of settings above the panel.
function earnProgram(p) {
  const detail = p.segments.length;
  const groups = earnGroups(p.segments);
  const notes = earnFootnotes(groups);
  // The tiers come from /api/programs and not from the reply being rendered: an
  // earn report says what a journey earned, and the list of tiers a programme
  // publishes is a fact about the programme.
  const published = (PROGRAMS.find(x => x.id === p.id) || {}).tiers || [];
  const tierPicker = published.length ? `
    <label class="mt-1 flex flex-wrap items-center gap-2 text-[12px] text-muted">
      Membership
      <select class="tier field-select h-6 w-[9rem] py-0 text-[11.5px]" data-prog="${esc(p.id)}"
              aria-label="${esc(p.name)} membership tier">
        <option value="">no status</option>
        ${published.map(t => `<option value="${esc(t.key)}"${tiers.get(p.id) === t.key ? ' selected' : ''}>${esc(t.name)}</option>`).join('')}
      </select>
    </label>` : '';

  return `<details class="group prog border-t border-rule first:border-t-0"
                   data-prog="${esc(p.id)}"${opened && opened.has(p.id) ? ' open' : ''}>
    <summary class="flex cursor-pointer select-none flex-wrap items-baseline justify-between gap-x-4 px-4 py-2.5">
      <span class="text-[13px] font-semibold">
        <span class="mono inline-block w-3 text-muted transition-transform duration-150 group-open:rotate-90">&rsaquo;</span>
        ${esc(p.name)}
      </span>
      <span class="text-[13px]">${p.totals.map(t => total(t, p.currencies)).join(' · ')}</span>
    </summary>
    <div class="px-4 pb-2.5 pl-7">
      ${tierPicker}
      ${detail ? `
        <div class="scroll-x mt-1.5">${earnRows(p, groups, notes)}</div>
        <!-- The numbered notes stay open and stay next to the table, because the
             rows above point up at them: a marker whose text is behind a click
             is a figure the reader cannot finish reading. Hoisting them off the
             rows was about printing one sentence once, not about hiding it. -->
        ${notes.size ? `
          <ol class="mt-1.5 list-none space-y-0.5 text-[11.5px] leading-[1.6] text-muted">
            ${[...notes].map(([text, n]) => `<li class="-indent-3 pl-3"><sup class="mr-0.5 text-[9px]">${n}</sup>${esc(text)}</li>`).join('')}
          </ol>` : ''}
        <!-- The first note is the one that must never be a click away: it says
             the figure is an estimate. The rest is provenance -- which tables,
             read when, and what they do not cover -- which a reader wants when
             checking a number and not while reading one. -->
        <p class="mt-2 text-[11.5px] leading-[1.6] text-muted">${esc(p.notes[0] || '')}</p>
        ${p.notes.length > 1 || p.sources.length ? `
          <details class="group/src mt-1">
            <summary class="label cursor-pointer select-none text-[10.5px]">
              <span class="mono inline-block w-3 transition-transform duration-150 group-open/src:rotate-90">&rsaquo;</span>
              Where these came from
            </summary>
            <p class="mt-1 text-[11.5px] leading-[1.6] text-muted">
              ${p.notes.slice(1).map(esc).join(' ')}
              ${p.sources.map(x => `The <a class="underline underline-offset-2" href="${esc(x.url)}" rel="noreferrer">${esc(x.table.replace(/_/g, ' '))} table</a> was read ${esc(x.fetched)}.`).join(' ')}
            </p>
          </details>` : ''}` : ''}
    </div>
  </details>`;
}

// Set when a tier was just changed, so the control the reader is holding keeps
// focus across the re-render its own change caused. The picker used to sit
// outside this region and never lose it; moving it into the programme is worth
// one line here.
let refocusTier = null;

function renderEarn(data) {
  const panel = $('earn-panel');
  const programs = (data && data.programs) || [];
  if (!programs.length) { panel.classList.add('hidden'); return; }
  panel.classList.remove('hidden');
  if (!opened) opened = new Set(programs.map(p => p.id));
  // No ranking between programmes, and deliberately: a mile and a Status Point
  // are not commensurable without a valuation, and a valuation is an opinion.
  // They are listed, not scored.
  $('earn').innerHTML = programs.map(earnProgram).join('');

  // `toggle` does not bubble, so these are wired per section rather than once on
  // the panel. What each one records is the whole panel's state read back off the
  // document, never a delta from the event: setting innerHTML fires a toggle on
  // the sections it replaced as well as on the ones it created, and the two
  // arrive in no guaranteed order, so an add-or-remove here dropped a section
  // that was plainly open on screen. Reading the live DOM cannot disagree with
  // it, and a stale event just recomputes the same answer.
  for (const section of $('earn').querySelectorAll('details.prog')) {
    section.addEventListener('toggle', () => {
      opened = new Set([...$('earn').querySelectorAll('details.prog')]
        .filter(d => d.open).map(d => d.dataset.prog));
      syncUrl();
    });
  }
  for (const sel of $('earn').querySelectorAll('.tier')) {
    sel.addEventListener('change', () => {
      if (sel.value) tiers.set(sel.dataset.prog, sel.value);
      else tiers.delete(sel.dataset.prog);
      refocusTier = sel.dataset.prog;
      syncUrl();
      // Re-priced rather than marked stale: the itinerary did not change, only
      // what the traveller holds, and the answer is one call away.
      if (reported) reprice();
    });
  }
  if (refocusTier) {
    const sel = $('earn').querySelector(`.tier[data-prog="${CSS.escape(refocusTier)}"]`);
    if (sel) sel.focus();
    refocusTier = null;
  }
}

function earnUnavailable(message) {
  $('earn-panel').classList.remove('hidden');
  $('earn').innerHTML =
    `<p class="px-4 py-3 text-[13px] text-muted">${esc(message)}</p>`;
}

// The map is drawn after the report's markup is in the document, because it
// builds real SVG nodes rather than a string. A failure here must not take the
// report down with it: the table below says everything the map does.
function drawMap(ann) {
  const box = $('map');
  if (!box) return;
  const drop = () => ($('map-block') || box).remove();
  try {
    if (!window.RTWMap || !RTWMap.draw(box, ann)) drop();
  } catch (e) {
    drop();
  }
}

// Hovering a connection lights up the same airport on the map. Cheap, and the
// alternative is counting dots along a route that crosses itself.
// On #answer rather than #report: the connections table and the map it lights
// up now live in a sibling panel, and one listener over both is simpler than
// two that have to stay in step.
document.getElementById('answer').addEventListener('mouseover', e => {
  const row = e.target.closest('tr[data-airport]');
  highlight(row && row.dataset.airport);
});
document.getElementById('answer').addEventListener('mouseout', e => {
  if (e.target.closest('tr[data-airport]')) highlight(null);
});

function highlight(code) {
  for (const node of document.querySelectorAll('#map [data-airport]')) {
    node.classList.toggle('is-lit', !!code && node.dataset.airport === code);
  }
}

// Continents and traffic conferences are table keys in the report and read like
// table keys. The report carries its own table of display names — see
// place_names/1 in json_out.pl — so this never has to guess, and never has to
// wait for a second request to come back before the first report can render.
// Anything the table does not cover falls back to the atom rather than to a
// title-cased guess, which would quietly invent a name for a new continent.
function named(names, key) {
  return (names && names[key]) || key;
}
const namedList = (names, keys, sep) =>
  (keys || []).map(k => named(names, k)).join(sep);

// Ruled rows rather than a card: the fare is a reading off the itinerary, and the
// tariff sets its own summaries as a table.
function fareBlock(fare, ann) {
  const names = ann.names;
  const line = (k, val) => val
    ? `<div class="flex flex-wrap items-baseline gap-x-3 border-t border-rule px-4 py-1.5">
         <dt class="label w-[7.5rem] shrink-0">${k}</dt>
         <dd class="min-w-0 flex-1 text-[13px]">${val}</dd>
       </div>`
    : '';

  const basis = fare.fareBasis === 'none'
    ? `<span class="text-muted">none published for ${fare.continents} continents in ${esc(fare.cabin)}</span>`
    : `<strong class="mono text-[14px] font-semibold">${esc(fare.fareBasis)}</strong>
       <span class="text-muted"> · ${fare.continents} continents · ${esc(fare.cabin)}</span>`;

  return `<dl class="mb-0">
    ${line('Fare basis', basis)}
    ${line('Continents', `<span class="text-[12.5px]">${esc(namedList(names, fare.continentList, ' · '))}</span>`)}
    ${line('Conferences', `<span class="mono text-[12px]">${esc(namedList(names, ann.trafficConferenceSequence, ' → '))}</span>`)}
    ${line('Route', `<span class="text-[12.5px] break-words">${esc(namedList(names, ann.continentSequence, ' → '))}</span>`)}
    ${fare.cabin === 'economy' && fare.premiumEconomyUpgradeUsd
      ? line('Premium economy', `USD ${fare.premiumEconomyUpgradeUsd} for all segments <span class="text-muted">(section 12)</span>`)
      : ''}
  </dl>`;
}

// The rules that were broken, and nothing when none were. A verdict of VALID is
// derived from exactly this list being empty -- verdict_of/2 has no other way to
// reach it -- so a line here saying so restated the word above it in smaller
// type. What a reader wants instead when the list is empty is the check
// register, which says what was measured rather than what was not found.
function violationList(v) {
  if (!v.length) return '';
  return `<ul class="border-t border-rule">${v.map(x => {
    const look = SEV[x.severity] || SEV.error;
    // Citation, severity and rule id share one wrapping row above the message
    // rather than sitting in a fixed-width rail. A rail is tidier until the word
    // is "indeterminate", which is wider than any column worth reserving and used
    // to overrun the message beside it.
    return `
      <li class="border-b border-rule px-4 py-2.5 last:border-b-0">
        <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
          <span class="cite">${esc(x.citation)}</span>
          <span class="sev-label ${look.text}">${esc(x.severity)}</span>
          <span class="mono ml-auto shrink-0 text-[11px] text-muted">${esc(x.rule)}</span>
        </div>
        <p class="mt-1.5 max-w-[62ch] text-[13.5px]">${esc(x.message)}</p>
        <div class="mt-1 flex flex-wrap gap-x-3 gap-y-0.5 text-[11px] text-muted">
          ${evidence(x.evidence)}
        </div>
      </li>`;
  }).join('')}</ul>`;
}

// The route, under the rules it broke. It reads as the evidence for the lines
// above it -- a repeated sector, a continent entered twice, a surface gap -- and
// that is a thing to look at while reading them rather than after scrolling past
// the register. It used to sit above the connections table in the panel beside,
// which put the tallest element on the page between the reader and everything
// printed after it.
//
// The box is emptied by drawMap when there is nothing to draw, so a journey with
// no resolvable coordinates costs no space here.
function mapBlock(ann) {
  if (!(ann.points || []).length) return '';
  return `<div id="map-block" class="border-t border-rule">
            <div id="map" class="px-4 py-3"></div>
          </div>`;
}

// What every rule measured, not just the ones that were broken. "Every rule this
// input can answer is satisfied" is a claim about coverage a reader has no way to
// audit from the verdict alone, and the number a cap was cleared by is the thing
// a fare-construction tool is actually asked. Collapsed by default because it is
// four times the length of the verdict it supports.
function checkList(checks, violations) {
  if (!checks.length) {
    return violations.some(x => x.rule === 'input_error')
      ? `<p class="border-t border-rule px-4 py-3 text-[13px] text-muted">
           No rule was evaluated — the input errors above describe an itinerary the rules cannot be measured against.
         </p>`
      : '';
  }

  const counts = OUTCOME_ORDER
    .map(name => {
      const n = checks.filter(c => c.outcome === name).length;
      return n ? `${n} ${OUTCOME[name].word}` : null;
    })
    .filter(Boolean).join(', ');

  return `
    <details class="group border-t border-rule">
      <summary class="label cursor-pointer select-none px-4 py-2">
        <span class="mono inline-block w-3 transition-transform duration-150 group-open:rotate-90">&rsaquo;</span>
        Rules evaluated (${checks.length}) — ${esc(counts)}
      </summary>
      <ul class="border-t border-rule">${checks.map(c => {
        const look = OUTCOME[c.outcome] || OUTCOME.pass;
        return `
        <li class="border-b border-rule px-4 py-1.5 last:border-b-0">
          <div class="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
            <span class="cite">${esc(c.citation)}</span>
            <span class="text-[12.5px] font-medium ${look.dim ? 'text-muted' : ''}">${esc(c.label)}</span>
            <span class="sev-label ml-auto shrink-0 ${look.text}">${esc(look.word)}</span>
          </div>
          <p class="mt-0.5 max-w-[64ch] text-[12px] text-muted">${esc(c.detail)}</p>
        </li>`;
      }).join('')}</ul>
    </details>`;
}

function connections(ann) {
  const points = ann.points || [];
  if (!points.length) return '';
  return `
    <details open class="group">
      <summary class="label cursor-pointer select-none px-4 py-2">
        <span class="mono inline-block w-3 transition-transform duration-150 group-open:rotate-90">&rsaquo;</span>
        Connections (${points.length})
      </summary>
      <div class="scroll-x px-4 pb-3">
        <table class="w-full border-collapse text-[12.5px]">
          <thead>
            <tr class="border-b border-rule-strong">
              <th class="label pb-1 pr-3 text-left">After</th>
              <th class="label pb-1 pr-3 text-left">At</th>
              <th class="label pb-1 pr-3 text-left">Counts as</th>
              <th class="label pb-1 pr-3 text-right">Ground</th>
              <th class="label pb-1 text-left">Decided by</th>
            </tr>
          </thead>
          <tbody>
            ${points.map(p => `
              <tr class="border-b border-rule last:border-b-0" data-airport="${esc(p.airport)}">
                <td class="mono py-1 pr-3 text-[11px] text-muted">${p.afterSegment}</td>
                <td class="mono py-1 pr-3 font-medium">${esc(p.airport)}</td>
                <td class="py-1 pr-3 ${KIND[p.kind] || ''}">${esc(p.kind)}</td>
                <td class="mono py-1 pr-3 text-right">${p.groundHours === null ? '<span class="text-muted">—</span>' : p.groundHours + ' h'}</td>
                <td class="py-1 text-[11.5px] text-muted">${esc(source(p))}</td>
              </tr>`).join('')}
          </tbody>
        </table>
      </div>
    </details>`;
}

// Which of the two sources settled this point. Worth showing: a declaration that
// disagrees with the clock changes the stopover count, and the report would
// otherwise give no clue which one the verdict rests on.
function source(p) {
  if (p.surfaceAdjacent) return 'surface sector';
  const clock = p.derivedKind === 'transfer' || p.derivedKind === 'stopover';
  if (p.declaredKind && clock && p.declaredKind !== p.derivedKind)
    return `declared, over ${p.derivedKind} by the clock`;
  if (p.declaredKind) return 'declared';
  if (p.kind === 'indeterminate') return 'neither time nor declaration';
  return 'ground time';
}

function evidence(e) {
  if (!e || !Object.keys(e).length) return '';
  return Object.entries(e).map(([k, val]) =>
    `<span class="mono">${esc(k)}: ${esc(Array.isArray(val) ? val.join(', ') : val)}</span>`).join('');
}

function disclosure(title, text) {
  return `
    <details class="group border-b border-rule last:border-b-0">
      <summary class="label cursor-pointer select-none px-4 py-2">
        <span class="mono inline-block w-3 transition-transform duration-150 group-open:rotate-90">&rsaquo;</span>
        ${esc(title)}
      </summary>
      <pre class="mono mx-4 mb-3 overflow-x-auto rounded-xs border border-rule bg-sunken p-2.5 text-[11px] leading-[1.5]">${esc(text)}</pre>
    </details>`;
}

// --- loading ---------------------------------------------------------------

// Returns the routing string if the itinerary is given as one, so the caller knows
// to validate that rather than the (still empty) segment table.
function loadItinerary(it) {
  $('cabin').value = it.cabin || 'economy';
  $('origin').value = it.origin || '';
  if (it.route) {
    $('route').value = it.route;
    $('composed').classList.add('hidden');
    rows = [];
    render();
    show('routing');
    return it.route;
  }
  $('route').value = '';
  segmentsDerived = false;
  $('times').value = it.mode === 'routing' ? 'routing' : (hasTimes(it) ? 'full' : $('times').value);
  rows = (it.segments || []).map(s => ({
    type: s.type || 'flight',
    from: s.from || '', to: s.to || '',
    marketing: s.marketingCarrier || s.carrier || '',
    operating: s.operatingCarrier || s.carrier || '',
    flight: s.flight || '',
    dep: s.dep || '', arr: s.arr || '',
    stop: s.stop || '',
    class: s.bookingClass || '', family: s.fareFamily || ''
  }));
  render();
  show('segments');
  $('adopted').classList.add('hidden');
  return null;
}

const hasTimes = it => (it.segments || []).some(s => s.dep || s.arr);

// The server's own reading of a routing, turned back into editable rows. The codes
// here are resolved, so a city code comes back as its airport.
function adoptSegments(ann) {
  if (!ann || !ann.segments) return;
  segmentsDerived = true;
  // A class or a fare family typed against a routing survives it being
  // re-validated. The routing regenerates every other cell and has no notation
  // for these two, so dropping them would silently discard the only thing on
  // the row the user actually typed.
  const kept = rows.length === ann.segments.length ? rows : null;
  rows = ann.segments.map((s, i) => ({
    type: s.type, from: s.from || '', to: s.to || '',
    marketing: s.marketingCarrier || '', operating: s.operatingCarrier || '',
    flight: s.flight && s.flight !== 'unknown' ? s.flight : '',
    dep: s.dep || '', arr: s.arr || '',
    stop: s.stop || '',
    class: s.bookingClass || (kept ? kept[i].class : ''),
    family: s.fareFamily || (kept ? kept[i].family : '')
  }));
  $('times').value = ann.mode === 'full' ? 'full' : 'routing';
  if (ann.origin) $('origin').value = ann.origin;
  render();
  $('composed').classList.add('hidden');
  $('adopted').classList.remove('hidden');
}

// --- the programme list ----------------------------------------------------

// Taken from the validator's own list, which is also the only thing that decides
// what the page offers: the tiers a programme publishes, the fare families it
// prices, and whether the segment table needs a column for them.
function adoptPrograms(programs) {
  PROGRAMS = programs;
  FAMILIES = [...new Set(programs.flatMap(p => p.fareFamilies || []))];
  opened = new Set(
    pendingPrograms
      ? pendingPrograms.filter(id => programs.some(p => p.id === id))
      : programs.map(p => p.id));
  pendingPrograms = null;
  for (const [id, tier] of pendingTiers || []) {
    const p = programs.find(x => x.id === id);
    if (p && (p.tiers || []).some(t => t.key === tier)) tiers.set(id, tier);
  }
  pendingTiers = null;

  // No programme prices a fare family, so the column would be a control with
  // nothing behind it.
  $('segtable').classList.toggle('hide-fare', FAMILIES.length === 0);

  render();
}

// The rows always, never the routing string: a routing has no notation for a
// booking class and the rows carry one. Same reason as in validate().
const reprice = () => earn(rows.length ? buildRequest() : buildRequest($('route').value.trim()));

// --- colour scheme ---------------------------------------------------------

// Three states. "Auto" is the default and stores nothing, so a machine that has
// never been told otherwise keeps following the OS; the other two write a key.
// The theme itself is one `color-scheme` declaration in app.src.css -- all this
// does is set or clear data-theme. The pre-paint copy of the read is inline in
// index.html, because doing it here would show one frame of the wrong theme.
const THEME_KEY = 'rtw-theme';

function applyTheme(choice) {
  if (choice === 'light' || choice === 'dark') {
    document.documentElement.dataset.theme = choice;
  } else {
    delete document.documentElement.dataset.theme;
  }
  try {
    if (choice === 'auto') localStorage.removeItem(THEME_KEY);
    else localStorage.setItem(THEME_KEY, choice);
  } catch (e) { /* private mode: the choice holds for this page only */ }
}

for (const input of document.querySelectorAll('input[name="theme"]')) {
  input.addEventListener('change', () => applyTheme(input.value));
}

// Reflect what the inline script already applied, so the control agrees with the
// page it is describing.
(() => {
  let stored = null;
  try { stored = localStorage.getItem(THEME_KEY); } catch (e) { /* ignore */ }
  const chosen = $('th-' + stored) || $('th-auto');
  chosen.checked = true;
})();

// --- the URL ---------------------------------------------------------------

// The itinerary lives in the query string, so a routing can be pasted into a
// message and come back as a validated report. Written with replaceState rather
// than pushState: at one entry per keystroke the back button would become an
// undo key, which is not what anyone reaches for it expecting.
//
//   ?r=LHR-BA-JFK-AA-X/LAX-JL-NRT-CX-HKG-QR-LHR    the routing box, verbatim
//   ?s=<base64url>                                 the segment table
//   &t=s                                           the Segments tab was active
//   &c=economy &p=adult+child                      only when not the default
//
// Both r and s are written when both hold something, so switching tabs to read
// the syntax help cannot quietly drop the table from a link you then share.
const CABIN_DEFAULT = 'business';
const PAX_DEFAULT = 'adult';

// Read off the markup rather than restated here, so the two cannot drift.
const CABINS = new Set([...$('cabin').options].map(o => o.value));

// `/` is legal in a query string (RFC 3986) and the routing notation is full of
// it. Leaving it alone is most of what keeps the URL readable, which is the
// whole point of storing the routing rather than an opaque blob.
const enc = v => encodeURIComponent(v).replace(/%2F/g, '/');

const b64url = s =>
  btoa(String.fromCharCode(...new TextEncoder().encode(s)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

const unb64url = s =>
  new TextDecoder().decode(
    Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0)));

// Positional rather than keyed, and trailing blanks are dropped: a keyed object
// would roughly double a sixteen-segment URL for no gain, since nothing but this
// file ever reads it.
const FIELDS = ['type', 'from', 'to', 'marketing', 'operating', 'flight', 'dep', 'arr', 'stop',
                'class', 'family'];

function encodeSegments() {
  const payload = {
    v: 1,
    m: timesGiven() ? 'full' : 'routing',
    o: $('origin').value.trim().toUpperCase(),
    g: rows.map(r => {
      const cells = FIELDS.map(f => r[f] || '');
      while (cells.length && cells[cells.length - 1] === '') cells.pop();
      return cells;
    })
  };
  if (!payload.o) delete payload.o;
  return b64url(JSON.stringify(payload));
}

function decodeSegments(text) {
  const payload = JSON.parse(unb64url(text));
  if (!payload || !Array.isArray(payload.g)) throw new Error('no segments');
  segmentsDerived = false;
  $('times').value = payload.m === 'routing' ? 'routing' : 'full';
  $('origin').value = payload.o || '';
  rows = payload.g.map(cells => {
    const row = blank();
    FIELDS.forEach((f, i) => { row[f] = cells[i] || ''; });
    row.type = row.type === 'surface' ? 'surface' : 'flight';
    return row;
  });
}

// Rows filled in from a parsed routing are derived, not authored: the routing
// regenerates them exactly, so writing them to the URL as well would bury a
// readable ?r=LHR-BA-JFK... under two kilobytes of base64 for nothing. The flag
// clears the moment the table is touched directly, because from then on it holds
// something -- a date, a flight number -- the routing cannot express.
let segmentsDerived = false;
let pendingPrograms = null;
let pendingTiers = null;
let pendingClasses = null;
let pendingFamilies = null;
let booted = false;
let urlTimer = null;
let pendingTab = null;

function syncUrl() {
  if (!booted) return;
  clearTimeout(urlTimer);
  urlTimer = setTimeout(writeUrl, 250);
}

function writeUrl() {
  const parts = [];
  // The field wraps and may hold hand-entered breaks, which the grammar treats
  // as separators and a URL renders as %0A. The link is meant to be legible, so
  // the whitespace is collapsed on the way into it — this changes nothing about
  // what gets parsed, since a run of whitespace and a single space are one
  // separator either way.
  const route = $('route').value.trim().replace(/\s+/g, ' ');
  const authored = rows.length > 0 && !segmentsDerived;
  if (route) parts.push('r=' + enc(route));
  if (authored) parts.push('s=' + encodeSegments());
  // Only for derived rows: `s` already carries these positionally when the table
  // was authored, and writing them twice could put two answers in one link.
  // One character per segment, so ?r=LHR-BA-JFK-AA-LHR&b=DDD stays readable --
  // which is most of what keeps a routing link worth sharing.
  if (!authored && rows.length) {
    const classes = positional(rows.map(r => (r.class || '').toUpperCase().slice(0, 1)));
    const families = positional(rows.map(r => familyLetter(r.family)));
    if (classes) parts.push('b=' + enc(classes));
    if (families) parts.push('f=' + enc(families));
  }
  if (view === 'segments' && (authored || route)) parts.push('t=s');
  if ($('cabin').value !== CABIN_DEFAULT) parts.push('c=' + enc($('cabin').value));
  if ($('pax').value !== PAX_DEFAULT) parts.push('p=' + enc($('pax').value));
  // Which programme sections are open. Every programme is priced whatever this
  // says, so absent means all of them are open -- the common case, which
  // therefore adds nothing to the link.
  if (opened && opened.size !== PROGRAMS.length) parts.push('g=' + enc([...opened].join(',')));
  if (tiers.size) parts.push('m=' + enc([...tiers].map(([id, t]) => `${id}:${t}`).join(',')));

  const query = parts.join('&');
  history.replaceState(null, '', query ? '?' + query : location.pathname);
}

// A dash holds a gap so the string stays positional, and a run of them at the
// end is dropped. All dashes means nothing was stated and the parameter is
// omitted entirely.
const positional = (cells) => {
  const out = cells.map(c => c || '-');
  while (out.length && out[out.length - 1] === '-') out.pop();
  return out.join('');
};

// Families are written by initial, which is unambiguous across everything any
// registered programme publishes and is checked to be -- a two-character
// encoding would make the parameter longer than the routing beside it.
const familyLetter = (family) =>
  family && FAMILIES.includes(family) ? family[0].toUpperCase() : '';

const familyFromLetter = (letter) =>
  FAMILIES.find(f => f[0].toUpperCase() === letter) || '';

// Returns the routing to validate, null to validate the segment table, or
// undefined when the URL carried no itinerary at all.
function readUrl() {
  const q = new URLSearchParams(location.search);
  // Both are checked against what the control actually offers. Assigning an
  // unknown value to a <select> leaves it empty rather than rejecting it, and an
  // empty cabin is refused by the validator on a link that merely had a typo.
  if (q.has('c') && CABINS.has(q.get('c'))) $('cabin').value = q.get('c');
  if (q.has('p') && PAX[q.get('p')]) $('pax').value = q.get('p');

  const route = q.get('r') || '';
  $('route').value = route;

  let haveSegments = false;
  if (q.has('s')) {
    // A hand-mangled link should land on an empty form, not a broken one.
    try { decodeSegments(q.get('s')); haveSegments = true; }
    catch (e) { rows = []; }
  }

  // An empty `g` is a link where every section was closed, which is a state
  // worth being able to share -- so this deliberately does not fall back to
  // opening them all.
  if (q.has('g')) pendingPrograms = q.get('g').split(',').filter(Boolean);
  // Checked against what each programme publishes once the list arrives, not
  // here: a tier this page has never heard of is the validator's to refuse.
  if (q.has('m')) pendingTiers = q.get('m').split(',').map(p => p.split(':')).filter(p => p.length === 2);
  // Held until the rows exist -- a routing has to be validated before there are
  // any rows for its classes to land on.
  pendingClasses = q.get('b') || null;
  pendingFamilies = q.get('f') || null;
  if (haveSegments) applyPositional();

  const segmentsActive = haveSegments && (q.get('t') === 's' || !route);
  show(segmentsActive ? 'segments' : 'routing');

  if (segmentsActive) return null;
  // A link made from the Segments tab while a routing was showing there carries
  // t=s but no s, because the rows were derived. Validating the routing rebuilds
  // them, so the tab is switched once that has happened.
  if (route) {
    if (q.get('t') === 's') pendingTab = 'segments';
    return route;
  }
  return undefined;
}

// The `b` and `f` parameters name a class and a family per segment, and the
// segments they name may not exist yet: a routing has to be parsed first. So
// they are held and applied to whatever rows end up on the page.
function applyPositional() {
  if (pendingClasses) {
    [...pendingClasses].forEach((c, i) => {
      if (rows[i] && c !== '-') rows[i].class = c;
    });
  }
  if (pendingFamilies) {
    [...pendingFamilies].forEach((c, i) => {
      if (rows[i] && c !== '-') rows[i].family = familyFromLetter(c);
    });
  }
  pendingClasses = null;
  pendingFamilies = null;
}

// --- wiring ----------------------------------------------------------------

$('example').addEventListener('change', e => {
  const it = EXAMPLES[e.target.value];
  if (it) validate(loadItinerary(it));
});
$('times').addEventListener('change', render);
$('add').addEventListener('click', () => { segmentsDerived = false; rows.push(blank()); render(); });

let cleared = null;
$('clear').addEventListener('click', () => {
  cleared = { rows: rows.slice(), route: $('route').value, derived: segmentsDerived };
  segmentsDerived = false;
  $('undo').classList.toggle('hidden', rows.length === 0 && !cleared.route);
  rows = [];
  $('route').value = '';
  $('adopted').classList.add('hidden');
  $('composed').classList.add('hidden');
  $('routingerr').classList.add('hidden');
  render();
});
$('undo').addEventListener('click', () => {
  if (!cleared) return;
  rows = cleared.rows;
  $('route').value = cleared.route;
  segmentsDerived = cleared.derived;
  cleared = null;
  $('undo').classList.add('hidden');
  render();
});
$('validate').addEventListener('click', () => validate());
$('parse').addEventListener('click', readRouting);
// Enter validates, as it did when this was a single-line input. Shift+Enter is
// left alone so the field can still be broken across lines by hand.
$('route').addEventListener('keydown', e => {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); readRouting(); }
});
$('load').addEventListener('click', () => {
  try {
    validate(loadItinerary(JSON.parse($('paste').value)));
  } catch (e) {
    $('report').innerHTML = `
      <div class="p-4">
        <p class="verdict-word text-err">Not JSON</p>
        <p class="mt-1 max-w-[62ch] text-[13px] text-muted">${esc(e.message)}</p>
      </div>`;
  }
});

function readRouting() {
  const r = $('route').value.trim();
  if (r) validate(r);
}

// Segments -> routing. The string is composed by Prolog from the same annotation
// pass the validator uses, so the browser never has to know the grammar in this
// direction either. A routing cannot express a point that is neither a transfer
// nor a stopover, and the validator says which ones rather than quietly
// promoting them to stopovers and changing the itinerary's meaning.
$('toroute').addEventListener('click', async () => {
  $('routingerr').classList.add('hidden');
  if (rows.length === 0) { show('segments'); return; }
  const btn = $('toroute');
  btn.disabled = true;
  $('status').textContent = 'composing…';
  try {
    const res = await RTWApi.routing(buildRequest());
    if (res.ok) {
      const route = res.data.route;
      $('route').value = route;
      $('adopted').classList.add('hidden');
      $('composed').classList.remove('hidden');
      show('routing');
      $('route').focus();
      $('route').setSelectionRange(route.length, route.length);
      announce(`Routing: ${route}`);
    } else {
      $('routingerr').textContent = res.data.message || 'Could not write this itinerary as a routing.';
      $('routingerr').classList.remove('hidden');
      announce($('routingerr').textContent);
    }
  } catch (e) {
    $('routingerr').textContent = `The validator did not answer. ${e.message}`;
    $('routingerr').classList.remove('hidden');
  } finally {
    btn.disabled = false;
    $('status').textContent = '';
  }
});

for (const name of Object.keys(EXAMPLES)) {
  const o = document.createElement('option');
  o.value = o.textContent = name;
  $('example').appendChild(o);
}

// An empty state that teaches the syntax rather than announcing that nothing is
// here. It is replaced by the first report and never comes back.
$('report').innerHTML = `
  <div class="p-4">
    <p class="text-[13.5px]">Write the journey as a routing, or build it segment by segment.</p>
    <dl class="mt-3 space-y-1.5 text-[12.5px] text-muted">
      <div class="flex gap-3"><dt class="mono w-[5.5rem] shrink-0 text-ink">LHR</dt><dd>a stopover</dd></div>
      <div class="flex gap-3"><dt class="mono w-[5.5rem] shrink-0 text-ink">X/LHR</dt><dd>a transfer — you do not break the journey here</dd></div>
      <div class="flex gap-3"><dt class="mono w-[5.5rem] shrink-0 text-ink">//</dt><dd>a surface sector you arrange yourself</dd></div>
      <div class="flex gap-3"><dt class="mono w-[5.5rem] shrink-0 text-ink">BA</dt><dd>the carrier for the leg that follows</dd></div>
    </dl>
  </div>`;

// The grammar, the limits and the city table are described by the ruleset the
// validator reports, so the page never carries a second copy of any of them to
// fall out of date. This is also the first thing that needs the worker, so it is
// what the page waits on: by the time it answers, the image has booted.
buttons().forEach(b => { b.disabled = true; });
$('status').textContent = 'starting the validator…';

RTWApi.ruleset()
  .then(res => {
    if (!res.ok) throw new Error(res.data.message || 'the ruleset could not be read');
    const d = res.data;
    $('ruleset').textContent =
      `Tariff RWR2 Rule 3015 · version ${d.version} · ` +
      `${d.limits.min_segments}–${d.limits.max_segments} segments`;
    $('routehelp').innerHTML =
      esc(d.routeSyntax || '').replace(/&quot;([^&]+?)&quot;/g, '<code>$1</code>');
    $('citycodes').innerHTML = (d.cityCodes || [])
      .map(c => `<code>${esc(c.code)}</code>&nbsp;${esc(c.airport)}`).join('&ensp;');
  })
  .catch(() => { $('ruleset').textContent = 'Tariff RWR2 Rule 3015 · validator unavailable'; })
  .finally(() => {
    buttons().forEach(b => { b.disabled = false; });
    $('status').textContent = '';
  });

// The programme list is what the earning column, the fare-family select and the
// picker are all built from, so the page carries no copy of any programme's
// name, currencies or fare families.
RTWApi.programs()
  .then(res => { if (res.ok) adoptPrograms(res.data.programs || []); })
  .catch(() => { /* the page still validates; it just cannot price */ });

// The URL is read before anything renders, because render() is one of the things
// that writes it back and would otherwise erase the link that was just opened.
// booted stays false until the form matches the URL, for the same reason.
const linked = readUrl();
render();
booted = true;

// A linked itinerary validates as soon as the worker is up. validate() disables
// and re-enables the buttons itself, so it is sequenced after the ruleset call
// rather than racing it -- otherwise whichever finished second would re-enable
// them while the other was still working.
if (linked !== undefined) {
  RTWApi.ready()
    .then(() => validate(linked || undefined))
    .then(() => {
      if (pendingTab) { show(pendingTab); pendingTab = null; }
    });
}
