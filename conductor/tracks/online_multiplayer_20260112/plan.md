# Track Plan: Online Multiplayer Infrastructure

## Phase 1: Go Backend Server

- [x] **Task 1: Set up Go Project** c8c16b0
    - Initialize `server/` directory and `go.mod`.
    - Install `gorilla/websocket`.
- [x] **Task 2: Implement WebSocket Hub and Client** 8d13bf5
    - Create `Hub` to manage clients.
    - Implement `Client` struct to read/write messages.
    - Write unit tests for connection handling.
- [x] **Task 3: Implement Matchmaking Logic** 6ab832c
    - Create `Matchmaker` to pair waiting clients.
    - Implement `GameSession` to manage board state on server.
    - Write unit tests for pairing and game loop.
- [ ] **Task: Conductor - User Manual Verification 'Go Backend Server' (Protocol in workflow.md)**

## Phase 2: Flutter Client Networking

- [ ] **Task 1: Implement WebSocket Service**
    - Create `WebSocketService` in Flutter to connect to server.
    - Implement JSON serialization for game messages.
- [ ] **Task 2: Update GameBloc for Online Play**
    - Add `GameMode.online`.
    - Handle socket events (`MATCH_FOUND`, `MOVE_MADE`).
- [ ] **Task: Conductor - User Manual Verification 'Flutter Client Networking' (Protocol in workflow.md)**

## Phase 3: Integration & UI

- [ ] **Task 1: Online Match UI**
    - Add "Play Online" button.
    - Add "Searching for match" overlay.
- [ ] **Task 2: End-to-End Testing**
    - Verify full game loop with local server and two clients (simulated or real).
- [ ] **Task: Conductor - User Manual Verification 'Integration & UI' (Protocol in workflow.md)**
