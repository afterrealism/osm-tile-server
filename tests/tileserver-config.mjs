import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const config = JSON.parse(readFileSync('themes/config.json', 'utf8'));

test('exactly three styles, all raster-rendered from local files', () => {
  assert.deepEqual(Object.keys(config.styles).sort(), ['dark', 'light', 'natural']);
  for (const style of Object.values(config.styles)) {
    assert.equal(style.serve_rendered, true);
    assert.doesNotMatch(JSON.stringify(style), /https?:\/\//);
  }
});

test('data source is the local openmaptiles archive', () => {
  assert.deepEqual(config.data.openmaptiles.mbtiles, 'openmaptiles.mbtiles');
});

test('front page disabled and hosts restricted', () => {
  assert.equal(config.options.frontPage, false);
  assert.equal(config.options.allowedHosts, 'localhost');
});
