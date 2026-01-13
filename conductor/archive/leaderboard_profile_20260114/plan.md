# Track: Leaderboard & Profiles

**Goal**: Implement a server-side leaderboard for ELO rankings and enhance the client profile screen with real stats.

## Tasks

### Phase 1: Server API
- [x] **Task 1: Repository**
    - `GetLeaderboard(limit int) ([]*User, error)`: Fetch top users by ELO.
- [x] **Task 2: Endpoints**
    - `GET /leaderboard`: Returns top 50 users.
    - `GET /users/{id}`: (Enhancement) Ensure it returns full stats (Wins, Losses, etc).

### Phase 2: Client UI
- [x] **Task 1: Service Layer**
    - `LeaderboardService` (or add to `UserRepository`).
    - Model: `LeaderboardEntry`.
- [x] **Task 2: Leaderboard Screen**
    - List of top players with Rank, Name, ELO.
    - Highlight current user.
- [x] **Task 3: Profile Integration**
    - Update `ProfileScreen` to fetch and display real `Wins/Losses/Draws` from server.

## Verification Plan
- **Server**: `curl` request to `/leaderboard`.
- **Client**: Check Leaderboard UI, Verify Profile stats match server data.
