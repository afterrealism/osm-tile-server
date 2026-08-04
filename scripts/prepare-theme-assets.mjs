import { existsSync, mkdirSync, readFileSync, readdirSync, renameSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { FONT_FAMILIES, STYLES, baseStylesRoot } from './style-registry.mjs';

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const assetRoot = process.env.STYLE_ASSET_ROOT ?? join(repoRoot, 'data/style-assets');

const naturalPaint = {
  background: { 'background-color': '#e8eadf' },
  'landcover-wood': { 'fill-color': '#b8d3a7' },
  'landcover-grass': { 'fill-color': '#cfe1b9' },
  'landcover-grass-park': { 'fill-color': '#c4ddb0' },
  water: { 'fill-color': '#8fc5d8' },
  'landuse-residential': { 'fill-color': '#ddd9cd' },
  building: { 'fill-color': '#c9c1b0' },
  'building-top': { 'fill-color': '#d8d0bf' },
};

function writeAtomic(path, contents) {
  const part = `${path}.part`;
  writeFileSync(part, contents);
  renameSync(part, path);
}

function loadAvailableFonts() {
  const fontsDir = join(assetRoot, 'fonts');
  if (!existsSync(fontsDir)) return null;
  return new Set(readdirSync(fontsDir));
}

function remapFonts(fonts, availableFonts) {
  if (!availableFonts) return fonts;
  const mapped = fonts.filter((f) => availableFonts.has(f));
  if (mapped.length === 0 && availableFonts.size > 0) {
    return [availableFonts.values().next().value];
  }
  return mapped.length > 0 ? mapped : fonts;
}

function prepareVendored(def, availableFonts) {
  const sourcePath = join(baseStylesRoot, def.upstream, 'style.json');
  const style = JSON.parse(readFileSync(sourcePath, 'utf8'));
  const dropped = new Set(def.dropSources ?? []);
  style.layers = style.layers.filter((layer) => !dropped.has(layer.source));
  for (const layer of style.layers) {
    if (layer.source && layer.source !== 'openmaptiles') layer.source = 'openmaptiles';
  }
  style.sources = { openmaptiles: { type: 'vector', url: 'pmtiles://openmaptiles' } };
  style.glyphs = '{fontstack}/{range}.pbf';
  style.sprite = '{styleJsonFolder}/sprite';
  delete style.metadata;
  for (const layer of style.layers) {
    if (layer.layout?.['text-font']) {
      layer.layout['text-font'] = remapFonts(layer.layout['text-font'], availableFonts);
    }
  }
  if (def.recolor === 'natural') {
    style.name = 'Natural';
    const layers = Object.fromEntries(style.layers.map((layer) => [layer.id, layer]));
    for (const [layerId, paint] of Object.entries(naturalPaint)) {
      if (!layers[layerId]) {
        throw new Error(`natural override layer id missing from osm-bright: ${layerId}`);
      }
      layers[layerId].paint = { ...(layers[layerId].paint ?? {}), ...paint };
    }
  }
  return style;
}

if (process.argv.includes('--plan')) {
  for (const def of STYLES) {
    const sprites = def.sprites;
    const spriteArg = sprites.type === 'build'
      ? join(baseStylesRoot, sprites.icons)
      : join(baseStylesRoot, sprites.prefix);
    const manifestSource = join(baseStylesRoot, def.upstream, 'style.json');
    const localSource = join(baseStylesRoot, def.upstream);
    console.log([def.name, sprites.type, spriteArg, manifestSource, def.upstream, localSource].join('\t'));
  }
} else if (process.argv.includes('--fonts')) {
  for (const family of FONT_FAMILIES) {
    console.log(family);
  }
} else if (process.argv.includes('--config')) {
  const template = JSON.parse(
    readFileSync(join(repoRoot, 'themes/config.options.json'), 'utf8'),
  );
  const config = {
    options: template.options,
    styles: Object.fromEntries(
      STYLES.map((def) => [def.name, {
        style: `${def.name}/style.json`,
        serve_rendered: true,
        serve_data: false,
      }]),
    ),
    data: template.data,
  };
  writeAtomic(join(repoRoot, 'themes/config.json'), `${JSON.stringify(config, null, 2)}\n`);
  console.log('generated themes/config.json');
} else {
  const availableFonts = loadAvailableFonts();
  for (const def of STYLES) {
    const style = prepareVendored(def, availableFonts);
    const targetDir = join(assetRoot, def.name);
    mkdirSync(targetDir, { recursive: true });
    writeAtomic(join(targetDir, 'style.json'), `${JSON.stringify(style, null, 2)}\n`);
    console.log(`prepared ${def.name} from ${def.upstream}`);
  }
}
