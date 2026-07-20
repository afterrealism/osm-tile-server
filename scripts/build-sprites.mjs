import { readdirSync, renameSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { basename, join } from 'node:path';
import process from 'node:process';

const require = createRequire(new URL('../themes/package.json', import.meta.url));
const ShelfPack = require('@mapbox/shelf-pack');
const sharp = require('sharp');

const [output, iconsDir] = process.argv.slice(2).filter((arg) => !arg.startsWith('--'));
const pixelRatio = process.argv.includes('--retina') ? 2 : 1;

if (!output || !iconsDir) {
  console.error('usage: build-sprites.mjs [--retina] OUTPUT ICONS_DIR');
  process.exit(2);
}

const density = 72 * pixelRatio;
const files = readdirSync(iconsDir).filter((file) => file.endsWith('.svg')).sort();

const images = [];
for (const file of files) {
  const buffer = await sharp(join(iconsDir, file), { density }).png().toBuffer();
  const metadata = await sharp(buffer).metadata();
  images.push({
    id: basename(file, '.svg'),
    buffer,
    width: metadata.width,
    height: metadata.height,
  });
}

const shelf = new ShelfPack(1, 1, { autoResize: true });
for (const image of images) {
  image.pack = shelf.packOne(image.width, image.height);
  if (image.pack === -1) {
    throw new Error(`failed to pack icon ${image.id}`);
  }
}

const composites = images.map((image) => ({
  input: image.buffer,
  left: image.pack.x,
  top: image.pack.y,
}));
const png = await sharp({
  create: {
    width: Math.max(shelf.w, 1),
    height: Math.max(shelf.h, 1),
    channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  },
}).composite(composites).png().toBuffer();

const layout = Object.fromEntries(
  images.map((image) => [
    image.id,
    {
      width: image.width,
      height: image.height,
      x: image.pack.x,
      y: image.pack.y,
      pixelRatio,
      sdf: false,
    },
  ]),
);

writeFileSync(`${output}.png.part`, png);
renameSync(`${output}.png.part`, `${output}.png`);
writeFileSync(`${output}.json.part`, `${JSON.stringify(layout, null, 2)}\n`);
renameSync(`${output}.json.part`, `${output}.json`);
console.log(`${output}: ${images.length} icons at ${pixelRatio}x`);
