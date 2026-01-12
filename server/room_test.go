package main

import (
	"testing"
)

func TestRoomCreation(t *testing.T) {
	rm := newRoomManager()
	
	c1 := &Client{ID: "p1", send: make(chan []byte, 10)}
	
	code, err := rm.createRoom(c1)
	if err != nil {
		t.Fatalf("createRoom failed: %v", err)
	}
	
	if len(code) != 4 {
		t.Errorf("expected 4-char code, got %s", code)
	}
	
	session, exists := rm.getRoom(code)
	if !exists {
		t.Fatalf("room %s not found", code)
	}
	if session.ClientX != c1 {
		t.Errorf("expected p1 as host")
	}
	
	c2 := &Client{ID: "p2", send: make(chan []byte, 10)}
	if err := rm.joinRoom(code, c2); err != nil {
		t.Fatalf("joinRoom failed: %v", err)
	}
	
	if session.ClientO != c2 {
		t.Errorf("expected p2 as guest")
	}
	
	c3 := &Client{ID: "p3", send: make(chan []byte, 10)}
	if err := rm.joinRoom(code, c3); err == nil {
		t.Errorf("expected error joining full room")
	}
}
