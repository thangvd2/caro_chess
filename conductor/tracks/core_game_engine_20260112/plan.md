# Track Plan: Core Game Engine & Local Play MVP

This plan outlines the steps to implement the core game engine and local multiplayer mode.

## Phase 1: Game Engine Logic (Pure Dart) [checkpoint: 1bf615c]

- [x] **Task 1: Define Game Models and Basic State** 1238e4d
    - Create `GameBoard`, `Cell`, `Position`, and `Player` models.
- [x] **Task 2: Implement Move Validation and Turn Logic** 5942bfc
    - Write unit tests for placing pieces and switching turns.
    - Implement logic to manage the 15x15 board state.
- [x] **Task 3: Implement Win Detection - Standard Gomoku** 50a0f9e
    - Write unit tests for 5-in-a-row (H/V/D).
    - Implement detection logic.
- [x] **Task 4: Implement Win Detection - Free-style** a72fd2d
    - Write unit tests for overlines (6+ in a row).
    - Implement detection logic.
- [x] **Task 5: Implement Win Detection - Vietnamese Caro (Blocked Ends)** 991ca30
    - Write unit tests for the "blocked at both ends" edge case.
    - Implement the specific Vietnamese Caro logic.
- [x] **Task 6: Implement Undo/Redo Functionality** ab70e4c
    - Write unit tests for the move history stack.
    - Implement undo/redo logic.
- [x] **Task: Conductor - User Manual Verification 'Game Engine Logic' (Protocol in workflow.md)**

## Phase 2: Flutter UI & State Management

- [ ] **Task 1: Set up GameBloc for State Management**
    - Write tests for `GameBloc` events and state transitions.
    - Implement the Bloc to coordinate engine logic and UI.
- [ ] **Task 2: Build Basic Board UI**
    - Create `GameBoard` and `BoardCell` widgets.
    - Connect UI interactions to `GameBloc`.
- [ ] **Task 3: Implement Game Info and Controls**
    - Build UI for turn indicator, reset button, and status messages.
- [ ] **Task 4: Implement Undo/Redo Controls**
    - Add buttons to trigger undo/redo events.
- [ ] **Task: Conductor - User Manual Verification 'Flutter UI & State Management' (Protocol in workflow.md)**

## Phase 3: Rule Variations & Guidelines

- [ ] **Task 1: Rule Selection UI**
    - Implement a way for the user to select the rule set before/during a game.
- [ ] **Task 2: Rule Explanatory Guidelines**
    - Create a modal or info section that displays rules for the selected variation.
- [ ] **Task 3: Final Integration and Persistence**
    - Ensure local persistence of the game state using `shared_preferences` or similar.
- [ ] **Task: Conductor - User Manual Verification 'Rule Variations & Guidelines' (Protocol in workflow.md)**
