import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

const root = process.env.STYLE_ASSET_ROOT ?? 'data/style-assets';

function readStyle(name) {
  return JSON.parse(readFileSync(join(root, name, 'style.json'), 'utf8'));
}

for (const name of ['light', 'dark', 'natural']) {
  test(`${name} style is fully local`, () => {
    const style = readStyle(name);
    assert.equal(style.sources.openmaptiles.url, 'mbtiles://openmaptiles.mbtiles');
    assert.equal(style.glyphs, '{fontstack}/{range}.pbf');
    assert.equal(style.sprite, '{styleJsonFolder}/sprite');
    assert.doesNotMatch(JSON.stringify(style), /https?:\/\/|\{key\}|maptiler/i);
  });
}

test('natural style has the green terrain palette', () => {
  const style = readStyle('natural');
  assert.equal(style.name, 'Natural');
  const paint = Object.fromEntries(style.layers.map((layer) => [layer.id, layer.paint ?? {}]));
  assert.equal(paint.background['background-color'], '#e8eadf');
  assert.equal(paint['landcover-wood']['fill-color'], '#b8d3a7');
  assert.equal(paint['landcover-grass']['fill-color'], '#cfe1b9');
  assert.equal(paint.water['fill-color'], '#8fc5d8');
});
