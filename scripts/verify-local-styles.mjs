import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { STYLE_NAMES } from './style-registry.mjs';

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const assetRoot = process.env.STYLE_ASSET_ROOT ?? join(repoRoot, 'data/style-assets');

const REQUIRED_FILES = ['sprite.json', 'sprite.png', 'sprite@2x.json', 'sprite@2x.png', 'manifest.json'];
const FORBIDDEN = /https?:\/\/|\{key\}|maptiler/i;

let failures = 0;
const fail = (message) => {
  console.error(`ERROR: ${message}`);
  failures += 1;
};

for (const name of STYLE_NAMES) {
  const dir = join(assetRoot, name);
  const stylePath = join(dir, 'style.json');
  if (!existsSync(stylePath)) {
    fail(`${name}: missing style.json`);
    continue;
  }
  const raw = readFileSync(stylePath, 'utf8');
  if (FORBIDDEN.test(raw)) {
    fail(`${name}: style.json contains a remote URL, {key} placeholder, or maptiler reference`);
  }
  const style = JSON.parse(raw);
  if (style.sources?.openmaptiles?.url !== 'pmtiles://openmaptiles') {
    fail(`${name}: source is not pmtiles://openmaptiles`);
  }
  for (const file of REQUIRED_FILES) {
    if (!existsSync(join(dir, file))) {
      fail(`${name}: missing ${file}`);
    }
  }
  const families = new Set();
  const FONT_NAME = /^(Inter|Noto|Nunito|Rubik|Roboto|Open Sans|Metropolis|PT Sans|Arial|Helvetica)/;
  const collectFonts = (value) => {
    if (typeof value === 'string') {
      if (FONT_NAME.test(value)) families.add(value);
    } else if (Array.isArray(value)) value.forEach(collectFonts);
    else if (value && typeof value === 'object') Object.values(value).forEach(collectFonts);
  };
  for (const layer of style.layers ?? []) {
    collectFonts(layer.layout?.['text-font']);
  }
  for (const family of families) {
    if (!existsSync(join(assetRoot, 'fonts', family, '0-255.pbf'))) {
      fail(`${name}: missing glyphs for font family "${family}" (fonts/${family}/0-255.pbf)`);
    }
  }
}

if (failures > 0) {
  process.exit(1);
}
console.log('all styles are fully local');
