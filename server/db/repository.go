package db

import (
	"encoding/json"
	"os"
	"sync"
)

type User struct {
	ID     string `json:"id"`
	ELO    int    `json:"elo"`
	Wins   int    `json:"wins"`
	Losses int    `json:"losses"`
	Draws  int    `json:"draws"`
}

type UserRepository interface {
	SaveUser(user *User) error
	GetUser(id string) (*User, error)
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
