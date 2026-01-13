package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"caro_chess_server/db"
)

type HistoryHandler struct {
	Repo db.UserRepository
}

func NewHistoryHandler(repo db.UserRepository) *HistoryHandler {
	return &HistoryHandler{Repo: repo}
}

func (h *HistoryHandler) GetUserMatches(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	pathParts := strings.Split(r.URL.Path, "/")
	// Expected path: /users/{id}/matches
	if len(pathParts) < 3 {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	userID := pathParts[2] // index 2 is {id} in /users/{id}/matches

	limit := 20
	if l := r.URL.Query().Get("limit"); l != "" {
		if val, err := strconv.Atoi(l); err == nil {
			limit = val
		}
	}

	matches, err := h.Repo.GetMatchesByUserID(userID, limit)
	if err != nil {
		http.Error(w, "Failed to fetch matches", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(matches)
}

func (h *HistoryHandler) GetMatch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	pathParts := strings.Split(r.URL.Path, "/")
	// Expected path: /matches/{id}
	if len(pathParts) < 3 {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	matchID := pathParts[2]

	match, err := h.Repo.GetMatch(matchID)
	if err != nil {
		http.Error(w, "Failed to fetch match", http.StatusInternalServerError)
		return
	}
	if match == nil {
		http.Error(w, "Match not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(match)
}
