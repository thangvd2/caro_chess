import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/shop_service.dart';
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
  List<ShopItem>? _items;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Fetch Items
    try {
        final items = await _service.getShopItems();
        
        // 2. Fetch latest coins (Sync)
        // Get ID from Bloc. If n/a, use guest (which won't have coins on server but safe fallback)
        final state = context.read<GameBloc>().state;
        final uid = state.userProfile?.id;
        
        if (uid != null) {
            final coins = await _service.getUserCoins(uid);
            if (coins != null && mounted) {
                // Update Bloc with latest server coin balance
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

  // Not strictly needed if we trust GameBloc state, but useful for init
  // Future<void> _refreshInventory() async { ... } 

  final Set<String> _processingItems = {};

  Future<void> _buy(ShopItem item) async {
     setState(() => _processingItems.add(item.id));
     
     final state = context.read<GameBloc>().state;
     String uid = state.userProfile?.id ?? "guest";

     // Call service to buy
     final newBalance = await _service.buyItem(uid, item.id);
     
     if (mounted) {
         setState(() => _processingItems.remove(item.id));
         if (newBalance != null) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful!')));
             // Sync result to GameBloc
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
       // Only allow equipping if we own it (UI check + Logic check)
       final state = context.read<GameBloc>().state;
       if (state.inventory?.ownedItemIds.contains(item.id) ?? false) {
           context.read<GameBloc>().add(EquipItemRequested(item.id, _mapType(item.type)));
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Equipped ${item.name}')));
       }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to inventory changes for coins/ownership
    final coinBalance = context.select((GameBloc bloc) => bloc.state.inventory?.coins ?? 0);
    // Also listen to owned items to update UI
    final ownedItems = context.select((GameBloc bloc) => bloc.state.inventory?.ownedItemIds ?? []);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Cosmetics Shop'),
            bottom: const TabBar(
              tabs: [
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
            : TabBarView(
                children: [
                  _buildCategoryGrid('piece_skin'),
                  _buildCategoryGrid('board_skin'),
                  _buildCategoryGrid('avatar_frame'),
                ],
              ),
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
