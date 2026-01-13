# Track Spec: Cosmetic Store & Monetization

## Overview
This track adds a commercial layer to the game by introducing "Skins" for game elements (X/O pieces and the board itself) and a virtual currency system to purchase them.

## Technical Requirements

### 1. Currency & Inventory System
- **Virtual Currency (Coins):** Players earn coins by winning matches (e.g., 50 per win, 10 per loss).
- **Persistent Inventory:** Track which skins the user owns.
- **Persistence:** Save currency and inventory to `shared_preferences`.

### 2. Cosmetics (Skins)
- **Piece Skins:**
    - Default (X/O)
    - Neon (Glowing Blue/Red)
    - Classic (Serif fonts)
- **Board Themes:**
    - Default (White/Grey)
    - Dark Mode (Black/Navy)
    - Wooden (Tan/Brown)

### 3. Store UI
- **Store Screen:** List available items with prices and preview images.
- **Purchasing Logic:** Deduct coins and add to inventory.
- **Equipping Logic:** Select an owned skin to use in-game.

### 4. Gameplay Integration
- Update `GameBoardWidget` and `BoardCell` to use the currently equipped skin/theme from the user's profile.

## Acceptance Criteria
- [ ] Users earn coins after completing a match.
- [ ] Store displays all available skins with correct prices.
- [ ] Users can purchase a skin if they have enough coins.
- [ ] Purchased skins persist across app restarts.
- [ ] Equipping a skin immediately updates the game board visuals.
