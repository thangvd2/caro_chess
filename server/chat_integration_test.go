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

func TestChat(t *testing.T) {
	repo := db.NewFileUserRepository("test_chat.json")
	defer os.Remove("test_chat.json")
	
	hub := newHub()
	go hub.run()
	mm := newMatchmaker(repo)
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
