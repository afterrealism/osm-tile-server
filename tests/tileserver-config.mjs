import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import { STYLE_NAMES } from '../scripts/style-registry.mjs';

const config = JSON.parse(readFileSync('themes/config.json', 'utf8'));
const cloudConfig = JSON.parse(readFileSync('gcp/config.template.json', 'utf8'));

test('all registry styles are raster-rendered from local files', () => {
  assert.deepEqual(Object.keys(config.styles).sort(), [...STYLE_NAMES].sort());
  for (const style of Object.values(config.styles)) {
    assert.equal(style.serve_rendered, true);
    assert.doesNotMatch(JSON.stringify(style), /https?:\/\//);
  }
});

test('cloud template matches the style registry', () => {
  assert.deepEqual(Object.keys(cloudConfig.styles).sort(), [...STYLE_NAMES].sort());
});

test('cloud renderer pools match production request concurrency', () => {
  assert.equal(cloudConfig.options.maxScaleFactor, 1);
  assert.deepEqual(cloudConfig.options.minRendererPoolSizes, [1]);
  assert.deepEqual(cloudConfig.options.maxRendererPoolSizes, [4]);
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
