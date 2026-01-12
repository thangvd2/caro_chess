# Track Spec: Online Multiplayer Infrastructure

## Overview
This track focuses on enabling real-time online multiplayer. It involves creating a standalone Go backend server that handles WebSocket connections, matchmaking, and game state synchronization, and integrating the Flutter client to communicate with this server.

## Technical Requirements

### 1. Backend Server (Go)
- **Framework:** Standard `net/http` or lightweight router.
- **Protocol:** WebSockets (`gorilla/websocket`) for real-time events.
- **Core Components:**
    - **Hub/Lobby:** Manages active connections.
    - **Matchmaker:** pairs players (Random pairing for MVP).
    - **Game Session:** Manages the state of a specific match (board, turns).
- **API Endpoints:**
    - `/ws`: WebSocket endpoint for connection.

### 2. Client Integration (Flutter)
- **Networking:**
    - `WebSocketClient`: Service to handle connection, sending/receiving JSON messages.
- **Bloc Updates:**
    - `OnlineGameBloc` (or update `GameBloc`) to handle network events (`MatchFound`, `OpponentMove`, `GameEnd`).
- **UI:**
    - "Play Online" button in main menu.
    - "Finding Match..." screen.

### 3. Protocol (JSON Messages)
- **Client -> Server:**
    - `FIND_MATCH`: Request to join queue.
    - `MOVE`: { x: int, y: int }
    - `SURRENDER`: Give up.
- **Server -> Client:**
    - `MATCH_FOUND`: { opponent_id: string, your_color: X/O }
    - `MOVE_MADE`: { x: int, y: int, player: X/O }
    - `GAME_OVER`: { winner: X/O, reason: string }
    - `ERROR`: { message: string }

## Acceptance Criteria
- [ ] Go server runs and accepts WebSocket connections.
- [ ] Two clients can connect and are paired into a match.
- [ ] Moves made by one client appear on the other client.
- [ ] Win condition on server propagates to clients.
- [ ] Disconnection handles gracefully (win by forfeit).
