import { mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const assetRoot = process.env.STYLE_ASSET_ROOT ?? join(repoRoot, 'data/style-assets');

const styles = {
  standard: 'osm-bright',
  light: 'positron',
  dark: 'dark-matter',
  natural: 'osm-bright',
};
const styleNames = ['standard', 'light', 'dark', 'natural'];
const sourceUrl = 'pmtiles://openmaptiles';

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

for (const name of styleNames) {
  const upstream = styles[name];
  if (!upstream) {
    throw new Error(`unknown style: ${name}`);
  }
  const sourcePath = join(repoRoot, 'base-styles', upstream, 'style.json');
  const style = JSON.parse(readFileSync(sourcePath, 'utf8'));

  style.sources.openmaptiles.url = sourceUrl;
  style.glyphs = '{fontstack}/{range}.pbf';
  style.sprite = '{styleJsonFolder}/sprite';

  if (name === 'natural') {
    style.name = 'Natural';
    const layers = Object.fromEntries(style.layers.map((layer) => [layer.id, layer]));
    for (const [layerId, paint] of Object.entries(naturalPaint)) {
      if (!layers[layerId]) {
        throw new Error(`natural override layer id missing from osm-bright: ${layerId}`);
      }
      layers[layerId].paint = { ...(layers[layerId].paint ?? {}), ...paint };
    }
  }

  const targetDir = join(assetRoot, name);
  mkdirSync(targetDir, { recursive: true });
  writeAtomic(join(targetDir, 'style.json'), `${JSON.stringify(style, null, 2)}\n`);
  console.log(`prepared ${name} from ${upstream}`);
}
