import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tic_tac_toe_state.dart';

class XOBoardWidget extends ConsumerWidget {
  final Function(int) onCellTap;
  final TicTacToeState gameState;

  const XOBoardWidget({
    super.key,
    required this.onCellTap,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      autofocus: true,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          final keyLabel = event.logicalKey.keyLabel;
          // Accept numbers 1-9 for board moves
          if (keyLabel.length == 1 && '123456789'.contains(keyLabel)) {
            final index = int.parse(keyLabel) - 1;
            onCellTap(index);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final cellValue = gameState.board[index];
            final isWinningCell = gameState.winningLine?.contains(index) ?? false;

            return GestureDetector(
              onTap: () => onCellTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isWinningCell 
                      ? (cellValue == 'X' ? Colors.blue.withOpacity(0.3) : Colors.red.withOpacity(0.3))
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isWinningCell 
                        ? (cellValue == 'X' ? Colors.blue : Colors.red)
                        : Colors.white10,
                    width: isWinningCell ? 3 : 1,
                  ),
                  boxShadow: isWinningCell 
                      ? [BoxShadow(color: (cellValue == 'X' ? Colors.blue : Colors.red).withOpacity(0.4), blurRadius: 10)]
                      : [],
                ),
                child: Center(
                  child: cellValue == null 
                      ? Text(
                          '${index + 1}', 
                          style: const TextStyle(color: Colors.white12, fontSize: 28)
                        )
                      : Text(
                          cellValue,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: cellValue == 'X' ? Colors.blueAccent : Colors.redAccent,
                            shadows: [
                              Shadow(
                                color: (cellValue == 'X' ? Colors.blueAccent : Colors.redAccent).withOpacity(0.5),
                                blurRadius: 10
                              )
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
