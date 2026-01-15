package main

import (
	"caro_chess_server/engine"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

type Client struct {
	ID      string
	hub     *Hub
	mm      *Matchmaker
	rm      *RoomManager
	conn    *websocket.Conn
	send    chan []byte
	Session *GameSession
}

func (c *Client) readPump() {
	defer func() {
		// Clean up session reference logic
		// Clean up session reference logic
		if c.Session != nil {
			isX := (c.Session.PlayerXID == c.ID)

			// Start Timer
			c.Session.StartDisconnectTimer(isX, 2*time.Minute, func() {
				// Time's up! Forfeit game.
				// We need to notify the OTHER player if they are still connected.
				// Or just end game via Matchmaker?
				// But we are in a background goroutine here.
				// c.mm.endGame needs winner. If this timer fires, existing player WINS.

				// Need access to Matchmaker or Session methods.
				// But this callback runs on a Timer thread.
				// Let's call a safe cleanup function.
				// Note: c.Session might be modified by other thread?
				// But we hold pointer.

				// Let's implement timeout handling in Matchmaker for safety/centralization?
				// Or just:
				otherClient := c.Session.ClientO
				if !isX {
					otherClient = c.Session.ClientX
				}

				if otherClient != nil {
					// Notify winner?
					log.Printf("Session Abandoned by %s. Forfeiting...", c.ID)
					// Actually, we should trigger endGame with winner = otherClient
					// But do we have access to Matchmaker instance?
					// c.mm is available via closure if we use it?
					// c.mm is available via closure if we use it?
					// Yes, c is available.
					c.mm.endGame(c.Session, otherClient)

					// Broadcast Game Over Abandoned?
					// endGame updates ELO but doesn't broadcast "Game Over" message usually?
					// In client.go validation logic, we send GAME_OVER.
					// We should mimic that.

					msg, _ := json.Marshal(map[string]interface{}{
						"type":        "GAME_OVER",
						"winner":      "OPPONENT_ABANDONED", // or UserID
						"winningLine": nil,
					})
					otherClient.send <- msg
				} else {
					// Both disconnected? Just log.
					log.Printf("Session %s fully abandoned.", c.Session.PlayerXID)
				}
			})

			if c.Session.ClientX == c {
				c.Session.ClientX = nil
			}
			if c.Session.ClientO == c {
				c.Session.ClientO = nil
			}
		}
		c.hub.unregister <- c
		c.mm.removeClient <- c // Notify Matchmaker
		c.conn.Close()
	}()
	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error { c.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		var msg map[string]interface{}
		if err := json.Unmarshal(message, &msg); err == nil {
			if msg["type"] == "MOVE" {
				if c.Session == nil || c.Session.Engine == nil {
					continue
				}

				xFloat, okX := msg["x"].(float64)
				yFloat, okY := msg["y"].(float64)
				if !okX || !okY {
					continue
				}
				x, y := int(xFloat), int(yFloat)

				// Validate turn
				isPlayerX := c == c.Session.ClientX
				isPlayerO := c == c.Session.ClientO

				currentTurn := c.Session.Engine.CurrentPlayer

				isMyTurn := (isPlayerX && currentTurn == engine.PlayerX) || (isPlayerO && currentTurn == engine.PlayerO)

				if !isMyTurn {
					// Send error? Or just ignore.
					continue
				}

				if c.Session.Engine.PlacePiece(engine.Position{X: x, Y: y}) {
					resp, _ := json.Marshal(map[string]interface{}{
						"type": "MOVE_MADE",
						"x":    x,
						"y":    y,
					})

					// Send only to players in session
					if c.Session.ClientX != nil {
						c.Session.ClientX.send <- resp
					}
					if c.Session.ClientO != nil {
						c.Session.ClientO.send <- resp
					}

					// Check Game Over
					if c.Session.Engine.IsGameOver {
						var winner *Client
						if c.Session.Engine.Winner != nil {
							if *c.Session.Engine.Winner == engine.PlayerX {
								winner = c.Session.ClientX
							} else {
								winner = c.Session.ClientO
							}
						}

						// Broadcast GAME_OVER
						resp, _ := json.Marshal(map[string]interface{}{
							"type": "GAME_OVER",
							"winner": func() string {
								if c.Session.Engine.Winner == nil {
									return "DRAW"
								}
								return string(*c.Session.Engine.Winner)
							}(),
							"winningLine": c.Session.Engine.WinningLine,
						})

						if c.Session.ClientX != nil {
							c.Session.ClientX.send <- resp
						}
						if c.Session.ClientO != nil {
							c.Session.ClientO.send <- resp
						}

						// Call endGame to record match and update ELO
						c.mm.endGame(c.Session, winner)
					}
				}
			} else if msg["type"] == "WIN_CLAIM" {
				c.mm.endGame(c.Session, c)
			} else if msg["type"] == "FIND_MATCH" {
				c.mm.addClient <- c
			} else if msg["type"] == "CREATE_ROOM" {
				code, _ := c.rm.createRoom(c)
				resp, _ := json.Marshal(map[string]string{"type": "ROOM_CREATED", "code": code})
				c.send <- resp
			} else if msg["type"] == "JOIN_ROOM" {
				code := msg["code"].(string)
				err := c.rm.joinRoom(code, c)
				if err != nil {
					resp, _ := json.Marshal(map[string]string{"type": "ERROR", "message": err.Error()})
					c.send <- resp
				} else {
					session, _ := c.rm.getRoom(code)

					// Register with matchmaker to track session/ELO
					c.mm.RegisterSession(session)

					// Check state
					if len(session.Engine.History) > 0 {
						sendGameSync(c, session)
					} else {
						// New game or start
						if session.ClientX != nil && session.ClientO != nil {
							sendMatchFound(session)
						}
					}
				}
			} else if msg["type"] == "LEAVE_ROOM" {
				log.Printf("Received LEAVE_ROOM from Client %s", c.ID)
				// Player explicitly leaving. Forfeit game.
				if c.Session != nil {
					log.Printf("Client %s has valid session. Processing forfeit.", c.ID)
					var opponent *Client
					var winnerStr string
					var winner *Client

					if c == c.Session.ClientX {
						opponent = c.Session.ClientO
						winnerStr = "O"
						winner = c.Session.ClientO
					} else {
						opponent = c.Session.ClientX
						winnerStr = "X"
						winner = c.Session.ClientX
					}

					if opponent != nil {
						log.Printf("Opponent found: %s. Sending GAME_OVER.", opponent.ID)
						// Broadcast GAME_OVER to opponent
						resp, _ := json.Marshal(map[string]interface{}{
							"type":        "GAME_OVER",
							"winner":      winnerStr,
							"winningLine": nil,
							"reason":      "opponent_left",
						})
						opponent.send <- resp

						// Record verification and end session
						c.mm.endGame(c.Session, winner)
					} else {
						log.Println("Opponent is nil. Cannot notify.")
					}
				} else {
					log.Println("Client Session is nil. Ignoring LEAVE_ROOM.")
				}
			} else if msg["type"] == "CHAT_MESSAGE" {
				if roomID, ok := msg["room_id"].(string); ok && roomID != "" {
					c.rm.broadcast(roomID, message)
				} else {
					c.hub.broadcast <- message
				}
			} else {
				c.hub.broadcast <- message
			}
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()
	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// n := len(c.send)
			// for i := 0; i < n; i++ {
			// 	w.Write(<-c.send)
			// }

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func serveWs(hub *Hub, mm *Matchmaker, rm *RoomManager, w http.ResponseWriter, r *http.Request, id string) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	client := &Client{ID: id, hub: hub, mm: mm, rm: rm, conn: conn, send: make(chan []byte, 256)}
	client.hub.register <- client

	go client.writePump()
	go client.readPump()
}

func sendMatchFound(session *GameSession) {
	msg1, _ := json.Marshal(map[string]string{"type": "MATCH_FOUND", "color": "X"})
	if session.ClientX != nil {
		session.ClientX.send <- msg1
	}

	msg2, _ := json.Marshal(map[string]string{"type": "MATCH_FOUND", "color": "O"})
	if session.ClientO != nil {
		session.ClientO.send <- msg2
	}
}

func sendGameSync(c *Client, session *GameSession) {
	// Reconstruct board for sync? Or simply send history and let client replay?
	// Sending history is robust.
	// But client might want full state.
	// For now, let's send Board State + History.

	// Convert Engine Board to persistable format if needed, OR just send moves.
	// Sending moves is easiest for client to replay.

	var myColor string
	if c == session.ClientX {
		myColor = "X"
	} else {
		myColor = "O"
	}

	resp, _ := json.Marshal(map[string]interface{}{
		"type":    "GAME_SYNC",
		"color":   myColor,
		"history": session.Engine.History,
		"turn":    session.Engine.CurrentPlayer, // engine holds strict turn
	})
	c.send <- resp
}
