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
  List<String> _myInventoryIds = [];
  bool _isLoading = true;
  // TODO: Get real user ID from Auth/Repo
  final String _userId = "user_123"; // Placeholder or standard ID

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // In a real app we'd get the actual user ID from AuthService
    // For now, we might need to rely on what the GameBloc knows or a fixed ID?
    // Let's assume we can pass userID or get it from context if we had a UserBloc.
    // For this prototype, I'll fetch as if I am the logged in user.
    // But wait, _userId is needed for API calls.
    // I should probably get it from GameBloc or Auth Service.
    
    // Quick fix: Assume single player ID compatibility or fetch from repo
    // Let's just fetch items first.
    final items = await _service.getShopItems();
    
    // Fetch inventory if we can get an ID. 
    // If not, we start with empty or local.
    // For the purpose of this task, let's just show items first.
    
    // To allow buying, we need a User ID. 
    // I'll grab it from the GameBloc state if possible (userProfile)
    
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
      _refreshInventory();
    }
  }

  Future<void> _refreshInventory() async {
     // Try to get ID from GameBloc state
     final state = context.read<GameBloc>().state;
     String? uid;
     if (state is GameInProgress) uid = state.userProfile?.id;
     
     // Fallback to "guest" or whatever ID is being used
     uid ??= "guest"; 
     
     final owned = await _service.getInventory(uid);
     if (mounted) {
         setState(() {
             _myInventoryIds = owned;
         });
     }
  }

  Future<void> _buy(ShopItem item) async {
     final state = context.read<GameBloc>().state;
     String uid = (state is GameInProgress) ? state.userProfile?.id ?? "guest" : "guest";

     bool success = await _service.buyItem(uid, item.id);
     if (success) {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase successful!')));
             _refreshInventory();
             // Also notify GameBloc to unlock it locally
             context.read<GameBloc>().add(UnlockItem(item.id));
         }
     } else {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase failed (insufficient coins?)')));
         }
     }
  }
  
  SkinType _mapType(String type) {
      if (type == 'board_skin') return SkinType.board;
      if (type == 'piece_skin') return SkinType.piece;
      return SkinType.avatarFrame;
  }
  
  void _equip(ShopItem item) {
       context.read<GameBloc>().add(EquipItemRequested(item.id, _mapType(item.type)));
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Equipped ${item.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cosmetics Shop')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
              ),
              itemCount: _items?.length ?? 0,
              itemBuilder: (context, index) {
                  final item = _items![index];
                  final isOwned = _myInventoryIds.contains(item.id);
                  return Card(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.diamond, size: 48, color: Colors.purple.shade200),
                              const SizedBox(height: 8),
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${item.cost} Coins', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              if (isOwned)
                                  ElevatedButton(
                                      onPressed: () => _equip(item), 
                                      child: const Text('Equip'),
                                  )
                              else
                                  ElevatedButton(
                                      onPressed: () => _buy(item),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Buy'),
                                  ),
                          ],
                      ),
                  );
              },
          ),
    );
  }
}
