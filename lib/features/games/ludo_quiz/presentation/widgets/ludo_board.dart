import 'dart:math' show cos, sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ludo_entities.dart';
import '../../domain/models/ludo_state.dart';
import '../providers/ludo_controller.dart';
import 'ludo_token_widget.dart';

class LudoBoard extends ConsumerWidget {
  const LudoBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LudoState state = ref.watch(ludoControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth < constraints.maxHeight 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        final double cellSize = boardSize / 15;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black87, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 16, spreadRadius: 4),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: _LudoBoardPainter(),
                  ),
                  ..._buildAllTokens(state, cellSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAllTokens(LudoState state, double cellSize) {
    final List<Widget> widgets = <Widget>[];
    final Map<(int, int), List<LudoToken>> spotOccupants = {};

    for (final LudoPlayer player in state.players) {
      for (final LudoToken token in player.tokens) {
        final (int, int) coords = _getTokenPosition(token);
        spotOccupants.putIfAbsent(coords, () => []).add(token);
      }
    }

    spotOccupants.forEach((coords, occupants) {
      for (int i = 0; i < occupants.length; i++) {
        final token = occupants[i];
        final bool isSelectable = state.selectableTokens.any((LudoToken t) => t.id == token.id);
        
        double offsetX = 0;
        double offsetY = 0;
        double scale = 1.0;
        
        if (occupants.length > 1) {
          final double shift = cellSize * 0.22;
          if (occupants.length == 2) {
            offsetX = (i == 0) ? -shift : shift;
            scale = 0.95;
          } else if (occupants.length == 3) {
            scale = 0.85;
            if (i == 0) { offsetX = -shift; offsetY = shift * 0.5; }
            if (i == 1) { offsetX = shift; offsetY = shift * 0.5; }
            if (i == 2) { offsetX = 0; offsetY = -shift * 0.8; }
          } else {
            // 4 or more tokens
            scale = 0.75;
            if (i % 4 == 0) { offsetX = -shift; offsetY = -shift; }
            if (i % 4 == 1) { offsetX = shift; offsetY = -shift; }
            if (i % 4 == 2) { offsetX = -shift; offsetY = shift; }
            if (i % 4 == 3) { offsetX = shift; offsetY = shift; }
          }
        }

        widgets.add(
          LudoTokenWidget(
            token: token,
            cellSize: cellSize,
            row: coords.$1,
            col: coords.$2,
            offsetX: offsetX,
            offsetY: offsetY,
            isSelectable: isSelectable,
            scale: scale,
          ),
        );
      }
    });
    return widgets;
  }

  // Classic Ludo 52-cell cyclic path (row, col) on a 15x15 grid
  static const List<(int, int)> _cyclicPath = [
    (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5),
    (5, 6), (4, 6), (3, 6), (2, 6), (1, 6), (0, 6),
    (0, 7), (0, 8),
    (1, 8), (2, 8), (3, 8), (4, 8), (5, 8),
    (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14),
    (7, 14), (8, 14),
    (8, 13), (8, 12), (8, 11), (8, 10), (8, 9),
    (9, 8), (10, 8), (11, 8), (12, 8), (13, 8), (14, 8),
    (14, 7), (14, 6),
    (13, 6), (12, 6), (11, 6), (10, 6), (9, 6),
    (8, 5), (8, 4), (8, 3), (8, 2), (8, 1), (8, 0),
    (7, 0),
  ];

  (int, int) _getTokenPosition(LudoToken token) {
    if (token.position == -1) return _getBasePosition(token);
    if (token.position == 57) return _getHomeCenter(token.color);
    if (token.position >= 52) return _getHomePathPosition(token.color, token.position - 52);

    int startOffset = 1; // Red starts at index 1
    if (token.color == LudoColor.green) startOffset = 14;
    if (token.color == LudoColor.yellow) startOffset = 27;
    if (token.color == LudoColor.blue) startOffset = 40;
    final int idx = (token.position + startOffset) % 52;
    return _cyclicPath[idx];
  }

  (int, int) _getBasePosition(LudoToken token) {
    final int localId = token.id % 4;
    switch (token.color) {
      case LudoColor.red:
        const p = [(1, 1), (1, 4), (4, 1), (4, 4)];
        return p[localId];
      case LudoColor.green:
        const p = [(1, 10), (1, 13), (4, 10), (4, 13)];
        return p[localId];
      case LudoColor.yellow:
        const p = [(10, 10), (10, 13), (13, 10), (13, 13)];
        return p[localId];
      case LudoColor.blue:
        const p = [(10, 1), (10, 4), (13, 1), (13, 4)];
        return p[localId];
    }
  }

  (int, int) _getHomeCenter(LudoColor color) {
    switch (color) {
      case LudoColor.red: return (7, 6);
      case LudoColor.green: return (6, 7);
      case LudoColor.yellow: return (7, 8);
      case LudoColor.blue: return (8, 7);
    }
  }

  (int, int) _getHomePathPosition(LudoColor color, int idx) {
    switch (color) {
      case LudoColor.red: return (7, 1 + idx);
      case LudoColor.green: return (1 + idx, 7);
      case LudoColor.yellow: return (7, 13 - idx);
      case LudoColor.blue: return (13 - idx, 7);
    }
  }
}

