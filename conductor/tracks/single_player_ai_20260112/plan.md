# Track Plan: Single Player AI Integration

## Phase 1: AI Engine Logic (Pure Dart) [checkpoint: 46b394e]

- [x] **Task 1: Implement Move Generator** 1aa485f
    - Create `MoveGenerator` class to find relevant moves.
    - Write unit tests for pruning empty areas.
- [x] **Task 2: Implement Heuristic Evaluation** 6f289d4
    - Create `EvaluationService` to score board patterns.
    - Write unit tests for pattern recognition (e.g., scoring a "Open 3").
- [x] **Task 3: Implement Minimax with Alpha-Beta** a6df891
    - Create `MinimaxSolver`.
    - Write unit tests to verify it finds winning moves in simple scenarios.
- [x] **Task: Conductor - User Manual Verification 'AI Engine Logic' (Protocol in workflow.md)**

## Phase 2: AI Service & Concurrency [checkpoint: 377e20f]

- [x] **Task 1: Create AI Service with Isolate Support** 264986e
    - Implement `AIService` that uses `compute()` to run the solver.
    - Write integration tests to ensure it returns a move asynchronously.
- [x] **Task: Conductor - User Manual Verification 'AI Service & Concurrency' (Protocol in workflow.md)**

## Phase 3: UI Integration

- [x] **Task 1: Update GameBloc for AI Turn** cd347b8
    - Add `AIMoveRequested` event and `GameAIThinking` state.
    - Handle AI turn logic in Bloc.
- [ ] **Task 2: Update Game Controls for Single Player**
    - Add "Play vs AI" and Difficulty Selector to UI.
    - Show thinking indicator.
- [ ] **Task: Conductor - User Manual Verification 'UI Integration' (Protocol in workflow.md)**
