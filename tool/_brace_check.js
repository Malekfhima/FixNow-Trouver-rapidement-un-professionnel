const fs = require('fs');
const file = process.argv[2];
const src = fs.readFileSync(file, 'utf8');
let i = 0, line = 1;
const stack = [];
let mode = null;
const BS = String.fromCharCode(92);

while (i < src.length) {
  const c = src[i], n = src[i + 1];
  if (c === '\n') { line++; if (mode === 'lc') mode = null; i++; continue; }
  if (mode === 'lc') { i++; continue; }
  if (mode === 'bc') { if (c === '*' && n === '/') { mode = null; i += 2; continue; } i++; continue; }
  if (mode === 'sq' || mode === 'dq' || mode === 'tpl') {
    if (c === BS) { i += 2; continue; }
    if (mode === 'sq' && c === "'") mode = null;
    else if (mode === 'dq' && c === '"') mode = null;
    else if (mode === 'tpl' && c === '`') mode = null;
    i++; continue;
  }
  if (c === '/' && n === '/') { mode = 'lc'; i += 2; continue; }
  if (c === '/' && n === '*') { mode = 'bc'; i += 2; continue; }
  if (c === "'") { mode = 'sq'; i++; continue; }
  if (c === '"') { mode = 'dq'; i++; continue; }
  if (c === '`') { mode = 'tpl'; i++; continue; }
  if (c === '(' || c === '{' || c === '[') stack.push([c, line]);
  if (c === ')' || c === '}' || c === ']') {
    const top = stack.pop();
    if (!top) console.log('EXTRA close', c, 'line', line);
  }
  i++;
}
console.log('unclosed:', JSON.stringify(stack.slice(-10)));
console.log('mode at end:', mode);
