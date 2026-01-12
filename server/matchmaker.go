package main

import (
	"encoding/json"
	"log"
)

type Matchmaker struct {
	addClient  chan *Client
	sessions   map[*Client]*GameSession
}

func newMatchmaker() *Matchmaker {
	return &Matchmaker{
		addClient: make(chan *Client),
		sessions:  make(map[*Client]*GameSession),
	}
}

func (m *Matchmaker) run() {
	var pendingClient *Client

	for {
		select {
		case client := <-m.addClient:
			if pendingClient == nil {
				pendingClient = client
			} else {
				m.startGame(pendingClient, client)
				pendingClient = nil
			}
		}
	}
}

func (m *Matchmaker) startGame(c1, c2 *Client) {
	session := newGameSession(c1, c2)
	m.sessions[c1] = session
	m.sessions[c2] = session

	msg1, _ := json.Marshal(map[string]string{"type": "MATCH_FOUND", "color": "X"})
	c1.send <- msg1

	msg2, _ := json.Marshal(map[string]string{"type": "MATCH_FOUND", "color": "O"})
	c2.send <- msg2
	
	addr1 := "unknown"
	if c1.conn != nil {
		addr1 = c1.conn.RemoteAddr().String()
	}
	addr2 := "unknown"
	if c2.conn != nil {
		addr2 = c2.conn.RemoteAddr().String()
	}
	log.Printf("Started game between %s and %s", addr1, addr2)
}
