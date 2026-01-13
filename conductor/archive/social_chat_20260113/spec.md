# Track Spec: Social & Chat System

## Overview
This track introduces real-time text communication between players. It involves updating the Go backend to handle chat messages and the Flutter client to display a chat interface in the lobby and during active matches.

## Technical Requirements

### 1. Backend (Go)
- **Message Types:**
    - `CHAT_MESSAGE`: { sender_id: string, text: string, room_id: string? }
- **Broadcasting:**
    - Global messages: Broadcast to all connected clients in the Hub.
    - Room messages: Broadcast only to participants in a specific `GameSession`.

### 2. Frontend (Flutter)
- **Chat UI:**
    - A sliding panel or overlay to view and send messages.
    - Message list with bubbles (My messages vs Opponent messages).
- **Bloc Integration:**
    - Handle `SendChatMessage` event.
    - Update state with a list of received `ChatMessage` objects.

## Acceptance Criteria
- [ ] Users can send and receive global messages in the main menu.
- [ ] Users in a private room or match can chat exclusively with their opponent.
- [ ] UI correctly distinguishes between the user's messages and others.
- [ ] Messages are delivered in real-time with minimal latency.
- [ ] Chat history is cleared when leaving a room/match.
