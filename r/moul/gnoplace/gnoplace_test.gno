package gnoplace

import (
	"strings"
	"testing"

	"gno.land/p/moul/gnoplace/v0"
	"gno.land/p/nt/avl/v0"
	"gno.land/p/nt/testutils/v0"
	"gno.land/p/nt/uassert/v0"
	"gno.land/p/nt/urequire/v0"
)

var (
	alice = testutils.TestAddress("alice")
	bob   = testutils.TestAddress("bob")
)

// Every caller switch below is a literal testing.SetRealm, never a helper.
//
// SetRealm sets the realm of the CURRENT FRAME. Wrapped in a func it sets the
// helper's frame, which then returns, and the caller the realm sees is whoever
// it was before. The call still succeeds, so the test passes for the wrong
// reason.
func reset() {
	canvas = gnoplace.New()
	painters = avl.Tree{}
	recent = nil
	strokes = 0
}

func TestPaint(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(alice))
	Paint(cross(cur), 3, 4, 7)

	painted, paints, people := Stats()
	uassert.Equal(t, 1, painted)
	uassert.Equal(t, 1, paints)
	uassert.Equal(t, 1, people)
	uassert.Equal(t, 7, canvas.At(3, 4))

	count, _ := PainterOf(alice)
	uassert.Equal(t, 1, count)
}

// The cooldown is the only rate limit, so it is tested at both edges: it must
// refuse a paint one block too early and allow one exactly on the boundary.
func TestCooldown(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(alice))
	Paint(cross(cur), 0, 0, 1)

	urequire.AbortsContains(t, cur, ErrCooldown.Error(), func() {
		Paint(cross(cur), 1, 0, 1)
	})

	testing.SkipHeights(Cooldown - 1)
	testing.SetRealm(testing.NewUserRealm(alice))
	urequire.AbortsContains(t, cur, ErrCooldown.Error(), func() {
		Paint(cross(cur), 1, 0, 1)
	})

	testing.SkipHeights(1)
	testing.SetRealm(testing.NewUserRealm(alice))
	Paint(cross(cur), 1, 0, 1)
	uassert.Equal(t, 2, canvas.Painted())
}

// The documented hole, pinned so it stays documented: a second address is not
// rate limited by the first one's cooldown. This test passing is the statement
// that the limit is a speed bump, not a defence.
func TestCooldownIsPerAddress(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(alice))
	Paint(cross(cur), 0, 0, 1)
	testing.SetRealm(testing.NewUserRealm(bob))
	Paint(cross(cur), 1, 0, 2)
	uassert.Equal(t, 2, canvas.Painted())
}

func TestEngineRefusalsReachTheCaller(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(alice))
	urequire.AbortsContains(t, cur, gnoplace.ErrOutOfRange.Error(), func() {
		Paint(cross(cur), gnoplace.Size, 0, 1)
	})
	testing.SetRealm(testing.NewUserRealm(alice))
	urequire.AbortsContains(t, cur, gnoplace.ErrNoSuchColor.Error(), func() {
		Paint(cross(cur), 0, 0, 99)
	})
	// A refused paint must not consume the cooldown or count as a stroke.
	_, paints, _ := Stats()
	uassert.Equal(t, 0, paints)
}

// The activity log is bounded, or the page renders slower every day and the
// storage is never reclaimed.
func TestRecentIsBounded(cur realm, t *testing.T) {
	reset()
	for i := 0; i < Recent+5; i++ {
		testing.SetRealm(testing.NewUserRealm(alice))
		testing.SkipHeights(Cooldown)
		Paint(cross(cur), i%gnoplace.Size, 0, 1+i%15)
	}
	uassert.Equal(t, Recent, len(recent))
	uassert.Equal(t, Recent, len(strings.Split(strings.TrimSuffix(Feed(), "\n"), "\n")))
	_, paints, _ := Stats()
	uassert.Equal(t, Recent+5, paints, "every stroke is still counted")
}

// Feed is a contract with a program, not a page: a column added in the middle
// is a broken front-end with nothing on chain to fix it with.
func TestFeedShape(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(alice))
	Paint(cross(cur), 5, 6, 9)
	row := strings.TrimSuffix(Feed(), "\n")
	cols := strings.Split(row, "\t")
	uassert.Equal(t, 5, len(cols))
	uassert.Equal(t, alice.String(), cols[0])
	uassert.Equal(t, "5", cols[1])
	uassert.Equal(t, "6", cols[2])
	uassert.Equal(t, "9", cols[3])
	uassert.Equal(t, gnoplace.Size*gnoplace.Size, len(Canvas()))
}

func TestRenderNeverPanics(cur realm, t *testing.T) {
	reset()
	testing.SetRealm(testing.NewUserRealm(alice))
	Paint(cross(cur), 1, 1, 3)
	for _, p := range []string{
		"", "about", "u/" + alice.String(), "u/", "u/nonsense", "nope",
		"../../etc/passwd", "<script>alert(1)</script>", "u/g1notanaddress",
	} {
		uassert.True(t, len(Render(p)) > 0, "empty render for "+p)
	}
}

func TestRenderEscapesThePathItEchoes(cur realm, t *testing.T) {
	reset()
	uassert.False(t, strings.Contains(Render("u/<script>"), "<script>"))
}
