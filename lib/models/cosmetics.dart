import 'package:equatable/equatable.dart';

enum SkinType { piece, board, avatarFrame }

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
  final String equippedAvatarFrameId;

  const Inventory({
    this.coins = 0,
    this.ownedItemIds = const ['default_piece', 'default_board', 'default_avatar'],
    this.equippedPieceSkinId = 'default_piece',
    this.equippedBoardSkinId = 'default_board',
    this.equippedAvatarFrameId = 'default_avatar',
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
    } else if (type == SkinType.board) {
      return copyWith(equippedBoardSkinId: itemId);
    } else {
      return copyWith(equippedAvatarFrameId: itemId);
    }
  }

  Inventory copyWith({
    int? coins,
    List<String>? ownedItemIds,
    String? equippedPieceSkinId,
    String? equippedBoardSkinId,
    String? equippedAvatarFrameId,
  }) {
    return Inventory(
      coins: coins ?? this.coins,
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
      equippedPieceSkinId: equippedPieceSkinId ?? this.equippedPieceSkinId,
      equippedBoardSkinId: equippedBoardSkinId ?? this.equippedBoardSkinId,
      equippedAvatarFrameId: equippedAvatarFrameId ?? this.equippedAvatarFrameId,
    );
  }

  @override
  List<Object?> get props => [coins, ownedItemIds, equippedPieceSkinId, equippedBoardSkinId, equippedAvatarFrameId];
}
