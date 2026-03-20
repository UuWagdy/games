import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/snakes_ladders_entities.dart';

class GameBoardWidget extends StatelessWidget {
  final int boardSize;
  final List<BoardElement> elements;
  final Map<int, int> playerPositions;
  final List<dynamic> teams;

  const GameBoardWidget({
    super.key,
    required this.boardSize,
    required this.elements,
    required this.playerPositions,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    final int sideSize = math.sqrt(boardSize).ceil();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellSize = constraints.maxWidth / sideSize;
        
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
            // Grid Cells
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: sideSize,
              ),
              itemCount: boardSize,
              itemBuilder: (context, index) {
                final int cellNum = _getCellNumber(index, sideSize, boardSize);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Center(
                    child: Text(
                      '$cellNum',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: cellSize * 0.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Snakes and Ladders
            IgnorePointer(
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxWidth),
                painter: SnakeLadderPainter(
                  boardSize: boardSize,
                  elements: elements,
                  sideSize: sideSize,
                  cellSize: cellSize,
                ),
              ),
            ),

            // Players
            ...playerPositions.entries.expand((entry) {
              final teamId = entry.key;
              final pos = entry.value;
              final teamIndex = teams.indexWhere((t) => t.id == teamId);
              if (teamIndex == -1) return [];

              final offset = _getCellCenter(pos, sideSize, cellSize, boardSize);
              
              // Count how many players are on this SAME position
              final playersOnSamePos = playerPositions.values.where((p) => p == pos).length;
              
              double shift = 0;
              if (playersOnSamePos > 1) {
                // Find which "index" this player has among those on the same cell
                final playersAtPos = playerPositions.entries
                    .where((e) => e.value == pos)
                    .map((e) => e.key)
                    .toList();
                final playerIdxInCell = playersAtPos.indexOf(teamId);
                shift = (playerIdxInCell * 8.0) - ((playersOnSamePos - 1) * 4.0);
              }

              return [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  left: offset.dx - (cellSize * 0.35) + shift,
                  top: offset.dy - (cellSize * 0.35) + shift,
                  child: Container(
                    width: cellSize * 0.7,
                    height: cellSize * 0.7,
                    decoration: BoxDecoration(
                      color: _getTeamColor(teamIndex),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getTeamColor(teamIndex).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${teamIndex + 1}',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w900,
                          fontSize: cellSize * 0.35,
                        ),
                      ),
                    ),
                  ),
                )
              ];
            }),
          ],
        )
      );
      },
    );
  }

  int _getCellNumber(int gridIndex, int sideSize, int total) {
    // GridView (0 to 99) in LTR:
    // 0  1  2  3  4  5  6  7  8  9  (Top Row)
    // ...
    // 90 91 92 93 94 95 96 97 98 99 (Bottom Row)
    
    int row = gridIndex ~/ sideSize; // 0 is top
    int col = gridIndex % sideSize; // 0 is left
    
    int actualRow = (sideSize - 1) - row; // 0 is bottom
    
    // Zigzag logic
    // If row 0 (bottom) is LTR: 1..10
    // If row 1 (next) is RTL: 20..11
    bool isReversed = actualRow % 2 != 0;
    int actualCol = isReversed ? (sideSize - 1 - col) : col;
    
    return (actualRow * sideSize) + actualCol + 1;
  }

  Offset _getCellCenter(int cellNum, int sideSize, double cellSize, int total) {
    int n = cellNum - 1;
    int row = n ~/ sideSize; // 0 is bottom
    int col = n % sideSize; // 0 is left (relative to row start)
    
    bool isReversed = row % 2 != 0;
    int actualCol = isReversed ? (sideSize - 1 - col) : col;
    int screenRow = (sideSize - 1) - row; // screen 0 is top
    
    return Offset(
      (actualCol * cellSize) + (cellSize / 2),
      (screenRow * cellSize) + (cellSize / 2),
    );
  }

  Color _getTeamColor(int index) {
    const colors = [Colors.redAccent, Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.cyanAccent];
    return colors[index % colors.length];
  }
}

class SnakeLadderPainter extends CustomPainter {
  final int boardSize;
  final List<BoardElement> elements;
  final int sideSize;
  final double cellSize;

