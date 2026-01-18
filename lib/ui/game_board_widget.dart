import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import '../models/game_models.dart';
import '../models/cosmetics.dart';
import '../config/app_config.dart';

class GameBoardWidget extends StatelessWidget {
  const GameBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is GameInProgress || state is GameOver) {
          final board = (state is GameInProgress) ? state.board : (state as GameOver).board;
          final inventory = (state is GameInProgress) ? state.inventory : (state as GameOver).inventory;
          final winningLine = (state is GameOver) ? state.winningLine : null;

          return BoardDisplay(
            board: board,
            inventory: inventory,
            winningLine: winningLine,
            onTap: (pos) {
              if (state is GameInProgress && state.isSpectating) return;
              if (state is GameOver) return;
              HapticFeedback.lightImpact();
              context.read<GameBloc>().add(PlacePiece(pos));
            },
          );
        }
        
        // Default / Initial State (Empty Board)
        return BoardDisplay(
          board: GameBoard(rows: AppConfig.boardRows, columns: AppConfig.boardColumns),
          inventory: const Inventory(),
          onTap: (_) {},
        );
      },
    );
  }
}

class BoardDisplay extends StatelessWidget {
  final GameBoard board;
  final Inventory inventory;
  final List<Position>? winningLine;
  final Function(Position) onTap;

  const BoardDisplay({
    super.key,
    required this.board,
    required this.inventory,
    required this.onTap,
    this.winningLine,
  });

  @override
  Widget build(BuildContext context) {
    Color boardColor = Colors.white;
    Color gridColor = Colors.black12;
    Gradient? boardGradient;

    final skin = inventory.equippedBoardSkinId;

    // Board Skin Logic
    switch (skin) {
      case 'dark_board':
        boardColor = Colors.black87;
        gridColor = Colors.white12;
        break;
      case 'wooden_board':
        boardColor = Colors.orange.shade100;
        gridColor = Colors.brown.withOpacity(0.3);
        break;
      case 'board_iron':
        boardColor = Colors.blueGrey.shade700;
        gridColor = Colors.white24;
        break;
      case 'board_rainbow':
        boardGradient = const LinearGradient(
          colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        gridColor = Colors.white54;
        break;
      case 'board_forest':
        boardColor = Colors.green.shade800;
        gridColor = Colors.lightGreenAccent.withOpacity(0.3);
        break;
      case 'board_ocean':
        boardColor = Colors.blue.shade900;
        gridColor = Colors.cyanAccent.withOpacity(0.3);
        break;
      case 'board_desert':
        boardColor = const Color(0xFFEDC9AF); // Sand color
        gridColor = Colors.brown.withOpacity(0.2);
        break;
      case 'board_ice':
        boardColor = Colors.cyan.shade50;
        gridColor = Colors.blue.withOpacity(0.3);
        break;
      case 'board_lava':
        boardGradient = LinearGradient(
          colors: [Colors.red.shade900, Colors.orange.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        gridColor = Colors.yellowAccent.withOpacity(0.4);
        break;
      case 'board_space':
        boardColor = const Color(0xFF1a1a2e); // Deep space blue
        gridColor = Colors.white24;
        break;
      case 'board_checker':
        boardColor = Colors.grey.shade300;
        gridColor = Colors.black87;
        break;
      case 'board_pink':
        boardColor = Colors.pink.shade50;
        gridColor = Colors.pinkAccent.withOpacity(0.2);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: boardGradient == null ? boardColor : null,
        gradient: boardGradient,
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GridView.builder(
          itemCount: board.rows * board.columns,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: board.columns,
          ),
          itemBuilder: (context, index) {
            final x = index % board.columns;
            final y = index ~/ board.columns;
            final cell = board.cells[y][x];

            final isHighlighted = winningLine?.contains(Position(x: x, y: y)) ?? false;

            return BoardCell(
              cell: cell,
              isHighlighted: isHighlighted,
              inventory: inventory,
              gridColor: gridColor,
              onTap: () => onTap(Position(x: x, y: y)),
            );
          },
        ),
      ),
    );
  }
}

class BoardCell extends StatelessWidget {
  final Cell cell;
  final VoidCallback onTap;
  final bool isHighlighted;
  final Inventory? inventory;
  final Color gridColor;

  const BoardCell({
    super.key, 
    required this.cell, 
    required this.onTap, 
    this.isHighlighted = false,
    this.inventory,
    required this.gridColor,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isHighlighted ? Colors.amberAccent : gridColor;
    final backgroundColor = isHighlighted ? Colors.amber.withOpacity(0.2) : Colors.transparent;

    Widget content = Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 2 : 1,
        ),
        color: backgroundColor,
      ),
      child: Center(
        child: cell.isEmpty
            ? const SizedBox.shrink()
            : TweenAnimationBuilder<double>(
                key: ValueKey('${cell.position.x}_${cell.position.y}_${cell.owner}'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: _buildPiece(),
              ),
      ),
    );

    if (isHighlighted) {
      content = PulsingWidget(child: content);
    }

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }

  Widget _buildPiece() {
    final skinId = inventory?.equippedPieceSkinId;
    String text = cell.owner == Player.x ? 'X' : 'O';
    
    // Default Style
    TextStyle style = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: cell.owner == Player.x ? Colors.cyanAccent : Colors.pinkAccent,
      height: 1.0,
    );

    // Piece Skin Logic
    switch (skinId) {
      case 'neon_piece':
        style = style.copyWith(
          shadows: [
            Shadow(color: style.color!, blurRadius: 10),
            Shadow(color: style.color!, blurRadius: 20),
          ],
        );
        break;
      case 'piece_fish_bear':
        text = cell.owner == Player.x ? '🐟' : '🐻';
        style = style.copyWith(fontSize: 24); // Emojis often need slightly larger font
        break;
      case 'piece_mouse_cat':
        text = cell.owner == Player.x ? '🐭' : '🐱';
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_dog_bone':
        text = cell.owner == Player.x ? '🐶' : '🦴';
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_sun_moon':
        text = cell.owner == Player.x ? '☀️' : '🌙';
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_fire_water':
        text = cell.owner == Player.x ? '🔥' : '💧';
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_sword_shield':
        text = cell.owner == Player.x ? '⚔️' : '🛡️';
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_alien_ufo':
        text = cell.owner == Player.x ? '👽' : '🛸';
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_robot_gear':
        text = cell.owner == Player.x ? '🤖' : '⚙️';
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_dragon_phoenix':
        text = cell.owner == Player.x ? '🐉' : '🐦‍🔥'; // Phoenix/Bird
        style = style.copyWith(fontSize: 24);
        break;
      case 'piece_king_queen':
        text = cell.owner == Player.x ? '🤴' : '👸';
        style = style.copyWith(fontSize: 24);
        break;
    }

    return Text(text, style: style);
  }
}

class PulsingWidget extends StatefulWidget {
  final Widget child;
  const PulsingWidget({super.key, required this.child});

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 800),
       vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
       CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
           scale: _animation.value,
           child: Container(
             decoration: BoxDecoration(
               boxShadow: [
                  BoxShadow(
                     color: Colors.amber.withOpacity(0.5 * (_animation.value - 1.0) * 6), // Pulse glow
                     blurRadius: 10,
                     spreadRadius: 2,
                  )
               ]
             ),
             child: child,
           ),
        );
      },
      child: widget.child,
    );
  }
}
