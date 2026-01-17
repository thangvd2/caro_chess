# Game Turn Timer Implementation

**Status**: Completed 
**Date**: 2026-01-16

## Context
To add competitive depth, we will implement a **Chess Clock** system (Total Time Control) for online games. Players select a total time budget (e.g., 5 minutes) for the entire game. If their time runs out, they lose. This prevents stalling and adds strategic time management.

## Requirements
1.  **Online Only**: Timers only apply to Multiplayer (PvP) matches.
2.  **Time Controls (Hybrid)**:
    -   **Strict Turn Limit**: Default 30s per move (configurable?). If exceeded, forfeit.
    -   **Total Time (Chess Clock)**: Players have a total bank.
    -   **Increment**: Time added *after* each move.
3.  **Presets**:
    -   1 min + 3 sec
    -   3 min + 3 sec
    -   5 min + 5 sec
    -   10 min + 10 sec
    -   30 min + 30 sec
4.  **Server Authority**:
    -   Track `TimeRemaining` and enforce `TurnLimit`.
    -   Apply `Increment` on valid move.
    -   Auto-forfeit on either timeout.
5.  **Sync**:
    -   Send `time_remaining` and `turn_duration` (if needed) to client.

## Implementation Plan

### 1. Protocols & Models
-   **Client -> Server**: `CREATE_ROOM` / `FIND_MATCH` now accept `time_control` (int seconds).
-   **Server -> Client**:
    -   `GAME_START`: Include `initial_time` (seconds).
    -   `GAME_SYNC` / `MOVE_MADE`: Include `time_remaining_x`, `time_remaining_o` (milliseconds precision?).
    -   `GAME_OVER`: reason `timeout`.

### 2. Server-Side (Go)
-   **Structs**: Add `TimeRemainingX`, `TimeRemainingO`, `LastMoveTimestamp`.
-   **Logic**:
    -   Goroutine `ticker` that runs *only* for the active game.
    -   On `Move`: Calculate delta, update storage, switch active timer.
    -   On `Timeout`: Trigger `EndGame`.

### 3. Client-Side (Flutter)
-   **UI**:
    -   Add `TimeSelector` to `GameControlsWidget` (when creating room).
    -   Add `PlayerTimerWidget` next to avatars.
-   **BLoC**:
    -   `Timer` subscription that ticks down every second.
    -   Resyncs value from `MOVE_MADE` payload.

## Tasks
- [x] Define timer configuration in `server/config`
- [x] Implement timeout logic in `GameSession` (Server)
- [x] Update `client.go` to handle timeout forfeits
- [x] Implement `TimerWidget` in Flutter
- [x] Update `GameBloc` to manage countdown state
