# Track Plan: Cosmetic Store & Monetization

## Phase 1: Models & Persistence [checkpoint: 916cc13]

- [x] **Task 1: Implement Cosmetic Models** 9f0cc80
    - Create `SkinItem` and `Inventory` models.
- [x] **Task 2: Currency & Inventory Repository** 452a796
    - Update `GameRepository` to save/load coins and owned skins.
- [x] **Task 3: Reward Logic** ac28631
    - Update `GameBloc` to award coins at the end of a match.
- [x] **Task: Conductor - User Manual Verification 'Models & Persistence' (Protocol in workflow.md)**

## Phase 2: Store UI

- [~] **Task 1: Build Store Screen**
    - Create a list of available skins with buy/equip buttons.
- [ ] **Task 2: Implement Purchase Logic**
    - Add Bloc events for purchasing and equipping items.
- [ ] **Task: Conductor - User Manual Verification 'Store UI' (Protocol in workflow.md)**

## Phase 3: Visual Integration

- [ ] **Task 1: Update Board Theming**
    - Refactor `GameBoardWidget` to support different background colors and grid styles.
- [ ] **Task 2: Update Piece Rendering**
    - Update `BoardCell` to render pieces based on the equipped skin.
- [ ] **Task: Conductor - User Manual Verification 'Visual Integration' (Protocol in workflow.md)**
