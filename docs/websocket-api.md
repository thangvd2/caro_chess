# WebSocket API Reference

This document describes the WebSocket protocol used for communication between the Flutter client and Go server.

## Connection

### URL Format
```
ws://localhost:8080/ws?id=<user_id>
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | No | User identifier. Defaults to `"guest"` if not provided |

### Protocol
- **Protocol**: WebSocket (RFC 6455)
- **Message Format**: JSON
- **Encoding**: UTF-8

### Connection Lifecycle
```
Client                    Server
  |                          |
  |----- CONNECT ----------->|
  |<---- UPGRADE ------------|
  |                          |
  |----- [ Messages ] ------>|
  |<---- [ Messages ] --------|
  |                          |
  |----- CLOSE ------------->|
```

---

## Client → Server Messages

### FIND_MATCH
Queue the player for random matchmaking.

```json
{
  "type": "FIND_MATCH"
}
```

**Response**: `MATCH_FOUND` when a match is made.

---

### CREATE_ROOM
Create a private room with a generated 4-letter code.

```json
{
  "type": "CREATE_ROOM"
}
```

**Response**: `ROOM_CREATED` with the room code.

---

### JOIN_ROOM
Join an existing private room.

```json
{
  "type": "JOIN_ROOM",
  "code": "ABCD"
}
```

**Response**: `MATCH_FOUND` if successful, `ERROR` if room doesn't exist or is full.

---

### MOVE
Make a move on the game board.

```json
{
  "type": "MOVE",
  "x": 7,
  "y": 7
}
```

**Coordinates**: 0-indexed (0-14 for a 15x15 board)

**Validation**:
- Server validates it's the player's turn
- Server validates the position is within bounds
- Server validates the cell is empty
- Invalid moves are silently ignored

**Response**: `MOVE_MADE` broadcast to both players if valid.

---

### CHAT_MESSAGE
Send a chat message to other players.

```json
{
  "type": "CHAT_MESSAGE",
  "text": "Good game!",
  "sender_id": "player123",
  "room_id": "ABCD"
}
```

**Fields**:
- `text`: Message content
- `sender_id`: User identifier
- `room_id`: Optional. If provided, sends to room only. If omitted, sends to global chat.

---

## Server → Client Messages

### ROOM_CREATED
Sent when a private room is successfully created.

```json
{
  "type": "ROOM_CREATED",
  "code": "ABCD"
}
```

Share this code with a friend so they can join your room.

---

### MATCH_FOUND
Sent when a match is found (both quick match and private rooms).

```json
{
  "type": "MATCH_FOUND",
  "color": "X"
}
```

**Colors**: `"X"` or `"O"`
- Player X always goes first

---

### GAME_SYNC
Sent when reconnecting to an existing game.

```json
{
  "type": "GAME_SYNC",
  "color": "X",
  "history": [
    {"x": 7, "y": 7},
    {"x": 7, "y": 8}
  ],
  "turn": "O"
}
```

**Fields**:
- `color`: Your assigned color
- `history`: Array of all moves made (in order)
- `turn`: Current player's turn

Client should replay the history to reconstruct the board state.

---

### MOVE_MADE
Sent when either player makes a move.

```json
{
  "type": "MOVE_MADE",
  "x": 7,
  "y": 7
}
```

Broadcast to both players in the session.

---

### GAME_OVER
Sent when the game ends.

```json
{
  "type": "GAME_OVER",
  "winner": "X",
  "winningLine": [
    {"x": 5, "y": 5},
    {"x": 6, "y": 6},
    {"x": 7, "y": 7},
    {"x": 8, "y": 8},
    {"x": 9, "y": 9}
  ]
}
```

**Winner values**:
- `"X"` or `"O"`: Player won
- `"DRAW"`: Game ended in a draw
- `"OPPONENT_ABANDONED"`: Other player disconnected and timed out

**winningLine**: Array of 5 positions forming the winning line. `null` if no winner (draw/abandonment).

---

### UPDATE_RANK
Sent after a game completes with ELO rating changes.

```json
{
  "type": "UPDATE_RANK",
  "elo": 1250
}
```

New ELO rating for the current player.

---

### CHAT_MESSAGE
Sent when a chat message is received.

```json
{
  "type": "CHAT_MESSAGE",
  "sender_id": "player123",
  "text": "Good game!"
}
```

---

### ERROR
Sent when an error occurs.

```json
{
  "type": "ERROR",
  "message": "Room not found"
}
```

**Common error messages**:
- `"Room not found"`: Invalid room code
- `"Room is full"`: Room already has 2 players

---

## Game Flows

### Quick Match Flow
```
Client                    Server                 Matchmaker
  |                          |                        |
  |----- FIND_MATCH ------->|                        |
  |                          |----- ADD_CLIENT ------>|
  |                          |                        | [Waiting...]
  |                          |<----- MATCH_FOUND -----|
  |<---- MATCH_FOUND --------|                        |
  |                          |                        |
