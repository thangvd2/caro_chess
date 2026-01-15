# Victory Logic & Online Reliability Improvements

**Status**: Completed
**Date**: 2026-01-16

## Context
Fixed issues where online victory animations were displaying incorrectly (for losers) and player forfeits were not communicated clearly or handled safely.

## Implementation Steps

### 1. Victory Animation Fix
- **Goal**: Show confetti only for the actual winner.
- **Change**: Updated `VictoryOverlay` visibility logic in `lib/main.dart` to check `state.winner == state.myPlayer` (online) or `state.winner != null` (local).

### 2. Victory Reason ("Opponent Left")
- **Goal**: Inform the winner that the opponent disconnected/left.
- **Change**: 
    - Server (`server/client.go`): Added `reason: "opponent_left"` to `GAME_OVER` message.
    - Client (`lib/bloc/game_bloc.dart`): Added `winReason` field to `GameOver` state.
    - UI (`lib/ui/game_controls_widget.dart`): Added "(Opponent Left)" text to victory message.

### 3. Board Safety
- **Goal**: Prevent moves after the game ends via forfeit.
- **Change**: 
    - `GameBloc`: Guard clause in `_onPlacePiece`.
    - `GameBoardWidget`: Disable interactions if `state is GameOver`.

## Artifacts
- [Walkthrough](../../../.gemini/antigravity/brain/3b5be7b3-6c38-4ffc-b8c7-355a16c0fd43/walkthrough_victory_logic.md)
