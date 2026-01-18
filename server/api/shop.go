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
	// Existing (Renamed)
	{"id": "neon_piece", "name": "Neon", "cost": 100, "type": "piece_skin"},
	{"id": "wooden_board", "name": "Wooden", "cost": 200, "type": "board_skin"},
	{"id": "gold_avatar", "name": "Gold", "cost": 500, "type": "avatar_frame"},

	// New Pieces (10) - Emojis/Styles
	{"id": "piece_fish_bear", "name": "Fish & Bear", "cost": 150, "type": "piece_skin"},
	{"id": "piece_mouse_cat", "name": "Mouse & Cat", "cost": 150, "type": "piece_skin"},
	{"id": "piece_dog_bone", "name": "Dog & Bone", "cost": 150, "type": "piece_skin"},
	{"id": "piece_sun_moon", "name": "Sun & Moon", "cost": 200, "type": "piece_skin"},
	{"id": "piece_fire_water", "name": "Fire & Water", "cost": 200, "type": "piece_skin"},
	{"id": "piece_sword_shield", "name": "Sword & Shield", "cost": 250, "type": "piece_skin"},
	{"id": "piece_alien_ufo", "name": "Alien & UFO", "cost": 300, "type": "piece_skin"},
	{"id": "piece_robot_gear", "name": "Robot & Gear", "cost": 300, "type": "piece_skin"},
	{"id": "piece_dragon_phoenix", "name": "Dragon & Phoenix", "cost": 500, "type": "piece_skin"},
	{"id": "piece_king_queen", "name": "King & Queen", "cost": 500, "type": "piece_skin"},

	// New Boards (10) - Colors/Themes
	{"id": "board_iron", "name": "Iron", "cost": 250, "type": "board_skin"},
	{"id": "board_rainbow", "name": "Rainbow", "cost": 1000, "type": "board_skin"},
	{"id": "board_forest", "name": "Forest", "cost": 200, "type": "board_skin"},
	{"id": "board_ocean", "name": "Ocean", "cost": 200, "type": "board_skin"},
	{"id": "board_desert", "name": "Desert", "cost": 200, "type": "board_skin"},
	{"id": "board_ice", "name": "Ice", "cost": 300, "type": "board_skin"},
	{"id": "board_lava", "name": "Lava", "cost": 300, "type": "board_skin"},
	{"id": "board_space", "name": "Space", "cost": 500, "type": "board_skin"},
	{"id": "board_checker", "name": "Checker", "cost": 150, "type": "board_skin"},
	{"id": "board_pink", "name": "Pink", "cost": 150, "type": "board_skin"},

	// New Avatars (10) - Frames/Gradients
	{"id": "avatar_diamond", "name": "Diamond", "cost": 1000, "type": "avatar_frame"},
	{"id": "avatar_rainbow", "name": "Rainbow", "cost": 1000, "type": "avatar_frame"},
	{"id": "avatar_fire", "name": "Fire", "cost": 400, "type": "avatar_frame"},
	{"id": "avatar_ice", "name": "Ice", "cost": 400, "type": "avatar_frame"},
	{"id": "avatar_nature", "name": "Nature", "cost": 300, "type": "avatar_frame"},
	{"id": "avatar_tech", "name": "Tech", "cost": 500, "type": "avatar_frame"},
	{"id": "avatar_royal", "name": "Royal", "cost": 800, "type": "avatar_frame"},
	{"id": "avatar_mystic", "name": "Mystic", "cost": 600, "type": "avatar_frame"},
	{"id": "avatar_cyber", "name": "Cyber", "cost": 500, "type": "avatar_frame"},
	{"id": "avatar_pixel", "name": "Pixel", "cost": 200, "type": "avatar_frame"},
}

func (h *ShopHandler) GetShopItems(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

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
	if err := h.Repo.UpdateUserCoins(req.UserID, -cost); err != nil {
		http.Error(w, "Failed to process payment", http.StatusInternalServerError)
		return
	}

	if err := h.Repo.AddToInventory(req.UserID, req.ItemID); err != nil {
		// Rollback coins
		h.Repo.UpdateUserCoins(req.UserID, cost)
		http.Error(w, "Failed to add item to inventory", http.StatusInternalServerError)
		return
	}

	// Get updated balance
	updatedUser, err := h.Repo.GetUser(req.UserID)
	newBalance := 0
	if err == nil && updatedUser != nil {
		newBalance = updatedUser.Coins
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "success",
		"new_balance": newBalance,
	})
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
