package auth

import (
	"encoding/json"
	"net/http"
	"time"

	"caro_chess_server/db"

	"github.com/golang-jwt/jwt/v5"
)

var SecretKey = []byte("your-secret-key-should-be-in-env") // TODO: Move to Config

type Claims struct {
	UserID string `json:"user_id"`
	jwt.RegisteredClaims
}

type AuthHandler struct {
	Repo db.UserRepository
}

// SignupRequest structure
type SignupRequest struct {
	ID string `json:"id"`
}

// LoginRequest structure (simplified for now, usually needs password)
type LoginRequest struct {
	ID string `json:"id"`
}

func NewAuthHandler(repo db.UserRepository) *AuthHandler {
	return &AuthHandler{Repo: repo}
}

func (h *AuthHandler) Signup(w http.ResponseWriter, r *http.Request) {
	// Ideally accept password, hash it, store it.
	// For now, simpler: register ID if not exists.
	var req SignupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Check if user exists
	_, err := h.Repo.GetUser(req.ID)
	if err == nil {
		// Exists (or mock created it, but in real DB it would exist)
		// With SQLiteStore, GetUser auto-creates if missing?
		// Let's rely on CreateUser explicitly if we want strict Signup.
		// But our SQLite implementation auto-creates on Get.
		// So effectively Signup is "Ensure User Exists".
	}

	// Generate Token
	token, err := GenerateToken(req.ID)
	if err != nil {
		http.Error(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]string{"token": token, "id": req.ID})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	// Validate User exists
	_, err := h.Repo.GetUser(req.ID)
	if err != nil {
		http.Error(w, "User not found", http.StatusUnauthorized)
		return
	}

	// Generate Token
	token, err := GenerateToken(req.ID)
	if err != nil {
		http.Error(w, "Error generating token", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]string{"token": token, "id": req.ID})
}

func GenerateToken(userID string) (string, error) {
	claims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(SecretKey)
}

func ValidateToken(tokenString string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return SecretKey, nil
	})
	if err != nil {
		return nil, err
	}
	if !token.Valid {
		return nil, jwt.ErrSignatureInvalid
	}
	return claims, nil
}
