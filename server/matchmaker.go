package main

import (
	"encoding/json"
	"log"

	"caro_chess_server/db"
	"caro_chess_server/elo"
)

type Matchmaker struct {
	repo      db.UserRepository
	addClient chan *Client
	sessions  map[*Client]*GameSession
}

func newMatchmaker(repo db.UserRepository) *Matchmaker {
	return &Matchmaker{
		repo:      repo,
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
	c1.Session = session
	c2.Session = session

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

func (m *Matchmaker) RegisterSession(session *GameSession) {
	if session.ClientX != nil {
		m.sessions[session.ClientX] = session
		session.ClientX.Session = session
	}
	if session.ClientO != nil {
		m.sessions[session.ClientO] = session
		session.ClientO.Session = session
	}
}

func (m *Matchmaker) endGame(winner *Client) {
	session := m.sessions[winner]
	if session == nil {
		return
	}

	loser := session.ClientX
	if winner == session.ClientX {
		loser = session.ClientO
	}

	u1, _ := m.repo.GetUser(winner.ID)
	u2, _ := m.repo.GetUser(loser.ID)

	r1, r2 := elo.CalculateRatings(u1.ELO, u2.ELO, 1.0)

	u1.ELO = r1
	u1.Wins++
	u2.ELO = r2
	u2.Losses++

	m.repo.SaveUser(u1)
	m.repo.SaveUser(u2)

	msg1, _ := json.Marshal(map[string]interface{}{"type": "UPDATE_RANK", "elo": u1.ELO})
	winner.send <- msg1

	msg2, _ := json.Marshal(map[string]interface{}{"type": "UPDATE_RANK", "elo": u2.ELO})
	loser.send <- msg2

	delete(m.sessions, winner)
	delete(m.sessions, loser)
}
