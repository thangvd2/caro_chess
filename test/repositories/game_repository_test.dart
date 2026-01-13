import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caro_chess/repositories/game_repository.dart';
import 'package:caro_chess/models/cosmetics.dart';

void main() {
  group('GameRepository', () {
    late GameRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = GameRepository();
    });

    test('saves and loads inventory', () async {
      const inv = Inventory(coins: 100, ownedItemIds: ['a', 'b']);
      await repo.saveInventory(inv);
      
      final loaded = await repo.loadInventory();
      expect(loaded, equals(inv));
    });
  });
}
