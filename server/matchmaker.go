package main

import (
	"encoding/json"
	"log"
	"time"

	"github.com/google/uuid"

	"caro_chess_server/db"
	"caro_chess_server/elo"
)

type Matchmaker struct {
	repo         db.UserRepository
	addClient    chan *Client
	removeClient chan *Client // New channel
	sessions     map[*Client]*GameSession
}

func newMatchmaker(repo db.UserRepository) *Matchmaker {
	return &Matchmaker{
		repo:         repo,
		addClient:    make(chan *Client),
		removeClient: make(chan *Client), // Initialize
		sessions:     make(map[*Client]*GameSession),
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
		case client := <-m.removeClient: // Handle removal
			if pendingClient == client {
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

func (m *Matchmaker) endGame(session *GameSession, winner *Client) {
	if session == nil {
		return
	}
	// Determine Loser (if any)
	if winner != nil {
		// Logic to identify loser if needed
	} else {
		// Draw
	}

	u1, _ := m.repo.GetUser(session.PlayerXID)
	u2, _ := m.repo.GetUser(session.PlayerOID) // Assumes O exists

	// Calculate ELO
	var scoreX float64 = 0.5
	if winner == session.ClientX {
		scoreX = 1.0
	} else if winner == session.ClientO {
		scoreX = 0.0
	}

	r1, r2 := elo.CalculateRatings(u1.ELO, u2.ELO, scoreX)

	u1.ELO = r1
	u2.ELO = r2

	// Update Stats
	u1.GamesPlayed++
	u2.GamesPlayed++
	if scoreX == 1.0 {
		u1.Wins++
		u2.Losses++
	} else if scoreX == 0.0 {
		u1.Losses++
		u2.Wins++
	} else {
		u1.Draws++
		u2.Draws++
	}

	m.repo.SaveUser(u1)
	m.repo.SaveUser(u2)

	// Save Match to DB
	moves := make([]db.Move, len(session.Engine.History))
	for i, mv := range session.Engine.History {
		p := "X"
		if i%2 != 0 {
			p = "O"
		}
		moves[i] = db.Move{
			X:      mv.X,
			Y:      mv.Y,
			Player: p,
			Order:  i,
		}
	}

	var winnerID *string
	if winner != nil {
		wid := winner.ID
		winnerID = &wid
	}

	match := &db.Match{
		ID:        uuid.New().String(),
		PlayerXID: session.PlayerXID,
		PlayerOID: session.PlayerOID,
		WinnerID:  winnerID,
		Moves:     moves,
		Timestamp: time.Now(),
	}
	m.repo.SaveMatch(match)

	// Notify clients of new Rank
	if session.ClientX != nil {
		msg, _ := json.Marshal(map[string]interface{}{"type": "UPDATE_RANK", "elo": u1.ELO})
		session.ClientX.send <- msg
	}
	if session.ClientO != nil {
		msg, _ := json.Marshal(map[string]interface{}{"type": "UPDATE_RANK", "elo": u2.ELO})
		session.ClientO.send <- msg
	}

	// Cleanup session
	if session.ClientX != nil {
		delete(m.sessions, session.ClientX)
		session.ClientX.Session = nil
	}
	if session.ClientO != nil {
		delete(m.sessions, session.ClientO)
		session.ClientO.Session = nil
	}
}
