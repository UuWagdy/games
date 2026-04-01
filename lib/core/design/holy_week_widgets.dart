import 'package:flutter/material.dart';
import 'dart:math' as math;

class HolyWeekDecorations extends StatelessWidget {
  const HolyWeekDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Dark vignette - edges of screen darken
        const _DarkVignette(),

        // 2. Subtle blood-red pulse in the background
        const _BloodRedPulse(),

        // 3. Blood drops falling slowly
        const _BloodDrops(),

        // 4. Floating dust/ash particles
        const _AshParticles(),

        // 5. Top border - dark with subtle red
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _HolyWeekTopBorder(),
        ),

        // 6. Dark Cross silhouette (bottom right)
        Positioned(
          bottom: -40,
          right: -30,
          child: _buildDarkCross(220),
        ),

        // 7. Crown of thorns watermark
        Positioned.fill(
          child: Opacity(
            opacity: 0.07,
            child: Image.asset(
              'assets/images/crown_thorns.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),

        // 8. Three nails at the top
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _ThreeNails(),
        ),
      ],
    );
  }

  Widget _buildDarkCross(double size) {
    return Opacity(
      opacity: 0.25,
      child: Transform.rotate(
        angle: -0.08,
        child: SizedBox(
          width: size,
          height: size * 1.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow behind cross
              Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B0000).withOpacity(0.15),
                      blurRadius: 80,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
              // Vertical bar - rough wood texture feel
              Container(
                width: size * 0.14,
                height: size * 1.5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A0A00), // Very dark brown
                      Color(0xFF2D1810), // Dark wood
                      Color(0xFF1A0A00),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: const Color(0xFF3D2818).withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
              ),
              // Horizontal bar
              Positioned(
                top: size * 0.35,
                child: Container(
                  width: size * 0.75,
                  height: size * 0.14,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1A0A00),
                        Color(0xFF2D1810),
                        Color(0xFF1A0A00),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFF3D2818).withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              // Nail marks - three small dark dots
              Positioned(
                top: size * 0.38,
                left: size * 0.12,
                child: _buildNailMark(),
              ),
              Positioned(
                top: size * 0.38,
                right: size * 0.12,
                child: _buildNailMark(),
              ),
              Positioned(
                bottom: size * 0.25,
                child: _buildNailMark(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNailMark() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B0000).withOpacity(0.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

// ─── Dark Vignette - darkens the edges ───
class _DarkVignette extends StatelessWidget {
  const _DarkVignette();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.6),
            ],
            stops: const [0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─── Blood Red Pulse - breathing darkness with red tint ───
class _BloodRedPulse extends StatefulWidget {
  const _BloodRedPulse();
  @override
  State<_BloodRedPulse> createState() => _BloodRedPulseState();
}

class _BloodRedPulseState extends State<_BloodRedPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
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
        final opacity = 0.03 + math.sin(_controller.value * math.pi) * 0.04;
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, 0.3),
                radius: 1.5,
                colors: [
                  const Color(0xFF8B0000).withOpacity(opacity),
                  const Color(0xFF4A0000).withOpacity(opacity * 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Blood Drops - slow falling drops ───
class _BloodDrops extends StatefulWidget {
  const _BloodDrops();
  @override
  State<_BloodDrops> createState() => _BloodDropsState();
}

class _BloodDropsState extends State<_BloodDrops> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Drop> _drops = List.generate(15, (i) => _Drop.create(i));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
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
        return CustomPaint(
          painter: _BloodDropPainter(
            drops: _drops,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Drop {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double opacity;
  final double tailLength;

  _Drop({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.tailLength,
  });

  static _Drop create(int i) {
    final r = math.Random(i * 13 + 7);
    return _Drop(
      x: r.nextDouble(),
      startY: r.nextDouble(),
      size: 2.0 + r.nextDouble() * 3.0,
      speed: 0.06 + r.nextDouble() * 0.08,
      opacity: 0.15 + r.nextDouble() * 0.25,
      tailLength: 8.0 + r.nextDouble() * 20.0,
    );
  }
}

class _BloodDropPainter extends CustomPainter {
  final List<_Drop> drops;
  final double progress;

  _BloodDropPainter({required this.drops, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0) return;

    for (var drop in drops) {
      final y = ((drop.startY + progress * drop.speed) % 1.1) - 0.05;
      final x = drop.x * size.width;
      final dropY = y * size.height;

      // Draw the tail (streak above the drop)
      final tailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF8B0000).withOpacity(drop.opacity * 0.3),
            const Color(0xFF8B0000).withOpacity(drop.opacity * 0.6),
          ],
        ).createShader(Rect.fromLTWH(x - 1, dropY - drop.tailLength, 2, drop.tailLength));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 0.8, dropY - drop.tailLength, 1.6, drop.tailLength),
          const Radius.circular(1),
        ),
        tailPaint,
      );

      // Draw the drop (teardrop shape)
      final dropPaint = Paint()
        ..color = const Color(0xFF8B0000).withOpacity(drop.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      // Simple oval for the drop body
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, dropY),
          width: drop.size,
          height: drop.size * 1.4,
        ),
        dropPaint,
      );

      // Subtle glow around each drop
      final glowPaint = Paint()
        ..color = const Color(0xFF8B0000).withOpacity(drop.opacity * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, dropY), drop.size * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Ash Particles - floating dust/ash in the dark ───
class _AshParticles extends StatefulWidget {
  const _AshParticles();
  @override
  State<_AshParticles> createState() => _AshParticlesState();
}

class _AshParticlesState extends State<_AshParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_AshParticle> _particles = List.generate(30, (i) => _AshParticle.create(i));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
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
        return CustomPaint(
          painter: _AshPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AshParticle {
  final double x;
  final double y;
  final double size;
  final double speedX;
  final double speedY;
  final double opacity;

  _AshParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });

  static _AshParticle create(int i) {
    final r = math.Random(i * 31 + 11);
    return _AshParticle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 0.8 + r.nextDouble() * 1.5,
      speedX: (r.nextDouble() - 0.5) * 0.05,
      speedY: 0.02 + r.nextDouble() * 0.04,
      opacity: 0.08 + r.nextDouble() * 0.15,
    );
  }
}

