# Track Spec: Private Rooms and Match Codes

## Overview
This track expands the online functionality to allow players to create private game sessions identified by a unique 4-6 character code. This enables direct "Play with Friend" scenarios alongside random matchmaking.

## Technical Requirements

### 1. Backend (Go)
- **Room Manager:** New component to manage private lobbies separately from the matchmaker queue.
- **Protocol Updates:**
    - `CREATE_ROOM`: Client requests a new private room. Response: `ROOM_CREATED` with `code`.
    - `JOIN_ROOM`: Client requests to join a room by `code`. Response: `MATCH_FOUND` (if success) or `ERROR` (if full/invalid).
- **Code Generation:** Generate short, memorable, unique codes (e.g., "ABCD").

### 2. Frontend (Flutter)
- **UI:**
    - "Create Room" button -> Displays waiting screen with Code.
    - "Join Room" button -> Popup to enter Code -> Join.
- **Bloc Updates:**
    - Handle `CreateRoom` and `JoinRoom` events.
    - Handle `ROOM_CREATED` response.

## Acceptance Criteria
- [ ] Backend can create a room and return a unique code.
- [ ] Backend pairs a second player who sends the correct code.
- [ ] Join request fails gracefully if code is invalid or room is full.
- [ ] UI allows copying the code to clipboard.
- [ ] Full game loop works in private rooms just like random matches.
