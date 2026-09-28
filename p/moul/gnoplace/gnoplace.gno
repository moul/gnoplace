// Package gnoplace is a shared pixel canvas: 32 by 32 cells, 16 colours, and
// nothing else.
//
// It imports no chain package. Who may paint, how often, and what it costs are
// the realm's problem; this only knows what the canvas looks like and how to
// draw it.
//
// Live demo: [r/moul/gnoplace](/r/moul/gnoplace).
package gnoplace

import (
	"errors"
	"strings"
)

// Size is the canvas edge, in cells. 32 is not arbitrary: the whole canvas is
// one stored value, and at 32x32 that value is 512 bytes, small enough that
// rewriting it on every paint stays cheap. At 64 it is 2 KB, and the rewrite
// starts to dominate what a paint costs.
const Size = 32

// Colors is the palette. Sixteen, so a cell is one nibble and two cells share
// a byte. Index 0 is the background and is never stored as a paint.
var Colors = [16]string{
	"#ffffff", "#e4e4e4", "#888888", "#222222",
	"#ffa7d1", "#e50000", "#e59500", "#a06a42",
	"#e5d900", "#94e044", "#02be01", "#00d3dd",
	"#0083c7", "#0000ea", "#cf6ee4", "#820080",
}

var (
	ErrOutOfRange = errors.New("gnoplace: cell out of range")
	ErrNoSuchColor = errors.New("gnoplace: no such colour")
	ErrBadEncoding = errors.New("gnoplace: not a valid canvas encoding")
)

// Canvas is Size*Size cells packed two per byte.
//
// One []byte, not an avl tree of cells. A tree keyed by "x,y" would make a
// paint touch one small object instead of rewriting 512 bytes, which sounds
// cheaper and is not: a thousand painted cells is a thousand persisted objects
// and a thousand storage deposits, against one value whose size never changes.
// The tree wins only if the canvas gets big enough that the rewrite hurts more
// than the objects do, which at this size it does not.
type Canvas struct {
	cells [Size * Size / 2]byte
	count int // painted cells, so Render need not count them
}

// New returns an empty canvas: every cell colour 0.
func New() *Canvas { return &Canvas{} }

func inRange(x, y int) bool { return x >= 0 && x < Size && y >= 0 && y < Size }

// At returns the colour index at (x, y), or 0 out of range.
//
// Out of range is 0 rather than a panic because render loops walk past the edge
// on purpose, and a Render that panics is a realm page nobody can ever read
// again.
func (c *Canvas) At(x, y int) int {
	if !inRange(x, y) {
		return 0
	}
	i := y*Size + x
	b := c.cells[i/2]
	if i%2 == 0 {
		return int(b >> 4)
	}
	return int(b & 0x0f)
}

// Set paints one cell. It is the only mutator.
func (c *Canvas) Set(x, y, color int) error {
	if !inRange(x, y) {
		return ErrOutOfRange
	}
	if color < 0 || color >= len(Colors) {
		return ErrNoSuchColor
	}
	was := c.At(x, y)
	i := y*Size + x
	if i%2 == 0 {
		c.cells[i/2] = byte(color)<<4 | c.cells[i/2]&0x0f
	} else {
		c.cells[i/2] = c.cells[i/2]&0xf0 | byte(color)
	}
	switch {
	case was == 0 && color != 0:
		c.count++
	case was != 0 && color == 0:
		c.count--
	}
	return nil
}

// Painted returns how many cells hold a colour other than the background.
func (c *Canvas) Painted() int { return c.count }

// Encode returns the canvas as one hex digit per cell, row by row: 1024
// characters that a browser can draw with no chain and no decoder of its own.
func (c *Canvas) Encode() string {
	const hex = "0123456789abcdef"
	var sb strings.Builder
	for y := 0; y < Size; y++ {
		for x := 0; x < Size; x++ {
			sb.WriteByte(hex[c.At(x, y)])
		}
	}
	return sb.String()
}

// Decode rebuilds a canvas from [Canvas.Encode]. It goes through Set, so a
// malformed encoding is refused here rather than becoming a canvas no rule
// allows.
func Decode(s string) (*Canvas, error) {
	if len(s) != Size*Size {
		return nil, ErrBadEncoding
	}
	c := New()
	for i := 0; i < len(s); i++ {
		v := hexVal(s[i])
		if v < 0 {
			return nil, ErrBadEncoding
		}
		if err := c.Set(i%Size, i/Size, v); err != nil {
			return nil, ErrBadEncoding
		}
	}
	return c, nil
}

func hexVal(b byte) int {
	switch {
	case b >= '0' && b <= '9':
		return int(b - '0')
	case b >= 'a' && b <= 'f':
		return int(b-'a') + 10
	}
	return -1
}
