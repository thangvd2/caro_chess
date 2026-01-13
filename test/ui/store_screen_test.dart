import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/models/cosmetics.dart';
import 'package:caro_chess/ui/store_screen.dart';

void main() {
  testWidgets('StoreScreen displays coins and items', (tester) async {
    const inv = Inventory(coins: 200, ownedItemIds: ['default_piece']);
    
    await tester.pumpWidget(
      const MaterialApp(
        home: StoreScreen(inventory: inv),
      ),
    );

    // Finding the coin display in the header
    expect(find.text('200 Coins'), findsAtLeastNWidgets(1));
    expect(find.text('Neon X/O'), findsOneWidget);
  });
}