# Tech Stack: Caro Chess (Cờ Caro)

## Frontend (Cross-Platform)
- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Rationale:** Flutter provides a single codebase for Web, Mobile (iOS/Android), and Desktop (macOS/Windows/Linux) with high-performance rendering and a rich set of animation tools, perfect for a high-energy, gamified UI.

## Backend & Infrastructure (Development)
- **Technology:** [Go (Golang)](https://go.dev/)
- **Communication:** [Gorilla WebSocket](https://github.com/gorilla/websocket) or standard `net/http` library.
- **Rationale:** A self-hosted Go server provides extremely high performance and concurrency for handling real-time game moves. It allows for completely free, offline local development without external dependencies or cloud costs. This can be containerized or migrated to cloud hosting (or swapped for Firebase) for production later.

## State Management
- **Library:** [Bloc (Business Logic Component)](https://pub.dev/packages/flutter_bloc)
- **Rationale:** Bloc enforces a clear separation between game logic and the UI, making the complex states of a turn-based game (turns, win detection, AI processing) predictable, easy to test, and scalable.

## Testing & Quality
- **Framework:** [Flutter Test](https://docs.flutter.dev/cookbook/testing/unit/introduction) with [Mockito](https://pub.dev/packages/mockito)
- **Strategy:** Prioritize unit tests for the game engine (win detection logic) and widget tests for core UI components.
- **Rationale:** This combination is the industry standard for Flutter development, ensuring the core game mechanics are solid and bug-free.

## CI/CD
- **Tool:** GitHub Actions
- **Rationale:** Automated builds and tests for all platforms on every push to ensure cross-platform compatibility remains intact.
