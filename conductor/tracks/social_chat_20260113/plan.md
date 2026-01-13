# Track Plan: Social & Chat System

## Phase 1: Backend Chat Logic (Go)

- [x] **Task 1: Update Message Protocol** a2de41e
    - Define `ChatMessage` struct.
    - Update `Client.readPump` to route chat messages based on scope (Global vs Room).
- [x] **Task 2: Implement Broadcasting Logic** a2de41e
    - Add `broadcastToRoom` method to `Matchmaker` or update `Hub`.
- [ ] **Task: Conductor - User Manual Verification 'Backend Chat Logic' (Protocol in workflow.md)**

## Phase 2: Frontend Chat UI (Flutter)

- [ ] **Task 1: Create Chat Models & UI Components**
    - Define `ChatMessage` model in Dart.
    - Build `ChatOverlay` or `ChatPanel` widget.
- [ ] **Task 2: Integrate with GameBloc**
    - Update `GameBloc` to manage message history.
    - Update `WebSocketService` to handle chat events.
- [ ] **Task: Conductor - User Manual Verification 'Frontend Chat UI' (Protocol in workflow.md)**

## Phase 3: Final Verification

- [ ] **Task 1: End-to-End Testing**
    - Verify global chat between unrelated clients.
    - Verify private chat within a match.
- [ ] **Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)**
