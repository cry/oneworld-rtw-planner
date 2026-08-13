// Contrast check over the palette in app.src.css. Run with `npm run check:contrast`.
//
// The tokens are duplicated here rather than parsed out of the CSS, which is a real
// cost: in app.src.css each colour is one light-dark(light, dark) pair, and both
// halves also appear in the two tables below. It buys a check that runs without a
// browser, a build, or a CSS parser, and the duplication fails loudly -- a token
// edited in one place and not the other shows up as a ratio that moved for no
// reason. Values are OKLCH [L, C, H], converted to sRGB and scored by WCAG 2.2.
//
// Targets: 4.5:1 for text (1.4.3), 3:1 for the boundary of a control and for the
// focus ring (1.4.11). Row hairlines are decorative and only checked for being
// visible at all.
const oklch2srgb = (L, C, H) => {
  const h = H * Math.PI / 180, a = C * Math.cos(h), b = C * Math.sin(h);
  const l_ = L + 0.3963377774*a + 0.2158037573*b;
  const m_ = L - 0.1055613458*a - 0.0638541728*b;
  const s_ = L - 0.0894841775*a - 1.2914855480*b;
  const l = l_**3, m = m_**3, s = s_**3;
  const lin = [
    +4.0767416621*l - 3.3077115913*m + 0.2309699292*s,
    -1.2684380046*l + 2.6097574011*m - 0.3413193965*s,
    -0.0041960863*l - 0.7034186147*m + 1.7076147010*s,
  ];
  return lin.map(v => Math.max(0, Math.min(1, v)));
};
const lum = ([r,g,b]) => 0.2126*r + 0.7152*g + 0.0722*b;
const ratio = (a, b) => { const [x,y] = [lum(a)+0.05, lum(b)+0.05].sort((p,q)=>q-p); return x/y; };

const LIGHT = {
  canvas:[0.972,0.004,255], panel:[0.995,0.002,255], sunken:[0.955,0.006,255],
  ink:[0.25,0.022,255], muted:[0.512,0.021,255], rule:[0.871,0.009,255],
  ruleStrong:[0.789,0.013,255], fieldLine:[0.665,0.014,255], accent:[0.47,0.14,252],
  ok:[0.478,0.117,155], err:[0.492,0.192,27], warn:[0.474,0.104,65], indet:[0.462,0.116,295],
  okWash:[0.955,0.028,155], errWash:[0.958,0.024,27], warnWash:[0.962,0.032,80], indetWash:[0.957,0.021,295],
};
const DARK = {
  canvas:[0.185,0.012,255], panel:[0.225,0.014,255], sunken:[0.163,0.011,255],
  ink:[0.928,0.008,255], muted:[0.672,0.016,255], rule:[0.341,0.016,255],
  ruleStrong:[0.407,0.019,255], fieldLine:[0.513,0.016,255], accent:[0.775,0.115,250],
  ok:[0.812,0.145,158], err:[0.762,0.135,27], warn:[0.822,0.125,78], indet:[0.795,0.105,297],
  okWash:[0.278,0.043,158], errWash:[0.288,0.055,27], warnWash:[0.283,0.043,78], indetWash:[0.282,0.043,297],
};

// [foreground, background, minimum, what it is]
const PAIRS = [
  ['ink','panel',4.5,'body text'], ['ink','canvas',4.5,'body on canvas'],
  ['muted','panel',4.5,'labels, hints, evidence'], ['muted','canvas',4.5,'muted on canvas'],
  ['muted','sunken',4.5,'muted in code blocks'],
  ['ink','sunken',4.5,'text on a hovered quiet control'],
  ['accent','panel',4.5,'links, active tab, stopover'],
  ['err','errWash',4.5,'INVALID on its wash'], ['ok','okWash',4.5,'VALID on its wash'],
  ['indet','indetWash',4.5,'INDETERMINATE on its wash'], ['warn','warnWash',4.5,'warning on its wash'],
  ['err','panel',4.5,'error severity label'], ['warn','panel',4.5,'warning severity label'],
  ['indet','panel',4.5,'indeterminate label'], ['ok','panel',4.5,'ok text'],
  ['fieldLine','panel',3,'input + select borders (WCAG 1.4.11)'],
  ['muted','canvas',3,'the floating back-to-form button, whose edge is all that bounds it'],
  ['ruleStrong','panel',1.8,'column header rules'],
  ['rule','panel',1.4,'row hairlines (decorative)'],
  ['accent','panel',3,'focus ring (WCAG 1.4.11)'],
];

for (const [name, T] of [['LIGHT', LIGHT], ['DARK', DARK]]) {
  console.log(`\n=== ${name}`);
  for (const [fg, bg, min, what] of PAIRS) {
    const r = ratio(oklch2srgb(...T[fg]), oklch2srgb(...T[bg]));
    const ok = r >= min;
    console.log(`${ok ? ' ok ' : 'FAIL'} ${r.toFixed(2).padStart(6)} (min ${min})  ${fg} on ${bg} — ${what}`);
  }
}

const failures = [];
for (const [name, T] of [['light', LIGHT], ['dark', DARK]]) {
  for (const [fg, bg, min] of PAIRS) {
    if (ratio(oklch2srgb(...T[fg]), oklch2srgb(...T[bg])) < min) failures.push(`${name}: ${fg} on ${bg}`);
  }
}
if (failures.length) {
  console.error(`\n${failures.length} pair(s) below target: ${failures.join(', ')}`);
  process.exit(1);
}
console.log('\nAll pairs meet their target.');
