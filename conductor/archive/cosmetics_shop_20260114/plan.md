# Track: Cosmetics Shop

**Goal**: Implement a virtual economy where users earn coins from games and spend them on cosmetic items (skins).

## Tasks

### Phase 1: Server Economy & Inventory
- [x] **Task 1: Database Schema**
    - Update `users` table: Add `coins` (int).
    - New table: `inventory` (`user_id`, `item_id`).
- [x] **Task 2: Repository Updates**
    - `UpdateUserCoins(userID string, amount int) error`: For earning/spending.
    - `AddToInventory(userID string, itemID string) error`.
    - `GetInventory(userID string) ([]string, error)`.
    - Update `Get/CreateUser` to include coins.
- [x] **Task 3: Shop API**
    - `GET /shop`: List available items (hardcoded or DB).
    - `POST /shop/buy`: `{userId, itemId}` -> Deducts coins, adds item.

### Phase 2: Client UI
- [x] **Task 1: Models & Service**
    - Update `UserProfile` with `coins`.
    - `ShopService`: `getShopItems()`, `buyItem()`.
- [x] **Task 2: Shop Screen**
    - Grid of items (Boards, Pieces).
    - Buy button (shows cost, disables if owned/insufficient funds).
- [x] **Task 3: Inventory & equipping**
    - "My Items" tab or integrated into Shop.
    - Equip logic (update `Inventory` state in `GameBloc` or `Settings`).

## Verification Plan
- **Server**: `curl` buy item, check coins deducted.
- **Client**: Buy item in UI, see "Owned", equip it, verify game board changes.
