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
          final board = (state is GameInProgress) 
              ? state.board 
              : (state as GameOver).board;
          
          final inventory = (state is GameInProgress) 
              ? state.inventory 
              : (state as GameOver).inventory;
          
          final winningLine = (state is GameOver) ? state.winningLine : null;

          Color boardColor = Colors.white;
          if (inventory.equippedBoardSkinId == 'dark_board') {
            boardColor = Colors.black87;
          } else if (inventory.equippedBoardSkinId == 'wooden_board') {
            boardColor = Colors.orange.shade100;
          }
              
          return Container(
            color: boardColor,
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
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<GameBloc>().add(PlacePiece(Position(x: x, y: y)));
                    },
                  );
                },
              ),
            ),
          );
        }
        
        // Default / Initial State (Empty Board)
        return Container(
          color: Colors.white,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: GridView.builder(
              itemCount: AppConfig.boardRows * AppConfig.boardColumns,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppConfig.boardColumns,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class BoardCell extends StatelessWidget {
  final Cell cell;
  final VoidCallback onTap;
  final bool isHighlighted;
  final Inventory? inventory;

  const BoardCell({
    super.key, 
    required this.cell, 
    required this.onTap, 
    this.isHighlighted = false,
    this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isHighlighted ? Colors.orange : Colors.grey.shade300,
            width: isHighlighted ? 2 : 1,
          ),
          color: isHighlighted ? Colors.orange.withOpacity(0.2) : Colors.transparent,
        ),
        child: Center(
          child: cell.isEmpty
              ? const SizedBox.shrink()
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: _buildPiece(),
                ),
        ),
      ),
    );
  }

  Widget _buildPiece() {
    final skinId = inventory?.equippedPieceSkinId;
    
    TextStyle style = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: cell.owner == Player.x ? Colors.blue : Colors.red,
    );

    if (skinId == 'neon_piece') {
      style = style.copyWith(
        shadows: [
          Shadow(color: style.color!, blurRadius: 10),
          Shadow(color: style.color!, blurRadius: 20),
        ],
      );
    } else if (skinId == 'classic_piece') {
      style = style.copyWith(fontFamily: 'Serif');
    }

    return Text(
      cell.owner == Player.x ? 'X' : 'O',
      style: style,
    );
  }
}
