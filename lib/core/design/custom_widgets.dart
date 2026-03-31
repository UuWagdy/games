import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:io';

class CustomDecorations extends StatelessWidget {
  final Map<String, dynamic> settings;
  const CustomDecorations({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(settings['custom_primary_color'] ?? 0xFF00BCD4);
    final iconCodePoints = settings['custom_icons'] as List<dynamic>? ?? ['58713'];
    final iconFiles = settings['custom_icon_files'] as List<dynamic>? ?? [];
    
    // Combine both types of icons
    final List<Widget> backgroundElements = [];
    
    for (var code in iconCodePoints) {
      backgroundElements.add(Text(
        String.fromCharCode(int.parse(code.toString())),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          color: primaryColor,
          fontSize: 24,
        ),
      ));
    }
    
    for (var path in iconFiles) {
      if (path.toString().isNotEmpty) {
        backgroundElements.add(Image.file(
          File(path.toString()),
          width: 24,
          height: 24,
          color: primaryColor,
          colorBlendMode: BlendMode.modulate,
        ));
      }
    }

    if (backgroundElements.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // 1. Dynamic Glow Particles
        _GlowParticles(color: primaryColor),

        // 2. Distributed Hanging Elements
        for (int i = 0; i < backgroundElements.length; i++)
          Positioned(
            top: -10,
            left: 50.0 + (i * 100).toDouble() % (MediaQuery.of(context).size.width - 50),
            child: _HangingElement(
              color: primaryColor,
              length: 100.0 + (i * 40) % 150,
              iconWidget: backgroundElements[i],
            ),
          ),
          
        // 3. Floating Elements (Bottom)
        for (int i = 0; i < 3; i++)
          Positioned(
            bottom: 40.0 + (i * 20),
            left: 40.0 + (i * 120),
            child: _FloatingElement(
              color: primaryColor,
              iconWidget: backgroundElements[i % backgroundElements.length],
              reverse: i % 2 == 0,
            ),
          ),
      ],
    );
  }
}

class _GlowParticles extends StatefulWidget {
  final Color color;
  const _GlowParticles({required this.color});

  @override
  State<_GlowParticles> createState() => _GlowParticlesState();
}

class _GlowParticlesState extends State<_GlowParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
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
          painter: _ParticlePainter(progress: _controller.value, color: widget.color),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0) return;
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    
    final random = math.Random(42);
    for (int i = 0; i < 5; i++) {
      final angle = (progress * 2 * math.pi) + (i * math.pi / 2.5);
      final radius = 100.0 + random.nextDouble() * 100;
      final x = size.width / 2 + math.cos(angle) * (size.width * 0.3);
      final y = size.height / 2 + math.sin(angle * 0.7) * (size.height * 0.3);
      
      paint.color = color.withOpacity(0.05);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HangingElement extends StatefulWidget {
  final Color color;
  final double length;
  final Widget iconWidget;

  const _HangingElement({required this.color, required this.length, required this.iconWidget});

  @override
  State<_HangingElement> createState() => _HangingElementState();
}

class _HangingElementState extends State<_HangingElement> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
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
        final angle = math.sin(_controller.value * 2 * math.pi) * 0.05;
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Container(
                width: 1,
                height: widget.length,
                color: Colors.white24,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.1),
                  border: Border.all(color: widget.color.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 15),
                  ],
                ),
                child: widget.iconWidget,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingElement extends StatefulWidget {
  final Color color;
  final Widget iconWidget;
  final bool reverse;

  const _FloatingElement({required this.color, required this.iconWidget, this.reverse = false});

  @override
  State<_FloatingElement> createState() => _FloatingElementState();
}

class _FloatingElementState extends State<_FloatingElement> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    if (widget.reverse) _controller.forward(from: 0.5);
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
        final offset = math.sin(_controller.value * 2 * math.pi) * 20;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.1),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: widget.iconWidget,
          ),
        );
      },
    );
  }
}
