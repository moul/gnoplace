package gnoplace

import (
	"strings"
	"testing"

	"gno.land/p/nt/uassert/v0"
	"gno.land/p/nt/urequire/v0"
)

func TestEmptyCanvas(t *testing.T) {
	c := New()
	uassert.Equal(t, 0, c.Painted())
	uassert.Equal(t, 0, c.At(0, 0))
	uassert.Equal(t, Size*Size, len(c.Encode()))
	uassert.Equal(t, strings.Repeat("0", Size*Size), c.Encode())
}

func TestSet(t *testing.T) {
	cases := []struct {
		name          string
		x, y, color   int
		wantErr       error
	}{
		{"top left", 0, 0, 5, nil},
		{"bottom right", Size - 1, Size - 1, 15, nil},
		{"an odd index, the low nibble", 1, 0, 9, nil},
		{"left of the canvas", -1, 0, 1, ErrOutOfRange},
		{"above the canvas", 0, -1, 1, ErrOutOfRange},
		{"right of the canvas", Size, 0, 1, ErrOutOfRange},
		{"below the canvas", 0, Size, 1, ErrOutOfRange},
		{"colour 16 does not exist", 0, 0, 16, ErrNoSuchColor},
		{"nor does a negative one", 0, 0, -1, ErrNoSuchColor},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			c := New()
			err := c.Set(tc.x, tc.y, tc.color)
			if tc.wantErr != nil {
				uassert.ErrorIs(t, err, tc.wantErr)
				uassert.Equal(t, 0, c.Painted(), "a refused paint changes nothing")
				return
			}
			urequire.NoError(t, err)
			uassert.Equal(t, tc.color, c.At(tc.x, tc.y))
			uassert.Equal(t, 1, c.Painted())
		})
	}
}

// Two cells share a byte, so writing one must not disturb its neighbour. This
// is the whole risk of packing, and it is invisible until a drawing has a
// vertical edge on an odd column.
func TestNibblePackingDoesNotBleed(t *testing.T) {
	c := New()
	urequire.NoError(t, c.Set(0, 0, 0x0a))
	urequire.NoError(t, c.Set(1, 0, 0x05))
	uassert.Equal(t, 0x0a, c.At(0, 0))
	uassert.Equal(t, 0x05, c.At(1, 0))

	urequire.NoError(t, c.Set(1, 0, 0x0f))
	uassert.Equal(t, 0x0a, c.At(0, 0), "the high nibble survived a low-nibble write")
	uassert.Equal(t, 0x0f, c.At(1, 0))

	urequire.NoError(t, c.Set(0, 0, 0x03))
	uassert.Equal(t, 0x03, c.At(0, 0))
	uassert.Equal(t, 0x0f, c.At(1, 0), "the low nibble survived a high-nibble write")
}

func TestPaintedCountsTransitionsBothWays(t *testing.T) {
	c := New()
	urequire.NoError(t, c.Set(4, 4, 7))
	uassert.Equal(t, 1, c.Painted())
	urequire.NoError(t, c.Set(4, 4, 8)) // recolour, not a new cell
	uassert.Equal(t, 1, c.Painted())
	urequire.NoError(t, c.Set(4, 4, 0)) // erased
	uassert.Equal(t, 0, c.Painted())
}

func TestEncodeRoundTrip(t *testing.T) {
	c := New()
	for i := 0; i < Size; i++ {
		urequire.NoError(t, c.Set(i, i, 1+i%15))
	}
	back, err := Decode(c.Encode())
	urequire.NoError(t, err)
	uassert.Equal(t, c.Encode(), back.Encode())
	uassert.Equal(t, c.Painted(), back.Painted())
}

func TestDecodeRejectsGarbage(t *testing.T) {
	cases := []struct{ name, in string }{
		{"empty", ""},
		{"one short", strings.Repeat("0", Size*Size-1)},
		{"one long", strings.Repeat("0", Size*Size+1)},
		{"not hex", strings.Repeat("0", Size*Size-1) + "z"},
		{"uppercase is not the encoding we emit", strings.Repeat("0", Size*Size-1) + "A"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			c, err := Decode(tc.in)
			uassert.ErrorIs(t, err, ErrBadEncoding)
			uassert.True(t, c == nil)
		})
	}
}

// The run-length encoding is the difference between a page that costs 80 KB
// and one that costs a few hundred bytes, so its shape is measured rather than
// asserted in a comment.
func TestRunsCollapseTheDrawing(t *testing.T) {
	c := New()
	uassert.Equal(t, 1, c.Rects(), "an empty canvas is one background rectangle")

	for x := 0; x < Size; x++ {
		urequire.NoError(t, c.Set(x, 0, 3))
	}
	uassert.Equal(t, 2, c.Rects(), "a solid row is one rectangle")

	for x := 0; x < Size; x += 2 {
		urequire.NoError(t, c.Set(x, 1, 4))
	}
	uassert.Equal(t, 2+Size/2, c.Rects(), "a dashed row is one rectangle per dash")
}

func TestSVGIsWellFormed(t *testing.T) {
	c := New()
	urequire.NoError(t, c.Set(2, 3, 5))
	s := c.SVG()
	uassert.True(t, strings.HasPrefix(s, "<svg "), s[:40])
	uassert.True(t, strings.HasSuffix(s, "</svg>"))
	uassert.Equal(t, c.Rects(), strings.Count(s, "<rect"))
}

// gnoweb lets an inline image through only as image/svg+xml, so the prefix is
// a contract with the renderer. Break it and the canvas silently disappears.
func TestImageIsAnSvgDataURI(t *testing.T) {
	img := New().Image("canvas")
	uassert.True(t, strings.HasPrefix(img, "![canvas](data:image/svg+xml;base64,"), img[:60])
}

func TestAtOutOfRangeIsBackgroundNotAPanic(t *testing.T) {
	c := New()
	uassert.Equal(t, 0, c.At(-1, 0))
	uassert.Equal(t, 0, c.At(0, -1))
	uassert.Equal(t, 0, c.At(Size, 0))
	uassert.Equal(t, 0, c.At(0, Size))
}
