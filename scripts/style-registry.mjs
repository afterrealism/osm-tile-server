import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
export const baseStylesRoot = join(repoRoot, 'base-styles');
export const v4SourcesRoot = join(repoRoot, 'data', 'v4-sources');

export const STYLES = [
  { name: 'standard', upstream: 'osm-bright', sprites: { type: 'build', icons: 'osm-bright/icons' } },
  { name: 'light', upstream: 'positron', sprites: { type: 'build', icons: 'positron/icons' } },
  { name: 'dark', upstream: 'dark-matter', sprites: { type: 'build', icons: 'dark-matter/icons' } },
  { name: 'natural', upstream: 'osm-bright', sprites: { type: 'build', icons: 'osm-bright/icons' }, recolor: 'natural' },
  { name: 'basic', upstream: 'maptiler-basic', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  { name: 'toner', upstream: 'maptiler-toner', sprites: { type: 'build', icons: 'maptiler-toner/icons' } },
  { name: 'fiord', upstream: 'fiord-color', sprites: { type: 'build', icons: 'fiord-color/icons' } },
  {
    name: 'liberty',
    upstream: 'osm-liberty',
    sprites: { type: 'prebuilt', prefix: 'osm-liberty/sprites/osm-liberty' },
    dropSources: ['natural_earth_shaded_relief'],
  },
  {
    name: 'openstreetmap',
    upstream: 'maptiler-openstreetmap',
    sprites: { type: 'prebuilt', prefix: 'maptiler-openstreetmap/sprite' },
  },
  { name: 'base', v4: 'base-v4', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  { name: 'backdrop', v4: 'backdrop-v4', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  { name: 'dataviz', v4: 'dataviz-v4', sprites: { type: 'build', icons: 'maptiler-basic/icons' } },
  {
    name: 'streets',
    v4: 'streets-v4',
    keepIcons: true,
    dropLayerIds: ['Airport gate labels'],
    sprites: { type: 'prebuilt', prefix: 'v4-assets/streets/sprite' },
  },
  {
    name: 'aquarelle',
    v4: 'aquarelle-v4',
    sprites: { type: 'prebuilt', prefix: 'v4-assets/aquarelle/sprite' },
  },
  {
    name: 'toner2',
    upstream: 'maptiler-toner2',
    sprites: { type: 'prebuilt', prefix: 'v4-assets/toner2/sprite' },
  },
];

export const STYLE_NAMES = STYLES.map((style) => style.name);
