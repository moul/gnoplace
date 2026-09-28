package gnoplace

import (
	"strings"
	"testing"

	"gno.land/p/nt/uassert/v0"
)

// fixture paints a small deterministic drawing.
//
// Deterministic is the operative word: Render reads no current height and no
// clock, only heights recorded by the paints themselves, so the same fixture
// always produces the same bytes and the pins can be exact.
func fixture(cur realm, t *testing.T) {
	t.Helper()
	reset()
	for i, s := range []struct {
		by         address
		x, y, c    int
	}{
		{alice, 4, 4, 5}, {bob, 5, 4, 5}, {alice, 6, 4, 5},
		{bob, 4, 5, 13}, {alice, 6, 5, 13}, {bob, 5, 6, 9},
	} {
		testing.SetRealm(testing.NewUserRealm(s.by))
		if i > 0 {
			testing.SkipHeights(Cooldown)
		}
		Paint(cross(cur), s.x, s.y, s.c)
	}
}

func pinnedPaths() []string {
	return []string{"", "u/" + alice.String(), "about", "nope"}
}

// renderForPin strips the inline canvas, which is base64 and would make the pin
// unreadable. The SVG is asserted by shape in the engine's own tests; what is
// pinned here is the page this realm writes around it.
func renderForPin(path string) string {
	out := Render(path)
	start := strings.Index(out, "![")
	if start < 0 {
		return out
	}
	end := strings.Index(out[start:], ")")
	if end < 0 {
		return out
	}
	return out[:start] + "<canvas>" + out[start+end+1:]
}

type pinnedPage struct{ path, want string }

