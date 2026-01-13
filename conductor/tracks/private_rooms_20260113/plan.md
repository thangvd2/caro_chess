# Track Plan: Private Rooms and Match Codes

## Phase 1: Backend Room Logic (Go) [checkpoint: acf4b8c]

- [x] **Task 1: Implement Room Manager** 06249e5
    - Create `RoomManager` struct to store private sessions by code.
    - Implement code generation logic.
    - Write unit tests for room creation and joining.
- [x] **Task 2: Update Protocol Handlers** 8f6986b
    - Update `Client.readPump` to handle `CREATE_ROOM` and `JOIN_ROOM`.
    - Integrate `RoomManager` into `main.go`.
- [x] **Task: Conductor - User Manual Verification 'Backend Room Logic' (Protocol in workflow.md)**

## Phase 2: Frontend Integration (Flutter)

- [x] **Task 1: Update WebSocket Service & Bloc** cd486cc
    - Add methods to send `CREATE_ROOM` and `JOIN_ROOM`.
    - Handle `ROOM_CREATED` event in `GameBloc`.
- [x] **Task 2: Build Room UI** 5869e97
    - Create `RoomControlWidget` (or update existing) with Create/Join buttons.
    - Create `WaitingRoomWidget` to show the code while waiting.
- [ ] **Task: Conductor - User Manual Verification 'Frontend Integration' (Protocol in workflow.md)**

## Phase 3: Final Verification

- [ ] **Task 1: End-to-End Testing**
    - Verify creating a room on Client A and joining with Client B works.
- [ ] **Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)**
