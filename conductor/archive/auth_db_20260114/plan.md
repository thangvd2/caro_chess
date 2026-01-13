# Track: User Authentication & Database

**Goal**: Replace the in-memory `MockRepo` with a persistent SQL database to store users, ELO ratings, and match history.

## Technology Choice
- **Database**: SQLite (via `modernc.org/sqlite` or `github.com/mattn/go-sqlite3`) for easy local development without separate server process, or PostgreSQL if scalable deployment is immediate goal. *Recommendation: SQLite for now.*
- **ORM/SQL**: Standard `database/sql` or `sqlx` or `GORM`. *Recommendation: Standard `database/sql` with simple migrations.*

## Tasks

### Phase 1: Database Setup [x]
- [x] **Task 1: Infrastructure**
    - Add SQLite driver dependency.
    - Create `server/db/sqlite` package (or `server/storage`).
    - Implement database connection and schema migration (User table).
- [x] **Task 2: Repository Implementation**
    - Implement `UserRepository` interface using SQL.
    - Methods: `CreateUser`, `GetUser`, `UpdateELO`.

### Phase 2: User Identity [~]
- [x] **Task 1: API Endpoints**
    - Add HTTP endpoints for `POST /signup` and `POST /login` (returning JWT or simple Token).
    - Update WebSocket connection to require/validate Token.
- [x] **Task 2: Client Integration**
    - Update Flutter client to call Login API before WebSocket connection.
    - Store Token in `SharedPreferences`.

### Phase 3: Match History [~]
- [~] **Task 1: Schema**
    - Create `Matches` and `Moves` tables.
- [ ] **Task 2: Recording**
    - Update `Matchmaker.endGame` to save match result to DB.

## Verification Plan
- **Unit Tests**: Test Repository implementation with in-memory SQLite.
- **Integration**: Verify Client can sign up, login, and maintain ELO across server restarts.
