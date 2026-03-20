import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';
import 'dart:math' as math;

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback? onTap;
  final Color accentColor;

  const DiceWidget({
    super.key,
    required this.value,
    this.isRolling = false,
    this.onTap,
    this.accentColor = Colors.amber,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayValue = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    if (widget.isRolling) _controller.repeat();
    _displayValue = widget.value;
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller.repeat();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _controller.stop();
      setState(() {
        _displayValue = widget.value;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRolling ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double angle = _controller.value * math.pi * 2;
          final int rollVal = (math.Random().nextInt(6) + 1);
          final showVal = widget.isRolling ? rollVal : (widget.value > 0 ? widget.value : _displayValue);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(widget.isRolling ? angle : 0)
              ..rotateY(widget.isRolling ? angle : 0),
            alignment: Alignment.center,
            child: Container(
              width: 55,
              height: 55,
              decoration: AppDesign.glassDecoration.copyWith(
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: widget.accentColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Center(
                child: _buildDiceFace(showVal),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiceFace(int val) {
    if (val == 0) return const Text("🎲", style: TextStyle(fontSize: 24));
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      padding: const EdgeInsets.all(8),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: List.generate(9, (index) {
        if (_shouldShowDot(val, index)) {
          return Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          );
        }
        return const SizedBox();
      }),
    );
  }

  bool _shouldShowDot(int val, int index) {
    const dots = {
      1: [4],
      2: [0, 8],
      3: [0, 4, 8],
      4: [0, 2, 6, 8],
      5: [0, 2, 4, 6, 8],
      6: [0, 2, 3, 5, 6, 8],
    };
    return dots[val]?.contains(index) ?? false;
  }
}
