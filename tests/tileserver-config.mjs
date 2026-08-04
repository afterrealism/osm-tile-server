import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import { STYLE_NAMES } from '../scripts/style-registry.mjs';

const config = JSON.parse(readFileSync('themes/config.json', 'utf8'));

test('all registry styles are raster-rendered from local files', () => {
  assert.deepEqual(Object.keys(config.styles).sort(), [...STYLE_NAMES].sort());
  for (const style of Object.values(config.styles)) {
    assert.equal(style.serve_rendered, true);
    assert.doesNotMatch(JSON.stringify(style), /https?:\/\//);
  }
});

test('data source is the local openmaptiles archive', () => {
  assert.equal(config.options.paths.pmtiles, 'openmaptiles');
  assert.equal(config.data.openmaptiles.pmtiles, 'openmaptiles.pmtiles');
  assert.equal(config.data.openmaptiles.mbtiles, undefined);
});

test('front page disabled and hosts restricted', () => {
  assert.equal(config.options.frontPage, false);
  assert.equal(config.options.allowedHosts, 'localhost,127.0.0.1');
});

test('renderer pools are tuned for single-host serving', () => {
  assert.equal(config.options.maxScaleFactor, 1);
  assert.deepEqual(config.options.minRendererPoolSizes, [2]);
  assert.deepEqual(config.options.maxRendererPoolSizes, [8]);
  assert.equal(config.options.serveStaticMaps, false);
});

test('themes/config.json is exactly the registry-generated shape', () => {
  const template = JSON.parse(readFileSync('themes/config.options.json', 'utf8'));
  const expected = {
    options: template.options,
    styles: Object.fromEntries(STYLE_NAMES.map((name) => [name, {
      style: `${name}/style.json`,
      serve_rendered: true,
      serve_data: false,
    }])),
    data: template.data,
  };
  assert.deepEqual(config, expected);
});

test('rendered tiles are CDN-cacheable', () => {
  for (const compose of ['docker-compose.yml', 'tests/docker-compose.yml']) {
    assert.match(
      readFileSync(compose, 'utf8'),
      /TILE_CACHE_CONTROL: "public, max-age=86400, immutable"/,
    );
  }
});
