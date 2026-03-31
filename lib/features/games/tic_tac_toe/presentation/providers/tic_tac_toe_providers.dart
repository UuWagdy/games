import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/tic_tac_toe_state.dart';

part 'tic_tac_toe_providers.g.dart';

@riverpod
class TicTacToeController extends _$TicTacToeController {
  @override
  TicTacToeState build() {
    final settingsMap = ref.watch(generalSettingsProvider).value;
    final bool globalAi = settingsMap?['global_ai_enabled'] == true;
    final bool localAi = settingsMap?['tic_tac_toe_vs_computer'] == true;
    final bool swapRoles = settingsMap?['tic_tac_toe_swap_roles'] == true;
    final vsComputer = globalAi || localAi;
    return TicTacToeState.initial(vsComputer: vsComputer, swapRoles: swapRoles);
  }

  void resetGame() {
    final settingsMap = ref.read(generalSettingsProvider).value;
    final bool globalAi = settingsMap?['global_ai_enabled'] == true;
    final bool localAi = settingsMap?['tic_tac_toe_vs_computer'] == true;
    final bool swapRoles = settingsMap?['tic_tac_toe_swap_roles'] == true;
    final vsComputer = globalAi || localAi;

    if (swapRoles) {
      final currentX = settingsMap?['tic_tac_toe_team_x_id'];
      final currentO = settingsMap?['tic_tac_toe_team_o_id'];
      if (currentX != null && currentO != null) {
        ref.read(generalSettingsProvider.notifier).setTicTacToeTeamXId(currentO);
        ref.read(generalSettingsProvider.notifier).setTicTacToeTeamOId(currentX);
      }
    }

    state = TicTacToeState.initial(vsComputer: vsComputer, swapRoles: swapRoles);
  }

  void toggleVsComputer(bool enabled) {
    state = state.copyWith(vsComputer: enabled);
    if (enabled && state.currentPlayer == TicTacToePlayer.o && state.winner == null && !state.isDraw) {
      _computerMove();
    }
  }

  void skipTurn() {
    if (state.winner != null || state.isDraw) return;
    
    state = state.copyWith(
      currentPlayer: state.currentPlayer == TicTacToePlayer.x ? TicTacToePlayer.o : TicTacToePlayer.x,
    );
    
    // If it's O's turn and vsComputer is enabled, let it move
    if (state.vsComputer && state.currentPlayer == TicTacToePlayer.o) {
      _computerMove();
    }
  }

  void makeMove(int index) {
    if (state.board[index] != null || state.winner != null || state.isDraw) return;

    final newBoard = List<String?>.from(state.board);
    newBoard[index] = state.currentPlayer == TicTacToePlayer.x ? 'X' : 'O';

    final winningResult = _checkWin(newBoard);
    final TicTacToePlayer? winner = winningResult?['winner'];
    final List<int>? winningLine = winningResult?['line'];
    final isDraw = winner == null && !newBoard.contains(null);

    state = state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == TicTacToePlayer.x ? TicTacToePlayer.o : TicTacToePlayer.x,
      winner: winner,
      winningLine: winningLine,
      isDraw: isDraw,
    );

    // Auto-fill last cell if 1 left
    if (winner == null && !isDraw) {
      final nullIndices = <int>[];
      for (int i = 0; i < 9; i++) {
        if (state.board[i] == null) nullIndices.add(i);
      }
      if (nullIndices.length == 1) {
        makeMove(nullIndices[0]);
        return;
      }
    }
    
    // If it's O's turn and vsComputer is enabled, let it move
    if (winner == null && !isDraw && state.vsComputer && state.currentPlayer == TicTacToePlayer.o) {
      _computerMove();
    }
  }

  void _computerMove() async {
    if (state.winner != null || state.isDraw) return;
    
    // Artificial small delay for better feel
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Minimax for "very very smart" play
    int bestVal = -1000;
    int bestMove = -1;
    
    for (int i = 0; i < 9; i++) {
        if (state.board[i] == null) {
            final tempBoard = List<String?>.from(state.board);
            tempBoard[i] = 'O';
            int moveVal = _minimax(tempBoard, 0, false);
            if (moveVal > bestVal) {
                bestVal = moveVal;
                bestMove = i;
            }
        }
    }
    
    if (bestMove != -1) {
       makeMove(bestMove);
    }
  }

  int _minimax(List<String?> board, int depth, bool isMax) {
    final winRes = _checkWin(board);
    if (winRes != null) {
       return winRes['winner'] == TicTacToePlayer.o ? (10 - depth) : (depth - 10);
    }
    if (!board.contains(null)) return 0;

    if (isMax) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == null) {
          board[i] = 'O';
          best = max(best, _minimax(board, depth + 1, !isMax));
          board[i] = null;
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == null) {
          board[i] = 'X';
          best = min(best, _minimax(board, depth + 1, !isMax));
          board[i] = null;
        }
      }
      return best;
    }
  }

  int? _findWinningOrBlockingMove(String symbol) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6] // Diagonals
    ];

    for (var line in lines) {
      final cells = [state.board[line[0]], state.board[line[1]], state.board[line[2]]];
      int symbolCount = cells.where((c) => c == symbol).length;
      int nullCount = cells.where((c) => c == null).length;

      if (symbolCount == 2 && nullCount == 1) {
        return line[cells.indexOf(null)];
      }
    }
    return null;
  }

  Map<String, dynamic>? _checkWin(List<String?> board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var line in lines) {
      if (board[line[0]] != null && 
          board[line[0]] == board[line[1]] && 
          board[line[0]] == board[line[2]]) {
        return {
          'winner': board[line[0]] == 'X' ? TicTacToePlayer.x : TicTacToePlayer.o,
          'line': line
        };
      }
    }
    return null;
  }
}
