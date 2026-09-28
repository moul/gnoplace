# `gno.land/r/moul/gnoplace`

**One canvas. Everybody paints. Every cell is a transaction.**

The canvas is [`p/moul/gnoplace`](/p/moul/gnoplace/v0), which knows nothing about a chain.
This realm owns the three things that package cannot decide: who may paint, how often, and
what the world sees.

This is the **write-volume** corner of the [web2.5
checklist](https://github.com/moul/gnoplace/blob/main/CHECKLIST.md): thousands of tiny
writes to one shared object, each of them a transaction somebody pays for. The drawing is
almost incidental; what is being measured is what a paint costs, what a page view costs,
and which of the two is worth optimising.

**The cooldown is a speed bump, not a defence.** One address may paint every 3 blocks, and
a second address bypasses that entirely. Anything stronger is a policy argument, and the
honest position for an exploration is a limit that costs nothing and is documented as
bypassable rather than a mechanism that looks like security and is not. There is a test
that pins the hole, so it stays documented.

**The activity log is bounded.** 24 strokes, then the oldest falls off. An unbounded log is
a page that renders slower every day and storage nobody ever reclaims.

**No page hardcodes this realm's path.** The same source is deployed here and at
`/preview`, and every link is built from the package path the code is actually running
under.

Pages: the canvas at the root, `:u/<address>` for a painter, `:about` for what the
repository is exploring. `Canvas()` and `Feed()` are the machine-readable views, so the
front-end never has to parse the rendered page.

Source: [github.com/moul/gnoplace](https://github.com/moul/gnoplace).
