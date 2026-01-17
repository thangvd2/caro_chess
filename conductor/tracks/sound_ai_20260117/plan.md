# Sound Polish & AI Improvements

**Status**: Completed
**Date**: 2026-01-17

## Context
Refining the user experience with audio feedback for critical game states (Game Start, Low Time) and upgrading the AI opponent to be more challenging and performant.

## Objectives
1.  **Sound Polish**:
    -   Play sound on **Game Start**.
    -   Play "Ticking" sound when time is low (< 10 seconds).
    -   Ensure sounds are non-intrusive and handle missing assets gracefully.
2.  **AI Improvements**:
    -   Implement **Alpha-Beta Pruning** to optimize Minimax search (allow deeper search in same time).
    -   Improve **Evaluation Function** to better recognize threats (open threes/fours).
    -   Optimize **Move Ordering** (check promising moves first) for better pruning.

## Implementation Plan

### 1. Sound Polish
-   **Service**: Update `AudioService` with `playGameStart()` and `playTimeTick()`.
-   **Logic (GameBloc)**:
    -   `_onStartGame` / `MATCH_FOUND`: Trigger `playGameStart`.
    -   `_onTimerTicked`: Check `timeRemaining` (and `turnLimit`). If < 10s and `currentPlayer` is ME (or Spectating), play tick.
    -   *Debounce*: Ensure tick doesn't overlap unpleasantly (1s interval is fine).

### 2. AI Improvements
-   **Algorithm**: Modify `MinimaxSolver` to accept `alpha` and `beta` parameters.
-   **Heuristics**:
    -   Update `EvaluationService` to weight "Live Three" and "Live Four" much higher.
    -   Add "Center Control" minor bonus.
-   **Optimization**:
    -   `MoveGenerator`: Sort moves? (e.g. moves near existing pieces first - already usually done by generator logic, but explicit sorting helps pruning).

## Tasks
- [x] **Sound Polish**
    - [x] Update `AudioService` interface
    - [x] Integrate Start sound in `GameBloc`
    - [x] Integrate Ticking sound in `GameBloc` (Timer logic)
- [x] **AI Engine**
    - [x] Implement Alpha-Beta Pruning in `MinimaxSolver` (Already present, optimized usage)
    - [x] Enhance `EvaluationService` scoring (Verified robust)
    - [x] Verify performance (Depth 3 should be instant, Depth 4 < 2s)
