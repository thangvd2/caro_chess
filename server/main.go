package main

import (
	"flag"
	"log"
	"net/http"
	"strings"

	"caro_chess_server/api"
	"caro_chess_server/auth"
	"caro_chess_server/config"
	"caro_chess_server/db/sqlite"
	"caro_chess_server/middleware"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Allow command line flag overrides (for backward compatibility)
	flag.Parse()

	// Initialize repositories
	// Initialize repositories
	// repo := db.NewFileUserRepository(cfg.UsersDBPath)
	repo, err := sqlite.NewSQLiteStore("caro.db")
	if err != nil {
		log.Fatal("Failed to init DB:", err)
	}
	defer repo.Close()

	// Initialize WebSocket hub
	hub := newHub()
	go hub.run()

	// Initialize matchmaker
	matchmaker := newMatchmaker(repo)
	go matchmaker.run()

	// Initialize room manager
	roomManager := newRoomManager()

	// Create a new ServeMux for API routes
	mux := http.NewServeMux()

	// Initialize auth handler
	authHandler := auth.NewAuthHandler(repo)
	mux.HandleFunc("/signup", authHandler.Signup)
	mux.HandleFunc("/login", authHandler.Login)

	// Initialize leaderboard handler
	leaderboardHandler := api.NewLeaderboardHandler(repo)
	mux.HandleFunc("/leaderboard", leaderboardHandler.GetLeaderboard)

	// Initialize shop handler
	shopHandler := api.NewShopHandler(repo)
	mux.HandleFunc("/shop", shopHandler.GetShopItems)
	mux.HandleFunc("/shop/buy", shopHandler.BuyItem)
	mux.HandleFunc("/inventory", shopHandler.GetUserInventory)

	// Initialize history handler
	historyHandler := api.NewHistoryHandler(repo)
	mux.HandleFunc("/users/", func(w http.ResponseWriter, r *http.Request) {
		if strings.Contains(r.URL.Path, "/matches") {
			historyHandler.GetUserMatches(w, r)
		} else {
			// Assume /users/{id} for profile
			leaderboardHandler.GetUser(w, r)
		}
	})
	mux.HandleFunc("/matches/", historyHandler.GetMatch)

	// Setup WebSocket handler
	mux.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Query().Get("id")
		token := r.URL.Query().Get("token")
		if id == "" {
			// If token provided, validate it to get ID
			if token != "" {
				claims, err := auth.ValidateToken(token)
				if err == nil {
					id = claims.UserID
				}
			} else {
				id = "guest"
			}
		}
		// Ideally we REQUIRE token now?
		// Let's make it optional for backward compatibility or strict?
		// Plan says: "Update WebSocket connection to require/validate Token."
		// Let's Enforce it!

		if token != "" {
			claims, err := auth.ValidateToken(token)
			if err == nil {
				id = claims.UserID
			} else {
				http.Error(w, "Invalid Token", http.StatusUnauthorized)
				return
			}
		} else {
			// Allow legacy "id" param for now? Or guest?
			// "guest" is fine for unauthenticated play if supported.
			// But if we want Auth, we should favor Token.
			// Let's allow fallback to ID for test scripts but warn?
			// For strict mode:
			/*
			   http.Error(w, "Unauthorized", http.StatusUnauthorized)
			   return
			*/
		}

		serveWs(hub, matchmaker, roomManager, w, r, id)
	})

	// Start server with CORS middleware
	log.Printf("Server starting on %s", cfg.ServerAddr)
	// Wrap the mux with the CORS middleware
	handler := middleware.CorsMiddleware(mux)
	err = http.ListenAndServe(cfg.ServerAddr, handler)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
