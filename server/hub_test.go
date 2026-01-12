package main

import (
	"testing"
	"time"
)

func TestHubRegistration(t *testing.T) {
	hub := newHub()
	go hub.run()

	client := &Client{hub: hub, send: make(chan []byte)}
	hub.register <- client

	// Allow time for registration
	time.Sleep(10 * time.Millisecond)

	if len(hub.clients) != 1 {
		t.Errorf("expected 1 client, got %d", len(hub.clients))
	}

	hub.unregister <- client
	time.Sleep(10 * time.Millisecond)

	if len(hub.clients) != 0 {
		t.Errorf("expected 0 clients, got %d", len(hub.clients))
	}
}
