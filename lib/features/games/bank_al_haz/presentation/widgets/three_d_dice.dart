import 'package:flutter/material.dart';
import 'dart:math' as math;

class ThreeDDice extends StatefulWidget {
  final int value;
  final int rollCounter;
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  const ThreeDDice({
    super.key,
    required this.value,
    this.rollCounter = 0,
    this.duration = const Duration(milliseconds: 1200),
    this.onAnimationComplete,
  });

  @override
  State<ThreeDDice> createState() => _ThreeDDiceState();
}

class _ThreeDDiceState extends State<ThreeDDice>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final _random = math.Random();

  // The face value currently displaying
  int _displayedValue = 1;
  // Track whether we're in the "cycling" phase of the animation
  bool _isCycling = false;
  // Store the sequence of face changes during roll
  List<int> _rollSequence = [];
  int _sequenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _displayedValue = widget.value.clamp(1, 6);
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _displayedValue = widget.value.clamp(1, 6);
          _isCycling = false;
        });
        widget.onAnimationComplete?.call();
      }
    });

    _animation.addListener(() {
      if (_isCycling && _rollSequence.isNotEmpty) {
        // Calculate which frame of the sequence we should be showing
        // Slow down toward the end (show later values for longer)
        final progress = _animation.value;
        final newIndex =
            (progress * (_rollSequence.length - 1)).floor().clamp(0, _rollSequence.length - 1);
        if (newIndex != _sequenceIndex) {
          _sequenceIndex = newIndex;
          setState(() {
            _displayedValue = _rollSequence[_sequenceIndex];
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(ThreeDDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rollCounter != widget.rollCounter) {
      _startRoll();
    }
  }

  void _startRoll() {
    // Build a sequence of random face values, ending with the real value
    final int totalFrames = 14; // Number of face-change frames
    _rollSequence = List.generate(totalFrames, (i) {
      if (i == totalFrames - 1) {
        return widget.value.clamp(1, 6); // Last frame is the final value
      }
      return _random.nextInt(6) + 1; // Random face
    });
    _sequenceIndex = 0;
    _isCycling = true;
    _displayedValue = _rollSequence[0];

    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // During cycling, add a 3D tumble effect
        final double rotX =
            _isCycling ? math.sin(_animation.value * math.pi * 4) * 0.3 : 0;
        final double rotY =
            _isCycling ? math.cos(_animation.value * math.pi * 3) * 0.3 : 0;
        // Bounce/scale effect
        final double scale =
            _isCycling ? 1.0 + math.sin(_animation.value * math.pi) * 0.15 : 1.0;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.003)
            ..scale(scale, scale, 1.0)
            ..rotateX(rotX)
            ..rotateY(rotY),
          alignment: Alignment.center,
          child: _buildDiceFace(_displayedValue),
        );
      },
    );
  }

  Widget _buildDiceFace(int value) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade100],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          painter: DiceDotsPainter(value),
          size: const Size(46, 46),
        ),
      ),
    );
  }
}

class DiceDotsPainter extends CustomPainter {
  final int value;
  DiceDotsPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    final r = size.width / 9;

    void drawDot(double x, double y) => canvas.drawCircle(
          Offset(x * size.width, y * size.height),
          r,
          paint,
        );

    // Standard dice dot patterns
    switch (value) {
      case 1:
        drawDot(0.5, 0.5);
        break;
      case 2:
        drawDot(0.27, 0.27);
        drawDot(0.73, 0.73);
        break;
      case 3:
        drawDot(0.27, 0.27);
        drawDot(0.5, 0.5);
        drawDot(0.73, 0.73);
        break;
      case 4:
        drawDot(0.27, 0.27);
        drawDot(0.73, 0.27);
        drawDot(0.27, 0.73);
        drawDot(0.73, 0.73);
        break;
      case 5:
        drawDot(0.27, 0.27);
        drawDot(0.73, 0.27);
        drawDot(0.5, 0.5);
        drawDot(0.27, 0.73);
        drawDot(0.73, 0.73);
        break;
      case 6:
        drawDot(0.27, 0.25);
        drawDot(0.73, 0.25);
        drawDot(0.27, 0.5);
        drawDot(0.73, 0.5);
        drawDot(0.27, 0.75);
        drawDot(0.73, 0.75);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DiceDotsPainter oldDelegate) =>
      oldDelegate.value != value;
}
