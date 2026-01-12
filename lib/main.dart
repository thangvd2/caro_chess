import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/game_bloc.dart';
import 'ui/game_board_widget.dart';
import 'ui/game_controls_widget.dart';

void main() {
  runApp(const CaroChessApp());
}

class CaroChessApp extends StatelessWidget {
  const CaroChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caro Chess',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => GameBloc()..add(const StartGame()),
        child: const GamePage(),
      ),
    );
  }
}

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caro Chess'),
      ),
      body: const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameControlsWidget(),
              SizedBox(height: 20),
              GameBoardWidget(),
            ],
          ),
        ),
      ),
    );
  }
}