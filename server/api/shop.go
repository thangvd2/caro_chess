package api

import (
	"encoding/json"
	"net/http"

	"caro_chess_server/db"
)

type ShopHandler struct {
	Repo db.UserRepository
}

func NewShopHandler(repo db.UserRepository) *ShopHandler {
	return &ShopHandler{Repo: repo}
}

// Hardcoded shop items for now
var ShopItems = []map[string]interface{}{
	{"id": "neon_piece", "name": "Neon Pieces", "cost": 100, "type": "piece_skin"},
	{"id": "wooden_board", "name": "Wooden Board", "cost": 200, "type": "board_skin"},
	{"id": "gold_avatar", "name": "Gold Avatar Frame", "cost": 500, "type": "avatar_frame"},
}

func (h *ShopHandler) GetShopItems(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// In a real app, we might check what the user already owns to flag them,
	// but the client can do that by fetching inventory separately.

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(ShopItems)
}

type BuyRequest struct {
	UserID string `json:"user_id"`
	ItemID string `json:"item_id"`
}

func (h *ShopHandler) BuyItem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req BuyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// 1. Check if user has enough coins
	user, err := h.Repo.GetUser(req.UserID)
	if err != nil || user == nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Find item cost
	var cost int
	found := false
	for _, item := range ShopItems {
		if item["id"] == req.ItemID {
			cost = item["cost"].(int)
			found = true
			break
		}
	}

	if !found {
		http.Error(w, "Item not found", http.StatusBadRequest)
		return
	}

	if user.Coins < cost {
		http.Error(w, "Insufficient funds", http.StatusPaymentRequired)
		return
	}

	// 2. Deduct coins and add to inventory
	// Ideally this should be a transaction.
	// SQLiteStore methods are separate, but let's just call them sequentially for MVP.
	// Error handling on partial failure is a risk here but acceptable for prototype.

	if err := h.Repo.UpdateUserCoins(req.UserID, -cost); err != nil {
		http.Error(w, "Failed to process payment", http.StatusInternalServerError)
		return
	}

	if err := h.Repo.AddToInventory(req.UserID, req.ItemID); err != nil {
		// Rollback coins?
		h.Repo.UpdateUserCoins(req.UserID, cost)
		http.Error(w, "Failed to add item to inventory", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "success"})
}

func (h *ShopHandler) GetUserInventory(w http.ResponseWriter, r *http.Request) {
	// Helper to get inventory via API
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		http.Error(w, "Missing user_id", http.StatusBadRequest)
		return
	}

	items, err := h.Repo.GetInventory(userID)
	if err != nil {
		http.Error(w, "Failed to fetch inventory", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(items)
}
