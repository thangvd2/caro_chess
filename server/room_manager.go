package main

import (
	"errors"
	"math/rand"
	"sync"
	"time"
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

func (rm *RoomManager) createRoom(host *Client) (string, error) {
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
		ClientX: host,
		Turn: "X",
	}
	
	rm.rooms[code] = session
	return code, nil
}

func (rm *RoomManager) joinRoom(code string, guest *Client) error {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	
	session, exists := rm.rooms[code]
	if !exists {
		return errors.New("room not found")
	}
	
	if session.ClientO != nil {
		return errors.New("room full")
	}
	
	session.ClientO = guest
	
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
