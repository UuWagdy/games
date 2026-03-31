import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class ChristmasDecorations extends StatelessWidget {
  const ChristmasDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Premium Aurora / Fog Effect (Greenish mist)
        const _AuroraBackground(),

        // 2. High-Quality Snowfall (with depth)
        const SnowfallEffect(),
        
        // 3. Top Decorative Light String
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _ChristmasLightString(),
        ),

        // 4. Luxurious Christmas Tree (Bottom Right)
        Positioned(
          bottom: -30,
          right: -50,
          child: _buildChristmasTree(220, true),
        ),
        
        // 4. Background Christmas Tree (Bottom Left)
        Positioned(
          bottom: -20,
          left: -40,
          child: Opacity(opacity: 0.5, child: _buildChristmasTree(150, false)),
        ),

        // 5. Elegant Hanging Ornaments (Top) with glowing ropes
        Positioned(
          top: -10,
          left: 60,
          child: _buildHangingOrnament(const Color(0xFFEF4444), 120),
        ),
        Positioned(
          top: -20,
          right: 100,
          child: _buildHangingOrnament(const Color(0xFFFBBF24), 180),
        ),
        Positioned(
          top: -10,
          left: 220,
          child: _buildHangingOrnament(const Color(0xFF10B981), 90), // Green ornament to match theme
        ),
        Positioned(
          top: -5,
          right: 40,
          child: _buildHangingOrnament(Colors.white, 140),
        ),

        // 6. Santa Claus (Baba Noel) in the bottom left
        const Positioned(
          bottom: 40,
          left: 30,
          child: _FloatingImage(
            assetPath: 'assets/images/santa-claus.png',
            width: 100,
            glowColor: Colors.redAccent,
          ),
        ),

        // 7. Secondary festive image (culture.png) in the bottom right
        const Positioned(
          bottom: 30,
          right: 40,
          child: _FloatingImage(
            assetPath: 'assets/images/culture.png',
            width: 90,
            glowColor: Colors.amberAccent,
            reverseAnimation: true,
          ),
        ),
      ],
    );
  }

  Widget _buildChristmasTree(double size, bool isMain) {
    return _GlowWidget(
      color: Colors.greenAccent.withOpacity(0.1),
      blurRadius: isMain ? 40 : 20,
      child: SizedBox(
        width: size,
        height: size * 1.5,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Tree layers with richer gradients
            for (int i = 0; i < 4; i++)
              Positioned(
                bottom: (i * size * 0.22) + 15,
                child: _TreeLayer(
                  width: size * (1 - (i * 0.2)),
                  height: size * 0.55,
                  color: i == 3 
                    ? const Color(0xFF059669) // Top layer
                    : Color.lerp(const Color(0xFF064E3B), const Color(0xFF10B981), i * 0.3)!,
                ),
              ),
            // Trunk
            Container(
              width: size * 0.12,
              height: 25,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown[900]!, Colors.brown[700]!],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Animated Lights
            for (int i = 0; i < (isMain ? 25 : 10); i++)
              _BlinkingLight(
                size: size,
                random: math.Random(i + (isMain ? 100 : 0)),
              ),
            // Glowing Star
            Positioned(
              top: 15,
              child: _GlowingStar(size: size * 0.22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHangingOrnament(Color color, double length) {
    return _HangingWidget(
      length: length,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.9), color, color.withAlpha(150)],
            center: const Alignment(-0.3, -0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(Icons.ac_unit, color: Colors.white.withOpacity(0.3), size: 18),
        ),
      ),
    );
  }
}

class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size.width == 0 || size.height == 0) return const SizedBox.shrink();
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _AuroraPainter(progress: _controller.value),
              size: size,
            );
          },
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double progress;
  _AuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    void drawAura(Offset center, double radius, Color color, double opacity) {
      paint.shader = RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final angle = progress * 2 * math.pi;
    
    // Large slow moving green glow
    drawAura(
      Offset(
        size.width * 0.5 + math.sin(angle) * 100,
        size.height * 0.8 + math.cos(angle * 0.5) * 50,
      ),
      size.width * 1.5,
      const Color(0xFF10B981).withOpacity(0.1),
      0.2,
    );

    // Subtle golden glow
    drawAura(
      Offset(
        size.width * 0.8 + math.cos(angle * 0.7) * 40,
        size.height * 0.2 + math.sin(angle * 1.2) * 80,
      ),
      size.width * 0.8,
      const Color(0xFFFBBF24).withOpacity(0.05),
      0.1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GlowingStar extends StatefulWidget {
  final double size;
  const _GlowingStar({required this.size});

  @override
  State<_GlowingStar> createState() => _GlowingStarState();
}

class _GlowingStarState extends State<_GlowingStar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withOpacity(0.5 * _controller.value),
                blurRadius: 20 * _controller.value,
                spreadRadius: 5 * _controller.value,
              ),
            ],
          ),
          child: Icon(
            Icons.star_rounded,
            color: Colors.amberAccent,
            size: widget.size,
          ),
        );
      },
    );
  }
}