class _AshPainter extends CustomPainter {
  final List<_AshParticle> particles;
  final double progress;

  _AshPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0) return;

    final paint = Paint();
    for (var p in particles) {
      // Slow downward drift with horizontal sway
      final y = (p.y + progress * p.speedY) % 1.0;
      final x = (p.x + math.sin(progress * 2 * math.pi + p.y * 10) * 0.02 + progress * p.speedX) % 1.0;

      paint.color = Colors.white.withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Top Border ───
class _HolyWeekTopBorder extends StatelessWidget {
  const _HolyWeekTopBorder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFF4A0000), // Dark blood red
            Color(0xFF8B0000), // Blood red center
            Color(0xFF4A0000),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─── Three Nails hanging from the top ───
class _ThreeNails extends StatelessWidget {
  const _ThreeNails();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 120,
      child: Stack(
        children: [
          // Left nail
          Positioned(
            left: screenWidth * 0.2,
            top: 0,
            child: const _HangingNail(length: 55),
          ),
          // Center nail (longer)
          Positioned(
            left: screenWidth * 0.5 - 4,
            top: 0,
            child: const _HangingNail(length: 75),
          ),
          // Right nail
          Positioned(
            right: screenWidth * 0.2,
            top: 0,
            child: const _HangingNail(length: 60),
          ),
        ],
      ),
    );
  }
}

class _HangingNail extends StatefulWidget {
  final double length;
  const _HangingNail({required this.length});

  @override
  State<_HangingNail> createState() => _HangingNailState();
}

class _HangingNailState extends State<_HangingNail> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
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
        final swing = math.sin(_controller.value * 2 * math.pi) * 0.03;
        return Transform.rotate(
          angle: swing,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thread
              Container(
                width: 0.8,
                height: widget.length * 0.5,
                color: Colors.white.withOpacity(0.08),
              ),
              // Nail head
              Container(
                width: 8,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D3D3D),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B0000).withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              // Nail body
              Container(
                width: 3,
                height: widget.length * 0.4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4A4A4A), // Dark iron
                      Color(0xFF2D2D2D),
                      Color(0xFF1A1A1A),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(1),
                    bottomRight: Radius.circular(1),
                  ),
                ),
              ),
              // Nail tip (pointed)
              CustomPaint(
                size: const Size(3, 8),
                painter: _NailTipPainter(),
              ),
              // Blood drip from the nail
              const SizedBox(height: 2),
              Container(
                width: 2.5,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NailTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