class _LudoBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 15;

    // White background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);

    // Home bases
    _drawHomeBase(canvas, cell, 0, 0, Colors.red);       // Top-left = Red
    _drawHomeBase(canvas, cell, 0, 9, Colors.green);      // Top-right = Green
    _drawHomeBase(canvas, cell, 9, 9, Colors.yellow);     // Bottom-right = Yellow
    _drawHomeBase(canvas, cell, 9, 0, Colors.blue);       // Bottom-left = Blue

    // Center triangles
    _drawCenterHome(canvas, cell);

    // Colored home paths
    _drawColoredPaths(canvas, cell);

    // Grid
    _drawGridLines(canvas, cell, size);

    // Safe stars
    _drawSafeStars(canvas, cell);

    // Start arrows
    _drawStartArrows(canvas, cell);
  }

  void _drawHomeBase(Canvas canvas, double cell, int startRow, int startCol, Color color) {
    final Paint bgPaint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(startCol * cell, startRow * cell, 6 * cell, 6 * cell), bgPaint);

    // White inner area
    final double margin = 0.8 * cell;
    final Rect innerRect = Rect.fromLTWH(
      startCol * cell + margin, startRow * cell + margin,
      6 * cell - 2 * margin, 6 * cell - 2 * margin,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(innerRect, const Radius.circular(8)), Paint()..color = Colors.white);

    // 4 token spots
    final Paint circleFill = Paint()..color = color;
    final Paint circleStroke = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final positions = [
      (startCol + 1.5, startRow + 1.5),
      (startCol + 4.5, startRow + 1.5),
      (startCol + 1.5, startRow + 4.5),
      (startCol + 4.5, startRow + 4.5),
    ];

    for (final pos in positions) {
      final Offset center = Offset(pos.$1 * cell, pos.$2 * cell);
      canvas.drawCircle(center, cell * 0.55, Paint()..color = Colors.white);
      canvas.drawCircle(center, cell * 0.55, circleStroke);
      canvas.drawCircle(center, cell * 0.35, circleFill);
    }
  }

  void _drawCenterHome(Canvas canvas, double cell) {
    // Top triangle = Green
    final Path top = Path()
      ..moveTo(6 * cell, 6 * cell)
      ..lineTo(9 * cell, 6 * cell)
      ..lineTo(7.5 * cell, 7.5 * cell)
      ..close();
    canvas.drawPath(top, Paint()..color = Colors.green);

    // Right triangle = Yellow
    final Path right = Path()
      ..moveTo(9 * cell, 6 * cell)
      ..lineTo(9 * cell, 9 * cell)
      ..lineTo(7.5 * cell, 7.5 * cell)
      ..close();
    canvas.drawPath(right, Paint()..color = Colors.yellow);

    // Bottom triangle = Blue
    final Path bottom = Path()
      ..moveTo(6 * cell, 9 * cell)
      ..lineTo(9 * cell, 9 * cell)
      ..lineTo(7.5 * cell, 7.5 * cell)
      ..close();
    canvas.drawPath(bottom, Paint()..color = Colors.blue);

    // Left triangle = Red
    final Path left = Path()
      ..moveTo(6 * cell, 6 * cell)
      ..lineTo(6 * cell, 9 * cell)
      ..lineTo(7.5 * cell, 7.5 * cell)
      ..close();
    canvas.drawPath(left, Paint()..color = Colors.red);

    // Center border
    canvas.drawRect(
      Rect.fromLTWH(6 * cell, 6 * cell, 3 * cell, 3 * cell),
      Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
  }

  void _drawColoredPaths(Canvas canvas, double cell) {
    final Paint p = Paint();

    // Red home path (row 7, cols 1-5)
    p.color = Colors.red;
    for (int c = 1; c <= 5; c++) {
      canvas.drawRect(Rect.fromLTWH(c * cell, 7 * cell, cell, cell), p);
    }

    // Green home path (col 7, rows 1-5)
    p.color = Colors.green;
    for (int r = 1; r <= 5; r++) {
      canvas.drawRect(Rect.fromLTWH(7 * cell, r * cell, cell, cell), p);
    }

    // Yellow home path (row 7, cols 9-13)
    p.color = Colors.yellow;
    for (int c = 9; c <= 13; c++) {
      canvas.drawRect(Rect.fromLTWH(c * cell, 7 * cell, cell, cell), p);
    }

    // Blue home path (col 7, rows 9-13)
    p.color = Colors.blue;
    for (int r = 9; r <= 13; r++) {
      canvas.drawRect(Rect.fromLTWH(7 * cell, r * cell, cell, cell), p);
    }

    // Start cells
    canvas.drawRect(Rect.fromLTWH(1 * cell, 6 * cell, cell, cell), Paint()..color = Colors.red[300]!);
    canvas.drawRect(Rect.fromLTWH(8 * cell, 1 * cell, cell, cell), Paint()..color = Colors.green[300]!);
    canvas.drawRect(Rect.fromLTWH(13 * cell, 8 * cell, cell, cell), Paint()..color = Colors.yellow[300]!);
    canvas.drawRect(Rect.fromLTWH(6 * cell, 13 * cell, cell, cell), Paint()..color = Colors.blue[300]!);
  }

  void _drawSafeStars(Canvas canvas, double cell) {
    const safePositions = [(6, 2), (2, 8), (8, 12), (12, 6)];
    for (final pos in safePositions) {
      final Offset center = Offset(pos.$2 * cell + cell / 2, pos.$1 * cell + cell / 2);
      _drawStar(canvas, center, cell * 0.28, Colors.grey[600]!);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final Path star = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? radius : radius * 0.4;
      final double angle = (i * pi / 5) - (pi / 2);
      final double x = center.dx + r * cos(angle);
      final double y = center.dy + r * sin(angle);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = color);
  }

  void _drawStartArrows(Canvas canvas, double cell) {
    final Paint p = Paint()..color = Colors.black54..style = PaintingStyle.fill;

    // Red → right
    _drawArrow(canvas, Offset(0.3 * cell, 8.5 * cell), cell * 0.2, 0, p);
    // Green ↓ down
    _drawArrow(canvas, Offset(6.5 * cell, 0.3 * cell), cell * 0.2, 1, p);
    // Yellow ← left
    _drawArrow(canvas, Offset(14.7 * cell, 6.5 * cell), cell * 0.2, 2, p);
    // Blue ↑ up
    _drawArrow(canvas, Offset(8.5 * cell, 14.7 * cell), cell * 0.2, 3, p);
  }

  void _drawArrow(Canvas canvas, Offset pos, double sz, int dir, Paint paint) {
    final Path a = Path();
    switch (dir) {
      case 0:
        a.moveTo(pos.dx, pos.dy - sz);
        a.lineTo(pos.dx + sz * 2, pos.dy);
        a.lineTo(pos.dx, pos.dy + sz);
        break;
      case 1:
        a.moveTo(pos.dx - sz, pos.dy);
        a.lineTo(pos.dx, pos.dy + sz * 2);
        a.lineTo(pos.dx + sz, pos.dy);
        break;
      case 2:
        a.moveTo(pos.dx, pos.dy - sz);
        a.lineTo(pos.dx - sz * 2, pos.dy);
        a.lineTo(pos.dx, pos.dy + sz);
        break;
      case 3:
        a.moveTo(pos.dx - sz, pos.dy);
        a.lineTo(pos.dx, pos.dy - sz * 2);
        a.lineTo(pos.dx + sz, pos.dy);
        break;
    }
    a.close();
    canvas.drawPath(a, paint);
  }

  void _drawGridLines(Canvas canvas, double cell, Size size) {
    final Paint gp = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw cross area cells (the path where tokens travel)
    for (int r = 6; r <= 8; r++) {
      for (int c = 0; c < 15; c++) {
        canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), gp);
      }
    }
    for (int c = 6; c <= 8; c++) {
      for (int r = 0; r < 15; r++) {
        canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), gp);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