class _TreeLayer extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _TreeLayer({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TriangleClipper(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withAlpha(200)],
          ),
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.2, size.width, size.height);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.85, 0, size.height);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width / 2, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BlinkingLight extends StatefulWidget {
  final double size;
  final math.Random random;

  const _BlinkingLight({required this.size, required this.random});

  @override
  State<_BlinkingLight> createState() => _BlinkingLightState();
}

class _BlinkingLightState extends State<_BlinkingLight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Color _color;
  late final double _top;
  late final double _left;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000 + widget.random.nextInt(1500)),
    )..repeat(reverse: true);
    
    final colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFFFBBF24), // Gold
      const Color(0xFF60A5FA), // Soft Blue
      const Color(0xFF34D399), // Emerald
      Colors.white
    ];
    _color = colors[widget.random.nextInt(colors.length)];
    
    // Position inside the curvy triangle
    _top = 50 + widget.random.nextDouble() * (widget.size * 1.0);
    double horizontalSpan = (widget.size * 0.45) * (_top / (widget.size * 1.5));
    _left = (widget.size / 2) + (widget.random.nextDouble() - 0.5) * horizontalSpan * 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _top,
      left: _left,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withOpacity(0.4 + _controller.value * 0.6),
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.5 * _controller.value),
                  blurRadius: 8 * _controller.value,
                  spreadRadius: 2 * _controller.value,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FloatingImage extends StatefulWidget {
  final String assetPath;
  final double width;
  final Color glowColor;
  final bool reverseAnimation;

  const _FloatingImage({
    required this.assetPath,
    required this.width,
    required this.glowColor,
    this.reverseAnimation = false,
  });

  @override
  State<_FloatingImage> createState() => _FloatingImageState();
}

class _FloatingImageState extends State<_FloatingImage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    if (widget.reverseAnimation) {
      _controller.forward(from: 0.5); // Stagger start
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
        final val = _controller.value;
        final xOffset = math.sin(val * 2 * math.pi) * 15;
        final yOffset = math.cos(val * 2 * math.pi) * 10;
        
        return Transform.translate(
          offset: Offset(xOffset, yOffset),
          child: _GlowWidget(
            color: widget.glowColor.withOpacity(0.15),
            blurRadius: 25,
            child: Image.asset(
              widget.assetPath,
              width: widget.width,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

class SnowfallEffect extends StatefulWidget {
  const SnowfallEffect({super.key});

  @override
  State<SnowfallEffect> createState() => _SnowfallEffectState();
}

class _SnowfallEffectState extends State<SnowfallEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Snowflake> _snowflakes;

  @override
  void initState() {
    super.initState();
    _snowflakes = List.generate(80, (i) => _Snowflake.create(i, 80));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        if (canvasSize.width == 0 || canvasSize.height == 0) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SnowPainter(snowflakes: _snowflakes, progress: _controller.value),
              size: canvasSize,
            );
          },
        );
      },
    );
  }
}

