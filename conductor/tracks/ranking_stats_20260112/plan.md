# Track Plan: Ranking and Statistics System

## Phase 1: Backend ELO & Persistence (Go)

- [x] **Task 1: Implement ELO Calculator** db95ad7
    - Create `elo.go` with calculation logic.
    - Write unit tests for rating updates.
- [ ] **Task 2: Setup Database Persistence**
    - Implement a simple repository to save/load user stats.
    - Write unit tests for data persistence.
- [ ] **Task 3: Integrate with Game Loop**
    - Update `GameSession` to trigger ELO updates on match end.
    - Write integration tests for end-of-match stats update.
- [ ] **Task: Conductor - User Manual Verification 'Backend ELO & Persistence' (Protocol in workflow.md)**

## Phase 2: Client Profile & Visual Tiers (Flutter)

- [ ] **Task 1: Implement User Models and Tier Logic**
    - Create `UserProfile` model.
    - Add logic to calculate visual tiers from ELO.
    - Write unit tests for tier thresholds.
- [ ] **Task 2: Build Profile UI**
    - Create a Profile screen.
    - Design and implement visual tier badges.
- [ ] **Task: Conductor - User Manual Verification 'Client Profile & Visual Tiers' (Protocol in workflow.md)**

## Phase 3: Synchronization & Final Integration

- [ ] **Task 1: Profile Sync via WebSocket**
    - Add socket events to fetch and push profile data.
    - Update client state when rank changes.
- [ ] **Task 2: End-to-End Testing**
    - Verify that finishing an online match updates the player's profile correctly in the UI.
- [ ] **Task: Conductor - User Manual Verification 'Synchronization & Final Integration' (Protocol in workflow.md)**
