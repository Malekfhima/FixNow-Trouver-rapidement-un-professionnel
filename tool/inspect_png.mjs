// Quick PNG inspector: prints IHDR info + sample pixels (corner, center-edge background).
import { readFileSync } from 'node:fs';
import { inflateSync } from 'node:zlib';

const buf = readFileSync(process.argv[2]);
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
console.log('IHDR', JSON.stringify(ihdr));

if (ihdr.bitDepth !== 8 || ihdr.interlace !== 0) {
  console.log('Unsupported format for manual decode');
  process.exit(0);
}
const channels = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[ihdr.colorType];
if (!channels) {
  console.log('Unknown color type');
  process.exit(0);
}
const raw = inflateSync(Buffer.concat(idat));
const stride = ihdr.width * channels;
const pixels = Buffer.alloc(stride * ihdr.height);
let prev = Buffer.alloc(stride);
let off = 0;
for (let y = 0; y < ihdr.height; y++) {
  const filter = raw[off++];
  const line = raw.subarray(off, off + stride);
  off += stride;
  const cur = Buffer.alloc(stride);
  for (let x = 0; x < stride; x++) {
    const a = x >= channels ? cur[x - channels] : 0;
    const b = prev[x];
    const c = x >= channels ? prev[x - channels] : 0;
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
function px(x, y) {
  const i = y * stride + x * channels;
  if (ihdr.colorType === 6) return [pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3]];
  if (ihdr.colorType === 2) return [pixels[i], pixels[i + 1], pixels[i + 2], 255];
  if (ihdr.colorType === 0) return [pixels[i], pixels[i], pixels[i], 255];
  if (ihdr.colorType === 4) return [pixels[i], pixels[i], pixels[i], pixels[i + 1]];
  return [pixels[i], pixels[i], pixels[i], 255];
}
const w = ihdr.width, h = ihdr.height;
console.log('corner(2,2)      ', px(2, 2));
console.log('corner(w-3,h-3)  ', px(w - 3, h - 3));
console.log('edge-mid-left    ', px(4, h >> 1));
console.log('bg sample 15%,50%', px(Math.floor(w * 0.15), h >> 1));
console.log('bg sample 50%,12%', px(w >> 1, Math.floor(h * 0.12)));
console.log('center           ', px(w >> 1, h >> 1));
