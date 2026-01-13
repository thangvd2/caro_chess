class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String type; // 'board_skin', 'piece_skin', 'avatar_frame'

  const ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.type,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      name: json['name'],
      cost: json['cost'],
      type: json['type'],
    );
  }
}
