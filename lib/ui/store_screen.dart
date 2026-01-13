import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cosmetics.dart';
import '../bloc/game_bloc.dart';

const List<SkinItem> allSkins = [
  SkinItem(id: 'neon_piece', name: 'Neon X/O', price: 100, type: SkinType.piece, assetPath: ''),
  SkinItem(id: 'classic_piece', name: 'Classic Serif', price: 150, type: SkinType.piece, assetPath: ''),
  SkinItem(id: 'dark_board', name: 'Dark Theme', price: 200, type: SkinType.board, assetPath: ''),
  SkinItem(id: 'wooden_board', name: 'Wooden Board', price: 300, type: SkinType.board, assetPath: ''),
];

class StoreScreen extends StatelessWidget {
  final Inventory inventory;

  const StoreScreen({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cosmetic Store")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${inventory.coins} Coins",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allSkins.length,
              itemBuilder: (context, index) {
                final item = allSkins[index];
                final isOwned = inventory.ownedItemIds.contains(item.id);
                final isEquipped = (item.type == SkinType.piece && inventory.equippedPieceSkinId == item.id) ||
                                   (item.type == SkinType.board && inventory.equippedBoardSkinId == item.id);

                return ListTile(
                  leading: Icon(item.type == SkinType.piece ? Icons.grid_3x3 : Icons.vignette),
                  title: Text(item.name),
                  subtitle: Text(isOwned ? "Owned" : "${item.price} Coins"),
                  trailing: _buildAction(context, item, isOwned, isEquipped),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, SkinItem item, bool isOwned, bool isEquipped) {
    if (isEquipped) {
      return const Text("EQUIPPED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    }
    if (isOwned) {
      return ElevatedButton(
        onPressed: () => context.read<GameBloc>().add(EquipItemRequested(item.id, item.type)),
        child: const Text("Equip"),
      );
    }
    return ElevatedButton(
      onPressed: inventory.coins >= item.price 
          ? () => context.read<GameBloc>().add(PurchaseItemRequested(item))
          : null,
      child: const Text("Buy"),
    );
  }
}
