'use strict';

/* Behaviour for the validator page.
 *
 * Two ways in, one itinerary. The Routing tab posts {route: "..."} and lets the
 * server parse it; the Segments tab posts {mode, segments: [...]}.
 *
 * The grammar is not implemented here in either direction. Reading a routing is
 * /api/validate's job and writing one is /api/routing's, because a copy of the
 * grammar living in the browser would be the one nothing tests. Both directions
 * are Prolog, and the suite asserts that a routing survives the round trip.
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

// --- the segment table -----------------------------------------------------

const blank = () =>
  ({ type: 'flight', from: '', to: '', marketing: '', operating: '', flight: '', dep: '', arr: '', stop: '' });

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

let timer = null;
function suggest(input, listId) {
  clearTimeout(timer);
  const q = input.value.trim();
  if (q.length < 2) return;
  timer = setTimeout(async () => {
    try {
      const r = await fetch(`/api/airports?q=${encodeURIComponent(q)}&limit=8`);
      const d = await r.json();
      $(listId).innerHTML =
        d.results.map(a => `<option value="${esc(a.iata)}">${esc(a.city)}, ${esc(a.country)}</option>`).join('');
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

for (const ev of ['input', 'change']) {
  document.getElementById('itinerary-heading').parentElement.addEventListener(ev, e => {
    if (e.target.closest('#panel-segments')) segmentsDerived = false;
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
    const res = await fetch('/api/validate', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body)
    });
    const data = await res.json();
    if (!res.ok) renderError(res.status, data, body);
    else {
      // A routing that parsed becomes rows in the Segments tab, using the server's
      // own reading of it, so it can be refined without retyping.
      if (routeString) adoptSegments(data.annotations);
      renderReport(data, body);
    }
  } catch (e) {
    $('report').innerHTML = `
      <div class="p-4">
        <p class="verdict-word text-err">Unreachable</p>
        <p class="mt-1 text-[13px] text-muted">The validator did not answer. ${esc(e.message)}</p>
      </div>`;
  } finally {
    buttons().forEach(b => { b.disabled = false; });
    $('status').textContent = '';
  }
}

function renderError(status, data, body) {
  markFresh();
  announce(`Request refused: ${data.message || data.error || 'error'}`);
  $('report').innerHTML = `
    <div class="settle">
      <div class="border-b border-rule bg-err-wash p-4">
        <p class="verdict-word text-err">${esc(String(data.error || 'error').replace(/_/g, ' '))}</p>
        <p class="mono mt-1.5 text-[11px] text-muted">HTTP ${status}</p>
      </div>
      <p class="max-w-[68ch] p-4 text-[13.5px]">${esc(data.message || '')}</p>
      ${disclosure('Request sent', JSON.stringify(body, null, 2))}
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
  const look = VERDICT[data.verdict] || VERDICT.indeterminate;
  const counts = tally(v);

  markFresh();
  announce(`${data.verdict}. ${counts || 'No rule was broken.'}` +
           (nc.length ? ` ${nc.length} rule${nc.length === 1 ? '' : 's'} not checked.` : ''));

  $('report').innerHTML = `
    <div class="settle">
      <div class="border-b border-rule ${look.wash} p-4">
        <p class="verdict-word ${look.text}">${esc(data.verdict)}</p>
        <p class="mt-1.5 text-[12.5px] ${counts ? look.text : 'text-muted'}">
          ${counts ? esc(counts) : 'Every rule this input can answer is satisfied.'}
        </p>
      </div>

      ${fareBlock(fare, ann)}
      ${violationList(v)}
      ${notCheckedList(nc)}
      ${connections(ann)}

      <div class="border-t border-rule">
        ${disclosure('Request sent', JSON.stringify(body, null, 2))}
        ${disclosure('Full response', JSON.stringify(data, null, 2))}
      </div>
    </div>`;

  drawMap(ann);
}

// The map is drawn after the report's markup is in the document, because it
// builds real SVG nodes rather than a string. A failure here must not take the
// report down with it: the table below says everything the map does.
function drawMap(ann) {
  const box = $('map');
  if (!box) return;
  try {
    if (!window.RTWMap || !RTWMap.draw(box, ann)) box.remove();
  } catch (e) {
    box.remove();
  }
}

// Hovering a connection lights up the same airport on the map. Cheap, and the
// alternative is counting dots along a route that crosses itself.
document.getElementById('report').addEventListener('mouseover', e => {
  const row = e.target.closest('tr[data-airport]');
  highlight(row && row.dataset.airport);
});
document.getElementById('report').addEventListener('mouseout', e => {
  if (e.target.closest('tr[data-airport]')) highlight(null);
});

function highlight(code) {
  for (const node of document.querySelectorAll('#map [data-airport]')) {
    node.classList.toggle('is-lit', !!code && node.dataset.airport === code);
  }
}

// Ruled rows rather than a card: the fare is a reading off the itinerary, and the
// tariff sets its own summaries as a table.
function fareBlock(fare, ann) {
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
    ${line('Continents', `<span class="mono text-[12px]">${esc((fare.continentList || []).join(' · '))}</span>`)}
    ${line('Conferences', `<span class="mono text-[12px]">${esc((ann.trafficConferenceSequence || []).join(' → '))}</span>`)}
    ${line('Route', `<span class="mono text-[12px] break-words">${esc((ann.continentSequence || []).join(' → '))}</span>`)}
    ${fare.cabin === 'economy' && fare.premiumEconomyUpgradeUsd
      ? line('Premium economy', `USD ${fare.premiumEconomyUpgradeUsd} for all segments <span class="text-muted">(section 12)</span>`)
      : ''}
  </dl>`;
}

function violationList(v) {
  if (!v.length) {
    return `<p class="border-t border-rule px-4 py-3 text-[13px] text-muted">No rule was broken.</p>`;
  }
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

// Rules the input cannot answer at all. Dashed and unfilled on purpose: this is an
// absence, and rendering it in the same register as a satisfied rule would claim
// coverage the report does not give.
function notCheckedList(nc) {
  if (!nc.length) return '';
  return `
    <div class="border-t border-rule px-4 py-3">
      <div class="rounded-sm border border-dashed border-rule-strong px-3 py-2.5">
        <h3 class="label mb-1.5">
          Not checked — ${nc.length} rule${nc.length === 1 ? '' : 's'} this input cannot answer
        </h3>
        <ul class="space-y-1">
          ${nc.map(x => `
            <li class="flex flex-wrap items-baseline gap-2 text-[12.5px]">
              <span class="cite shrink-0">${esc(x.citation)}</span>
              <span class="min-w-0 flex-1 text-muted">${esc(x.reason)}</span>
            </li>`).join('')}
        </ul>
      </div>
    </div>`;
}

function connections(ann) {
  const points = ann.points || [];
  if (!points.length) return '';
  return `
    <details open class="group border-t border-rule">
      <summary class="label cursor-pointer select-none px-4 py-2">
        <span class="mono inline-block w-3 transition-transform duration-150 group-open:rotate-90">&rsaquo;</span>
        Connections (${points.length})
      </summary>
      <div id="map" class="px-4 pb-2"></div>
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
    stop: s.stop || ''
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
  rows = ann.segments.map(s => ({
    type: s.type, from: s.from || '', to: s.to || '',
    marketing: s.marketingCarrier || '', operating: s.operatingCarrier || '',
    flight: s.flight && s.flight !== 'unknown' ? s.flight : '',
    dep: s.dep || '', arr: s.arr || '',
    stop: s.stop || ''
  }));
  $('times').value = ann.mode === 'full' ? 'full' : 'routing';
  if (ann.origin) $('origin').value = ann.origin;
  render();
  $('composed').classList.add('hidden');
  $('adopted').classList.remove('hidden');
}

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
const FIELDS = ['type', 'from', 'to', 'marketing', 'operating', 'flight', 'dep', 'arr', 'stop'];

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
  const route = $('route').value.trim();
  const authored = rows.length > 0 && !segmentsDerived;
  if (route) parts.push('r=' + enc(route));
  if (authored) parts.push('s=' + encodeSegments());
  if (view === 'segments' && (authored || route)) parts.push('t=s');
  if ($('cabin').value !== CABIN_DEFAULT) parts.push('c=' + enc($('cabin').value));
  if ($('pax').value !== PAX_DEFAULT) parts.push('p=' + enc($('pax').value));

  const query = parts.join('&');
  history.replaceState(null, '', query ? '?' + query : location.pathname);
}

// Returns the routing to validate, null to validate the segment table, or
// undefined when the URL carried no itinerary at all.
function readUrl() {
  const q = new URLSearchParams(location.search);
  if (q.has('c')) $('cabin').value = q.get('c');
  if (q.has('p') && PAX[q.get('p')]) $('pax').value = q.get('p');

  const route = q.get('r') || '';
  $('route').value = route;

  let haveSegments = false;
  if (q.has('s')) {
    // A hand-mangled link should land on an empty form, not a broken one.
    try { decodeSegments(q.get('s')); haveSegments = true; }
    catch (e) { rows = []; }
  }

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
$('route').addEventListener('keydown', e => { if (e.key === 'Enter') readRouting(); });
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

// Segments -> routing. The string is composed by /api/routing from the same
// annotation pass the validator uses, so the browser never has to know the
// grammar in this direction either. A routing cannot express a point that is
// neither a transfer nor a stopover, and the server says which ones rather than
// quietly promoting them to stopovers and changing the itinerary's meaning.
$('toroute').addEventListener('click', async () => {
  $('routingerr').classList.add('hidden');
  if (rows.length === 0) { show('segments'); return; }
  const btn = $('toroute');
  btn.disabled = true;
  $('status').textContent = 'composing…';
  try {
    const res = await fetch('/api/routing', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(buildRequest())
    });
    const data = await res.json();
    if (res.ok) {
      $('route').value = data.route;
      $('adopted').classList.add('hidden');
      $('composed').classList.remove('hidden');
      show('routing');
      $('route').focus();
      $('route').setSelectionRange(data.route.length, data.route.length);
      announce(`Routing: ${data.route}`);
    } else {
      $('routingerr').textContent = data.message || 'Could not write this itinerary as a routing.';
      $('routingerr').classList.remove('hidden');
      announce($('routingerr').textContent);
    }
  } catch (e) {
    $('routingerr').textContent = `Could not reach the service. ${e.message}`;
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

// The grammar, the limits and the city table are described by the service, so the
// page never carries a second copy of any of them to fall out of date.
fetch('/api/ruleset')
  .then(r => r.json())
  .then(d => {
    $('ruleset').textContent =
      `Tariff RWR2 Rule 3015 · version ${d.version} · ` +
      `${d.limits.min_segments}–${d.limits.max_segments} segments`;
    $('routehelp').innerHTML =
      esc(d.routeSyntax || '').replace(/&quot;([^&]+?)&quot;/g, '<code>$1</code>');
    $('citycodes').innerHTML = (d.cityCodes || [])
      .map(c => `<code>${esc(c.code)}</code>&nbsp;${esc(c.airport)}`).join('&ensp;');
  })
  .catch(() => { $('ruleset').textContent = 'Tariff RWR2 Rule 3015 · service unreachable'; });

// The URL is read before anything renders, because render() is one of the things
// that writes it back and would otherwise erase the link that was just opened.
// booted stays false until the form matches the URL, for the same reason.
const linked = readUrl();
render();
booted = true;

if (linked !== undefined) {
  validate(linked || undefined).then(() => {
    if (pendingTab) { show(pendingTab); pendingTab = null; }
  });
}
