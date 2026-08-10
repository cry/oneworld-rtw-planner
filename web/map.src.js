/* Source for web/map.js. Build with `npm run map` and commit the result.
 *
 * Draws the validated itinerary as a world map: land outline, graticule, one
 * great-circle arc per segment, one marker per point.
 *
 * There are deliberately no tiles. A slippy map over OpenStreetMap would need
 * the network on every pan, which is the one thing this service is built not to
 * need -- the fonts and the stylesheet are bundled for the same reason -- and
 * street-level tiles carry nothing legible at the only zoom a round-the-world
 * route is ever viewed at. d3-geo plus the Natural Earth 110m land outline is
 * 55 KB of data and renders the whole thing as vectors that scale for free.
 *
 * Equirectangular, cut at the antimeridian. A closed loop around the globe
 * cannot be drawn on a rectangle without one cut somewhere; putting it in the
 * Pacific is where every round-the-world map puts it, and d3-geo does the
 * cutting itself, so a Pacific crossing correctly leaves one edge and re-enters
 * the other rather than drawing a wrong line back across the map.
 */

import { geoEquirectangular, geoPath, geoGraticule } from 'd3-geo';
import { feature } from 'topojson-client';
import topology from 'world-atlas/land-110m.json';

const LAND = feature(topology, topology.objects.land);

// The poles are empty for this purpose, so the frame is cropped to the
// latitudes traffic actually uses. Everything below derives from that, which is
// why there is no fitExtent call: an equirectangular projection is linear in
// both axes, so the numbers can just be stated.
const W = 900;
const NORTH = 80;
const SOUTH = -58;

const rad = d => (d * Math.PI) / 180;
const SCALE = W / (2 * Math.PI);
const H = Math.round(SCALE * (rad(NORTH) - rad(SOUTH)));

const projection = geoEquirectangular()
  .scale(SCALE)
  .translate([W / 2, SCALE * rad(NORTH)]);

const path = geoPath(projection);
const graticule = geoGraticule().step([30, 30]);

const NS = 'http://www.w3.org/2000/svg';

function el(name, attrs = {}) {
  const node = document.createElementNS(NS, name);
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  return node;
}

// A two-point LineString, not a polyline: d3-geo resamples it along the
// geodesic, so this is the great circle the aircraft actually flies rather than
// a straight line in projected space.
const arc = (a, b) => ({
  type: 'LineString',
  coordinates: [[a.lon, a.lat], [b.lon, b.lat]]
});

// Origin and final point are termini rather than intermediate points, and the
// server only classifies what lies between segments -- so anything without a
// matching point is one end of the journey.
function stops(ann) {
  const segs = ann.segments || [];
  if (!segs.length) return [];
  const points = ann.points || [];
  const kindAfter = n => (points.find(p => p.afterSegment === n) || {}).kind || 'terminus';

  return [
    { code: segs[0].from, coords: segs[0].fromCoords, kind: 'terminus' },
    ...segs.map(s => ({ code: s.to, coords: s.toCoords, kind: kindAfter(s.n) }))
  ];
}

/** Render into `container`. Returns false when there is nothing mappable. */
export function draw(container, ann) {
  container.textContent = '';

  const segs = (ann.segments || []).filter(s => s.fromCoords && s.toCoords);
  if (!segs.length) return false;

  const svg = el('svg', {
    viewBox: `0 0 ${W} ${H}`,
    class: 'map',
    role: 'img',
    'aria-label': `Route map: ${stops(ann).map(s => s.code).filter(Boolean).join(', ')}`
  });

  svg.appendChild(el('path', { class: 'map-graticule', d: path(graticule()) }));
  svg.appendChild(el('path', { class: 'map-land', d: path(LAND) }));

  for (const s of segs) {
    const line = el('path', {
      class: s.type === 'surface' ? 'map-arc is-surface' : 'map-arc',
      d: path(arc(s.fromCoords, s.toCoords))
    });
    line.appendChild(el('title', {})).textContent =
      `${s.from}–${s.to}${s.type === 'surface' ? ' (surface sector)' : ''}`;
    svg.appendChild(line);
  }

  // Labels are placed greedily and skipped where they would collide, so a dense
  // corner of the map stays readable. Transfers go unlabelled first: the code is
  // in the table beside this, and a stopover is the thing worth finding.
  const marks = el('g');
  const labels = el('g');
  const placed = [];

  for (const stop of stops(ann)) {
    if (!stop.coords) continue;
    const xy = projection([stop.coords.lon, stop.coords.lat]);
    if (!xy) continue;
    const [x, y] = xy;

    const dot = el('circle', {
      class: `map-stop is-${stop.kind}`,
      cx: x.toFixed(1),
      cy: y.toFixed(1),
      r: stop.kind === 'transfer' ? 2.5 : 4,
      'data-airport': stop.code || ''
    });
    dot.appendChild(el('title', {})).textContent = `${stop.code} — ${stop.kind}`;
    marks.appendChild(dot);

    if (stop.kind === 'transfer') continue;
    if (placed.some(([px, py]) => Math.abs(px - x) < 46 && Math.abs(py - y) < 14)) continue;
    placed.push([x, y]);

    const text = el('text', {
      class: 'map-label',
      x: (x + 7).toFixed(1),
      y: (y - 6).toFixed(1),
      'data-airport': stop.code || ''
    });
    text.textContent = stop.code;
    labels.appendChild(text);
  }

  svg.appendChild(marks);
  svg.appendChild(labels);
  container.appendChild(svg);
  return true;
}
