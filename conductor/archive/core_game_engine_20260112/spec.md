# Track Spec: Core Game Engine & Local Play MVP

## Overview
This track focuses on building the foundational game engine for Caro (Gomoku) using Flutter and Dart. It includes the game board UI, win detection logic for three different rule sets, and a local "Pass & Play" mode.

## Technical Requirements

### 1. Game Engine (Core Logic)
- **Board Representation:** A 2D grid (default 15x15, but flexible).
- **Turn Management:** Toggle between Player X and Player O.
- **Move Validation:** Prevent moves on already occupied cells.
- **Win Detection Algorithms:**
    - **Standard Gomoku:** 5 in a row (horizontal, vertical, diagonal).
    - **Vietnamese Caro:** 5 in a row, NOT blocked at both ends.
    - **Free-style:** 5 or more in a row (overlines count).
- **Game State:** `Idle`, `Playing`, `Won`, `Draw`.

### 2. UI Components (Flutter)
- **GameBoard Widget:** A responsive grid that handles tap interactions.
- **Board Cell Widget:** Visual representation of an empty cell, X, or O.
- **Game Info Panel:** Displays current turn, game status, and selected rule set.
- **Rule Selector:** UI to switch between the three rule variations.
- **Rule Guidelines:** Modal or overlay explaining the selected rule set.

### 3. State Management (Bloc)
- **GameBloc:**
    - **Events:** `StartGame`, `PlacePiece`, `ResetGame`, `ChangeRules`.
    - **States:** `GameInitial`, `GameInProgress`, `GameOver`.

### 4. Local Play
- Support for two players on the same device.
- "Undo/Redo" functionality for moves.
- Persistent state to allow resuming the local game if the app is closed.

## Acceptance Criteria
- [ ] Board renders correctly on Web, Mobile, and Desktop.
- [ ] Pieces can be placed with tap/click.
- [ ] Win detection correctly identifies winners for all 3 rule sets.
- [ ] "Blocked ends" rule in Vietnamese Caro is strictly enforced.
- [ ] Game state resets correctly.
- [ ] Rule guidelines are accessible and informative.
- [ ] Undo/Redo works reliably across all turns.
