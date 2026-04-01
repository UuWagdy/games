import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class ResurrectionDecorations extends StatelessWidget {
  const ResurrectionDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Warm sky gradient aura from top
        const _SkyAura(),

        // 2. The Sun - positioned at top center
        const Positioned(
          top: -60,
          left: 0,
          right: 0,
          child: Center(child: _RealisticSun()),
        ),

        // 3. Gentle light rays from the sun downward
        const _SunRays(),

        // 4. Rising golden particles (like dust in sunlight)
        const _RisingLightEffect(),

        // 5. Top Decorative Border (Gold/White)
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _ResurrectionTopBorder(),
        ),

        // 6. Glowing Cross with White Cloth (Bottom Right)
        Positioned(
          bottom: -30,
          right: -40,
          child: _buildResurrectionCross(200),
        ),

        // 7. Subtle lily overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: Image.asset(
              'assets/images/resurrection_lily.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResurrectionCross(double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 60,
            spreadRadius: 15,
          ),
        ],
      ),
      child: Transform.rotate(
        angle: 0.05,
        child: SizedBox(
          width: size,
          height: size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vertical bar
              Container(
                width: size * 0.16,
                height: size * 1.35,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B6B13), Color(0xFFFFD700), Color(0xFFFFFACD)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Horizontal bar
              Positioned(
                top: size * 0.35,
                child: Container(
                  width: size * 0.85,
                  height: size * 0.16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B6B13), Color(0xFFFFD700), Color(0xFF8B6B13)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // White Cloth (Draped)
              Positioned(
                top: size * 0.22,
                child: Icon(
                  Icons.gesture,
                  size: size * 0.7,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sky warm aura from the top ───
class _SkyAura extends StatelessWidget {
  const _SkyAura();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -1.0),
            radius: 1.2,
            colors: [
              const Color(0xFFFFD700).withOpacity(0.12),
              const Color(0xFFFFA500).withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─── The Realistic Sun ───
class _RealisticSun extends StatefulWidget {
  const _RealisticSun();
  @override
  State<_RealisticSun> createState() => _RealisticSunState();
}

class _RealisticSunState extends State<_RealisticSun> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
        // Subtle pulsing scale: 0.95 → 1.05
        final scale = 1.0 + math.sin(_controller.value * math.pi) * 0.05;
        final glowOpacity = 0.3 + math.sin(_controller.value * math.pi) * 0.1;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1: Outer soft glow (largest, most faded)
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(glowOpacity * 0.5),
                        blurRadius: 100,
                        spreadRadius: 40,
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Layer 2: Mid glow ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFE082).withOpacity(0.25),
                        const Color(0xFFFFD700).withOpacity(0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                // Layer 3: Sun core (warm white → gold)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFFDE7),  // Warm white center
                        Color(0xFFFFE082),  // Light gold
                        Color(0xFFFFD700),  // Gold edge
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(glowOpacity),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(glowOpacity * 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Natural Sun Rays ───
class _SunRays extends StatefulWidget {
  const _SunRays();
  @override
  State<_SunRays> createState() => _SunRaysState();
}

class _SunRaysState extends State<_SunRays> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
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
          size: Size.infinite,
          painter: _NaturalSunRaysPainter(_controller.value),
        );
      },
    );
  }
}

class _NaturalSunRaysPainter extends CustomPainter {
  final double progress;
  _NaturalSunRaysPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Sun is at top center, disk center is at y=50
    final sunCenter = Offset(size.width / 2, 50);
    final maxRayLength = size.height * 1.2;

    canvas.save();
    canvas.translate(sunCenter.dx, sunCenter.dy);

    // Very slow rotation (full circle in 60 seconds)
    canvas.rotate(progress * 2 * math.pi);

    final int rayCount = 24;
    final random = math.Random(42);

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      // Only draw rays in the lower half (visible on screen)

      // Vary ray width and length for natural look
      final rayLength = maxRayLength * (0.6 + random.nextDouble() * 0.4);
      final halfWidth = size.width * (0.012 + random.nextDouble() * 0.02);
      final opacity = 0.035 + random.nextDouble() * 0.045;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(opacity * 1.5),
            const Color(0xFFFFD700).withOpacity(opacity * 0.8),
            const Color(0xFFFFFACD).withOpacity(opacity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(-halfWidth, 0, halfWidth * 2, rayLength));

      canvas.save();
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, 0) // Start exactly at the point center
        ..lineTo(-halfWidth, rayLength)
        ..lineTo(halfWidth, rayLength)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NaturalSunRaysPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Rising Light Particles ───
class _RisingLightEffect extends StatefulWidget {
  const _RisingLightEffect();

  @override
  State<_RisingLightEffect> createState() => _RisingLightEffectState();
}

class _RisingLightEffectState extends State<_RisingLightEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_LightParticle> _particles = List.generate(25, (i) => _LightParticle.create(i));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
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
          painter: _LightPainter(particles: _particles, progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _LightParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _LightParticle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});

  static _LightParticle create(int i) {
    final r = math.Random(i * 7 + 3);
    return _LightParticle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 1.5 + r.nextDouble() * 2.5,
      speed: 0.08 + r.nextDouble() * 0.15,
      opacity: 0.15 + r.nextDouble() * 0.35,
    );
  }
}

class _LightPainter extends CustomPainter {
  final List<_LightParticle> particles;
  final double progress;

  _LightPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var p in particles) {
      // Particles float upward slowly
      final y = (p.y - progress * p.speed) % 1.0;
      // Subtle horizontal drift
      final drift = math.sin(progress * 2 * math.pi + p.x * 10) * 8;
      paint.color = const Color(0xFFFFE082).withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width + drift, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Top Border ───
class _ResurrectionTopBorder extends StatelessWidget {
  const _ResurrectionTopBorder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFFFFD700),
            Colors.white,
            Color(0xFFFFD700),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
