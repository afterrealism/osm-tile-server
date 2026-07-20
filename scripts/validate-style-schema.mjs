import { existsSync, openSync, readSync, readFileSync, readdirSync, closeSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gunzipSync } from 'node:zlib';

import { STYLE_NAMES } from './style-registry.mjs';

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const assetRoot = process.env.STYLE_ASSET_ROOT ?? join(repoRoot, 'data/style-assets');
const pmtilesPath = process.env.OMT_PMTILES ?? join(repoRoot, 'data/openmaptiles/openmaptiles.pmtiles');

function readVectorLayers(path) {
  const fd = openSync(path, 'r');
  const header = Buffer.alloc(127);
  readSync(fd, header, 0, 127, 0);
  if (header.subarray(0, 7).toString() !== 'PMTiles') {
    throw new Error(`${path} is not a PMTiles archive`);
  }
  const metaOffset = Number(header.readBigUInt64LE(24));
  const metaLength = Number(header.readBigUInt64LE(32));
  const raw = Buffer.alloc(metaLength);
  readSync(fd, raw, 0, metaLength, metaOffset);
  closeSync(fd);
  let metadata;
  try {
    metadata = JSON.parse(gunzipSync(raw).toString());
  } catch {
    metadata = JSON.parse(raw.toString());
  }
  return Object.fromEntries(
    metadata.vector_layers.map((layer) => [layer.id, new Set(Object.keys(layer.fields ?? {}))]),
  );
}

function collectRefs(node, gets, hases) {
  if (!Array.isArray(node)) return;
  const [op, ...args] = node;
  if (op === 'get' && typeof args[0] === 'string') gets.add(args[0]);
  if (op === 'has' && typeof args[0] === 'string') hases.add(args[0]);
  for (const arg of args) collectRefs(arg, gets, hases);
}

function legacyTextFields(textField) {
  if (typeof textField !== 'string') return [];
  return [...textField.matchAll(/\{([^}]+)\}/g)].map((match) => match[1]);
}

const vectorLayers = readVectorLayers(pmtilesPath);
const fontsDir = join(assetRoot, 'fonts');
const availableFonts = existsSync(fontsDir) ? new Set(readdirSync(fontsDir)) : new Set();

let errors = 0;
let warnings = 0;
const err = (message) => { console.error(`ERROR: ${message}`); errors += 1; };
const warn = (message) => { console.warn(`WARN: ${message}`); warnings += 1; };

for (const name of STYLE_NAMES) {
  const stylePath = join(assetRoot, name, 'style.json');
  if (!existsSync(stylePath)) {
    err(`${name}: missing style.json`);
    continue;
  }
  const style = JSON.parse(readFileSync(stylePath, 'utf8'));
  let sprite = {};
  const spritePath = join(assetRoot, name, 'sprite.json');
  if (existsSync(spritePath)) sprite = JSON.parse(readFileSync(spritePath, 'utf8'));

  for (const layer of style.layers ?? []) {
    const sourceLayer = layer['source-layer'];
    if (!sourceLayer) continue;
    const fields = vectorLayers[sourceLayer];
    if (!fields) {
      err(`${name}/${layer.id}: source-layer "${sourceLayer}" not present in PMTiles`);
      continue;
    }
    const gets = new Set();
    const hases = new Set();
    collectRefs(layer.filter, gets, hases);
    for (const field of [...gets, ...hases]) {
      if (!fields.has(field)) {
        err(`${name}/${layer.id}: filter references missing field "${sourceLayer}.${field}"`);
      }
    }
    const layout = layer.layout ?? {};
    const textGets = new Set();
    collectRefs(layout['text-field'], textGets, new Set());
    for (const field of [...textGets, ...legacyTextFields(layout['text-field'])]) {
      if (!fields.has(field)) {
        warn(`${name}/${layer.id}: text-field references missing field "${sourceLayer}.${field}"`);
      }
    }
    const fontFamilies = new Set();
    const FONT_NAME = /^(Inter|Noto|Nunito|Rubik|Roboto|Open Sans|Metropolis|PT Sans|Arial|Helvetica)/;
    const collectFonts = (value) => {
      if (typeof value === 'string') {
        if (FONT_NAME.test(value)) fontFamilies.add(value);
      } else if (Array.isArray(value)) value.forEach(collectFonts);
      else if (value && typeof value === 'object') Object.values(value).forEach(collectFonts);
    };
    collectFonts(layout['text-font']);
    for (const family of fontFamilies) {
      if (availableFonts.size > 0 && !availableFonts.has(family)) {
        err(`${name}/${layer.id}: missing glyphs for font family "${family}"`);
      }
    }
    const icon = layout['icon-image'];
    if (typeof icon === 'string' && !icon.includes('{') && Object.keys(sprite).length > 0 && !(icon in sprite)) {
      warn(`${name}/${layer.id}: icon-image "${icon}" not in sprite`);
    }
    const paintGets = new Set();
    collectRefs(layer.paint, paintGets, new Set());
    for (const field of paintGets) {
      if (!fields.has(field)) {
        warn(`${name}/${layer.id}: paint references missing field "${sourceLayer}.${field}"`);
      }
    }
  }
  console.log(`${name}: validated`);
}

if (errors > 0) {
  console.error(`schema validation failed: ${errors} error(s), ${warnings} warning(s)`);
  process.exit(1);
}
console.log(`all styles match the PMTiles schema (${warnings} warning(s))`);
