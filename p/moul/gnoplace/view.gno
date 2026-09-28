package gnoplace

import (
	"strings"

	"gno.land/p/nt/svg/v0"
)

const (
	cellPx = 16
	edgePx = Size * cellPx
)

// SVG draws the canvas, run-length encoded along each row.
//
// One <rect> per cell would be 1,024 of them, about 60 KB of markup and 80 KB
// once base64'd into a data URI, on every single page view. Runs collapse a
// blank canvas to one rectangle and a drawing to roughly the number of colour
// changes in it, which is what people actually paint. The picture is identical
// either way; only the bytes differ, and the bytes are the whole cost.
func (c *Canvas) SVG() string { return c.canvas().String() }

// Image returns the canvas as a markdown image. The SVG is inlined as a data
// URI, so it needs no hosting and costs no storage: it is drawn at read time
// from state that was going to be stored anyway.
func (c *Canvas) Image(alt string) string { return c.canvas().Render(alt) }

func (c *Canvas) canvas() *svg.Canvas {
	cv := svg.NewCanvas(edgePx, edgePx).WithViewBox(0, 0, edgePx, edgePx)
	cv.Append(svg.NewRectangle(0, 0, edgePx, edgePx, Colors[0]))
	c.runs(func(x, y, run, col int) {
		cv.Append(svg.NewRectangle(x*cellPx, y*cellPx, run*cellPx, cellPx, Colors[col]))
	})
	return cv
}

// runs walks the canvas as horizontal runs of one colour, skipping the
// background. It is the whole reason a drawing costs what it looks like rather
// than what the grid is: one rect per cell would be 1,024 of them, about 60 KB
// of markup and 80 KB once base64'd into a data URI, on every page view.
func (c *Canvas) runs(fn func(x, y, run, col int)) {
	for y := 0; y < Size; y++ {
		x := 0
		for x < Size {
			col := c.At(x, y)
			run := 1
			for x+run < Size && c.At(x+run, y) == col {
				run++
			}
			if col != 0 {
				fn(x, y, run, col)
			}
			x += run
		}
	}
}

// Rects reports how many rectangles [Canvas.SVG] emits for the current canvas.
// It exists so the cost of a drawing is measurable from a test rather than
// asserted in a comment.
func (c *Canvas) Rects() int {
	n := 1 // the background
	c.runs(func(_, _, _, _ int) { n++ })
	return n
}

// Emoji returns a small text view, for the places an image cannot go: a chain
// event, a terminal, a test failure. It samples rather than scales, because a
// 32-row block of emoji is unreadable in any of those places.
func (c *Canvas) Emoji() string {
	var sb strings.Builder
	for y := 0; y < Size; y += 4 {
		for x := 0; x < Size; x += 2 {
			if c.At(x, y) == 0 {
				sb.WriteString("·")
			} else {
				sb.WriteString("█")
			}
		}
		sb.WriteByte('\n')
	}
	return sb.String()
}
