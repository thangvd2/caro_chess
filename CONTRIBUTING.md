# Contributing to Caro Chess

Thank you for your interest in contributing to Caro Chess! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Project Structure](#project-structure)

---

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

---

## Development Setup

### Prerequisites

1. **Flutter SDK** (3.10.7+)
   ```bash
   flutter --version
   ```

2. **Go** (1.21+)
   ```bash
   go version
   ```

3. **Git**
   ```bash
   git --version
   ```

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/little-rock.git
   cd little-rock
   ```

3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/original-owner/little-rock.git
   ```

### Install Dependencies

**Flutter dependencies:**
```bash
flutter pub get
```

**Go dependencies:**
```bash
cd server
go mod download
cd ..
```

### Running the Application

1. Start the Go server (in one terminal):
   ```bash
   cd server
   go run .
   ```

2. Run the Flutter app (in another terminal):
   ```bash
   flutter run
   ```

---

## Code Style

### Dart / Flutter

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` to format code:
  ```bash
  dart format .
  ```
- Use `flutter analyze` to check for issues:
  ```bash
  flutter analyze
  ```

### Go

- Follow [Effective Go](https://go.dev/doc/effective_go) guidelines
- Use `gofmt` to format code (automatic with `go fmt`):
  ```bash
  go fmt ./...
  ```
- Use `go vet` to check for issues:
  ```bash
  go vet ./...
  ```

### General Principles

See [Code Style Guides](conductor/code_styleguides/general.md) for general coding principles that apply across all languages.

**Key principles:**
- Code should be readable and easy to understand
- Follow existing patterns in the codebase
- Maintain consistent formatting and naming
- Prefer simple solutions over complex ones
- Document *why* something is done, not just *what*

---

## Testing

### Running Tests

**Flutter tests:**
```bash
flutter test
```

**Go tests:**
```bash
cd server
go test ./...
```

**Run all tests:**
```bash
# Flutter tests
flutter test

# Go tests
cd server && go test ./... && cd ..
```

### Writing Tests

- Add tests for new features and bug fixes
- Aim for high test coverage on core game logic
- Follow existing test patterns in the codebase
- Use descriptive test names

**Test locations:**
- Flutter: `test/` directory (mirrors `lib/` structure)
- Go: `*_test.go` files next to source files

### Integration Tests

The project has integration tests for the Go server:
- `server/integration_test.go` - Full game loop testing
- `server/chat_integration_test.go` - Chat functionality testing

Run integration tests:
```bash
cd server
go run integration_test.go
go run chat_integration_test.go
```

---

## Submitting Changes

### Workflow

1. **Create a branch** for your work:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes** following the code style guidelines

3. **Test your changes**:
   ```bash
   flutter test
   cd server && go test ./... && cd ..
   ```

4. **Format your code**:
   ```bash
   dart format .
   cd server && go fmt ./... && cd ..
   ```

5. **Commit your changes** with a clear message:
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

   **Commit message format:**
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `refactor:` - Code refactoring
   - `test:` - Adding or updating tests
   - `chore:` - Maintenance tasks

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request** on GitHub

### Pull Request Guidelines

- Title your PR clearly (e.g., "Add feature X" or "Fix bug Y")
- Describe what changes you made and why
- Link related issues (e.g., "Fixes #123")
- Ensure all tests pass
- Request review from maintainers

### Review Process

1. Maintainers will review your PR
2. Address any feedback or requests for changes
3. Once approved, your PR will be merged

---

## Project Structure

### Client (Flutter)

```
lib/
├── ai/                    # AI opponent logic
│   ├── ai_service.dart    # AI interface
│   ├── minimax_solver.dart # Minimax algorithm
│   ├── evaluation_service.dart # Position evaluation
│   └── move_generator.dart # Valid move generation
├── bloc/                  # State management
│   └── game_bloc.dart     # Main game BLoC
├── engine/                # Game rules (client-side)
│   └── game_engine.dart   # Core game logic
├── models/                # Data models
│   ├── game_models.dart   # Game-related models
│   ├── user_profile.dart  # User profile & ELO
│   ├── cosmetics.dart     # Store items & inventory
│   └── chat_message.dart  # Chat messages
├── repositories/          # Data persistence
│   └── game_repository.dart # Local storage wrapper
├── services/              # External services
│   ├── web_socket_service.dart # WebSocket client
│   └── audio_service.dart  # Sound effects
└── ui/                    # UI components
    ├── game_board_widget.dart  # Main game board
    ├── game_controls_widget.dart # Game controls
    ├── rule_selector_widget.dart # Rule selection
    ├── rule_guidelines_widget.dart # Rule explanations
    ├── profile_screen.dart    # User profile
    ├── store_screen.dart      # In-game store
    ├── chat_panel.dart        # Chat interface
    ├── victory_overlay.dart   # Win animation
    └── shake_widget.dart      # Shake animation
```

### Server (Go)

```
server/
├── db/                     # Data persistence
│   └── user_repository.go  # User data storage
├── elo/                    # Rating system
│   └── elo.go              # ELO calculations
├── engine/                 # Game rules (authoritative)
│   ├── engine.go           # Core game logic
│   └── model.go            # Game data structures
├── client.go               # WebSocket client handling
├── hub.go                  # Connection management
├── matchmaker.go           # Player matchmaking
├── room_manager.go         # Private room management
└── main.go                 # Server entry point
```

### Key Files to Understand

| File | Purpose |
|------|---------|
| `lib/main.dart` | Flutter app entry point |
| `lib/bloc/game_bloc.dart` | State management - learn this first |
| `lib/engine/game_engine.dart` | Game rules (client) |
| `server/engine/engine.go` | Game rules (server) |
| `server/client.go` | WebSocket message handling |
| `lib/services/web_socket_service.dart` | WebSocket client wrapper |

---

## Feature Development

### Adding a New Feature

1. **Discuss first**: Open an issue to discuss the feature before implementing
2. **Follow patterns**: Look at similar features for implementation patterns
3. **Update tests**: Add tests for new functionality
4. **Update docs**: Update relevant documentation (README, API docs, etc.)

### Game Logic Changes

**Important**: Game logic is implemented in BOTH Dart and Go to prevent cheating.

When modifying game rules:
1. Update `lib/engine/game_engine.dart` (client-side)
2. Update `server/engine/engine.go` (server-side)
3. Ensure both implementations produce identical results
4. Add tests to verify consistency

---

## Getting Help

- **Documentation**: Check the [docs](docs/) folder and [conductor](conductor/) folder
- **Issues**: Search or create GitHub issues
- **Discussions**: Use GitHub Discussions for questions

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
