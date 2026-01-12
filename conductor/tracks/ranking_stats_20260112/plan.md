# Track Plan: Ranking and Statistics System

## Phase 1: Backend ELO & Persistence (Go) [checkpoint: edb49da]

- [x] **Task 1: Implement ELO Calculator** db95ad7
    - Create `elo.go` with calculation logic.
    - Write unit tests for rating updates.
- [x] **Task 2: Setup Database Persistence** 4640a89
    - Implement a simple repository to save/load user stats.
    - Write unit tests for data persistence.
- [x] **Task 3: Integrate with Game Loop** fe9b6e4
    - Update `GameSession` to trigger ELO updates on match end.
    - Write integration tests for end-of-match stats update.
- [x] **Task: Conductor - User Manual Verification 'Backend ELO & Persistence' (Protocol in workflow.md)**

## Phase 2: Client Profile & Visual Tiers (Flutter) [checkpoint: c42bf93]

- [x] **Task 1: Implement User Models and Tier Logic** 77f449e
    - Create `UserProfile` model.
    - Add logic to calculate visual tiers from ELO.
    - Write unit tests for tier thresholds.
- [x] **Task 2: Build Profile UI** fa4f21b
    - Create a Profile screen.
    - Design and implement visual tier badges.
- [x] **Task: Conductor - User Manual Verification 'Client Profile & Visual Tiers' (Protocol in workflow.md)**

## Phase 3: Synchronization & Final Integration

- [x] **Task 1: Profile Sync via WebSocket** 41d8fbb
    - Add socket events to fetch and push profile data.
    - Update client state when rank changes.
- [x] **Task 2: End-to-End Testing** 9a2da6c
    - Verify that finishing an online match updates the player's profile correctly in the UI.
- [ ] **Task: Conductor - User Manual Verification 'Synchronization & Final Integration' (Protocol in workflow.md)**
