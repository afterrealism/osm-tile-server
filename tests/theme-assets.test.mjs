import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import { STYLE_NAMES } from '../scripts/style-registry.mjs';

const root = mkdtempSync(join(tmpdir(), 'theme-assets-'));
test.after(() => rmSync(root, { recursive: true, force: true }));
execFileSync(process.execPath, ['scripts/prepare-theme-assets.mjs'], {
  env: { ...process.env, STYLE_ASSET_ROOT: root },
});

function readStyle(name) {
  return JSON.parse(readFileSync(join(root, name, 'style.json'), 'utf8'));
}

for (const name of STYLE_NAMES) {
  test(`${name} style is fully local`, () => {
    const style = readStyle(name);
    assert.equal(style.sources.openmaptiles.url, 'pmtiles://openmaptiles');
    assert.equal(style.glyphs, '{fontstack}/{range}.pbf');
    assert.equal(style.sprite, '{styleJsonFolder}/sprite');
    assert.doesNotMatch(JSON.stringify(style), /https?:\/\/|\{key\}|maptiler/i);
  });
}

test('standard style preserves the OSM Bright palette', () => {
  const standard = readStyle('standard');
  const standardPaint = Object.fromEntries(
    standard.layers.map((layer) => [layer.id, layer.paint ?? {}]),
  );
  assert.equal(standardPaint.background['background-color'], '#f8f4f0');
  assert.equal(standardPaint['landcover-wood']['fill-color'], '#6a4');
});

test('natural style has the green terrain palette', () => {
  const style = readStyle('natural');
  assert.equal(style.name, 'Natural');
  const paint = Object.fromEntries(style.layers.map((layer) => [layer.id, layer.paint ?? {}]));
  assert.equal(paint.background['background-color'], '#e8eadf');
  assert.equal(paint['landcover-wood']['fill-color'], '#b8d3a7');
  assert.equal(paint['landcover-grass']['fill-color'], '#cfe1b9');
  assert.equal(paint.water['fill-color'], '#8fc5d8');
});
