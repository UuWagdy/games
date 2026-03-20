import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ludo_entities.dart';
import '../providers/ludo_controller.dart';

class LudoTokenWidget extends ConsumerStatefulWidget {
  final LudoToken token;
  final double cellSize;
  final int row;
  final int col;
  final bool isSelectable;
  final double offsetX;
  final double offsetY;
  final double scale;

  const LudoTokenWidget({
    super.key,
    required this.token,
    required this.cellSize,
    required this.row,
    required this.col,
    this.offsetX = 0,
    this.offsetY = 0,
    this.isSelectable = false,
    this.scale = 1.0,
  });

  @override
  ConsumerState<LudoTokenWidget> createState() => _LudoTokenWidgetState();
}

class _LudoTokenWidgetState extends ConsumerState<LudoTokenWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isSelectable) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LudoTokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelectable && !oldWidget.isSelectable) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSelectable && oldWidget.isSelectable) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.token.color) {
      case LudoColor.red: return Colors.red;
      case LudoColor.green: return Colors.green;
      case LudoColor.blue: return Colors.blue;
      case LudoColor.yellow: return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _getColor();
    final double tokenWidth = widget.cellSize * 0.65;
    final double tokenHeight = widget.cellSize * 0.95;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: (widget.row + 0.5) * widget.cellSize - (tokenHeight * 1.2) + (tokenWidth * 0.2) + widget.offsetY, 
      left: widget.col * widget.cellSize + (widget.cellSize - tokenWidth) / 2 + widget.offsetX - 3, 
      width: tokenWidth,
      height: tokenHeight + (tokenHeight * 0.2), 
      child: GestureDetector(
        onTap: widget.isSelectable ? () {
          ref.read(ludoControllerProvider.notifier).selectToken(widget.token);
        } : null,
        child: Transform.scale(
          scale: widget.scale,
          child: ScaleTransition(
            scale: widget.isSelectable ? _animation : const AlwaysStoppedAnimation(1.0),
            child: _buildPieceContent(color, tokenWidth, tokenHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildPieceContent(Color color, double tokenWidth, double tokenHeight) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isSelectable ? [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10 * _animation.value,
                spreadRadius: 3 * _animation.value,
              )
            ] : null,
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Footprint/Ground circle
          Positioned(
            bottom: 0,
            child: Container(
              width: tokenWidth * 0.9,
              height: tokenWidth * 0.4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.all(Radius.elliptical(tokenWidth * 0.45, tokenWidth * 0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 4, spreadRadius: 2)
                ],
              ),
            ),
          ),
          // Shadow of the pawn itself
          Positioned(
            bottom: tokenHeight * 0.05,
            child: Container(
              width: tokenWidth * 0.75,
              height: tokenWidth * 0.2,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.all(Radius.elliptical(tokenWidth * 0.35, tokenWidth * 0.1)),
              ),
            ),
          ),
          // Body (Trapezoid/Conical)
          Positioned(
            bottom: tokenHeight * 0.15,
            child: ClipPath(
              clipper: _PawnBodyClipper(),
              child: Container(
                width: tokenWidth * 0.85,
                height: tokenHeight * 0.7,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.black.withOpacity(0.4), width: 0.8),
                  gradient: LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [color.withOpacity(0.8), color, color.withOpacity(0.9)],
                  ),
                ),
              ),
            ),
          ),
          // Base (Rounded)
          Positioned(
            bottom: tokenHeight * 0.1,
            child: Container(
              width: tokenWidth * 0.9,
              height: tokenHeight * 0.2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(tokenWidth * 0.1),
                border: Border.all(color: Colors.black.withOpacity(0.5), width: 1),
                gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [color.withOpacity(0.7), color, color.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelectable ? Colors.white70 : Colors.black26, 
                    blurRadius: widget.isSelectable ? 8 : 2, 
                    spreadRadius: widget.isSelectable ? 1 : 0
                  )
                ],
              ),
            ),
          ),
          // Neck piece
          Positioned(
            top: tokenHeight * 0.35,
            child: Container(
              width: tokenWidth * 0.4,
              height: tokenHeight * 0.1,
              decoration: BoxDecoration(
                color: color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(tokenWidth * 0.05),
                border: Border.all(color: Colors.black, width: 0.8),
              ),
            ),
          ),
          // Head (Main circular part)
          Positioned(
            top: tokenHeight * 0.05,
            child: Container(
              width: tokenWidth * 0.55,
              height: tokenWidth * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: Colors.black,
                  width: widget.isSelectable ? 1.5 : 0.8,
                ),
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.5),
                    color,
                    color,
                    color.withOpacity(0.8),
                  ],
                  center: const Alignment(-0.35, -0.35),
                  radius: 0.8,
                ),
                boxShadow: [
                   BoxShadow(
                    color: widget.isSelectable ? color.withOpacity(0.8) : Colors.black12, 
                    blurRadius: widget.isSelectable ? 10 : 4,
                    offset: const Offset(1, 1),
                  )
                ],
              ),
              child: Center(
                child: widget.token.isProtected
                    ? Icon(Icons.shield, size: tokenWidth * 0.3, color: Colors.white.withOpacity(0.8))
                    : (widget.token.isVisionModeUnlocked
                        ? Image.asset(
                            'assets/images/angel.png',
                            width: tokenWidth * 0.45,
                            height: tokenWidth * 0.45,
                            fit: BoxFit.contain,
                          )
                        : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PawnBodyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.15, size.height); // Bottom left
    path.lineTo(size.width * 0.85, size.height); // Bottom right
    path.lineTo(size.width * 0.65, 0); // Top right
    path.lineTo(size.width * 0.35, 0); // Top left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