class _Snowflake {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double phase; // For sine sway
  double blur;

  _Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
    required this.blur,
  });

  static _Snowflake create(int index, int total) {
    final random = math.Random(index);
    return _Snowflake(
      x: random.nextDouble(),
      y: random.nextDouble(), // Initial scattered
      size: 2 + random.nextDouble() * 4,
      speed: 0.15 + random.nextDouble() * 0.2, // Faster
      opacity: 0.3 + random.nextDouble() * 0.5,
      phase: random.nextDouble() * 2 * math.pi,
      blur: random.nextDouble() * 1.5,
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;
  final double progress;

  _SnowPainter({required this.snowflakes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Defensive check
    if (size.width <= 0 || size.height <= 0) return;

    for (var snowflake in snowflakes) {
      double y = (snowflake.y + progress * snowflake.speed) % 1.0;
      double sway = math.sin((progress * 2 * math.pi) + snowflake.phase) * 15;
      double x = (snowflake.x * size.width) + sway;
      
      final paint = Paint()
        ..color = Colors.white.withOpacity(snowflake.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, snowflake.blur);
        
      canvas.drawCircle(Offset(x, y * size.height), snowflake.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HangingWidget extends StatefulWidget {
  final double length;
  final Widget child;

  const _HangingWidget({required this.length, required this.child});

  @override
  State<_HangingWidget> createState() => _HangingWidgetState();
}

class _HangingWidgetState extends State<_HangingWidget> with SingleTickerProviderStateMixin {
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
        final curvedVal = Curves.easeInOut.transform(_controller.value);
        final angle = math.sin(curvedVal * 2 * math.pi) * 0.08;
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 1.5,
                height: widget.length,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white24, Colors.white.withOpacity(0.6)],
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _ChristmasLightString extends StatelessWidget {
  const _ChristmasLightString();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          // The wire
          CustomPaint(
            painter: _WirePainter(),
            size: const Size(double.infinity, 40),
          ),
          // The lights
          for (int i = 0; i < 20; i++)
            _HangingLight(
              index: i,
              total: 20,
            ),
        ],
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF064E3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, 5);
    
    double step = size.width / 10;
    for (int i = 0; i < 10; i++) {
      path.quadraticBezierTo(
        (i * step) + (step / 2), 25,
        (i + 1) * step, 5,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HangingLight extends StatefulWidget {
  final int index;
  final int total;
  const _HangingLight({required this.index, required this.total});

  @override
  State<_HangingLight> createState() => _HangingLightState();
}

class _HangingLightState extends State<_HangingLight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Color _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + (widget.index * 100) % 1000),
    )..repeat(reverse: true);
    
    final colors = [Colors.redAccent, Colors.amberAccent, Colors.greenAccent, Colors.blueAccent, Colors.pinkAccent];
    _color = colors[widget.index % colors.length];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / widget.total;
        final x = (widget.index + 0.5) * step;
        // Approximation of wire height
        final waveIdx = (widget.index / (widget.total / 10)).floor();
        final localX = (widget.index % (widget.total / 10)) / (widget.total / 10);
        final y = 10 + 15 * math.sin(localX * math.pi);

        return Positioned(
          left: x - 4,
          top: y,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 10,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.5 + _controller.value * 0.5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withOpacity(0.6 * _controller.value),
                      blurRadius: 10 * _controller.value,
                      spreadRadius: 2 * _controller.value,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GlowWidget extends StatelessWidget {
  final Widget child;
  final Color color;
  final double blurRadius;

  const _GlowWidget({required this.child, required this.color, this.blurRadius = 20});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: blurRadius,
                spreadRadius: blurRadius / 2,
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
