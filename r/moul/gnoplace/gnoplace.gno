// Package gnoplace is one canvas that everybody paints on.
//
// It is the write-volume corner of the exploration: thousands of tiny writes
// to a single shared object, where every one of them is a transaction someone
// pays for. The drawing is almost incidental. What is being measured is what a
// paint costs, what a page view costs, and which of the two you should be
// optimising.
//
// The canvas itself is [p/moul/gnoplace](/p/moul/gnoplace/v0), which knows
// nothing about a chain.
package gnoplace

import (
	"chain/runtime"
	"errors"

	"gno.land/p/moul/gnoplace/v0"
	"gno.land/p/nt/avl/v0"
)

// Cooldown is how many blocks an address waits between paints.
//
// It is the only defence here, and it is a weak one on purpose: a second
// address bypasses it entirely. Anything stronger (a fee, a stake, an
// allowlist) is a policy argument, and the honest position for an exploration
// is a limit that costs nothing and is documented as bypassable, rather than a
// mechanism that looks like security and is not.
const Cooldown = 3

// Recent is how many strokes the realm remembers. Bounded, because an unbounded
// activity log is a page that renders slower every day and storage nobody ever
// reclaims.
const Recent = 24

// Stroke is one paint, kept for the activity feed.
type Stroke struct {
	By     address
	X, Y   int
	Color  int
	Height int64
}

// Painter is one address's history.
type Painter struct {
	Count int
	Last  int64 // block height of the last paint
}

var (
	canvas   = gnoplace.New()
	painters avl.Tree // address -> *Painter
	recent   []Stroke
	strokes  int // every paint ever, including recoloured cells
)

var (
	ErrCooldown = errors.New("gnoplace: too soon, wait a few blocks")
)

// Paint colours one cell. x and y count from the top left, both zero-based.
func Paint(cur realm, x, y, color int) {
	caller := cur.Previous().Address()
	h := runtime.ChainHeight()

	p := painterOf(caller)
	if p.Count > 0 && h-p.Last < Cooldown {
		panic(ErrCooldown)
	}
	// The engine owns "is that a cell, is that a colour". The realm does not
	// re-implement the check, it forwards the error.
	if err := canvas.Set(x, y, color); err != nil {
		panic(err)
	}
	p.Count++
	p.Last = h
	strokes++
	recent = append([]Stroke{{By: caller, X: x, Y: y, Color: color, Height: h}}, recent...)
	if len(recent) > Recent {
		recent = recent[:Recent]
	}
}

// Canvas returns the canvas as its encoding: one hex digit per cell, row by
// row. A front-end draws from this and never has to parse the rendered page.
func Canvas() string { return canvas.Encode() }

// Feed returns the recent strokes, newest first, one per line:
//
//	<address>\t<x>\t<y>\t<color>\t<height>
func Feed() string {
	out := ""
	for _, s := range recent {
		out += s.By.String() + "\t" + itoa(s.X) + "\t" + itoa(s.Y) + "\t" +
			itoa(s.Color) + "\t" + itoa64(s.Height) + "\n"
	}
	return out
}

// Stats returns the three numbers a front-end wants and would otherwise derive
// wrongly: cells currently painted, paints ever made, distinct painters.
func Stats() (painted, paints, people int) {
	return canvas.Painted(), strokes, painters.Size()
}

// PainterOf returns one address's history. Values, not the *Painter: this realm
// is private = true, and handing out a pointer into its own storage is the one
// mistake that cannot be undone afterwards.
func PainterOf(addr address) (count int, last int64) {
	v := painters.Get(addr.String())
	if v == nil {
		return 0, 0
	}
	p := v.(*Painter)
	return p.Count, p.Last
}

func painterOf(addr address) *Painter {
	if v := painters.Get(addr.String()); v != nil {
		return v.(*Painter)
	}
	p := &Painter{}
	painters.Set(addr.String(), p)
	return p
}

func itoa64(n int64) string { return itoa(int(n)) }

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	out := ""
	for n > 0 {
		out = string(rune('0'+n%10)) + out
		n /= 10
	}
	if neg {
		out = "-" + out
	}
	return out
}