  SnakeLadderPainter({
    required this.boardSize,
    required this.elements,
    required this.sideSize,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final railPaint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.square;

    final rungPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.6)
      ..strokeWidth = 3.0;

    final snakePaint = Paint()
      ..strokeWidth = cellSize * 0.25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final snakeDetailPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var element in elements) {
      final startOffset = _getCellCenter(element.start);
      final endOffset = _getCellCenter(element.end);

      if (element.isLadder) {
        // --- Realistic Transparent Ladder ---
        final direction = endOffset - startOffset;
        final perp = Offset(-direction.dy, direction.dx).normalize();
        final width = cellSize * 0.35;
        
        final rail1Start = startOffset + perp * (width / 2);
        final rail1End = endOffset + perp * (width / 2);
        final rail2Start = startOffset - perp * (width / 2);
        final rail2End = endOffset - perp * (width / 2);
        
        // Shadow for depth
        canvas.drawLine(rail1Start + const Offset(2, 2), rail1End + const Offset(2, 2), Paint()..color = Colors.black26..strokeWidth = 6);
        canvas.drawLine(rail2Start + const Offset(2, 2), rail2End + const Offset(2, 2), Paint()..color = Colors.black26..strokeWidth = 6);

        canvas.drawLine(rail1Start, rail1End, railPaint);
        canvas.drawLine(rail2Start, rail2End, railPaint);
        
        const rungs = 10;
        for (int i = 0; i <= rungs; i++) {
          final t = i / rungs;
          final p1 = rail1Start + (rail1End - rail1Start) * t;
          final p2 = rail2Start + (rail2End - rail2Start) * t;
          canvas.drawLine(p1, p2, rungPaint);
        }
      } else {
        // --- Realistic & Beautiful Snake ---
        final path = Path();
        path.moveTo(startOffset.dx, startOffset.dy);
        
        final direction = endOffset - startOffset;
        final perp = Offset(-direction.dy, direction.dx).normalize();
        
        final p1 = startOffset + direction * 0.3 + perp * cellSize * 0.7;
        final p2 = startOffset + direction * 0.7 - perp * cellSize * 0.7;
        
        path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, endOffset.dx, endOffset.dy);
        
        // Gradient for body
        final rect = Rect.fromPoints(startOffset, endOffset);
        snakePaint.shader = const LinearGradient(
          colors: [Colors.redAccent, Colors.deepOrange, Colors.orangeAccent],
        ).createShader(rect);
        
        // Main body Shadow/Transparency
        canvas.drawPath(path, snakePaint..color = Colors.red.withOpacity(0.4)..shader = null);
        canvas.drawPath(path, snakePaint..strokeWidth = cellSize * 0.22);
        
        // Circular Rings/Patterns on body (Subtle & Simple)
        final pathMetrics = path.computeMetrics();
        for (final metric in pathMetrics) {
          final double length = metric.length;
          for (double d = 20; d < length - 20; d += 40) {
            final tangent = metric.getTangentForOffset(d);
            if (tangent != null) {
              final pos = tangent.position;
              final tperp = Offset(-tangent.vector.dy, tangent.vector.dx).normalize();
              final ringSize = cellSize * 0.08; 
              canvas.drawLine(pos - tperp * ringSize, pos + tperp * ringSize, snakeDetailPaint..strokeWidth = 1.0);
            }
          }
        }

        // Snake Head (Realistic but simple)
        final headRadius = cellSize * 0.18;
        final headPaint = Paint()..shader = RadialGradient(
          colors: [Colors.redAccent.withOpacity(0.7), Colors.red.shade900.withOpacity(0.7)],
          center: const Alignment(-0.2, -0.2),
        ).createShader(Rect.fromCircle(center: startOffset, radius: headRadius));
        
        canvas.drawCircle(startOffset, headRadius, headPaint);
        
        // Eyes (Simple dots)
        final dirNorm = direction.normalize();
        final eye1 = startOffset + Offset(perp.dx * (headRadius * 0.3) - dirNorm.dx * (headRadius * 0.2), perp.dy * (headRadius * 0.3) - dirNorm.dy * (headRadius * 0.2));
        final eye2 = startOffset + Offset(-perp.dx * (headRadius * 0.3) - dirNorm.dx * (headRadius * 0.2), -perp.dy * (headRadius * 0.3) - dirNorm.dy * (headRadius * 0.2));
        canvas.drawCircle(eye1, headRadius * 0.18, Paint()..color = Colors.white);
        canvas.drawCircle(eye2, headRadius * 0.18, Paint()..color = Colors.white);
        canvas.drawCircle(eye1, headRadius * 0.08, Paint()..color = Colors.black);
        canvas.drawCircle(eye2, headRadius * 0.08, Paint()..color = Colors.black);
      }
    }
  }

  Offset _getCellCenter(int cellNum) {
    int n = cellNum - 1;
    int row = n ~/ sideSize;
    int col = n % sideSize;
    bool isReversed = row % 2 != 0;
    int actualCol = isReversed ? (sideSize - 1 - col) : col;
    int screenRow = (sideSize - 1) - row;
    return Offset((actualCol * cellSize) + (cellSize / 2), (screenRow * cellSize) + (cellSize / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension OffsetExt on Offset {
  Offset normalize() {
    double len = math.sqrt(dx * dx + dy * dy);
    return len == 0 ? Offset.zero : Offset(dx / len, dy / len);
  }
}