// pinnedPages is generated: `make repin` rewrites it from what Render actually
// produces, and the diff is the review. A gno raw string literal cannot contain
// a backtick and these pages contain fenced code, so {BT} stands in for one.
var pinnedPages = []pinnedPage{
	{"", `# The canvas

<canvas>

**6** of 1024 cells painted, by **2** people, in **6** strokes.

Every cell is a transaction. One address may paint once every 3 blocks, which a second address bypasses completely: it is a speed bump, not a defence, and saying so is more useful than pretending otherwise.

## The palette
| | colour | paint |
|---|---|---|
| 0 | {BT}#ffffff{BT} | [use 0](/r/moul/gnoplace$help&func=Paint&color=0&x=0&y=0) |
| 1 | {BT}#e4e4e4{BT} | [use 1](/r/moul/gnoplace$help&func=Paint&color=1&x=0&y=0) |
| 2 | {BT}#888888{BT} | [use 2](/r/moul/gnoplace$help&func=Paint&color=2&x=0&y=0) |
| 3 | {BT}#222222{BT} | [use 3](/r/moul/gnoplace$help&func=Paint&color=3&x=0&y=0) |
| 4 | {BT}#ffa7d1{BT} | [use 4](/r/moul/gnoplace$help&func=Paint&color=4&x=0&y=0) |
| 5 | {BT}#e50000{BT} | [use 5](/r/moul/gnoplace$help&func=Paint&color=5&x=0&y=0) |
| 6 | {BT}#e59500{BT} | [use 6](/r/moul/gnoplace$help&func=Paint&color=6&x=0&y=0) |
| 7 | {BT}#a06a42{BT} | [use 7](/r/moul/gnoplace$help&func=Paint&color=7&x=0&y=0) |
| 8 | {BT}#e5d900{BT} | [use 8](/r/moul/gnoplace$help&func=Paint&color=8&x=0&y=0) |
| 9 | {BT}#94e044{BT} | [use 9](/r/moul/gnoplace$help&func=Paint&color=9&x=0&y=0) |
| 10 | {BT}#02be01{BT} | [use 10](/r/moul/gnoplace$help&func=Paint&color=10&x=0&y=0) |
| 11 | {BT}#00d3dd{BT} | [use 11](/r/moul/gnoplace$help&func=Paint&color=11&x=0&y=0) |
| 12 | {BT}#0083c7{BT} | [use 12](/r/moul/gnoplace$help&func=Paint&color=12&x=0&y=0) |
| 13 | {BT}#0000ea{BT} | [use 13](/r/moul/gnoplace$help&func=Paint&color=13&x=0&y=0) |
| 14 | {BT}#cf6ee4{BT} | [use 14](/r/moul/gnoplace$help&func=Paint&color=14&x=0&y=0) |
| 15 | {BT}#820080{BT} | [use 15](/r/moul/gnoplace$help&func=Paint&color=15&x=0&y=0) |

The links above paint the top-left cell. Change {BT}x{BT} and {BT}y{BT} in the form gnoweb opens, or use the front-end, which is a canvas you click.

## Recent strokes
| who | cell | colour | height |
|---|---|---|---|
| [g1vfhkyh…vdhu](/r/moul/gnoplace:u/g1vfhkyh6lta047h6lta047h6lta047h6l03vdhu) | 5,6 | 9 | 138 |
| [g1v9kxjc…40gh](/r/moul/gnoplace:u/g1v9kxjcm9ta047h6lta047h6lta047h6lzd40gh) | 6,5 | 13 | 135 |
| [g1vfhkyh…vdhu](/r/moul/gnoplace:u/g1vfhkyh6lta047h6lta047h6lta047h6l03vdhu) | 4,5 | 13 | 132 |
| [g1v9kxjc…40gh](/r/moul/gnoplace:u/g1v9kxjcm9ta047h6lta047h6lta047h6lzd40gh) | 6,4 | 5 | 129 |
| [g1vfhkyh…vdhu](/r/moul/gnoplace:u/g1vfhkyh6lta047h6lta047h6lta047h6l03vdhu) | 5,4 | 5 | 126 |
| [g1v9kxjc…40gh](/r/moul/gnoplace:u/g1v9kxjcm9ta047h6lta047h6lta047h6lzd40gh) | 4,4 | 5 | 123 |

---
<details><summary>Painting from a terminal</summary>

{BT}{BT}{BT}sh
# paint cell (5,7) in colour 10
gnokey maketx call -pkgpath gno.landr/moul/gnoplace -func Paint -args 5 -args 7 -args 10 \
  -gas-fee 1000000ugnot -gas-wanted 3000000 -broadcast \
  -chainid  -remote https://rpc.gno.land:443 YOURKEY
{BT}{BT}{BT}

That gas number is a starting point, not a measurement. Drop {BT}-broadcast{BT} and the node answers with what the call actually costs.

</details>

[What this realm is exploring](/r/moul/gnoplace:about)
`},
	{"u/g1v9kxjcm9ta047h6lta047h6lta047h6lzd40gh", `# g1v9kxjc…40gh

[g1v9kxjcm9ta047h6lta047h6lta047h6lzd40gh](/u/g1v9kxjcm9ta047h6lta047h6lta047h6lzd40gh)

**3** strokes, the last at height 135.

[Back to the canvas](/r/moul/gnoplace)
`},
	{"about", `# What this realm is exploring

One of four small applications written to answer a single question: **what does a
web2.5 application on gno.land actually have to get right?** This one is the
write-volume corner. Thousands of tiny writes to one shared object, each of them
a transaction somebody pays for.

The canvas is a single packed value, 512 bytes, rewritten on every paint. The
obvious alternative is a tree of cells, where a paint touches one small object
instead of rewriting everything. That sounds cheaper and is not: a thousand
painted cells would be a thousand persisted objects and a thousand storage
deposits, against one value whose size never changes.

The picture you see is drawn at read time and inlined as a data URI, so it costs
no storage at all. It is also run-length encoded along each row, which is the
difference between a page that carries 80 KB of markup and one that carries a
few hundred bytes of it.

There are two deployments of this same source: this one, and a {BT}r/moul/preview/gnoplace{BT}
flagged {BT}private = true{BT} so it stays redeployable while the design
is still moving. A public path can never be redeployed, which makes that flag the
most consequential line in the whole repository.

The repository, the checklist it is written against, and the other three:
[github.com/moul/gnoplace](https://github.com/moul/gnoplace).

[Back to the canvas](/r/moul/gnoplace)
`},
	{"nope", `# Not found

No page at {BT}nope{BT}. [Back to the canvas](/r/moul/gnoplace).
`},
}

func TestRenderIsPinned(cur realm, t *testing.T) {
	fixture(cur, t)
	if len(pinnedPages) != len(pinnedPaths()) {
		t.Fatalf("pins are stale: %d pinned, %d paths. Run `make repin`.",
			len(pinnedPages), len(pinnedPaths()))
	}
	for _, p := range pinnedPages {
		uassert.Equal(t, strings.ReplaceAll(p.want, "{BT}", "\x60"), renderForPin(p.path),
			"page "+p.path+" changed. If you meant it, run `make repin` and read the diff.")
	}
}

func TestRenderAboutMentionsThePrivateFlag(cur realm, t *testing.T) {
	out := Render("about")
	uassert.True(t, strings.Contains(out, "private = true"))
	uassert.True(t, strings.Contains(out, "github.com/moul/gnoplace"))
}
