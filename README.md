# Caro Chess (Cờ Caro)

A multiplayer Caro (Gomoku/Five in a Row) game built with Flutter and Go.

## Features

- **Three Game Modes**: Local PvP (same device), vs AI (3 difficulty levels), Online Multiplayer
- **Three Rule Variants**: Standard, FreeStyle, and Caro rules
- **Cross-Platform**: Runs on Web, Mobile (iOS/Android), and Desktop (macOS/Windows/Linux)
- **Competitive Play**: ELO rating system with matchmaking
- **Private Rooms**: Create rooms with shareable match codes
- **Reconnection Support**: Resume games if you disconnect
- **Cosmetic Store**: Earn coins and purchase skins

## Quick Start

### Prerequisites

- Flutter SDK (3.10.7+)
- Go 1.21+ (for the server)

### Running the App

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd little-rock
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the server (in a separate terminal):
   ```bash
   cd server
   go run .
   ```

4. Run the Flutter app:
   ```bash
   flutter run
   ```

### Running Tests

- Client tests:
  ```bash
  flutter test
  ```

- Server tests:
  ```bash
  cd server && go test ./...
  ```

## Project Structure

```
little-rock/
├── lib/                      # Flutter client
│   ├── ai/                   # AI opponent (minimax algorithm)
│   ├── bloc/                 # BLoC state management
│   ├── config/               # Application configuration
│   ├── engine/               # Game rules (client-side)
│   ├── models/               # Data models
│   ├── repositories/         # Local storage
│   ├── services/             # WebSocket, audio services
│   └── ui/                   # Widgets and screens
├── server/                   # Go WebSocket server
│   ├── config/               # Server configuration
│   ├── db/                  # User data persistence
│   ├── elo/                 # ELO rating system
│   ├── engine/              # Game rules (authoritative)
│   ├── client.go            # WebSocket client handling
│   ├── hub.go               # Connection management
│   ├── matchmaker.go        # Player matchmaking
│   ├── room_manager.go      # Private room management
│   └── main.go              # Server entry point
├── test/                     # Unit tests
├── test_vectors/             # Cross-language test scenarios
├── assets/audio/            # Sound effects
└── docs/                    # Additional documentation
```

## Documentation

- [Product Guide](conductor/product.md) - Vision, target audience, and feature overview
- [Tech Stack](conductor/tech-stack.md) - Technology choices and rationale
- [Code Style Guides](conductor/code_styleguides/) - Coding standards for Go and Dart
- [WebSocket API](docs/websocket-api.md) - WebSocket protocol reference
- [Game Rules](docs/game-rules.md) - Detailed explanation of rule variants
- [Contributing](CONTRIBUTING.md) - Guide for contributors

## Configuration

### Client Configuration (Dart/Flutter)

The client uses centralized configuration in `lib/config/app_config.dart`. Settings can be customized via:

**Environment Variables:**
- `CARO_CHESS_SERVER_URL` - WebSocket server URL (default: `ws://localhost:8080/ws`)

**Dart Compile-Time Constants:**
```bash
flutter run --dart-define=CARO_CHESS_SERVER_URL=ws://production-server.com:8080/ws
```

**Key Configuration Options:**
| Setting | Default | Description |
|---------|---------|-------------|
| `boardRows` | 15 | Game board rows |
| `boardColumns` | 15 | Game board columns |
| `serverUrl` | `ws://localhost:8080/ws` | WebSocket server URL |
| `defaultAIDifficulty` | `medium` | AI difficulty (easy/medium/hard) |
| `matchmakingEloRange` | 200 | ELO difference for matchmaking |
| `connectionTimeout` | 10 seconds | WebSocket connection timeout |
| `maxReconnectionAttempts` | 5 | Max reconnection tries |

### Server Configuration (Go)

The server uses centralized configuration in `server/config/config.go`. Settings can be customized via:

**Environment Variables:**
```bash
export CARO_CHESS_ADDR="0.0.0.0:8080"
export CARO_CHESS_USERS_DB="data/users.json"
export CARO_CHESS_BOARD_ROWS=15
export CARO_CHESS_BOARD_COLUMNS=15
export CARO_CHESS_ELO_RANGE=200
```

**Command Line Flags:**
```bash
# Using flags (for backward compatibility)
go run . -addr :9090 -users-db custom_users.json

# Using environment variables
CARO_CHESS_ADDR=:9090 go run .
```

**Key Configuration Options:**
| Setting | Environment Variable | Default | Description |
|---------|---------------------|---------|-------------|
| Server Address | `CARO_CHESS_ADDR` | `:8080` | HTTP server bind address |
| Server Host | `CARO_CHESS_HOST` | `0.0.0.0` | Server host |
| Server Port | `CARO_CHESS_PORT` | `8080` | Server port |
| Users DB Path | `CARO_CHESS_USERS_DB` | `users.json` | User database file |
| Board Rows | `CARO_CHESS_BOARD_ROWS` | `15` | Game board rows |
| Board Columns | `CARO_CHESS_BOARD_COLUMNS` | `15` | Game board columns |
| ELO Range | `CARO_CHESS_ELO_RANGE` | `200` | Matchmaking ELO range |
| Ping Interval | `CARO_CHESS_PING_INTERVAL` | `30` | WebSocket ping interval (seconds) |
| Ping Timeout | `CARO_CHESS_PING_TIMEOUT` | `60` | WebSocket ping timeout (seconds) |

## Game Rules

### Standard
First player to get exactly **5 pieces in a row** (horizontal, vertical, or diagonal) wins.

### FreeStyle
First player to get **5 or more pieces in a row** wins. Overlines count as wins.

### Caro
Must get exactly **5 pieces in a row**, and **both ends must be open** (not blocked by opponent pieces). This is the traditional Vietnamese Caro rule.

## Development

This project uses a monorepo structure with:
- **Flutter** for the cross-platform client
- **Go** for the real-time WebSocket server

Game logic is implemented in both Dart (client-side prediction) and Go (authoritative server) to ensure fair play and prevent cheating.

## License

[Specify your license here]
