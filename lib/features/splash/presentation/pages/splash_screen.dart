import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/features/home/presentation/pages/main_screen.dart';
import 'package:games/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textSweepAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    _textSweepAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.9, curve: Curves.easeInOut)),
    );

    _mainController.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 5000));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool showOnboarding = prefs.getBool('show_onboarding') ?? true;

    Widget nextScreen = showOnboarding ? const OnboardingScreen() : const MainScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionDuration: const Duration(milliseconds: 1200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 900;

    return Scaffold(
      body: AppDesign.backgroundWrapper(
        child: Stack(
          children: [
            // Dynamic Starfield Background
            ...List.generate(30, (index) => _AnimatedStar(index: index)),
            
            // Floating Decorative Rays
            ...List.generate(4, (index) => _DriftingRay(index: index)),

            // Dynamic Floating Orbs
            ...List.generate(6, (index) => _AnimatedOrb(index: index)),

            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mega Animated Logo Section
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Rotating Ring 1
                              RotationTransition(
                                turns: _rotationController,
                                child: _RingEffect(size: isSmall ? 180 : 450, color: Colors.blueAccent),
                              ),
                              // Middle Rotating Ring 2 (Anti-clockwise)
                              AnimatedBuilder(
                                animation: _rotationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: -_rotationController.value * 2 * math.pi,
                                    child: _RingEffect(size: isSmall ? 150 : 380, color: Colors.purpleAccent, opacity: 0.2),
                                  );
                                },
                              ),
                              // Core Glow
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: (isSmall ? 120 : 300) * (0.95 + (_pulseController.value * 0.1)),
                                    height: (isSmall ? 120 : 300) * (0.95 + (_pulseController.value * 0.1)),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(0.15 + (_pulseController.value * 0.1)),
                                          blurRadius: 60,
                                          spreadRadius: 20 * _pulseController.value,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // The Logo
                              Image.asset(
                                'assets/images/logo.png',
                                height: isSmall ? 100 : 280,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          SizedBox(height: isSmall ? 24 : 60),
                          // Premium Title with Sweep Shimmer
                          AnimatedBuilder(
                            animation: _textSweepAnimation,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: const [Colors.white24, Colors.white, Colors.blueAccent, Colors.white, Colors.white24],
                                  stops: [
                                    0.0,
                                    _textSweepAnimation.value - 0.2,
                                    _textSweepAnimation.value,
                                    _textSweepAnimation.value + 0.2,
                                    1.0
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'GAMES PLATFORM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 28 : 72,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: isSmall ? 4 : 14,
                                    height: 1.2,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isSmall ? 8 : 16),
                          // Typewriter Subtitle
                          _TypewriterText(
                            text: 'EXPERIENCE EXCELLENCE',
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 20,
                              color: Colors.amberAccent.withOpacity(0.7),
                              letterSpacing: isSmall ? 3 : 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Credits Footer (Responsive & Animating)
            Positioned(
              bottom: isSmall ? 20 : 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: isSmall ? 8 : 24),
                      height: 1,
                      width: isSmall ? 60 : 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.white.withOpacity(0.1), Colors.transparent],
                        ),
                      ),
                    ),
                    Text(
                      'DESIGNED & DEVELOPED BY',
                      style: TextStyle(
                        color: Colors.white12,
                        fontSize: isSmall ? 7 : 9,
                        letterSpacing: isSmall ? 2 : 3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: isSmall ? 8 : 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _CreditBadge(name: 'د. يوساب وجدي', role: 'Dev', color: Colors.blueAccent),
                          _CreditBadge(name: 'م. بافلي باسم', role: 'Ideas', color: Colors.amberAccent),
                          _CreditBadge(name: 'فيلوباتير باسم', role: 'Ideas', color: Colors.purpleAccent),
                          _CreditBadge(name: 'أ. چوليا چورچ', role: 'Questions', color: Colors.greenAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingEffect extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _RingEffect({required this.size, required this.color, this.opacity = 0.3});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(opacity * 0.5),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Container(
          width: size - 4,
          height: size - 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                color.withOpacity(0.0),
                color.withOpacity(opacity),
                color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStar extends StatefulWidget {
  final int index;
  const _AnimatedStar({required this.index});

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _top, _left, _size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500 + (math.Random().nextInt(3000))),
      vsync: this,
    )..repeat(reverse: true);
    
    final r = math.Random();
    _top = r.nextDouble() * 1000;
    _left = r.nextDouble() * 1600;
    _size = 1.0 + r.nextDouble() * 3.0;
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
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _AnimatedOrb extends StatefulWidget {
  final int index;
  const _AnimatedOrb({required this.index});

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _startX, _startY, _size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 15 + widget.index * 5),
      vsync: this,
    )..repeat();
    
    final r = math.Random();
    _startX = r.nextDouble() * 1000;
    _startY = r.nextDouble() * 1000;
    _size = 150 + r.nextDouble() * 300;
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
        double angle = _controller.value * 2 * math.pi;
        return Positioned(
          top: _startY + (math.sin(angle) * 100),
          left: _startX + (math.cos(angle) * 100),
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (widget.index % 2 == 0 ? Colors.blueAccent : Colors.purpleAccent).withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = '';
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    while (_charIndex < widget.text.length) {
      if (!mounted) break;
      setState(() {
        _displayedText += widget.text[_charIndex];
        _charIndex++;
      });
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, style: widget.style);
  }
}

class _CreditBadge extends StatelessWidget {
  final String name;
  final String role;
  final Color color;
  const _CreditBadge({required this.name, required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
          const SizedBox(height: 2),
          Text(role.toUpperCase(), style: TextStyle(color: color.withOpacity(0.7), fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DriftingRay extends StatefulWidget {
  final int index;
  const _DriftingRay({required this.index});

  @override
  State<_DriftingRay> createState() => _DriftingRayState();
}

class _DriftingRayState extends State<_DriftingRay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _angle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 20 + widget.index * 10),
      vsync: this,
    )..repeat();
    _angle = math.Random().nextDouble() * 2 * math.pi;
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
        final progress = _controller.value;
        return Positioned(
          top: -200 + (progress * 1500),
          left: -400 + (math.sin(progress * 2 * math.pi + _angle) * 300) + (widget.index * 300),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 2,
              height: 600,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

