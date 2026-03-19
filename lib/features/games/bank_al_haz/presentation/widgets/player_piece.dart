import 'dart:math' as math;
import 'package:flutter/material.dart';

class PlayerPiece extends StatefulWidget {
  final Color color;
  final String label;
  final bool isMoving;
  final double rotation;
  final bool flip;

  const PlayerPiece({
    super.key,
    required this.color,
    this.label = '',
    this.isMoving = false,
    this.rotation = 0,
    this.flip = false,
  });

  @override
  State<PlayerPiece> createState() => _PlayerPieceState();
}

class _PlayerPieceState extends State<PlayerPiece> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_DustParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isMoving) _controller.repeat();
    
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _updateParticles();
        });
      }
    });
  }

  @override
  void didUpdateWidget(PlayerPiece oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving != oldWidget.isMoving) {
      if (widget.isMoving) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  void _updateParticles() {
    // Add new particles ONLY when moving
    if (widget.isMoving && _random.nextDouble() > 0.4) {
      _particles.add(_DustParticle(
        // Start from the back of the car (Right side in local space)
        x: 40 + _random.nextDouble() * 10,
        y: 32 + _random.nextDouble() * 5,
        size: 2.5 + _random.nextDouble() * 3, // Smaller particles
        opacity: 0.7,
        vx: 1.0 + _random.nextDouble() * 2.5, // Move BACKWARD (X+)
        vy: (_random.nextDouble() - 0.5) * 1.5,
      ));
    }

    // Move and fade existing particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].x += _particles[i].vx;
      _particles[i].y += _particles[i].vy;
      _particles[i].opacity -= 0.06;
      _particles[i].size += 0.05;
      if (_particles[i].opacity <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Only active player has vibration
        final bounce = (widget.label.isNotEmpty) ? math.sin(DateTime.now().millisecondsSinceEpoch / 150) * 1.2 : 0.0;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(
              width: 60,
              height: 55,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // THE CAR BODY + WHEELS (This rotates and flips)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(widget.rotation)
                      ..scale(widget.flip ? -1.0 : 1.0, 1.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Dust Particles INSIDE the rotated/flipped space
                        ..._particles.map((p) => Positioned(
                          left: p.x,
                          top: p.y,
                          child: Opacity(
                            opacity: p.opacity,
                            child: Container(
                              width: p.size,
                              height: p.size,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )),

                        // Car Body (Vibrating)
                        Positioned(
                          bottom: 12 + bounce,
                          left: 0,
                          right: 0,
                          child: _buildCarBody(),
                        ),

                        // Wheels
                        Positioned(
                          bottom: 8,
                          left: 10,
                          child: Transform.rotate(
                            angle: widget.isMoving ? (_controller.value * math.pi * 4) : 0,
                            child: _buildWheel(),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 10,
                          child: Transform.rotate(
                            angle: widget.isMoving ? (_controller.value * math.pi * 4) : 0,
                            child: _buildWheel(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarBody() {
    return SizedBox(
      height: 35,
      child: Stack(
        children: [
          // Lower part
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 3)),
                ],
              ),
            ),
          ),
          // Cabin
          Positioned(
            top: 2,
            left: 14,
            right: 14,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          // Windows
          Positioned(
            top: 6,
            left: 18,
            right: 18,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ),
          // Lights
          Positioned(top: 18, left: 3, child: _buildLight()),
          Positioned(top: 18, right: 3, child: _buildLight()),
        ],
      ),
    );
  }

  Widget _buildLight() => Container(
    width: 6, 
    height: 4, 
    decoration: BoxDecoration(
      color: Colors.yellow, 
      borderRadius: BorderRadius.circular(2),
      boxShadow: [BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 4)],
    ),
  );

  Widget _buildWheel() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(width: 10, height: 1, color: Colors.white24),
          ),
          Center(
            child: Container(width: 1, height: 10, color: Colors.white24),
          ),
          Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _DustParticle {
  double x, y, size, opacity, vx, vy;
  _DustParticle({required this.x, required this.y, required this.size, required this.opacity, required this.vx, required this.vy});
}
