// Composites the transparent FixNow icon over an opaque background color and
// writes a full-bleed square PNG (used for iOS / legacy Android / web / desktop).
// Usage: node tool/make_icon_bg.mjs <input.png> <output.png> [#RRGGBB]
import { readFileSync, writeFileSync } from 'node:fs';
import { inflateSync, deflateSync } from 'node:zlib';

const [input, output, hexColor] = process.argv.slice(2);

const buf = readFileSync(input);
let pos = 8;
let ihdr = null;
const idat = [];
while (pos < buf.length) {
  const len = buf.readUInt32BE(pos);
  const type = buf.toString('ascii', pos + 4, pos + 8);
  const data = buf.subarray(pos + 8, pos + 8 + len);
  if (type === 'IHDR') {
    ihdr = {
      width: data.readUInt32BE(0),
      height: data.readUInt32BE(4),
      bitDepth: data[8],
      colorType: data[9],
      interlace: data[12],
    };
  } else if (type === 'IDAT') {
    idat.push(data);
  } else if (type === 'IEND') {
    break;
  }
  pos += 12 + len;
}
if (ihdr.bitDepth !== 8 || ihdr.colorType !== 6 || ihdr.interlace !== 0) {
  console.error('Expected 8-bit RGBA non-interlaced PNG');
  process.exit(1);
}

const raw = inflateSync(Buffer.concat(idat));
const { width: w, height: h } = ihdr;
const stride = w * 4;
const pixels = Buffer.alloc(stride * h);
let prev = Buffer.alloc(stride);
let off = 0;
for (let y = 0; y < h; y++) {
  const filter = raw[off++];
  const line = raw.subarray(off, off + stride);
  off += stride;
  const cur = Buffer.alloc(stride);
  for (let x = 0; x < stride; x++) {
    const a = x >= 4 ? cur[x - 4] : 0;
    const b = prev[x];
    const c = x >= 4 ? prev[x - 4] : 0;
    let v = line[x];
    switch (filter) {
      case 1: v = (v + a) & 255; break;
      case 2: v = (v + b) & 255; break;
      case 3: v = (v + ((a + b) >> 1)) & 255; break;
      case 4: {
        const p = a + b - c;
        const pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        v = (v + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c)) & 255;
        break;
      }
      default: break;
    }
    cur[x] = v;
  }
  cur.copy(pixels, y * stride);
  prev = cur;
}

// Background color: CLI arg, else dominant blue from the icon's top area.
let bg;
if (hexColor) {
  const m = hexColor.replace('#', '');
  bg = [parseInt(m.slice(0, 2), 16), parseInt(m.slice(2, 4), 16), parseInt(m.slice(4, 6), 16)];
} else {
  // Average opaque pixels of the top band (icon background gradient there).
  let r = 0, g = 0, b = 0, n = 0;
  for (let y = Math.floor(h * 0.05); y < Math.floor(h * 0.12); y++) {
    for (let x = Math.floor(w * 0.2); x < Math.floor(w * 0.8); x++) {
      const i = y * stride + x * 4;
      if (pixels[i + 3] > 200) {
        // Skip strongly non-blue pixels (orange roof / white pin).
        const pr = pixels[i], pg = pixels[i + 1], pb2 = pixels[i + 2];
        if (pb2 > pr && pb2 > pg) {
          r += pr; g += pg; b += pb2; n++;
        }
      }
    }
  }
  bg = n ? [Math.round(r / n), Math.round(g / n), Math.round(b / n)] : [2, 64, 172];
}
console.log('Background color:', '#' + bg.map((v) => v.toString(16).padStart(2, '0')).join('').toUpperCase());

// Composite over background (premultiplied-safe source-over).
for (let i = 0; i < pixels.length; i += 4) {
  const a = pixels[i + 3] / 255;
  pixels[i] = Math.round(pixels[i] * a + bg[0] * (1 - a));
  pixels[i + 1] = Math.round(pixels[i + 1] * a + bg[1] * (1 - a));
  pixels[i + 2] = Math.round(pixels[i + 2] * a + bg[2] * (1 - a));
  pixels[i + 3] = 255;
}

// Encode PNG (filter 0 per scanline).
const crcTable = [];
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  crcTable[n] = c >>> 0;
}
function crc32(b) {
  let c = 0xffffffff;
  for (let i = 0; i < b.length; i++) c = crcTable[(c ^ b[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  out.write(type, 4, 'ascii');
  data.copy(out, 8);
  out.writeUInt32BE(crc32(Buffer.concat([Buffer.from(type, 'ascii'), data])), 8 + data.length);
  return out;
}

const ihdrData = Buffer.alloc(13);
ihdrData.writeUInt32BE(w, 0);
ihdrData.writeUInt32BE(h, 4);
ihdrData[8] = 8; // bit depth
ihdrData[9] = 6; // RGBA
const scan = Buffer.alloc((stride + 1) * h);
for (let y = 0; y < h; y++) {
  scan[y * (stride + 1)] = 0; // filter: none
  pixels.copy(scan, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
}
const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdrData),
  chunk('IDAT', deflateSync(scan, { level: 9 })),
  chunk('IEND', Buffer.alloc(0)),
]);
writeFileSync(output, png);
console.log('Wrote', output, `(${w}x${h}, opaque)`);
