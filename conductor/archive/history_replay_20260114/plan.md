# Track: Game History & Replays

**Goal**: Enable users to view a list of their past games and watch a move-by-move replay of any match.

## Tasks

### Phase 1: Server API
- [x] **Task 1: Repository**
    - [x] Implement `GetMatchesByUserID(userID string, limit int) ([]*Match, error)` in `SQLiteStore`.
    - [x] Implement `GetMatch(matchID string) (*Match, error)` in `SQLiteStore`.
- [x] **Task 2: Endpoints**
    - [x] `GET /users/{id}/matches`: Returns list of detailed match summaries.
    - [x] `GET /matches/{id}`: Returns full match data including moves.

### Phase 2: Client History UI
- [x] **Task 1: Data Layer**
    - [x] Add methods to `GameRepository` / `HistoryService` to fetch history.
    - [x] Model: `MatchHistoryItem`, `MatchReplayData`.
- [x] **Task 2: UI**
    - [x] Create `HistoryScreen`: List of games (result, opponent, date).
    - [x] Add entry point from Main Menu.

### Phase 3: Replay System
- [x] **Task 1: Replay Logic**
    - [x] Update `GameEngine` or create `ReplayController`.
    - [x] Ability to `nextMove()`, `prevMove()`, `autoPlay()`.
- [x] **Task 2: Replay UI**
    - [x] Reuse `GameBoard`.
    - [x] Add controls: Play/Pause, Slider, Next/Prev.

## Verification Plan
- **Server**: curl requests to fetch history.
- **Client**: Manual test (Play game -> Check history -> Watch replay).
