import 'package:equatable/equatable.dart';

enum Player { x, o }

enum GameRule {
  standard,
  freeStyle,
  caro,
}

enum GameMode {
  localPvP,
  vsAI,
  online,
}

class Position extends Equatable {
  final int x;
  final int y;

  const Position({required this.x, required this.y});

  @override
  List<Object?> get props => [x, y];
}

class Cell extends Equatable {
  final Position position;
  final Player? owner;

  const Cell({required this.position, this.owner});

  bool get isEmpty => owner == null;

  @override
  List<Object?> get props => [position, owner];
}

class GameBoard extends Equatable {
  final int rows;
  final int columns;
  final List<List<Cell>> cells;

  GameBoard({required this.rows, required this.columns})
      : cells = List.generate(
          rows,
          (y) => List.generate(
            columns,
            (x) => Cell(position: Position(x: x, y: y)),
          ),
        );

  @override
  List<Object?> get props => [rows, columns, cells];
}