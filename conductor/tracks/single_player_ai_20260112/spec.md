# Track Spec: Single Player AI Integration

## Overview
This track introduces a single-player mode where users play against an AI opponent. The AI utilizes the Minimax algorithm with Alpha-Beta pruning to provide a challenging experience.

## Technical Requirements

### 1. AI Engine (Logic)
- **Heuristic Evaluation:** A scoring function that evaluates a board state based on patterns (e.g., open 3s, blocked 4s).
- **Move Generation:** Efficiently find relevant empty cells (neighbors of existing pieces) to reduce search space.
- **Minimax Algorithm:** Recursive search with depth limits.
- **Alpha-Beta Pruning:** Optimization to cut off irrelevant branches.
- **Difficulty Levels:**
    - **Easy:** Random moves or depth 1 + randomness.
    - **Medium:** Depth 2-3.
    - **Hard:** Depth 4+.

### 2. Concurrency
- **Isolate Integration:** AI calculations must run in a separate Isolate (using `compute`) to prevent UI jank.

### 3. State Management (Bloc)
- **GameBloc Updates:**
    - New Event: `AIMoveRequested`.
    - New State: `GameAIThinking` (to show spinner).
    - Logic to trigger AI move after player move if `gameMode == singlePlayer`.

### 4. UI Updates
- **Menu:** "Play vs AI" button in `GameControls` or a new Start Screen.
- **Difficulty Selector:** Dropdown to choose Easy/Medium/Hard.
- **Thinking Indicator:** Visual cue (spinner/text) when AI is calculating.

## Acceptance Criteria
- [ ] AI can play legal moves.
- [ ] AI blocks immediate threats (3 or 4 in a row).
- [ ] AI wins if given the chance (finds 5 in a row).
- [ ] UI remains responsive while AI is thinking.
- [ ] User can select difficulty.
- [ ] "Easy" is noticeably weaker than "Hard".
