import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/ui/rule_selector_widget.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(GameInitial());
    registerFallbackValue(const StartGame());
  });

  group('RuleSelectorWidget', () {
    late GameBloc gameBloc;

    setUp(() {
      gameBloc = MockGameBloc();
    });

    testWidgets('renders all rule options', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const RuleSelectorWidget(),
          ),
        ),
      );

      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Free-style'), findsOneWidget);
      expect(find.text('Caro (Vietnam)'), findsOneWidget);
    });

    testWidgets('selecting a rule starts game with that rule', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const RuleSelectorWidget(),
          ),
        ),
      );

      await tester.tap(find.text('Free-style'));
      verify(() => gameBloc.add(const StartGame(rule: GameRule.freeStyle))).called(1);
    });
  });
}
