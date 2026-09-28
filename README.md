<h1 align="center">gnoplace</h1>

<p align="center">
  <b>One canvas. Everybody paints. Every cell is a transaction.</b><br>
  A 32×32 shared pixel canvas living in 512 bytes of realm state.
</p>

<p align="center">
  <a href="https://github.com/moul/gnoplace/actions/workflows/ci.yml"><img src="https://github.com/moul/gnoplace/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://gnoscope.com/realm/r/moul/gnoplace"><img src="https://gnoscope.com/_badges/shield/status/r/moul/gnoplace?network=mainnet" alt="realm status on mainnet"></a>
  <a href="./CHECKLIST.md"><img src="https://img.shields.io/badge/web2.5-checklist-0083c7" alt="checklist"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-97ca00.svg" alt="License"></a>
</p>

> **This is an exploration, not a product.** One of four small applications written to
> answer a single question: *what does a web2.5 application on gno.land actually have to get
> right?* This one stresses **write volume and cost**. The decisions are the point, and they
> are written down in **[CHECKLIST.md](./CHECKLIST.md)**.

### ▶ [Paint on it](https://moul.github.io/gnoplace/) &nbsp;·&nbsp; [The realm in gnoweb](https://gno.land/r/moul/gnoplace) &nbsp;·&nbsp; [The checklist](./CHECKLIST.md)

---

## The shape

```
p/moul/gnoplace/v0      the canvas: cells, packing, drawing. no chain import.
r/moul/gnoplace         who may paint, how often, and what the world sees.
r/moul/preview/gnoplace the same source at a second path, private = true. generated.
web/                    a static page. no build step, no node_modules.
```

**One packed value, not a tree of cells.** 512 bytes, two cells per byte, rewritten whole
on every paint. The obvious alternative touches one small object per paint, which sounds
cheaper and is not: a thousand painted cells would be a thousand persisted objects and a
thousand storage deposits, against one value whose size never changes.

**The picture costs nothing to store.** It is an SVG drawn at read time and inlined as a
data URI, run-length encoded along each row: a blank canvas is one rectangle, and a drawing
costs what it looks like rather than what the grid is. `Rects()` reports the number, so the
saving is a measurement and not a claim.

**The rate limit is honest about being weak.** One address paints every 3 blocks; a second
address bypasses it completely. That is stated on the realm's own page and pinned by a test,
because a mechanism that looks like security and is not is worse than an admitted gap.

## Running it

```sh
make         # the list
make ci      # guards, lint, test: exactly what CI runs
make dev     # a local chain with these packages, at http://127.0.0.1:8888
make web     # the front-end at http://127.0.0.1:8080
make repin   # regenerate the pinned Render output, then read the diff
```

## What it does not do

**No ownership, no history per cell.** You cannot ask who painted a given cell three days
ago; only the last 24 strokes are kept. Per-cell history is one object per cell per paint,
which is precisely the cost this repository exists to avoid.

**No fee, no stake, no allowlist.** See the cooldown note above.

## The other three

Same checklist, different pressure: [gno4](https://github.com/moul/gno4) (the chain as
referee), [gnordle](https://github.com/moul/gnordle) (hidden state on a transparent chain),
[gnosnake](https://github.com/moul/gnosnake) (a score the chain recomputes rather than
believes).
