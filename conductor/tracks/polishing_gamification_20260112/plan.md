# Track Plan: Polishing & Gamification

## Phase 1: Audio System [checkpoint: 2c13db5]

- [x] **Task 1: Setup Audio Library and Assets** 371d4f1
    - Add `audioplayers` dependency.
    - Source and add placeholder mp3 assets.
- [x] **Task 2: Implement Audio Service** 3a70e35
    - Create `AudioService` to pre-load and play sounds.
    - Write unit tests for the service wrapper.
- [x] **Task 3: Connect Audio to UI** ed00f6e
    - Update UI listeners to trigger sounds on piece placement and game end.
- [x] **Task: Conductor - User Manual Verification 'Audio System' (Protocol in workflow.md)**

## Phase 2: Piece & Win Animations

- [x] **Task 1: Animate Board Pieces** 96e7ae7
    - Update `BoardCell` to include scale/fade animation on creation.
- [~] **Task 2: Implement Win Visualization**
    - Add a visual highlight for the winning line.
    - Implement celebration overlay.
- [ ] **Task: Conductor - User Manual Verification 'Piece & Win Animations' (Protocol in workflow.md)**

## Phase 3: "Juice" and Feedback

- [ ] **Task 1: Particle Effects**
    - Add `confetti` library.
    - Trigger particle explosion on victory.
- [ ] **Task 2: Haptics & Screen Shake**
    - Add `HapticFeedback` on placement.
    - Implement screen shake on winning move.
- [ ] **Task: Conductor - User Manual Verification 'Juice and Feedback' (Protocol in workflow.md)**
