import 'dart:async';
import 'package:flutter/material.dart';
import '../models/history_models.dart';
import '../models/game_models.dart';
import '../models/cosmetics.dart';
import '../config/app_config.dart';
import '../services/history_service.dart';
import 'game_board_widget.dart'; // For BoardDisplay

class ReplayScreen extends StatefulWidget {
  final String matchId;
  final MatchModel? initialData;

  const ReplayScreen({super.key, required this.matchId, this.initialData});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  final HistoryService _historyService = HistoryService();
  
  MatchModel? _match;
  bool _isLoading = true;
  
  // Replay State
  int _currentMoveIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;
  
  GameBoard _currentBoard = GameBoard(rows: AppConfig.boardRows, columns: AppConfig.boardColumns);

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }
  
  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMatch() async {
    if (widget.initialData != null && widget.initialData!.moves != null) {
      _match = widget.initialData;
      _isLoading = false;
      setState(() {});
      return;
    }

    final match = await _historyService.getMatch(widget.matchId);
    if (mounted) {
      setState(() {
        _match = match;
        _isLoading = false;
      });
    }
  }

  void _recomputeBoard() {
    if (_match == null || _match!.moves == null) return;
    
    // Efficiently update? Or simplistic rebuild?
    // Let's rebuild for robustness first.
    final newBoard = GameBoard(rows: AppConfig.boardRows, columns: AppConfig.boardColumns);
    for (int i = 0; i < _currentMoveIndex; i++) {
       final move = _match!.moves![i];
       newBoard.cells[move.y][move.x] = Cell(
           position: Position(x: move.x, y: move.y),
           owner: move.player,
       );
    }
    setState(() {
        _currentBoard = newBoard;
    });
  }

  void _next() {
    if (_match == null || _match!.moves == null) return;
    if (_currentMoveIndex < _match!.moves!.length) {
      _currentMoveIndex++;
      _recomputeBoard();
    } else {
        _pause();
    }
  }

  void _prev() {
     if (_currentMoveIndex > 0) {
       _currentMoveIndex--;
       _recomputeBoard();
     }
  }
  
  void _seek(int index) {
      _currentMoveIndex = index;
      _recomputeBoard();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    if (_match == null || _match!.moves == null) return;
    if (_currentMoveIndex >= _match!.moves!.length) {
        _currentMoveIndex = 0; // Restart if at end
    }
    
    setState(() {
      _isPlaying = true;
    });
    _playTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
       if (_currentMoveIndex < _match!.moves!.length) {
           _next();
       } else {
           _pause();
       }
    });
  }

  void _pause() {
    _playTimer?.cancel();
    if (mounted) {
        setState(() {
          _isPlaying = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Replay')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _match == null 
             ? const Center(child: Text('Failed to load match.'))
             : Column(
                children: [
                   // Board
                   Expanded(
                     child: Center(
                       child: SingleChildScrollView(
                           child: BoardDisplay(
                               board: _currentBoard,
                               inventory: const Inventory(), // Default for now
                               onTap: (_) {}, // No interaction
                           ),
                       ),
                     ),
                   ),
                   
                   // Controls
                   _buildControls(),
                ],
             ),
    );
  }

  Widget _buildControls() {
    final maxMoves = _match?.moves?.length ?? 0;
    
    return Container(
       padding: const EdgeInsets.all(16),
       color: Colors.grey.shade100,
       child: Column(
         children: [
            Slider(
                value: _currentMoveIndex.toDouble(),
                min: 0,
                max: maxMoves.toDouble(),
                divisions: maxMoves > 0 ? maxMoves : 1,
                onChanged: (val) {
                    _pause();
                    _seek(val.toInt());
                },
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                    IconButton(icon: const Icon(Icons.skip_previous), onPressed: () => _seek(0)),
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prev),
                    IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow), 
                        onPressed: _togglePlay,
                        iconSize: 32,
                        color: Colors.blue,
                    ),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: _next),
                    IconButton(icon: const Icon(Icons.skip_next), onPressed: () => _seek(maxMoves)),
                ],
            ),
            Text('Move $_currentMoveIndex / $maxMoves'),
         ],
       ),
    );
  }
}
