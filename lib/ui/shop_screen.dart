import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/shop_service.dart';
import '../services/iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/ad_service.dart';
import '../models/shop_models.dart';
import '../models/cosmetics.dart'; // For SkinType
import '../bloc/game_bloc.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ShopService _service = ShopService();
  final AdService _adService = AdService();
  final IAPService _iapService = IAPService();
  
  List<ShopItem>? _items;
  bool _isLoading = true;
  bool _isPremium = false;
  final Set<String> _processingItems = {};
  StreamSubscription<List<PurchaseDetails>>? _iapSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _adService.loadRewardedAd();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
      await _iapService.initialize();
      // Listen to purchases
      _iapSubscription = _iapService.purchaseStream.listen((purchaseDetailsList) {
          _handlePurchaseUpdates(purchaseDetailsList);
      });
      
      // Load premium status
      // AdService.isPremium is a synchronous getter/field
      setState(() {
          _isPremium = _adService.isPremium; 
      });
  }

  @override
  void dispose() {
      _iapSubscription?.cancel();
      super.dispose();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
      for (var purchase in purchaseDetailsList) {
          if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
              if (purchase.productID == 'com.carochess.remove_ads') {
                  context.read<GameBloc>().add(PurchaseRestored());
                  setState(() => _isPremium = true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ads Removed! Thank you!")));
              } else if (purchase.productID.contains('coins')) {
                  int amount = 0;
                  if (purchase.productID.contains('1000')) amount = 1000;
                  else if (purchase.productID.contains('500')) amount = 500;
                  else if (purchase.productID.contains('100')) amount = 100;
                  
                  if (amount > 0) {
                      context.read<GameBloc>().add(CoinsPurchased(amount));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Purchased $amount Coins!")));
                  }
              }
          }
      }
  }

  Future<void> _loadData() async {
    try {
        final items = await _service.getShopItems();
        
        if (!mounted) return;
        final state = context.read<GameBloc>().state;
        final uid = state.userProfile?.id;
        
        if (uid != null) {
            final coins = await _service.getUserCoins(uid);
            if (coins != null && mounted) {
                context.read<GameBloc>().add(SyncShopState(coins: coins));
            }
        }

        if (mounted) {
            setState(() {
                _items = items;
                _isLoading = false;
            });
        }
    } catch (e) {
        if (mounted) {
             setState(() => _isLoading = false);
        }
    }
  }

  Future<void> _buy(ShopItem item) async {
     setState(() => _processingItems.add(item.id));
     
     if (!mounted) return;
     final state = context.read<GameBloc>().state;
     String uid = state.userProfile?.id ?? "guest";

     final newBalance = await _service.buyItem(uid, item.id);
     
     if (mounted) {
         setState(() => _processingItems.remove(item.id));
         if (newBalance != null) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful!')));
             context.read<GameBloc>().add(SyncShopState(coins: newBalance, unlockedItemId: item.id));
         } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase failed (Insufficient funds or error)')));
         }
     }
  }
  
  SkinType _mapType(String type) {
      if (type == 'board_skin') return SkinType.board;
      if (type == 'piece_skin') return SkinType.piece;
      return SkinType.avatarFrame;
  }
  
  void _equip(ShopItem item) {
       if (!mounted) return;
       final state = context.read<GameBloc>().state;
       if (state.inventory?.ownedItemIds.contains(item.id) ?? false) {
           context.read<GameBloc>().add(EquipItemRequested(item.id, _mapType(item.type)));
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Equipped ${item.name}')));
       }
  }

  void _watchAd() {
      _adService.showRewardedAd(onUserEarnedReward: (amount) {
          context.read<GameBloc>().add(EarnCoins(50));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You earned 50 Coins!")));
      });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to inventory changes for coins/ownership
    final coinBalance = context.select((GameBloc bloc) => bloc.state.inventory?.coins ?? 0);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Cosmetics Shop'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: "Coins"),
                Tab(text: "Pieces"),
                Tab(text: "Boards"),
                Tab(text: "Avatars"),
              ],
            ),
            actions: [
                Center(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text("Coins: $coinBalance", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                )
            ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                    // Remove Ads (Floating Top)
                    if (_iapService.isAvailable) _buildRemoveAdsSection(),
                    
                    // Main Content
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildCoinsTab(),
                          _buildCategoryGrid('piece_skin'),
                          _buildCategoryGrid('board_skin'),
                          _buildCategoryGrid('avatar_frame'),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCoinsTab() {
      return ListView(
          padding: const EdgeInsets.all(16),
          children: [
               // Free Coins Section
               const Text("Free Coins", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               _buildAdCard(),
               
               const SizedBox(height: 24),
               
               // Coin Packs Section
               const Text("Coin Packs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               if (_iapService.isAvailable)
                 GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                        _buildCoinPack('com.carochess.coins_100', 100, Colors.blue),
                        _buildCoinPack('com.carochess.coins_500', 500, Colors.purple),
                        _buildCoinPack('com.carochess.coins_1000', 1000, Colors.amber),
                    ],
                 )
               else 
                 const Center(child: Text("Store not available")),
          ],
      );
  }

  Widget _buildRemoveAdsSection() {
     final removeAdsProduct = _iapService.getProduct('com.carochess.remove_ads');
     
     // Only show if available and not premium
     if (_isPremium || removeAdsProduct == null) return const SizedBox.shrink();

     return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
                _iapService.buyNonConsumable(removeAdsProduct);
            },
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Icon(Icons.block),
                    const SizedBox(width: 8),
                    Text("Remove Ads (${removeAdsProduct.price})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
            ),
        ),
     );
  }

  Widget _buildCoinPack(String id, int amount, Color color) {
      final product = _iapService.getProduct(id);
      if (product == null) return const SizedBox.shrink();

      return Card(
          color: color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withOpacity(0.3), width: 1)
          ),
          child: InkWell(
              onTap: () => _iapService.buyConsumable(product),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(Icons.monetization_on, color: color, size: 32),
                          const SizedBox(height: 8),
                          Text("$amount Coins", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                          const SizedBox(height: 4),
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text(product.price, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                  ),
              ),
          ),
      );
  }

  Widget _buildAdCard() {
      return Container(
          // Margin handled by parent list view
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.shade900, Colors.deepPurple.shade700]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade400, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
              children: [
                  const Icon(Icons.play_circle_fill, color: Colors.amber, size: 36),
                  const SizedBox(width: 16),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text("Need more Coins?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                              SizedBox(height: 4),
                              Text(kIsWeb ? "Claim 50 Coins (Web Dev)" : "Watch a short video to earn 50 Coins", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                      ),
                  ),
                  ElevatedButton(
                      onPressed: _watchAd,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber, 
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 0,
                      ),
                      child: const Text("Watch", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
              ],
          ),
      );
  }

  Widget _buildCategoryGrid(String type) {
    final categoryItems = _items?.where((i) => i.type == type).toList() ?? [];
    
    if (categoryItems.isEmpty) {
      return const Center(child: Text("No items in this category"));
    }

    return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
        ),
        itemCount: categoryItems.length,
        itemBuilder: (context, index) {
            final item = categoryItems[index];
            return _ShopItemCard(
                item: item,
                isLoading: _processingItems.contains(item.id),
                onBuy: () => _buy(item),
                onEquip: () => _equip(item),
            );
        },
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool isLoading;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  const _ShopItemCard({
    required this.item,
    this.isLoading = false,
    required this.onBuy,
    required this.onEquip,
  });

  SkinType _mapType(String type) {
      if (type == 'board_skin') return SkinType.board;
      if (type == 'piece_skin') return SkinType.piece;
      return SkinType.avatarFrame;
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.select((GameBloc bloc) => bloc.state.inventory);
    final ownedItems = inventory?.ownedItemIds ?? [];
    final isOwned = ownedItems.contains(item.id);

    bool isEquipped = false;
    if (inventory != null) {
        switch (_mapType(item.type)) {
            case SkinType.board:
                isEquipped = inventory.equippedBoardSkinId == item.id;
                break;
            case SkinType.piece:
                isEquipped = inventory.equippedPieceSkinId == item.id;
                break;
            case SkinType.avatarFrame:
                isEquipped = inventory.equippedAvatarFrameId == item.id;
                break;
        }
    }

    return Card(
        clipBehavior: Clip.antiAlias, // Needed for banner positioning
        shape: isEquipped 
          ? RoundedRectangleBorder(side: const BorderSide(color: Colors.green, width: 2), borderRadius: BorderRadius.circular(12))
          : null,
        child: Stack(
            children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          Icon(Icons.diamond, size: 48, color: Colors.purple.shade200),
                          const SizedBox(height: 8),
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          Text('${item.cost} Coins', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                          const Spacer(),
                          if (!isEquipped) 
                              if (isOwned)
                                  ElevatedButton(
                                      onPressed: onEquip, 
                                      child: const Text('Equip'),
                                  )
                              else
                                  ElevatedButton(
                                      onPressed: isLoading ? null : onBuy,
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: isLoading 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Buy'),
                                  )
                          else
                              const SizedBox(height: 36), // Height of button placeholder
                      ],
                  ),
                ),
                if (isEquipped)
                    Positioned(
                        top: 12,
                        right: -30,
                        child: Transform.rotate(
                            angle: 0.785, // 45 degrees in radians
                            child: Container(
                                width: 100,
                                color: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: const Text(
                                    "EQUIPPED",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold
                                    ),
                                ),
                            ),
                        ),
                    ),
            ],
        ),
    );
  }
}
