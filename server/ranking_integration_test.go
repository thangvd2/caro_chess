package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"caro_chess_server/db"
	"github.com/gorilla/websocket"
)

func TestRankingUpdate(t *testing.T) {
	repo := db.NewFileUserRepository("test_ranking.json")
	defer os.Remove("test_ranking.json")
	
	repo.SaveUser(&db.User{ID: "p1", ELO: 1200})
	repo.SaveUser(&db.User{ID: "p2", ELO: 1200})

	hub := newHub()
	go hub.run()
	mm := newMatchmaker(repo)
	go mm.run()

	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Query().Get("id")
		serveWs(hub, mm, w, r, id)
	}))
	defer s.Close()

	u := "ws" + strings.TrimPrefix(s.URL, "http")

	c1, _, err := websocket.DefaultDialer.Dial(u+"?id=p1", nil)
	if err != nil {
		t.Fatalf("dial p1: %v", err)
	}
	defer c1.Close()

	c2, _, err := websocket.DefaultDialer.Dial(u+"?id=p2", nil)
	if err != nil {
		t.Fatalf("dial p2: %v", err)
	}
	defer c2.Close()

	// Consume match found
	c1.ReadMessage()
	c2.ReadMessage()

	// P1 (X) claims win
	winMsg, _ := json.Marshal(map[string]string{"type": "WIN_CLAIM"})
	c1.WriteMessage(websocket.TextMessage, winMsg)

	// Expect UPDATE_RANK
	checkForRankUpdate(t, c1, 1216)
	checkForRankUpdate(t, c2, 1184)
}

func checkForRankUpdate(t *testing.T, c *websocket.Conn, expectedElo int) {
	for {
		_, msg, err := c.ReadMessage()
		if err != nil {
			t.Fatal(err)
		}
		var m map[string]interface{}
		json.Unmarshal(msg, &m)
		if m["type"] == "UPDATE_RANK" {
			elo := int(m["elo"].(float64))
			if elo != expectedElo {
				t.Errorf("Expected ELO %d, got %d", expectedElo, elo)
			}
			return
		}
	}
}
