// The canvas, in the browser: the same encoding the realm stores, so a page can
// draw the whole thing from one string and needs no decoder of its own.
export const SIZE = 32;
export const COLORS = [
  "#ffffff", "#e4e4e4", "#888888", "#222222",
  "#ffa7d1", "#e50000", "#e59500", "#a06a42",
  "#e5d900", "#94e044", "#02be01", "#00d3dd",
  "#0083c7", "#0000ea", "#cf6ee4", "#820080",
];

export const empty = () => "0".repeat(SIZE * SIZE);

// decode returns an array of colour indexes, or null. It is strict for the same
// reason the gno package is: a canvas that is nearly the right length would
// otherwise draw as a picture that is subtly wrong, which is worse than an error.
export function decode(s) {
  if (typeof s !== "string" || s.length !== SIZE * SIZE) return null;
  const out = new Uint8Array(SIZE * SIZE);
  for (let i = 0; i < s.length; i++) {
    const v = parseInt(s[i], 16);
    if (Number.isNaN(v) || s[i] !== v.toString(16)) return null; // lowercase only
    out[i] = v;
  }
  return out;
}

export const at = (cells, x, y) =>
  x < 0 || x >= SIZE || y < 0 || y >= SIZE ? 0 : cells[y * SIZE + x];

export function encode(cells) {
  let s = "";
  for (const v of cells) s += v.toString(16);
  return s;
}

export function painted(cells) {
  let n = 0;
  for (const v of cells) if (v !== 0) n++;
  return n;
}
