package gnoplace

import (
	"chain/runtime"
	"chain/runtime/unsafe"
	"strings"

	"gno.land/p/moul/gnoplace/v0"
	"gno.land/p/moul/md/v0"
	"gno.land/p/moul/txlink/v0"
)

// self is this realm's gnoweb prefix, read from the package path it is running
// under. The same source is deployed at r/moul/gnoplace and at .../preview, and
// a hardcoded link would send every click on the preview back to production
// while looking like it worked.
func self() string {
	return strings.TrimPrefix(unsafe.CurrentRealm().PkgPath(), runtime.ChainDomain())
}

// Render is the product. The canvas, the palette, the activity and the way to
// paint are all here, with no wallet and no JavaScript involved.
//
// Deterministic: no current height, no clock. Every height on the page was
// recorded by the paint that produced it, which is what lets the pinned tests
// assert the bytes.
func Render(path string) string {
	switch {
	case path == "":
		return renderHome()
	case path == "about":
		return renderAbout()
	case strings.HasPrefix(path, "u/"):
		return renderPainter(strings.TrimPrefix(path, "u/"))
	}
	return "# Not found\n\nNo page at `" + md.EscapeText(path) + "`. [Back to the canvas](" + self() + ").\n"
}

func renderHome() string {
	painted, paints, people := Stats()
	var b strings.Builder
	b.WriteString("# The canvas\n\n")
	b.WriteString(canvas.Image("the shared canvas") + "\n\n")
	b.WriteString(md.Bold(itoa(painted)) + " of " + itoa(gnoplace.Size*gnoplace.Size) +
		" cells painted, by " + md.Bold(itoa(people)) + " people, in " +
		md.Bold(itoa(paints)) + " strokes.\n\n")
	b.WriteString("Every cell is a transaction. One address may paint once every " +
		itoa(Cooldown) + " blocks, which a second address bypasses completely: it is a " +
		"speed bump, not a defence, and saying so is more useful than pretending otherwise.\n\n")

	b.WriteString(md.H2("The palette"))
	b.WriteString("| | colour | paint |\n|---|---|---|\n")
	for i, hex := range gnoplace.Colors {
		b.WriteString("| " + itoa(i) + " | `" + hex + "` | " +
			md.Link("use "+itoa(i), txlink.Call("Paint", "x", "0", "y", "0", "color", itoa(i))) + " |\n")
	}
	b.WriteString("\nThe links above paint the top-left cell. Change `x` and `y` in the form " +
		"gnoweb opens, or use the front-end, which is a canvas you click.\n\n")

	if len(recent) > 0 {
		b.WriteString(md.H2("Recent strokes"))
		b.WriteString("| who | cell | colour | height |\n|---|---|---|---|\n")
		for _, s := range recent {
			b.WriteString("| " + painter(s.By) + " | " + itoa(s.X) + "," + itoa(s.Y) + " | " +
				itoa(s.Color) + " | " + itoa64(s.Height) + " |\n")
		}
		b.WriteString("\n")
	}

	b.WriteString(md.HorizontalRule())
	b.WriteString(md.CollapsibleSection("Painting from a terminal", howTo()))
	b.WriteString("\n" + md.Link("What this realm is exploring", self()+":about") + "\n")
	return b.String()
}

func renderPainter(raw string) string {
	addr := address(raw)
	if !addr.IsValid() {
		return "# Not a painter\n\n`" + md.EscapeText(raw) + "` is not an address. [Back to the canvas](" + self() + ").\n"
	}
	count, last := PainterOf(addr)
	var b strings.Builder
	b.WriteString("# " + short(addr) + "\n\n")
	b.WriteString(md.Link(addr.String(), "/u/"+addr.String()) + "\n\n")
	b.WriteString(md.Bold(itoa(count)) + " strokes")
	if count > 0 {
		b.WriteString(", the last at height " + itoa64(last))
	}
	b.WriteString(".\n\n" + md.Link("Back to the canvas", self()) + "\n")
	return b.String()
}

func renderAbout() string {
	return `# What this realm is exploring

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

There are two deployments of this same source: this one, and a ` + "`r/moul/preview/gnoplace`" + `
flagged ` + "`private = true`" + ` so it stays redeployable while the design
is still moving. A public path can never be redeployed, which makes that flag the
most consequential line in the whole repository.

The repository, the checklist it is written against, and the other three:
[github.com/moul/gnoplace](https://github.com/moul/gnoplace).

` + md.Link("Back to the canvas", self()) + "\n"
}

func painter(addr address) string {
	if addr == "" {
		return "_nobody_"
	}
	return md.Link(short(addr), self()+":u/"+addr.String())
}

func short(addr address) string {
	s := addr.String()
	if len(s) <= 12 {
		return s
	}
	return s[:8] + "…" + s[len(s)-4:]
}

func howTo() string {
	pkg := runtime.ChainDomain() + strings.TrimPrefix(self(), "/")
	return "```sh\n" +
		"# paint cell (5,7) in colour 10\n" +
		"gnokey maketx call -pkgpath " + pkg + " -func Paint -args 5 -args 7 -args 10 \\\n" +
		"  -gas-fee 1000000ugnot -gas-wanted 3000000 -broadcast \\\n" +
		"  -chainid " + runtime.ChainID() + " -remote https://rpc.gno.land:443 YOURKEY\n" +
		"```\n" +
		"\nThat gas number is a starting point, not a measurement. Drop `-broadcast` and " +
		"the node answers with what the call actually costs.\n"
}
