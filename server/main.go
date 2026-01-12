package main

import (
	"flag"
	"log"
	"net/http"
	
	"caro_chess_server/db"
)

var addr = flag.String("addr", ":8080", "http service address")

func main() {
	flag.Parse()
	
	repo := db.NewFileUserRepository("users.json")
	
	hub := newHub()
	go hub.run()
	
	matchmaker := newMatchmaker(repo)
	go matchmaker.run()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Query().Get("id")
		if id == "" {
			id = "guest"
		}
		serveWs(hub, matchmaker, w, r, id)
	})

	log.Printf("Server starting on %s", *addr)
	err := http.ListenAndServe(*addr, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}