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

	TimerX *time.Timer
	TimerO *time.Timer

	Spectators map[*Client]bool
}

func newGameSession(x, o *Client) *GameSession {
	return &GameSession{
		ClientX:    x,
		ClientO:    o,
		PlayerXID:  x.ID,
		PlayerOID:  o.ID,
		Turn:       "X",
		Engine:     engine.NewGameEngine(15, 15, engine.RuleStandard),
		Spectators: make(map[*Client]bool),
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
