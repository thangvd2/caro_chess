import 'package:equatable/equatable.dart';

enum SkinType { piece, board }

class SkinItem extends Equatable {
  final String id;
  final String name;
  final int price;
  final SkinType type;
  final String assetPath;

  const SkinItem({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.assetPath,
  });

  @override
  List<Object?> get props => [id, name, price, type, assetPath];
}

class Inventory extends Equatable {
  final int coins;
  final List<String> ownedItemIds;
  final String equippedPieceSkinId;
  final String equippedBoardSkinId;

  const Inventory({
    this.coins = 0,
    this.ownedItemIds = const ['default_piece', 'default_board'],
    this.equippedPieceSkinId = 'default_piece',
    this.equippedBoardSkinId = 'default_board',
  });

  Inventory addCoins(int amount) {
    return copyWith(coins: coins + amount);
  }

  Inventory removeCoins(int amount) {
    return copyWith(coins: coins - amount);
  }

  Inventory addItem(String itemId) {
    if (ownedItemIds.contains(itemId)) return this;
    return copyWith(ownedItemIds: [...ownedItemIds, itemId]);
  }
  
  Inventory equipItem(String itemId, SkinType type) {
    if (!ownedItemIds.contains(itemId)) return this;
    if (type == SkinType.piece) {
      return copyWith(equippedPieceSkinId: itemId);
    } else {
      return copyWith(equippedBoardSkinId: itemId);
    }
  }

  Inventory copyWith({
    int? coins,
    List<String>? ownedItemIds,
    String? equippedPieceSkinId,
    String? equippedBoardSkinId,
  }) {
    return Inventory(
      coins: coins ?? this.coins,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      equippedPieceSkinId: equippedPieceSkinId ?? this.equippedPieceSkinId,
      equippedBoardSkinId: equippedBoardSkinId ?? this.equippedBoardSkinId,
    );
  }

  @override
  List<Object?> get props => [coins, ownedItemIds, equippedPieceSkinId, equippedBoardSkinId];
}
