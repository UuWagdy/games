import 'package:flutter/material.dart';
import 'package:games/features/home/presentation/pages/main_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:games/core/database/database_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ───────────────────────────────────────────────────────────
  late final AnimationController _mainCtrl; // Orchestrates overall entrance
  late final AnimationController _pulseCtrl; // Continuous idle pulse
  late final AnimationController _shimmerCtrl; // Periodic glint/shimmer
  late final AnimationController _nebulaCtrl; // Slow background evolution

  // ─── Animations ────────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoBlur;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _glowIntensity;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Controller (3.5s total)
    _mainCtrl = AnimationController(
      duration: const Duration(milliseconds: 6500),
      vsync: this,
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.4,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_mainCtrl);

    _logoBlur = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainCtrl,
            curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    _glowIntensity =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.0,
              end: 1.2,
            ).chain(CurveTween(curve: Curves.easeIn)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.2,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.2, 0.8)),
        );

    // 2. Idle Pulsing (Logo breathing)
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    // 3. Shimmer Effect
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    // 4. Nebula Background Evolution
    _nebulaCtrl = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _mainCtrl.forward();
    _navigate();

    // Start database initialization early during splash
    DatabaseService.instance.database;
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 9500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool showOnboarding = prefs.getBool('show_onboarding') ?? true;
    final Widget next = showOnboarding
        ? const OnboardingScreen()
        : const MainScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionDuration: const Duration(milliseconds: 1200),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _nebulaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compact = size.width < 520;

    final settingsAsync = ref.watch(generalSettingsProvider);
    final themeId = settingsAsync.when(
      data: (s) => s['app_theme'] as String? ?? 'default',
      loading: () => 'default',
      error: (_, __) => 'default',
    );
    final theme = AppThemes.getThemeById(themeId);

    return Scaffold(
      backgroundColor: theme.backgroundDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dynamic Nebula Background
          AnimatedBuilder(
            animation: _nebulaCtrl,
            builder: (context, _) => CustomPaint(
              painter: _NebulaPainter(
                progress: _nebulaCtrl.value,
                theme: theme,
              ),
            ),
          ),

          // 2. Subtle Star Field
          _StarField(animation: _nebulaCtrl),

          // 2.5 Fog/Atmosphere Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    theme.backgroundDeep.withOpacity(0.4),
                    theme.backgroundDeep.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          
          // Fog Blur
          IgnorePointer(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 3. Main Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glowing halo
                  AnimatedBuilder(
                    animation: Listenable.merge([_mainCtrl, _pulseCtrl]),
                    builder: (context, _) {
                      final pulse = _pulseCtrl.value;
                      final entranceGlow = _glowIntensity.value;

                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _logoBlur.value,
                              sigmaY: _logoBlur.value,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Layered Halo Glow
                                _LogoHalo(
                                  size: compact ? 180 : 260,
                                  intensity: (0.6 + pulse * 0.4) * entranceGlow,
                                  color: theme.primaryColor,
                                ),
                                _LogoHalo(
                                  size: compact ? 140 : 200,
                                  intensity: (0.8 + pulse * 0.2) * entranceGlow,
                                  color: theme.orbColors[1],
                                ),
                                // The Actual Logo
                                Container(
                                  width: compact ? 120 : 180,
                                  height: compact ? 120 : 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primaryColor.withOpacity(0.3 * entranceGlow),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                // Glint Sweep over the logo
                                AnimatedBuilder(
                                  animation: _shimmerCtrl,
                                  builder: (context, _) => _SweepGlint(
                                    size: compact ? 120 : 180,
                                    progress: _shimmerCtrl.value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Title and Subtitle
                  FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        children: [
                          _AnimatedTitle(
                            text: 'GAMES PLATFORM',
                            style: TextStyle(
                              fontSize: compact ? 26 : 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: compact ? 4 : 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            width: compact ? 150 : 250,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFB8A070).withOpacity(0.5),
                                  Colors.white.withOpacity(0.8),
                                  const Color(0xFFB8A070).withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'UNLEASH THE PLAY',
                            style: TextStyle(
                              fontSize: compact ? 10 : 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB8A070),
                              letterSpacing: compact ? 4 : 10,
                            ),
                          ),
                          // Extra space to prevent overlap with footer on small screens
                          if (compact) const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Footer
          Positioned(
            bottom: compact ? 30 : 50,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _contentFade,
              child: _RefinedFooter(
                compact: compact,
                parentAnimation: _mainCtrl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom Painter for Nebula Background
// ──────────────────────────────────────────────────────────────────────────────
class _NebulaPainter extends CustomPainter {
  final double progress;
  final ThemeConfig theme;
  _NebulaPainter({required this.progress, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base layer
    canvas.drawRect(rect, Paint()..color = theme.backgroundDeep);

    void drawGlow(Offset center, double radius, List<Color> colors) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: colors,
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // Moving Nebula Clouds
    final angle = progress * 2 * math.pi;

    // Theme Cloud 1
    drawGlow(
      Offset(
        size.width * 0.5 + math.cos(angle) * 100,
        size.height * 0.4 + math.sin(angle) * 50,
      ),
      size.width * 1.2,
      [theme.orbColors[0].withOpacity(0.25), Colors.transparent],
    );

    // Theme Cloud 2
    drawGlow(
      Offset(
        size.width * 0.3 + math.sin(angle * 0.5) * 80,
        size.height * 0.7 + math.cos(angle * 0.8) * 100,
      ),
      size.width * 0.8,
      [theme.orbColors[1].withOpacity(0.15), Colors.transparent],
    );

    // Theme Cloud 3
    drawGlow(
      Offset(
        size.width * 0.8 + math.cos(angle * 1.2) * 120,
        size.height * 0.2 + math.sin(angle * 0.6) * 60,
      ),
      size.width * 0.7,
      [theme.orbColors[2].withOpacity(0.12), Colors.transparent],
    );
  }

  @override
  bool shouldRepaint(_NebulaPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ──────────────────────────────────────────────────────────────────────────────
// Logo Components
// ──────────────────────────────────────────────────────────────────────────────
class _LogoHalo extends StatelessWidget {
  final double size;
  final double intensity;
  final Color color;

  const _LogoHalo({
    required this.size,
    required this.intensity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.4 * intensity), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

class _SweepGlint extends StatelessWidget {
  final double size;
  final double progress;

  const _SweepGlint({required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    // A diagonal "shimmer" stripe that moves across
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: FractionallySizedBox(
          widthFactor: 2.0,
          alignment: Alignment(lerpDouble(-2.0, 2.0, progress)!, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.4, 0.5, 0.6],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Typography Components
// ──────────────────────────────────────────────────────────────────────────────
class _AnimatedTitle extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _AnimatedTitle({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: style.copyWith(
        shadows: [
          Shadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Decorative Animated Star Field
// ──────────────────────────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  final Animation<double> animation;
  const _StarField({required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => CustomPaint(
            painter: _StarPainter(progress: animation.value), 
            size: Size.infinite
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double progress;
  _StarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(13); // Fixed seed for stars
    
    for (int i = 0; i < 60; i++) {
      final xBase = random.nextDouble() * size.width;
      final yBase = random.nextDouble() * size.height;
      
      // Faster, more dynamic periodic movement
      final x = xBase + math.sin(progress * 8 * math.pi + i) * 8;
      final y = yBase + math.cos(progress * 6 * math.pi + i) * 6;
      
      final baseOpacity = 0.1 + random.nextDouble() * 0.2;
      // Faster, more sparkling twinkle effect
      final flicker = math.sin(progress * 40 * math.pi + (i * 2.0)) * 0.1;
      final opacity = (baseOpacity + flicker).clamp(0.05, 0.4);
      
      final pSize = 0.5 + random.nextDouble() * 2.5;

      // Draw star core
      final corePaint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), pSize, corePaint);

      // Enhanced Glow Effect
      if (i % 6 == 0) {
        final glowIntensity = opacity * (0.4 + random.nextDouble() * 0.4);
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(glowIntensity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, pSize * 4);
        canvas.drawCircle(Offset(x, y), pSize * 6, glowPaint);
        
        // Occasional deeper colorful glows
        if (i % 18 == 0) {
           final colorGlowPaint = Paint()
            ..color = (i % 36 == 0 ? Colors.blueAccent : Colors.amberAccent).withOpacity(opacity * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
           canvas.drawCircle(Offset(x, y), pSize * 15, colorGlowPaint);
        }

        // Lens flare effect for brighter stars
        if (i % 30 == 0) {
          final flarePaint = Paint()
            ..color = Colors.white.withOpacity(opacity * 0.3)
            ..strokeWidth = 1.0;
          canvas.drawLine(Offset(x - pSize * 15, y), Offset(x + pSize * 15, y), flarePaint);
          canvas.drawLine(Offset(x, y - pSize * 15), Offset(x, y + pSize * 15), flarePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.progress != progress;
}

// ──────────────────────────────────────────────────────────────────────────────
// Refined Footer
// ──────────────────────────────────────────────────────────────────────────────
class _RefinedFooter extends StatelessWidget {
  final bool compact;
  final Animation<double> parentAnimation;
  const _RefinedFooter({required this.compact, required this.parentAnimation});

  static const List<Map<String, String>> developers = [
    {'name': 'د. يوساب وجدي', 'role': 'Developer'},
    {'name': 'م. باڤلي باسم', 'role': 'Games Ideas'},
    {'name': 'ف. فيلوباتير باسم', 'role': 'Games Ideas'},
    {'name': 'أ. چوليا چورچ', 'role': 'Questions'},
    {'name': 'م. مريم منتصر', 'role': 'Questions'},
    {'name': 'م. مارينا حسني', 'role': 'Tester'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'POWERED BY INNOVATION',
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: compact ? 8 : 10,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: List.generate(developers.length, (index) {
              // Creating a staggered interval for each badge
              final start = 0.6 + (index * 0.05);
              final end = (start + 0.2).clamp(0.0, 1.0);

              final animation = CurvedAnimation(
                parent: parentAnimation,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (animation.value * 0.2),
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - animation.value)),
                      child: Opacity(opacity: animation.value, child: child),
                    ),
                  );
                },
                child: _RefinedBadge(
                  name: developers[index]['name']!,
                  role: developers[index]['role']!,
                  animation: animation,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _RefinedBadge extends StatelessWidget {
  final String name;
  final String role;
  final Animation<double> animation;

  const _RefinedBadge({
    required this.name, 
    required this.role, 
    required this.animation
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glow = animation.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05 + (0.05 * glow)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFB8A070).withOpacity(0.1 + (0.3 * glow)),
              width: 1 + glow,
            ),
            boxShadow: [
              // Subtle Glow
              BoxShadow(
                color: const Color(0xFFB8A070).withOpacity(0.2 * glow),
                blurRadius: 15 * glow,
                spreadRadius: 2 * glow,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8 + (0.2 * glow)),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    if (glow > 0.5)
                      Shadow(
                        color: Colors.white.withOpacity(0.5 * (glow - 0.5)),
                        blurRadius: 10,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role,
                style: TextStyle(
                  color: const Color(0xFFB8A070).withOpacity(0.5 + (0.4 * glow)),
                  fontSize: 8,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
