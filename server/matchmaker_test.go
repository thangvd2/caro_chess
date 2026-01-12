package main

import (
	"os"
	"testing"
	"time"
	
	"caro_chess_server/db"
)

func TestMatchmaking(t *testing.T) {
	repo := db.NewFileUserRepository("test_mm.json")
	defer os.Remove("test_mm.json")
	
	mm := newMatchmaker(repo)
	go mm.run()

	c1 := &Client{send: make(chan []byte, 10)}
	c2 := &Client{send: make(chan []byte, 10)}

	mm.addClient <- c1
	mm.addClient <- c2

	time.Sleep(50 * time.Millisecond)

	select {
	case <-c1.send:
		// Received
	default:
		t.Error("Client 1 did not receive match message")
	}

	select {
	case <-c2.send:
		// Received
	default:
		t.Error("Client 2 did not receive match message")
	}
}