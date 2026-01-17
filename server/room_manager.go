package main

import (
	"encoding/json"
	"errors"
	"math/rand"
	"sync"
	"time"

	"caro_chess_server/engine"
)

type RoomManager struct {
	rooms map[string]*GameSession
	mu    sync.RWMutex
}

func newRoomManager() *RoomManager {
	rand.Seed(time.Now().UnixNano())
	return &RoomManager{
		rooms: make(map[string]*GameSession),
	}
}

func (rm *RoomManager) createRoom(host *Client, totalTime, increment, moveLimit time.Duration, rule engine.GameRule) (string, error) {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	code := rm.generateCode()
	for {
		if _, exists := rm.rooms[code]; !exists {
			break
		}
		code = rm.generateCode()
	}

	session := &GameSession{
		ClientX:       host,
		PlayerXID:     host.ID,
		Turn:          "X",
		Engine:        engine.NewGameEngine(15, 15, rule),
		Spectators:    make(map[*Client]bool),
		TotalTimeX:    totalTime,
		TotalTimeO:    totalTime,
		Increment:     increment,
		MoveTimeLimit: moveLimit,
		LastMoveTime:  time.Now(),
	}

	rm.rooms[code] = session
	host.Session = session
	return code, nil
}

func (rm *RoomManager) joinRoom(code string, guest *Client) error {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	session, exists := rm.rooms[code]
	if !exists {
		return errors.New("room not found")
	}

	// Check for Reconnect
	if session.PlayerXID == guest.ID {
		// Reconnect as Host
		session.StopDisconnectTimer(true)
		session.ClientX = guest
		guest.Session = session
		return nil
	}
	if session.PlayerOID == guest.ID {
		// Reconnect as Guest
		session.StopDisconnectTimer(false)
		session.ClientO = guest
		guest.Session = session
		return nil
	}

	if session.ClientO != nil {
		// Room full, add as spectator
		if session.Spectators == nil {
			session.Spectators = make(map[*Client]bool)
		}
		session.Spectators[guest] = true
		guest.Session = session

		// Send initial state to spectator
		initialState := map[string]interface{}{
			"type":     "SPECTATOR_JOINED",
			"history":  session.Engine.History,
			"player_x": session.PlayerXID,
			"player_o": session.PlayerOID,
		}

		msg, err := json.Marshal(initialState)
		if err == nil {
			guest.send <- msg
		}

		return nil
	}

	session.ClientO = guest
	session.PlayerOID = guest.ID
	guest.Session = session

	return nil
}

func (rm *RoomManager) getRoom(code string) (*GameSession, bool) {
	rm.mu.RLock()
	defer rm.mu.RUnlock()
	s, ok := rm.rooms[code]
	return s, ok
}

func (rm *RoomManager) generateCode() string {
	const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	b := make([]byte, 4)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

func (rm *RoomManager) broadcast(code string, msg []byte) {
	rm.mu.RLock()
	defer rm.mu.RUnlock()
	if session, ok := rm.rooms[code]; ok {
		if session.ClientX != nil {
			session.ClientX.send <- msg
		}
		if session.ClientO != nil {
			session.ClientO.send <- msg
		}
		for client := range session.Spectators {
			select {
			case client.send <- msg:
			default:
				// Drop message if buffer full
			}
		}
	}
}
