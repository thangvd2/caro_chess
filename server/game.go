package main

import (
	"caro_chess_server/engine"
	"sync"
	"time"
)

type GameSession struct {
	sync.Mutex
	ClientX   *Client
	ClientO   *Client
	PlayerXID string
	PlayerOID string
	Turn      string
	Engine    *engine.GameEngine // Engine has its own lock? No, we should protect session

	TimerX *time.Timer // For disconnect
	TimerO *time.Timer // For disconnect

	// Time Control
	TotalTimeX      time.Duration
	TotalTimeO      time.Duration
	Increment       time.Duration
	MoveTimeLimit   time.Duration // Strict limit per move (e.g., 30s)
	LastMoveTime    time.Time
	TurnTimer       *time.Timer         // Active timer for the current player's move calculation
	TimeoutCallback func(winner string) // Callback to end game on timeout

	Spectators map[*Client]bool
}

func newGameSession(x, o *Client, totalTime, increment, moveLimit time.Duration, rule engine.GameRule) *GameSession {
	return &GameSession{
		ClientX:       x,
		ClientO:       o,
		PlayerXID:     x.ID,
		PlayerOID:     o.ID,
		Turn:          "X",
		Engine:        engine.NewGameEngine(15, 15, rule),
		Spectators:    make(map[*Client]bool),
		TotalTimeX:    totalTime,
		TotalTimeO:    totalTime,
		Increment:     increment,
		MoveTimeLimit: moveLimit,
		LastMoveTime:  time.Now(),
	}
}

// StartDisconnectTimer starts a timer that will forfeit the game if not stopped.
// callback is the function to run if timeout occurs ( forfeit ).
func (gs *GameSession) StartDisconnectTimer(isX bool, duration time.Duration, callback func()) {
	gs.Lock()
	defer gs.Unlock()

	if isX {
		if gs.TimerX != nil {
			gs.TimerX.Stop()
		}
		gs.TimerX = time.AfterFunc(duration, callback)
	} else {
		if gs.TimerO != nil {
			gs.TimerO.Stop()
		}
		gs.TimerO = time.AfterFunc(duration, callback)
	}
}

// StopDisconnectTimer stops the disconnect timer for a specific player
func (gs *GameSession) StopDisconnectTimer(isX bool) {
	gs.Lock()
	defer gs.Unlock()

	if isX {
		if gs.TimerX != nil {
			gs.TimerX.Stop()
			gs.TimerX = nil
		}
	} else {
		if gs.TimerO != nil {
			gs.TimerO.Stop()
			gs.TimerO = nil
		}
	}
}

func (gs *GameSession) StartGame() {
	gs.Lock()
	defer gs.Unlock()
	gs.LastMoveTime = time.Now()
	gs.startTurnTimer()
}

func (gs *GameSession) startTurnTimer() {
	if gs.TurnTimer != nil {
		gs.TurnTimer.Stop()
	}

	isX := gs.Turn == "X"
	bank := gs.TotalTimeX
	if !isX {
		bank = gs.TotalTimeO
	}

	// Determine strict limit
	waitDuration := gs.MoveTimeLimit
	if bank < waitDuration {
		waitDuration = bank
	}

	gs.TurnTimer = time.AfterFunc(waitDuration, func() {
		gs.handleTimeout(gs.Turn)
	})
}

func (gs *GameSession) handleTimeout(turnWhoTimedOut string) {
	gs.Lock()
	defer gs.Unlock()

	// Verify turn hasn't changed (race condition)
	if gs.Turn != turnWhoTimedOut {
		return
	}

	// Determine winner (Opponent)
	winnerStr := "O"
	if turnWhoTimedOut == "O" {
		winnerStr = "X"
	}

	if gs.TimeoutCallback != nil {
		gs.TimeoutCallback(winnerStr)
	}
}

func (gs *GameSession) StopGame() {
	gs.Lock()
	defer gs.Unlock()

	if gs.TurnTimer != nil {
		gs.TurnTimer.Stop()
		gs.TurnTimer = nil
	}
	// Also stop disconnect timers if needed, though they are usually per-client
	if gs.TimerX != nil {
		gs.TimerX.Stop()
		gs.TimerX = nil
	}
	if gs.TimerO != nil {
		gs.TimerO.Stop()
		gs.TimerO = nil
	}
}

// MakeMove processes a move and updates clocks
func (gs *GameSession) MakeMove(x, y int) bool {

	gs.Lock()
	defer gs.Unlock()

	current := gs.Engine.CurrentPlayer
	// 1. Check validity via Engine first (don't update clock if invalid)
	// NOTE: validation happens in client.go usually, but we should do it here.
	// However, `PlacePiece` implementation in `engine` does it all.
	// We need to know IF it was successful.

	// 2. Validate Turn (Engine does this?)
	// GameEngine.PlacePiece returns true/false.

	success := gs.Engine.PlacePiece(engine.Position{X: x, Y: y})

	// Actually PlacePiece checks validity.

	if success {
		// 3. Update Clock for the player who JUST moved (current)
		now := time.Now()
		elapsed := now.Sub(gs.LastMoveTime)

		if current == engine.PlayerX {
			gs.TotalTimeX = gs.TotalTimeX - elapsed + gs.Increment
			if gs.TotalTimeX < 0 {
				// Should have timed out already, but just in case
				gs.TotalTimeX = 0
			}
		} else {
			gs.TotalTimeO = gs.TotalTimeO - elapsed + gs.Increment
			if gs.TotalTimeO < 0 {
				gs.TotalTimeO = 0
			}
		}

		gs.LastMoveTime = now
		gs.Turn = string(gs.Engine.CurrentPlayer) // Update Session Turn

		// 4. Start Timer for Next Player
		gs.startTurnTimer()
	}

	return success
}
