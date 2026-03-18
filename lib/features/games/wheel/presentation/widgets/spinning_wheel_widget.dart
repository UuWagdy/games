import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:async';
import '../domain/entities/wheel_segment.dart';

class SpinningWheelWidget extends StatefulWidget {
  final List<WheelSegment> segments;
  final Function(WheelSegment) onResult;

  const SpinningWheelWidget({
    super.key,
    required this.segments,
    required this.onResult,
  });

  @override
  State<SpinningWheelWidget> createState() => _SpinningWheelWidgetState();
}

class _SpinningWheelWidgetState extends State<SpinningWheelWidget> {
  final StreamController<int> selected = StreamController<int>();
  int _lastSelected = 0;
  bool _isSpinning = false;

  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty) {
      return const Center(child: Text('يرجى إضافة أقسام للعجلة من الإعدادات'));
    }

    return Column(
      children: [
        Expanded(
          child: FortuneWheel(
            selected: selected.stream,
            animateFirst: false,
            items: [
              for (var segment in widget.segments)
                FortuneItem(
                  child: Text(
                    segment.text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
            ],
            onAnimationEnd: () {
              setState(() => _isSpinning = false);
              widget.onResult(widget.segments[_lastSelected]);
            },
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isSpinning
              ? null
              : () {
                  setState(() {
                    _isSpinning = true;
                    _lastSelected = Fortune.randomInt(0, widget.segments.length);
                    selected.add(_lastSelected);
                  });
                },
          icon: const Icon(Icons.refresh),
          label: const Text('لف العجلة', style: TextStyle(fontSize: 20)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
        ),
      ],
    );
  }
}
