package engine

import (
	"testing"
)

func TestPlacePiece(t *testing.T) {
	ge := NewGameEngine(15, 15, RuleStandard)

	if !ge.PlacePiece(Position{X: 7, Y: 7}) {
		t.Error("Expected valid move to succeed")
	}
	if ge.CurrentPlayer != PlayerO {
		t.Errorf("Expected current player to be O, got %s", ge.CurrentPlayer)
	}

	if ge.PlacePiece(Position{X: 7, Y: 7}) {
		t.Error("Expected move on occupied cell to fail")
	}

	if ge.PlacePiece(Position{X: -1, Y: 0}) {
		t.Error("Expected out-of-bounds move to fail")
	}
}

func TestWinStandard(t *testing.T) {
	ge := NewGameEngine(15, 15, RuleStandard)

	// X X X X X
	ge.PlacePiece(Position{X: 0, Y: 0})  // X
	ge.PlacePiece(Position{X: 0, Y: 10}) // O
	ge.PlacePiece(Position{X: 1, Y: 0})  // X
	ge.PlacePiece(Position{X: 1, Y: 10}) // O
	ge.PlacePiece(Position{X: 2, Y: 0})  // X
	ge.PlacePiece(Position{X: 2, Y: 10}) // O
	ge.PlacePiece(Position{X: 3, Y: 0})  // X
	ge.PlacePiece(Position{X: 3, Y: 10}) // O

	if ge.IsGameOver {
		t.Error("Game should not be over yet (4 in row)")
	}

	ge.PlacePiece(Position{X: 4, Y: 0}) // X
	if !ge.IsGameOver {
		t.Error("Expected game over with 5 in a row")
	}
	if *ge.Winner != PlayerX {
		t.Errorf("Expected winner X, got %v", ge.Winner)
	}
}

func TestWinFreeStyleOverline(t *testing.T) {
	ge := NewGameEngine(15, 15, RuleFreeStyle)

	// X X X X . X -> Fill . gives 6
	ge.PlacePiece(Position{X: 0, Y: 0})  // X
	ge.PlacePiece(Position{X: 0, Y: 10}) // O
	ge.PlacePiece(Position{X: 1, Y: 0})  // X
	ge.PlacePiece(Position{X: 1, Y: 10}) // O
	ge.PlacePiece(Position{X: 2, Y: 0})  // X
	ge.PlacePiece(Position{X: 2, Y: 10}) // O
	ge.PlacePiece(Position{X: 3, Y: 0})  // X
	ge.PlacePiece(Position{X: 3, Y: 10}) // O
	ge.PlacePiece(Position{X: 5, Y: 0})  // X
	ge.PlacePiece(Position{X: 5, Y: 10}) // O

	ge.PlacePiece(Position{X: 4, Y: 0}) // X

	if !ge.IsGameOver {
		t.Error("Freestyle should win with 6 in a row")
	}
}

func TestWinStandardOverline(t *testing.T) {
	ge := NewGameEngine(15, 15, RuleStandard)

	// X X X X . X -> Fill . gives 6
	ge.PlacePiece(Position{X: 0, Y: 0})  // X
	ge.PlacePiece(Position{X: 0, Y: 10}) // O
	ge.PlacePiece(Position{X: 1, Y: 0})  // X
	ge.PlacePiece(Position{X: 1, Y: 10}) // O
	ge.PlacePiece(Position{X: 2, Y: 0})  // X
	ge.PlacePiece(Position{X: 2, Y: 10}) // O
	ge.PlacePiece(Position{X: 3, Y: 0})  // X
	ge.PlacePiece(Position{X: 3, Y: 10}) // O
	ge.PlacePiece(Position{X: 5, Y: 0})  // X
	ge.PlacePiece(Position{X: 5, Y: 10}) // O

	ge.PlacePiece(Position{X: 4, Y: 0}) // X

	if ge.IsGameOver {
		t.Logf("Winner: %v", ge.Winner)
		t.Logf("Winning Line: %v", ge.WinningLine)
		t.Error("Standard should NOT win with 6 in a row")
	}
}

func TestWinCaroBlocked(t *testing.T) {
	ge := NewGameEngine(15, 15, RuleCaro)

	ge.PlacePiece(Position{X: 0, Y: 10}) // X dummy
	ge.PlacePiece(Position{X: 0, Y: 0})  // O BLOCKER LEFT

	ge.PlacePiece(Position{X: 1, Y: 10}) // X dummy
	ge.PlacePiece(Position{X: 6, Y: 0})  // O BLOCKER RIGHT

	// X builds 1..5
	ge.PlacePiece(Position{X: 1, Y: 0})
	ge.PlacePiece(Position{X: 2, Y: 10})
	ge.PlacePiece(Position{X: 2, Y: 0})
	ge.PlacePiece(Position{X: 3, Y: 10})
	ge.PlacePiece(Position{X: 3, Y: 0})
	ge.PlacePiece(Position{X: 4, Y: 10})
	ge.PlacePiece(Position{X: 4, Y: 0})
	ge.PlacePiece(Position{X: 5, Y: 10})

	// X(5,0) -> Completes 5, blocked both ends
	ge.PlacePiece(Position{X: 5, Y: 0})

	if ge.IsGameOver {
		t.Error("Caro should NOT win with 5 in a row blocked at both ends")
	}
}

func TestWinCaroOneBlocked(t *testing.T) {
	ge := NewGameEngine(15, 15, RuleCaro)

	ge.PlacePiece(Position{X: 0, Y: 10}) // X dummy
	ge.PlacePiece(Position{X: 0, Y: 0})  // O BLOCKER LEFT

	for i := 1; i < 5; i++ {
		ge.PlacePiece(Position{X: i, Y: 0})  // X
		ge.PlacePiece(Position{X: i, Y: 10}) // O dummy
	}

	ge.PlacePiece(Position{X: 5, Y: 0})

	if !ge.IsGameOver {
		t.Error("Caro SHOULD win with 5 in a row blocked at only one end")
	}
}
