# Monetization Track: Ads & In-App Purchases

## Goal
Implement a comprehensive monetization strategy using Google AdMob (Interstitial & Rewarded Ads) and In-App Purchases (Consumable Coin Packs & Non-Consumable Ad Removal).

## Implementation Status

### [x] Phase 1: Ads Integration
- **Rewarded Ads**: Added "Watch Ad" card in Shop to earn 50 coins.
- **Interstitial Ads**:
  - Triggered after every 3 games.
  - Frequency capping implemented in `GameBloc`.
  - Persistence logic in `AdService` to enforce ad viewing across restarts.
  - **Premium Check**: Skipped if user has "Remove Ads" product.

### [x] Phase 2: In-App Purchases (IAP)
- **Infrastructure**:
  - `IAPService` created to handle Store connection and Product queries.
  - `GameBloc` listens to `purchaseStream` for events.
- **Products**:
  - `com.carochess.remove_ads` (Non-Consumable): Sets `isPremium` flag.
  - `com.carochess.coins_100/500/1000` (Consumables): Adds coins to inventory.
- **UI**:
  - `ShopScreen` updated with "Remove Ads" banner and "Coins" tab.
  - Mock IAP logic added for Debug builds to verify UI flow.

### [x] Phase 3: Verification
- Verified Mock Purchase flow in Debug mode.
- Verified Premium synchronization between `GameBloc` and `AdService`.
- Verified UI responsiveness and layout.

## Artifacts
- Walkthrough: [walkthrough_monetization.md](../../../.gemini/antigravity/brain/3b5be7b3-6c38-4ffc-b8c7-355a16c0fd43/walkthrough_monetization.md)
