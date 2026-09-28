// The browser decoder must agree with the gno one, including about what it
// refuses. Run: node web/engine.test.js
import * as e from "./engine.js";

let failures = 0;
const check = (ok, msg) => { if (!ok) { console.error("FAIL", msg); failures++; } };

const blank = e.empty();
check(e.decode(blank) !== null, "the empty canvas decodes");
check(e.painted(e.decode(blank)) === 0, "the empty canvas has nothing painted");
check(e.encode(e.decode(blank)) === blank, "round trip");

const cells = e.decode(blank);
cells[5 * e.SIZE + 3] = 10;
check(e.at(cells, 3, 5) === 10, "at() is x,y with x first");
check(e.painted(cells) === 1, "one painted cell");
check(e.encode(cells).length === e.SIZE * e.SIZE, "the encoding keeps its length");

for (const [name, bad] of [
  ["empty string", ""],
  ["one short", blank.slice(1)],
  ["one long", blank + "0"],
  ["not hex", blank.slice(1) + "z"],
  ["uppercase is not the encoding the realm emits", blank.slice(1) + "A"],
  ["not a string", 12345],
]) check(e.decode(bad) === null, `accepted ${name}`);

check(e.at(cells, -1, 0) === 0 && e.at(cells, e.SIZE, 0) === 0, "out of range reads as background");

console.log(failures === 0 ? "ok  engine.js agrees with the gno encoding" : `FAIL ${failures} check(s)`);
process.exit(failures === 0 ? 0 : 1);
