import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';

class SpinningWheelWidget extends StatefulWidget {
  final List<WheelSegment> segments;
  final Function(WheelSegment) onResult;

  const SpinningWheelWidget({
    super.key,
    required this.segments,
    required this.onResult,
  });

  @override
  State<SpinningWheelWidget> createState() => SpinningWheelWidgetState();
}

class SpinningWheelWidgetState extends State<SpinningWheelWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _angleAnimation;
  int _lastSelected = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _angleAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCirc),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSpinning = false);
        widget.onResult(widget.segments[_lastSelected]);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void spin() {
    if (_isSpinning || widget.segments.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _animationController.reset();

      // Calculate target angle
      final double totalRevolutions = 5 + math.Random().nextDouble() * 3; 
      _lastSelected = math.Random().nextInt(widget.segments.length);
      final double segmentAngle = (2 * math.pi) / widget.segments.length;
      
      // Target angle relative to the top pointer
      final double targetAngleForSegment = (2 * math.pi) - (_lastSelected * segmentAngle + segmentAngle / 2);

      final double endAngle = (totalRevolutions * 2 * math.pi) + targetAngleForSegment;

      _angleAnimation = Tween<double>(
        begin: _angleAnimation.value % (2 * math.pi),
        end: endAngle,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCirc),
      );
      
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty) {
      return const Center(child: Text('يرجى إضافة أقسام للعجلة من الإعدادات'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.49;
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

        return AnimatedBuilder(
          animation: _angleAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(radius * 2, radius * 2),
                  painter: _WheelPainter(
                    segments: widget.segments,
                    angle: _angleAnimation.value,
                  ),
                ),
                // Center Pin
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                      ),
                    ],
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ),
                // Pointer
                Positioned(
                  top: (constraints.maxHeight / 2) - radius - 20,
                  child: const Icon(
                    Icons.arrow_drop_down,
                    size: 90,
                    color: Colors.amber,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;
  final double angle;

  _WheelPainter({required this.segments, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final sweepAngle = (2 * math.pi) / segments.length;

    final List<Color> colors = [
      const Color(0xFF003F5C),
      const Color(0xFF2F6690),
      const Color(0xFF58508D),
      const Color(0xFFBC5090),
      const Color(0xFF9E3A73),
      const Color(0xFFFFA600),
    ];

    for (int i = 0; i < segments.length; i++) {
      final startAngle = angle + (i * sweepAngle);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw text with upright logic
      canvas.save();
      canvas.translate(center.dx, center.dy);
      
      double rotationAngle = startAngle + sweepAngle / 2;
      double normalizedAngle = rotationAngle % (2 * math.pi);
      if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;
      
      // Flip text if it's on bottom/left side to keep it upright
      bool shouldFlip = normalizedAngle > math.pi / 2 && normalizedAngle < 3 * math.pi / 2;

      canvas.rotate(rotationAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 55, // BIG FONT 55
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      );

      textPainter.layout(maxWidth: radius * 0.85);
      
      if (shouldFlip) {
        canvas.translate(radius * 0.55, 0); // Position text
        canvas.rotate(math.pi); // Flip 180 degrees
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      } else {
        textPainter.paint(
          canvas,
          Offset(radius * 0.55 - textPainter.width / 2, -textPainter.height / 2),
        );
      }
      
      canvas.restore();
    }

    // Outer thick gold border
    final borderPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => 
      oldDelegate.angle != angle || oldDelegate.segments != segments;
}
