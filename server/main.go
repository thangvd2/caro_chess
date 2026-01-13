package main

import (
	"flag"
	"log"
	"net/http"

	"caro_chess_server/config"
	"caro_chess_server/db"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Allow command line flag overrides (for backward compatibility)
	flag.Parse()

	// Initialize repositories
	repo := db.NewFileUserRepository(cfg.UsersDBPath)

	// Initialize WebSocket hub
	hub := newHub()
	go hub.run()

	// Initialize matchmaker
	matchmaker := newMatchmaker(repo)
	go matchmaker.run()

	// Initialize room manager
	roomManager := newRoomManager()

	// Setup WebSocket handler
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Query().Get("id")
		if id == "" {
			id = "guest"
		}
		serveWs(hub, matchmaker, roomManager, w, r, id)
	})

	// Start server
	log.Printf("Server starting on %s", cfg.ServerAddr)
	err := http.ListenAndServe(cfg.ServerAddr, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
