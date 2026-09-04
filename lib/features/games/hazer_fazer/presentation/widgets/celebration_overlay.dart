import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';
import '../../domain/entities/saint_picture.dart';

class CelebrationDialog extends StatefulWidget {
  final SaintPicture saint;
  final String? winningTeamName;
  final int winPoints;
  final VoidCallback onNewRound;
  final VoidCallback onBackToHub;

  const CelebrationDialog({
    super.key,
    required this.saint,
    this.winningTeamName,
    required this.winPoints,
    required this.onNewRound,
    required this.onBackToHub,
  });

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = AppDesign.isSmallScreen(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Falling Confetti Animation Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(progress: _confettiController.value),
                );
              },
            ),
          ),

          // Main Card Content
          Container(
            width: isSmall ? double.infinity : 520,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 36,
              vertical: isSmall ? 24 : 36,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B4B), // Deep indigo
                  Color(0xFF311042), // Royal purple
                  Color(0xFF0F172A), // Slate deep
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amberAccent.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Trophy
                Container(
                  width: isSmall ? 70 : 90,
                  height: isSmall ? 70 : 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.6),
                        blurRadius: 25,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: isSmall ? 40 : 54,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Title
                Text(
                  '🎉 مبرووووك الفوز! 🎉',
                  style: TextStyle(
                    fontSize: isSmall ? 24 : 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.amberAccent,
                    shadows: [
                      Shadow(
                        color: Colors.amber.withOpacity(0.8),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Winner Announcement
                if (widget.winningTeamName != null && widget.winningTeamName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'فاز فريق "${widget.winningTeamName}" بـ ${widget.winPoints} نقطة!',
                      style: TextStyle(
                        fontSize: isSmall ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Text(
                    'تم كشف الصورة والتخمين بنجاح!',
                    style: TextStyle(
                      fontSize: isSmall ? 15 : 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 20),

                // Saint Details & Thumbnail
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: isSmall ? 64 : 80,
                          height: isSmall ? 64 : 80,
                          child: widget.saint.buildImage(fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.saint.name,
                              style: TextStyle(
                                fontSize: isSmall ? 17 : 21,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            if (widget.saint.title.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.saint.title,
                                style: TextStyle(
                                  fontSize: isSmall ? 12 : 14,
                                  color: Colors.amber.shade200,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Action Buttons: دور جديد & رجوع للواجهة
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onNewRound();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 22),
                        label: const Text(
                          'دور جديد',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: const Color(0xFF1E1B4B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onBackToHub();
                        },
                        icon: const Icon(Icons.home_rounded, size: 22),
                        label: const Text(
                          'كل الألعاب',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final List<_ConfettiParticle> _particles = List.generate(45, (i) => _ConfettiParticle(i));

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((p.startY + progress * p.speed * size.height) % (size.height + 40)) - 20;
      final x = (p.startX * size.width + math.sin(progress * 2 * math.pi + p.wobble) * 25);
      final paint = Paint()
        ..color = p.color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 4 * math.pi + p.rotation);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double speed;
  final double size;
  final double rotation;
  final double wobble;
  final bool isCircle;
  final Color color;

  _ConfettiParticle(int seed)
      : startX = (seed * 37 % 100) / 100.0,
        startY = (seed * 73 % 100) / 100.0 * 200,
        speed = 0.6 + (seed % 5) * 0.15,
        size = 8.0 + (seed % 6) * 2,
        rotation = seed.toDouble(),
        wobble = (seed % 10).toDouble(),
        isCircle = seed % 3 == 0,
        color = _colors[seed % _colors.length];

  static const _colors = [
    Colors.amberAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];
}
