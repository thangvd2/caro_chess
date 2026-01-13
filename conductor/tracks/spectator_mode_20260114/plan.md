# Track: Spectator Mode

**Goal**: Allow users to join active games as spectators, watching the gameplay in real-time without being able to interact.

## Tasks

### Phase 1: Server Logic
- [x] **Task 1: Room Spectators**
    - Update `Room` struct: Add `Spectators map[*WebSocket]string`.
    - Update `JoinRoom`: If room has 2 players, add new user as spectator.
    - Update `Broadcast`: Ensure spectators receive `MOVE_MADE`, `GAME_OVER`, `CHAT_MESSAGE`.
- [x] **Task 2: Game State Sync**
    - When spectator joins, send current board state (`MATCH_FOUND` equivalent but `SPECTATOR_JOINED`).

### Phase 2: Client UI
- [x] **Task 1: Game State Handling**
    - Handle `SPECTATOR_JOINED` message in `GameBloc`.
    - Update `GameInProgress`: Add `isSpectating` flag (or infer from `myPlayer == null`).
- [x] **Task 2: UI Updates**
    - `GameControlsWidget`: Disable interaction (Undo/Resign) for spectators.
    - `GameBoardWidget`: Disable touch input for spectators.
    - `VictoryOverlay`: Show "Game Over: X Won" instead of "You Won/Lost".
    - `PlayerInfo`: Show both X and O profile info (if available).

## Verification Plan
- **Server**: 3 clients join same room. 3rd client receives updates.
- **Client UI**:
    - Spectator sees moves in real-time.
    - Spectator cannot place pieces.
    - Spectator sees chat.
