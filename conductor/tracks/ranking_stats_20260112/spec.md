# Track Spec: Ranking and Statistics System

## Overview
This track introduces a competitive ranking system to Caro Chess. It involves implementing an ELO rating algorithm on the backend, persisting user statistics (wins, losses, rank), and displaying this information in the Flutter app through a profile section and rank badges.

## Technical Requirements

### 1. Backend (Go)
- **ELO Algorithm:**
    - Calculate new ratings for both players after a match ends.
    - Base K-factor: 32 (standard).
- **Persistence (Database):**
    - Store player records: `user_id`, `elo`, `wins`, `losses`, `draws`.
    - Use SQLite or a simple JSON file for MVP persistence.
- **Protocol Updates:**
    - `GET_PROFILE`: Client requests stats.
    - `UPDATE_RANK`: Server pushes new rank after match.

### 2. Frontend (Flutter)
- **Profile Section:**
    - New screen to display player stats.
    - Display current ELO and Win/Loss ratio.
- **Visual Tiers:**
    - Define thresholds for tiers:
        - **Bronze:** 0 - 1199
        - **Silver:** 1200 - 1499
        - **Gold:** 1500 - 1799
        - **Platinum:** 1800+
    - Visual indicators (badges/colors) for each tier.
- **State Management:**
    - Update `GameBloc` or create `UserBloc` to manage profile data.

## Acceptance Criteria
- [ ] Backend correctly calculates ELO changes after a match.
- [ ] User stats are saved and persist after server restart.
- [ ] Flutter app displays the correct tier based on ELO.
- [ ] Win/Loss stats match the match history.
- [ ] Profile updates immediately after an online match ends.
