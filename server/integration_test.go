package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gorilla/websocket"
)

func TestFullGameLoop(t *testing.T) {
	hub := newHub()
	go hub.run()
	mm := newMatchmaker()
	go mm.run()

	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		serveWs(hub, mm, w, r)
	}))
	defer s.Close()

	u := "ws" + strings.TrimPrefix(s.URL, "http")

	c1, _, err := websocket.DefaultDialer.Dial(u, nil)
	if err != nil {
		t.Fatalf("dial c1: %v", err)
	}
	defer c1.Close()

	c2, _, err := websocket.DefaultDialer.Dial(u, nil)
	if err != nil {
		t.Fatalf("dial c2: %v", err)
	}
	defer c2.Close()

	_, m1, _ := c1.ReadMessage()
	_, m2, _ := c2.ReadMessage()

	var resp1, resp2 map[string]string
	json.Unmarshal(m1, &resp1)
	json.Unmarshal(m2, &resp2)

	if resp1["type"] != "MATCH_FOUND" || resp2["type"] != "MATCH_FOUND" {
		t.Errorf("expected MATCH_FOUND, got %v and %v", resp1["type"], resp2["type"])
	}
	
	// C1 moves
	moveMsg, _ := json.Marshal(map[string]interface{}{"type": "MOVE", "x": 7, "y": 7})
	c1.WriteMessage(websocket.TextMessage, moveMsg)

	// Read MOVE_MADE
	_, m3, _ := c1.ReadMessage()
	_, m4, _ := c2.ReadMessage()

	var moveResp1, moveResp2 map[string]interface{}
	json.Unmarshal(m3, &moveResp1)
	json.Unmarshal(m4, &moveResp2)

	if moveResp1["type"] != "MOVE_MADE" || moveResp1["x"].(float64) != 7 {
		t.Errorf("expected MOVE_MADE at 7,7, got %v", moveResp1)
	}
	if moveResp2["type"] != "MOVE_MADE" || moveResp2["x"].(float64) != 7 {
		t.Errorf("c2 expected MOVE_MADE at 7,7, got %v", moveResp2)
	}
}