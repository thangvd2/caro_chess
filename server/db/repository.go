package db

import (
	"encoding/json"
	"os"
	"sync"
	"time"
)

type User struct {
	ID          string `json:"id"`
	ELO         int    `json:"elo"`
	GamesPlayed int    `json:"games_played"`
	Wins        int    `json:"wins"`
	Losses      int    `json:"losses"`
	Draws       int    `json:"draws"`
	Coins       int    `json:"coins"`
}

type Match struct {
	ID        string    `json:"id"`
	PlayerXID string    `json:"player_x_id"`
	PlayerOID string    `json:"player_o_id"`
	WinnerID  *string   `json:"winner_id"` // null if draw
	Moves     []Move    `json:"moves"`
	Timestamp time.Time `json:"timestamp"`
}

type Move struct {
	X      int    `json:"x"`
	Y      int    `json:"y"`
	Player string `json:"player"` // "X" or "O"
	Order  int    `json:"order"`
}

type UserRepository interface {
	SaveUser(user *User) error
	GetUser(id string) (*User, error)
	SaveMatch(match *Match) error
	GetMatchesByUserID(userID string, limit int) ([]*Match, error)
	GetMatch(matchID string) (*Match, error)
	GetLeaderboard(limit int) ([]*User, error)
	UpdateUserCoins(userID string, amount int) error
	AddToInventory(userID string, itemID string) error
	GetInventory(userID string) ([]string, error)
}

type FileUserRepository struct {
	filename string
	users    map[string]*User
	mu       sync.RWMutex
}

func NewFileUserRepository(filename string) *FileUserRepository {
	repo := &FileUserRepository{
		filename: filename,
		users:    make(map[string]*User),
	}
	repo.load()
	return repo
}

func (r *FileUserRepository) load() error {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := os.ReadFile(r.filename)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}

	return json.Unmarshal(data, &r.users)
}

func (r *FileUserRepository) SaveUser(user *User) error {
	r.mu.Lock()
	r.users[user.ID] = user
	data, err := json.MarshalIndent(r.users, "", "  ")
	r.mu.Unlock()

	if err != nil {
		return err
	}
	return os.WriteFile(r.filename, data, 0644)
}

func (r *FileUserRepository) GetUser(id string) (*User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if u, ok := r.users[id]; ok {
		copy := *u
		return &copy, nil
	}

	return &User{ID: id, ELO: 1200}, nil
}

func (r *FileUserRepository) SaveMatch(match *Match) error {
	return nil
}

func (r *FileUserRepository) GetMatchesByUserID(userID string, limit int) ([]*Match, error) {
	return []*Match{}, nil
}

func (r *FileUserRepository) GetLeaderboard(limit int) ([]*User, error) {
	return []*User{}, nil
}

func (r *FileUserRepository) UpdateUserCoins(userID string, amount int) error {
	return nil
}

func (r *FileUserRepository) AddToInventory(userID string, itemID string) error {
	return nil
}

func (r *FileUserRepository) GetInventory(userID string) ([]string, error) {
	return []string{}, nil
}

func (r *FileUserRepository) GetMatch(matchID string) (*Match, error) {
	return nil, nil // Or error not found
}
