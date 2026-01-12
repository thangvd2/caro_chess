import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/models/user_profile.dart';
import 'package:caro_chess/ui/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen displays user stats', (tester) async {
    const user = UserProfile(id: 'test_user', elo: 1550, wins: 15, losses: 5);
    
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(profile: user),
      ),
    );

    expect(find.text('test_user'), findsOneWidget);
    expect(find.text('1550'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('GOLD'), findsOneWidget);
  });
}