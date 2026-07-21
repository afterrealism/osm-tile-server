import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
export const baseStylesRoot = join(repoRoot, 'base-styles');
export const v4SourcesRoot = join(repoRoot, 'data', 'v4-sources');

export const STYLES = [
  { name: 'atlas', upstream: 'osm-bright', sprites: { type: 'build', icons: 'osm-bright/icons' } },
  { name: 'paper', upstream: 'positron', sprites: { type: 'build', icons: 'positron/icons' } },
  { name: 'onyx', upstream: 'dark-matter', sprites: { type: 'build', icons: 'dark-matter/icons' } },
  { name: 'terra', upstream: 'osm-bright', sprites: { type: 'build', icons: 'osm-bright/icons' }, recolor: 'natural' },
  { name: 'nova', upstream: 'maptiler-basic', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  { name: 'graphite', upstream: 'maptiler-toner', sprites: { type: 'build', icons: 'maptiler-toner/icons' } },
  { name: 'fjord', upstream: 'fiord-color', sprites: { type: 'build', icons: 'fiord-color/icons' } },
  {
    name: 'meridian',
    upstream: 'osm-liberty',
    sprites: { type: 'prebuilt', prefix: 'osm-liberty/sprites/osm-liberty' },
    dropSources: ['natural_earth_shaded_relief'],
  },
  {
    name: 'community',
    upstream: 'maptiler-openstreetmap',
    sprites: { type: 'prebuilt', prefix: 'maptiler-openstreetmap/sprite' },
  },
  { name: 'canvas', v4: 'base-v4', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  { name: 'mist', v4: 'backdrop-v4', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  { name: 'prism', v4: 'dataviz-v4', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  {
    name: 'avenue',
    v4: 'streets-v4',
    keepIcons: true,
    dropLayerIds: ['Airport gate labels'],
    sprites: { type: 'prebuilt', prefix: 'v4-assets/streets/sprite' },
  },
  {
    name: 'watercolor',
    v4: 'aquarelle-v4',
    sprites: { type: 'prebuilt', prefix: 'v4-assets/aquarelle/sprite' },
  },
  {
    name: 'ink',
    upstream: 'maptiler-toner2',
    sprites: { type: 'prebuilt', prefix: 'v4-assets/toner2/sprite' },
  },
];

export const STYLE_NAMES = STYLES.map((style) => style.name);
