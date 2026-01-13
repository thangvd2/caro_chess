import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/models/cosmetics.dart';

void main() {
  group('Cosmetic Models', () {
    test('SkinItem properties', () {
      const item = SkinItem(
        id: 'neon_x',
        name: 'Neon X',
        price: 100,
        type: SkinType.piece,
        assetPath: 'assets/skins/neon_x.png',
      );
      expect(item.id, equals('neon_x'));
      expect(item.price, equals(100));
    });

    test('Inventory manages coins', () {
      const inv = Inventory(coins: 100, ownedItemIds: ['default']);
      expect(inv.coins, equals(100));
      
      final updated = inv.addCoins(50);
      expect(updated.coins, equals(150));
      
      final spent = updated.removeCoins(20);
      expect(spent.coins, equals(130));
    });

    test('Inventory manages items', () {
      const inv = Inventory(coins: 100, ownedItemIds: ['default']);
      final updated = inv.addItem('neon_x');
      expect(updated.ownedItemIds, contains('neon_x'));
      expect(updated.ownedItemIds, contains('default'));
    });
  });
}
