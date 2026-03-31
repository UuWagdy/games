enum TicTacToePlayer { x, o }

class TicTacToeState {
  final List<String?> board; // null for empty, 'X' or 'O'
  final TicTacToePlayer? winner;
  final bool isDraw;
  final TicTacToePlayer currentPlayer;
  final List<int>? winningLine;
  final bool vsComputer;
  final bool swapRoles;
  final int? lastStarterTeamXId;

  TicTacToeState({
    required this.board,
    required this.currentPlayer,
    this.winner,
    this.isDraw = false,
    this.winningLine,
    this.vsComputer = true,
    this.swapRoles = false,
    this.lastStarterTeamXId,
  });

  factory TicTacToeState.initial({bool vsComputer = true, bool swapRoles = false, int? lastStarterTeamXId}) {
    return TicTacToeState(
      board: List.filled(9, null),
      currentPlayer: TicTacToePlayer.x, 
      vsComputer: vsComputer,
      swapRoles: swapRoles,
      lastStarterTeamXId: lastStarterTeamXId,
    );
  }

  TicTacToeState copyWith({
    List<String?>? board,
    TicTacToePlayer? currentPlayer,
    TicTacToePlayer? winner,
    bool? isDraw,
    List<int>? winningLine,
    bool? vsComputer,
    bool? swapRoles,
    int? lastStarterTeamXId,
  }) {
    return TicTacToeState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      isDraw: isDraw ?? this.isDraw,
      winningLine: winningLine ?? this.winningLine,
      vsComputer: vsComputer ?? this.vsComputer,
      swapRoles: swapRoles ?? this.swapRoles,
      lastStarterTeamXId: lastStarterTeamXId ?? this.lastStarterTeamXId,
    );
  }
}
