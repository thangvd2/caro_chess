# Client Authentication Integration Plan

**Goal**: Update Fluxter client to authenticate with the server using JWT before establishing a WebSocket connection.

## Proposed Changes

### 1. Dependencies
- Add `http` package to `pubspec.yaml` for REST API calls.

### 2. Configuration
- Update `lib/config/app_config.dart`:
    - Add `static String get authUrl` (e.g., `http://localhost:8080`).

### 3. Services
- **New** `lib/services/auth_service.dart`:
    - `Future<Map<String, dynamic>> login(String userId)`
    - `Future<Map<String, dynamic>> signup(String userId)`
    - Uses `http` to call backend.
    - Uses `SharedPreferences` to store/retrieve `auth_token`.
- **Modify** `lib/services/web_socket_service.dart`:
    - Update `connect({String? token})` method.
    - Append `?token=...` to the WebSocket URL if token is provided.

### 4. Repository
- **Modify** `lib/repositories/game_repository.dart`:
    - Add `Future<String?> ensureAuthenticated()`
    - Logic: Check for stored token. If none, generate random Guest ID, call `signup`, store token. Return token.

### 5. State Management (Bloc)
- **Modify** `lib/bloc/game_bloc.dart`:
    - In `_onStartGame`, `_onStartRoomCreation`, `_onJoinRoomRequested`:
    - Call `await _repository.ensureAuthenticated()` before `_socketService.connect()`.
    - Pass the token to `connect(token: token)`.

## Verification Plan

### Automated Tests
- **Unit Test**: `test/services/auth_service_test.dart` (Mock http client).
- **Integration Test**: Update `test/services/web_socket_service_test.dart` to verify URL construction with token (mocking the actual connection or using a test server).

### Manual Verification
1.  **Start Server**: `go run main.go`
2.  **Run Client**: `flutter run -d macos`
3.  **Action**: Start "Online Game" (Find Match).
4.  **Observation**:
    - Client should auto-signup (first time).
    - Server logs should show `/signup` request followed by `/ws` connection with valid token.
    - Game should proceed normally.
