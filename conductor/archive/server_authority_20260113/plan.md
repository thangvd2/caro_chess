# Track Plan: Server Authority & Security

## Goal
Implement authoritative game logic on the Go backend to validate all moves, prevent cheating, and ensure game state integrity. Currently, the server blindly relays moves, which is insecure.

## Phase 1: Core Game Logic in Go [ ]

- [x] **Task 1: Define Game Models**
    - Create `server/engine/model.go` (or similar) to define `Board`, `Cell`, `Player`.
    - Mirror the structure from the Flutter `game_models.dart`.
- [x] **Task 2: Port Win Detection & Rules**
    - Implement `server/engine/engine.go`.
    - Port `CheckWin` logic (Standard, FreeStyle, Caro) from Dart to Go.
    - Implement `IsValidMove` (bounds check, empty cell check).
- [x] **Task 3: Unit Testing**
    - Write comprehensive tests in `server/engine/engine_test.go` to match the Flutter test suite.

## Phase 2: Server State Management [ ]

- [x] **Task 1: Update GameSession**
    - Modify `GameSession` in `server/game.go` to hold the authoritative `Board` state.
    - Initialize the board when the room is full/match starts.
- [x] **Task 2: Enforce Validation on Move**
    - Update the message handler in `hub.go` or `client.go` (wherever `MOVE` is processed).
    - Before broadcasting `MOVE`, validate it against the `GameSession` engine.
    - If valid: Update server state and broadcast.
    - If invalid: Send `ERROR` message to the offending client and do not broadcast.

## Phase 3: Game Over Handling & Optimization [ ]

- [x] **Task 1: Authoritative Game Over**
    - Server determines `GameOver` and `Winner`.
    - Send a trusted `GAME_OVER` message to clients (clients currently calculate this themselves).
- [ ] **Task 2: Reconnection Support (Optional/Stretch)**
    - Allow clients to request the current board state (snapshot) upon reconnecting.

## Phase 4: Verification [ ]

- [x] **Task 1: Cheat Simulation Test**
    - Create a test integration client that attempts to send invalid moves (occupied cell, out of turn).
    - Verify server rejects them.
    - *Note: Confirmed server validates turn order and move legality. Integration test `cheat_test.go` verifies flow.*
- [ ] **Task: Conductor - User Manual Verification 'Server Authority'**
