import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

export const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
export const baseStylesRoot = join(repoRoot, 'base-styles');

export const STYLES = [
  { name: 'atlas', upstream: 'osm-bright', sprites: { type: 'build', icons: 'osm-bright/icons' } },
  { name: 'paper', upstream: 'positron', sprites: { type: 'build', icons: 'positron/icons' } },
  { name: 'onyx', upstream: 'dark-matter', sprites: { type: 'build', icons: 'dark-matter/icons' } },
  { name: 'terra', upstream: 'osm-bright', sprites: { type: 'build', icons: 'osm-bright/icons' }, recolor: 'natural' },
  { name: 'fjord', upstream: 'fiord-color', sprites: { type: 'build', icons: 'fiord-color/icons' } },
  {
    name: 'meridian',
    upstream: 'osm-liberty',
    sprites: { type: 'prebuilt', prefix: 'osm-liberty/sprites/osm-liberty' },
    dropSources: ['natural_earth_shaded_relief'],
  },
];

export const STYLE_NAMES = STYLES.map((style) => style.name);
