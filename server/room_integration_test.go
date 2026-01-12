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

func TestRoomFlow(t *testing.T) {
	repo := db.NewFileUserRepository("test_room_flow.json")
	defer os.Remove("test_room_flow.json")
	
	hub := newHub()
	go hub.run()
	mm := newMatchmaker(repo)
	go mm.run()
	rm := newRoomManager()

	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		serveWs(hub, mm, rm, w, r, "test_user")
	}))
	defer s.Close()

	u := "ws" + strings.TrimPrefix(s.URL, "http")

	c1, _, _ := websocket.DefaultDialer.Dial(u+"?id=p1", nil)
	defer c1.Close()

	c2, _, _ := websocket.DefaultDialer.Dial(u+"?id=p2", nil)
	defer c2.Close()

	createMsg, _ := json.Marshal(map[string]string{"type": "CREATE_ROOM"})
	c1.WriteMessage(websocket.TextMessage, createMsg)

	_, m1, _ := c1.ReadMessage()
	var resp1 map[string]string
	json.Unmarshal(m1, &resp1)
	
	if resp1["type"] != "ROOM_CREATED" {
		t.Fatalf("expected ROOM_CREATED, got %v", resp1)
	}
	code := resp1["code"]

	joinMsg, _ := json.Marshal(map[string]string{"type": "JOIN_ROOM", "code": code})
	c2.WriteMessage(websocket.TextMessage, joinMsg)

	_, m1Match, _ := c1.ReadMessage()
	_, m2Match, _ := c2.ReadMessage()
	
	var r1, r2 map[string]string
	json.Unmarshal(m1Match, &r1)
	json.Unmarshal(m2Match, &r2)
	
	if r1["type"] != "MATCH_FOUND" || r2["type"] != "MATCH_FOUND" {
		t.Errorf("match failed")
	}
}
