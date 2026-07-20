import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const config = JSON.parse(readFileSync('themes/config.json', 'utf8'));

test('exactly four styles, all raster-rendered from local files', () => {
  assert.deepEqual(Object.keys(config.styles).sort(), ['dark', 'light', 'natural', 'standard']);
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
