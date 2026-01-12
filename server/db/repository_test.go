package db

import (
	"os"
	"testing"
)

func TestSaveAndLoadUser(t *testing.T) {
	filename := "test_users.json"
	defer os.Remove(filename)

	repo := NewFileUserRepository(filename)
	
	user := &User{ID: "user1", ELO: 1200, Wins: 5, Losses: 2}
	err := repo.SaveUser(user)
	if err != nil {
		t.Fatalf("SaveUser failed: %v", err)
	}

	loaded, err := repo.GetUser("user1")
	if err != nil {
		t.Fatalf("GetUser failed: %v", err)
	}

	if loaded.ELO != 1200 || loaded.Wins != 5 {
		t.Errorf("User data mismatch: got %v", loaded)
	}
	
	user.ELO = 1232
	repo.SaveUser(user)
	
	loaded2, _ := repo.GetUser("user1")
	if loaded2.ELO != 1232 {
		t.Errorf("Update failed, got %d", loaded2.ELO)
	}
}
