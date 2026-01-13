package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"caro_chess_server/db"
	"github.com/gorilla/websocket"
)

func TestChat(t *testing.T) {
	repo := db.NewFileUserRepository("test_chat.json")
	defer os.Remove("test_chat.json")
	
	hub := newHub()
	go hub.run()
	mm := newMatchmaker(repo)
	go mm.run()
	rm := newRoomManager()

	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		serveWs(hub, mm, rm, w, r, "user1")
	}))
	defer s.Close()

	u := "ws" + strings.TrimPrefix(s.URL, "http")

	c1, _, _ := websocket.DefaultDialer.Dial(u, nil)
	defer c1.Close()
	
	c2, _, _ := websocket.DefaultDialer.Dial(u, nil)
	defer c2.Close()

	msg, _ := json.Marshal(map[string]interface{}{
		"type": "CHAT_MESSAGE",
		"text": "Hello",
		"sender_id": "user1",
	})
	c1.WriteMessage(websocket.TextMessage, msg)

	_, m, _ := c2.ReadMessage()
	var resp map[string]interface{}
	json.Unmarshal(m, &resp)
	
	if resp["type"] != "CHAT_MESSAGE" || resp["text"] != "Hello" {
		t.Errorf("Expected chat message, got %v", resp)
	}
}

func TestRoomChatIsolation(t *testing.T) {
	repo := db.NewFileUserRepository("test_chat_iso.json")
	defer os.Remove("test_chat_iso.json")
	
	hub := newHub()
	go hub.run()
	mm := newMatchmaker(repo)
	go mm.run()
	rm := newRoomManager()

	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Query().Get("id")
		serveWs(hub, mm, rm, w, r, id)
	}))
	defer s.Close()

	u := "ws" + strings.TrimPrefix(s.URL, "http")

	// C1 creates room
	c1, _, _ := websocket.DefaultDialer.Dial(u+"?id=p1", nil)
	defer c1.Close()
	c1.WriteMessage(websocket.TextMessage, []byte(`{"type":"CREATE_ROOM"}`))
	_, m1, _ := c1.ReadMessage()
	var r1 map[string]string
	json.Unmarshal(m1, &r1)
	code := r1["code"]

	// C2 joins
	c2, _, _ := websocket.DefaultDialer.Dial(u+"?id=p2", nil)
	defer c2.Close()
	joinMsg, _ := json.Marshal(map[string]string{"type": "JOIN_ROOM", "code": code})
	c2.WriteMessage(websocket.TextMessage, joinMsg)
	// Consume MATCH_FOUND
	c1.ReadMessage()
	c2.ReadMessage()

	// C3 outside
	c3, _, _ := websocket.DefaultDialer.Dial(u+"?id=p3", nil)
	defer c3.Close()

	// C1 sends Room Chat
	roomChat, _ := json.Marshal(map[string]string{
		"type": "CHAT_MESSAGE",
		"text": "Secret",
		"room_id": code,
	})
	c1.WriteMessage(websocket.TextMessage, roomChat)

	// C2 should receive
	_, m2, _ := c2.ReadMessage()
	var r2 map[string]string
	json.Unmarshal(m2, &r2)
	if r2["text"] != "Secret" {
		t.Errorf("C2 did not receive room chat")
	}

	// C3 should NOT receive
	c3.SetReadDeadline(time.Now().Add(100 * time.Millisecond))
	_, _, err := c3.ReadMessage()
	if err == nil {
		t.Errorf("C3 received isolated room chat")
	}
}