[Game begins with assigned color]
```

### Private Room Flow
```
Client 1                  Server                 Client 2
   |                         |                        |
   |----- CREATE_ROOM ------>|                        |
   |<---- ROOM_CREATED (ABCD) ------------------------|
   |                         |                        |
   [Share code with friend]  |                        |
   |                         |                        |
   |                         |<----- JOIN_ROOM (ABCD) -|
   |<------------------------|----- MATCH_FOUND ------>|
   |                         |                        |
[Both receive MATCH_FOUND with colors]
```

### Game Play Flow
```
Client X                   Server                   Client O
   |                          |                          |
   |----- MOVE (7,7) -------->|                          |
   |                          |----- MOVE_MADE (7,7) --->|
   |                          |                          |
   |                          |                    [Update UI]
   |                    [Validate & Check Win]
   |                          |                          |
[Waiting for O's turn]       |                          |
```

### Reconnection Flow
```
Client                    Server                  Session
  |                          |                         |
  |----- DISCONNECT -------->|                         |
  |                          |----- START TIMER ------->|
  |                          |                         | [2 min window]
  |----- CONNECT (reconnect) ->|                         |
  |                          |----- GET STATE --------->|
  |                          |<---- STATE (history) ----|
  |<---- GAME_SYNC ----------|                         |
  |                          |                         |
[Resume game from current state]
```

---

## Reconnection Behavior

### Disconnect Timeout
- **Duration**: 2 minutes
- **Behavior**: If a player disconnects, a timer starts
  - If the player reconnects within 2 minutes: game resumes with `GAME_SYNC`
  - If the timer expires: the opponent wins by forfeit

### Session Persistence
- Game sessions persist on the server during disconnections
- Move history is preserved
- Current turn is preserved
- Board state is reconstructed from history on reconnection

### Reconnecting
To reconnect:
1. Reconnect to WebSocket with the same `id` parameter
2. If you were in a room, send `JOIN_ROOM` with the room code
3. Server responds with `GAME_SYNC` containing the current state
4. Client replays the `history` array to reconstruct the board

---

## Error Handling

### Client-Side Errors
The client should handle:
- Connection failures (server not running)
- Unexpected message types
- Malformed JSON

### Server-Side Errors
The server will send `ERROR` messages for:
- Invalid room codes
- Attempts to join full rooms
- Invalid move attempts (though these are usually silently ignored)

### Best Practices
1. Always check the `type` field before processing a message
2. Handle unknown message types gracefully
3. Implement timeout for operations that expect responses
4. Show user-friendly error messages

---

## Testing the WebSocket API

### Using websocat
```bash
# Install websocat
cargo install websocat

# Connect as player1
websocat ws://localhost:8080/ws?id=player1

# Send a FIND_MATCH message
{"type":"FIND_MATCH"}
```

### Using wscat
```bash
# Install wscat
npm install -g wscat

# Connect
wscat -c ws://localhost:8080/ws?id=player1

# Send messages
> {"type":"FIND_MATCH"}
< {"type":"MATCH_FOUND","color":"X"}
```

---

## Implementation Reference

- **Client implementation**: `lib/services/web_socket_service.dart`
- **Server implementation**: `server/client.go`
- **Message handling**: `server/client.go:readPump()`
- **Game sync logic**: `server/client.go:sendGameSync()`
