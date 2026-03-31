import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';

class SpinningWheelWidget extends StatefulWidget {
  final List<WheelSegment> segments;
  final List<int> exhaustedIds;
  final Function(WheelSegment) onResult;

  const SpinningWheelWidget({
    super.key,
    required this.segments,
    this.exhaustedIds = const [],
    required this.onResult,
  });

  @override
  State<SpinningWheelWidget> createState() => SpinningWheelWidgetState();
}

class SpinningWheelWidgetState extends State<SpinningWheelWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _angleAnimation;
  bool _isSpinning = false;
  double _manualAngle = 0;
  double _dragStartAngle = 0;
  ui.Image? _jokerImage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _angleAnimation = const AlwaysStoppedAnimation(0);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _manualAngle = _angleAnimation.value;
        });
        
        final double finalAngle = _angleAnimation.value;
        final double sweep = (2 * math.pi) / widget.segments.length;
        
        double normalizedTop = (1.5 * math.pi - finalAngle) % (2 * math.pi);
        if (normalizedTop < 0) normalizedTop += 2 * math.pi;
        
        int indexAtTop = (normalizedTop / sweep).floor() % widget.segments.length;
        widget.onResult(widget.segments[indexAtTop]);
      }
    });

    _loadJokerImage();
  }

  Future<void> _loadJokerImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/joker-hat.png');
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo fi = await codec.getNextFrame();
      setState(() {
        _jokerImage = fi.image;
      });
    } catch (e) {
      debugPrint('Error loading joker hat image: $e');
    }
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

      final double totalRevolutions = 5 + math.Random().nextDouble() * 3; 
      final int randomIndex = math.Random().nextInt(widget.segments.length);
      final double segmentAngle = (2 * math.pi) / widget.segments.length;
      
      final double targetAngle = (1.5 * math.pi) - (randomIndex * segmentAngle + segmentAngle / 2);

      final double startAngle = _manualAngle;
      final double endAngle = startAngle + (totalRevolutions * 2 * math.pi) + (targetAngle - (startAngle % (2 * math.pi)));

      _angleAnimation = Tween<double>(
        begin: startAngle,
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

        return GestureDetector(
          onPanDown: (details) {
            if (!_isSpinning) {
              _dragStartAngle = math.atan2(
                details.localPosition.dy - center.dy,
                details.localPosition.dx - center.dx,
              );
            }
          },
          onPanUpdate: (details) {
            if (!_isSpinning) {
              final currentAngle = math.atan2(
                details.localPosition.dy - center.dy,
                details.localPosition.dx - center.dx,
              );
              setState(() {
                _manualAngle += (currentAngle - _dragStartAngle);
                _dragStartAngle = currentAngle;
                _angleAnimation = AlwaysStoppedAnimation(_manualAngle);
              });
            }
          },
          onPanEnd: (details) {
            if (!_isSpinning && details.velocity.pixelsPerSecond.distance > 800) {
              spin();
            }
          },
          child: AnimatedBuilder(
            animation: _angleAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(radius * 2, radius * 2),
                    painter: _WheelPainter(
                      widget.segments,
                      widget.exhaustedIds,
                      _angleAnimation.value,
                      _jokerImage,
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: _isSpinning 
                          ? const CircularProgressIndicator(strokeWidth: 3, color: Colors.blueAccent)
                          : Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Positioned(
                    top: (constraints.maxHeight / 2) - radius - 25,
                    child: Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 70,
                      color: Colors.blueAccent,
                      shadows: [
                        Shadow(color: Colors.blueAccent.withOpacity(0.6), blurRadius: 15)
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;
  final List<int> exhaustedIds;
  final double angle;
  final ui.Image? jokerImage;

  _WheelPainter(this.segments, this.exhaustedIds, this.angle, this.jokerImage);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final sweepAngle = (2 * math.pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final s = segments[i];
      final isExhausted = s.id != null && exhaustedIds.contains(s.id!);
      final isDark = s.isQuestion || s.isSwitch || s.isJoker;
      final paint = Paint()
        ..color = isExhausted
            ? const Color(0xFF020617).withOpacity(0.95) // Deep Exhausted Black/Navy
            : isDark 
                ? const Color(0xFF0F172A).withOpacity(0.9) // Deep Glass Navy
                : const Color(0xFF1E293B).withOpacity(0.85) // Deep Glass Navy Consistent with Game Theme
        ..style = PaintingStyle.fill;
        
        
      // Inner glass glow
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(center, radius, [Colors.white.withOpacity(0.1), Colors.transparent])
        ..style = PaintingStyle.fill;

      final startAngle = angle + (i * sweepAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        glowPaint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw content
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sweepAngle / 2);

      if (segments[i].isSwitch || segments[i].isJoker) {
        if (segments[i].isJoker && jokerImage != null) {
          canvas.save();
          canvas.translate(radius * 0.75, 0); 
          canvas.rotate(-(startAngle + sweepAngle / 2)); 
          final double imgSize = radius * 0.3;
          paintImage(
            canvas: canvas,
            rect: Rect.fromCenter(center: Offset.zero, width: imgSize, height: imgSize),
            image: jokerImage!,
            fit: BoxFit.contain,
          );
          canvas.restore();
        } else {
          final icon = segments[i].isSwitch ? Icons.sync : Icons.style;
          double iconSize = radius * 0.25;
          if (iconSize > 55) iconSize = 55;
          if (iconSize < 24) iconSize = 24;

          final iconPainter = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(
                fontSize: iconSize,
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                color: segments[i].isQuestion || segments[i].isSwitch || segments[i].isJoker ? Colors.white : Colors.amberAccent,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          iconPainter.layout();
          final currentSliceAngle = (startAngle + sweepAngle / 2) % (2 * math.pi);
          final normalizedAngle = currentSliceAngle < 0 ? currentSliceAngle + 2 * math.pi : currentSliceAngle;
          final bool shouldFlip = normalizedAngle > math.pi / 2 && normalizedAngle < 3 * math.pi / 2;

          canvas.save();
          canvas.translate(radius * 0.65, 0);
          if (shouldFlip) canvas.rotate(math.pi);
          iconPainter.paint(canvas, Offset(-iconPainter.width / 2, -iconPainter.height / 2));
          canvas.restore();
        }
      } else {
        double fontSize = radius * 0.18; // Increased base proportion
        if (fontSize > 45) fontSize = 45; // Much higher cap for large screens
        if (fontSize < 12) fontSize = 12; 

        // Let the text occupy up to 75% of the sweep angle's width at our radius
        final double maxAllowedWidth = radius * 0.75 * sweepAngle; 
        
        TextPainter textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );

        // Try decreasing font size until it fits the available width
        bool fits = false;
        while (!fits && fontSize >= 8) {
          textPainter.text = TextSpan(
            text: segments[i].text,
            style: TextStyle(
              color: segments[i].isQuestion || segments[i].isSwitch || segments[i].isJoker ? Colors.white : Colors.amberAccent,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          );
          textPainter.layout();
          if (textPainter.width <= maxAllowedWidth) {
            fits = true;
          } else {
            fontSize -= 1;
          }
        }

        final currentSliceAngle = (startAngle + sweepAngle / 2) % (2 * math.pi);
        final normalizedAngle = currentSliceAngle < 0 ? currentSliceAngle + 2 * math.pi : currentSliceAngle;
        final bool shouldFlip = normalizedAngle > math.pi / 2 && normalizedAngle < 3 * math.pi / 2;

        canvas.save();
        canvas.translate(radius * 0.6, 0); 
        if (shouldFlip) canvas.rotate(math.pi);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
      canvas.restore();
    }

    // Outer glowing border
    final outerGlowPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius, outerGlowPaint);

    final outerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, outerPaint);

    final secondaryBorder = Paint()
      ..color = Colors.blueAccent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 4, secondaryBorder);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => 
      oldDelegate.angle != angle || oldDelegate.segments != segments || oldDelegate.jokerImage != jokerImage;
}
