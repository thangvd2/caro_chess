package elo

import (
	"testing"
)

func TestCalculateRatings(t *testing.T) {
	// P1 (1600) vs P2 (1600). P1 wins. K=32.
	// Expected: P1 -> 1616, P2 -> 1584
	r1, r2 := CalculateRatings(1600, 1600, 1.0)
	if r1 != 1616 {
		t.Errorf("Expected r1=1616, got %d", r1)
	}
	if r2 != 1584 {
		t.Errorf("Expected r2=1584, got %d", r2)
	}

	// P1 (1600) vs P2 (1600). Draw (0.5).
	// Expected: No change
	r1, r2 = CalculateRatings(1600, 1600, 0.5)
	if r1 != 1600 {
		t.Errorf("Expected r1=1600, got %d", r1)
	}
	if r2 != 1600 {
		t.Errorf("Expected r2=1600, got %d", r2)
	}
}
