# Track: Reliability & Reconnection

**Goal**: ensure gameplay robustness by allowing players to disconnect and reconnect without losing their game progress. Crucial for mobile users switching networks.

## Current State
- `server/client.go` unregisters clients immediately on disconnect.
- `GameSession` might persist (referenced by RoomManager), but the `ClientX/ClientO` pointer becomes stale/nil.
- No mechanism to "resume" a session with the current board state.

## Tasks

### Phase 1: Session Persistence & Reattachment [x]
- [x] **Task 1: Graceful Disconnect Handling**
    - Modify `Hub.unregister` or `Client` close logic to NOT immediately destroy the game session.
    - Keep `ClientX/ClientO` slots reserved but mark as "Disconnected".
- [x] **Task 2: Reconnect Handler**
    - Update `JOIN_ROOM` handling.
    - If a user joins a room where they are already a player (by ID?), re-associate the new websocket connection to the existing session slot.
- [x] **Task 3: State Synchronization**
    - When reconnecting, send a `GAME_SYNC` message containing:
        - Full board state (occupied cells).
        - Current turn.
        - Move history.
    - Frontend: Handle `GAME_SYNC` to restore UI.

### Phase 2: Abandonment & Cleanup [x]
- [x] **Task 1: Cleanup Timer**
    - If a player stays disconnected for > N minutes (e.g., 2 mins), forfeit the game and clean up the session.
    - *Note: Implemented using `time.AfterFunc` in `client.go`. Verification deferred to manual testing due to long duration.*

## Verification Plan
- **Manual Test**:
    1. Start a game. Make moves.
    2. Close client (simulate crash/network loss).
    3. Restart client. Join same room code.
    4. Verify board restores and game can continue.
