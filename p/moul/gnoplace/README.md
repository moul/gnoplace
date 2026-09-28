# `gno.land/p/moul/gnoplace/v0`

**A shared pixel canvas, as data and drawing only**: `New`, `Set`, `At`, `Encode`, `Decode`, `SVG`, `Image`.

```go
import "gno.land/p/moul/gnoplace/v0"

c := gnoplace.New()
c.Set(3, 4, 7)      // x, y, palette index
c.Encode()          // -> 1024 hex digits: the whole canvas, as a string
c.Image("canvas")   // -> ![canvas](data:image/svg+xml;base64,...)
```

32 by 32 cells, 16 colours. Who may paint, how often and what it costs are not here: this
package imports no chain package and has no idea a block exists.

**One packed value, not a tree of cells.** The canvas is 512 bytes, two cells per byte,
rewritten whole on every paint. A tree keyed by `"x,y"` would touch one small object per
paint instead, which sounds cheaper and is not: a thousand painted cells is a thousand
persisted objects and a thousand storage deposits, against one value whose size never
changes. The tree only wins once the canvas is large enough that the rewrite hurts more
than the objects do, and at 32x32 it is nowhere near.

**32 is a cost decision, not an aesthetic one.** At 64 the stored value is 2 KB and the
rewrite starts to dominate what a paint costs.

Three behaviours worth knowing before you use it:

- **Runs, not cells, in the SVG.** One `<rect>` per cell would be 1,024 of them, roughly
  60 KB of markup and 80 KB once base64'd into a data URI, on every page view. Each row is
  run-length encoded instead, so a blank canvas is one rectangle and a drawing costs what
  it looks like. `Rects()` reports the count, so the saving is measurable from a test
  rather than asserted in a comment.
- **`At` returns the background out of range instead of panicking.** Render loops walk past
  the edge on purpose, and a `Render` that panics is a realm page that can never be read
  again.
- **`Decode` is strict.** Wrong length, uppercase hex or a stray character is refused
  rather than drawn approximately, because a canvas that is subtly wrong is worse than an
  error.

Live demo: [r/moul/gnoplace](/r/moul/gnoplace).
