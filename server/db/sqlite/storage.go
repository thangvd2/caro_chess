package sqlite

import (
	"database/sql"
	"fmt"

	"caro_chess_server/db"

	_ "modernc.org/sqlite" // Import driver
)

type SQLiteStore struct {
	db *sql.DB
}

func NewSQLiteStore(dbPath string) (*SQLiteStore, error) {
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	store := &SQLiteStore{db: db}
	if err := store.initSchema(); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to init schema: %w", err)
	}

	return store, nil
}

func (s *SQLiteStore) initSchema() error {
	query := `
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        elo INTEGER NOT NULL DEFAULT 1200,
        games_played INTEGER DEFAULT 0,
        wins INTEGER DEFAULT 0,
        losses INTEGER DEFAULT 0,
        draws INTEGER DEFAULT 0,
        coins INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS matches (
        id TEXT PRIMARY KEY,
        player_x_id TEXT,
        player_o_id TEXT,
        winner_id TEXT,
        timestamp DATETIME
    );
    CREATE TABLE IF NOT EXISTS moves (
        match_id TEXT,
        player TEXT,
        x INTEGER,
        y INTEGER,
        move_order INTEGER,
        FOREIGN KEY(match_id) REFERENCES matches(id)
    );
    CREATE TABLE IF NOT EXISTS inventory (
        user_id TEXT,
        item_id TEXT,
        PRIMARY KEY (user_id, item_id),
        FOREIGN KEY(user_id) REFERENCES users(id)
    );
    `
	_, err := s.db.Exec(query)
	return err
}

func (s *SQLiteStore) GetUser(id string) (*db.User, error) {
	query := `SELECT id, elo, games_played, wins, losses, draws, coins FROM users WHERE id = ?`
	row := s.db.QueryRow(query, id)

	var user db.User
	err := row.Scan(&user.ID, &user.ELO, &user.GamesPlayed, &user.Wins, &user.Losses, &user.Draws, &user.Coins)
	if err == sql.ErrNoRows {
		return s.createUser(id)
	}
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (s *SQLiteStore) createUser(id string) (*db.User, error) {
	query := `INSERT INTO users (id, elo) VALUES (?, 1200)`
	_, err := s.db.Exec(query, id)
	if err != nil {
		return nil, err
	}
	return &db.User{ID: id, ELO: 1200}, nil
}

func (s *SQLiteStore) SaveUser(u *db.User) error {
	query := `INSERT INTO users (id, elo, wins, losses, draws, coins) VALUES (?, ?, ?, ?, ?, ?) 
              ON CONFLICT(id) DO UPDATE SET elo=excluded.elo, wins=excluded.wins, losses=excluded.losses, draws=excluded.draws, coins=excluded.coins`
	_, err := s.db.Exec(query, u.ID, u.ELO, u.Wins, u.Losses, u.Draws, u.Coins)
	return err
}

func (s *SQLiteStore) SaveMatch(match *db.Match) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	// Save Match
	_, err = tx.Exec(`INSERT INTO matches (id, player_x_id, player_o_id, winner_id, timestamp) VALUES (?, ?, ?, ?, ?)`,
		match.ID, match.PlayerXID, match.PlayerOID, match.WinnerID, match.Timestamp)
	if err != nil {
		tx.Rollback()
		return err
	}

	// Save Moves
	stmt, err := tx.Prepare(`INSERT INTO moves (match_id, player, x, y, move_order) VALUES (?, ?, ?, ?, ?)`)
	if err != nil {
		tx.Rollback()
		return err
	}
	defer stmt.Close()

	for _, move := range match.Moves {
		_, err = stmt.Exec(match.ID, move.Player, move.X, move.Y, move.Order)
		if err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit()
}

func (s *SQLiteStore) GetMatchesByUserID(userID string, limit int) ([]*db.Match, error) {
	query := `
        SELECT id, player_x_id, player_o_id, winner_id, timestamp
        FROM matches
        WHERE player_x_id = ? OR player_o_id = ?
        ORDER BY timestamp DESC
        LIMIT ?
    `
	rows, err := s.db.Query(query, userID, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var matches []*db.Match
	for rows.Next() {
		var m db.Match
		var winnerID sql.NullString
		err := rows.Scan(&m.ID, &m.PlayerXID, &m.PlayerOID, &winnerID, &m.Timestamp)
		if err != nil {
			return nil, err
		}
		if winnerID.Valid {
			m.WinnerID = &winnerID.String
		}
		matches = append(matches, &m)
	}
	return matches, nil
}

func (s *SQLiteStore) GetMatch(matchID string) (*db.Match, error) {
	// Get Match
	query := `SELECT id, player_x_id, player_o_id, winner_id, timestamp FROM matches WHERE id = ?`
	row := s.db.QueryRow(query, matchID)

	var m db.Match
	var winnerID sql.NullString
	err := row.Scan(&m.ID, &m.PlayerXID, &m.PlayerOID, &winnerID, &m.Timestamp)
	if err == sql.ErrNoRows {
		return nil, nil // Not Found
	}
	if err != nil {
		return nil, err
	}
	if winnerID.Valid {
		m.WinnerID = &winnerID.String
	}

	// Get Moves
	movesQuery := `SELECT x, y, player, move_order FROM moves WHERE match_id = ? ORDER BY move_order ASC`
	rows, err := s.db.Query(movesQuery, matchID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var mv db.Move
		err := rows.Scan(&mv.X, &mv.Y, &mv.Player, &mv.Order)
		if err != nil {
			return nil, err
		}
		m.Moves = append(m.Moves, mv)
	}

	return &m, nil
}

func (s *SQLiteStore) GetLeaderboard(limit int) ([]*db.User, error) {
	query := `
        SELECT id, elo, games_played, wins, losses, draws
        FROM users
        ORDER BY elo DESC
        LIMIT ?
    `
	rows, err := s.db.Query(query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []*db.User
	for rows.Next() {
		var u db.User
		if err := rows.Scan(&u.ID, &u.ELO, &u.GamesPlayed, &u.Wins, &u.Losses, &u.Draws); err != nil {
			return nil, err
		}
		users = append(users, &u)
	}
	return users, nil
}

// Close closes the database connection
func (s *SQLiteStore) Close() error {
	return s.db.Close()
}

func (s *SQLiteStore) UpdateUserCoins(userID string, amount int) error {
	_, err := s.db.Exec(`UPDATE users SET coins = coins + ? WHERE id = ?`, amount, userID)
	return err
}

func (s *SQLiteStore) AddToInventory(userID string, itemID string) error {
	_, err := s.db.Exec(`INSERT OR IGNORE INTO inventory (user_id, item_id) VALUES (?, ?)`, userID, itemID)
	return err
}

func (s *SQLiteStore) GetInventory(userID string) ([]string, error) {
	rows, err := s.db.Query(`SELECT item_id FROM inventory WHERE user_id = ?`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []string
	for rows.Next() {
		var itemID string
		if err := rows.Scan(&itemID); err != nil {
			return nil, err
		}
		items = append(items, itemID)
	}
	return items, nil
}
