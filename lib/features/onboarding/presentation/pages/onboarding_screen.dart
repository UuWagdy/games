import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/features/home/presentation/pages/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingModel> _pages = [
    OnboardingModel(
      title: 'GAMES PLATFORM',
      subtitle: 'EXPERIENCE EXCELLENCE',
      description: 'نقدم لكم منصة الألعاب الأكثر تميزاً وإثارة، حيث تلتقي التكنولوجيا بالإبداع ليخلقا تجربة فريدة لا تُنسى.',
      image: 'assets/images/logo.png',
      color: Colors.blueAccent,
      namesTitle: 'بواسطة فريق العمل',
      names: ['د. يوساب وجدي', 'م. باڤلي باسم', 'ف. فيلوباتير باسم', 'أ. چوليا چورچ', 'م. مريم منتصر', 'م. مارينا حسني'],
    ),
    OnboardingModel(
      title: 'تطوير البرنامج',
      subtitle: 'DEVELOPMENT',
      description: 'تم بناء هذا النظام باستخدام أحدث تقنيات تطوير التطبيقات لضمان الأداء السلس والتصميم الراقي الذي يرضي تطلعاتكم.',
      image: 'assets/images/logo.png',
      color: Colors.purpleAccent,
      namesTitle: 'تطوير وبرمجة',
      names: ['د. يوساب وجدي'],
    ),
    OnboardingModel(
      title: 'أفكار الألعاب',
      subtitle: 'GAME CONCEPTS',
      description: 'تم تصميم وتخطيط كل لعبة بعناية فائقة لتناسب جميع الأذواق والمناسبات، بإلهام من أرقى الأفكار الابتكارية.',
      image: 'assets/images/logo.png',
      color: Colors.amberAccent,
      namesTitle: 'أفكار وإبداع',
      names: ['م. باڤلي باسم', 'ف. فيلوباتير باسم'],
    ),
    OnboardingModel(
      title: 'تجميع الأسئلة',
      subtitle: 'QUESTIONS',
      description: 'تم اختيار وتجميع وتدقيق مجموعة واسعة ومتنوعة من الأسئلة بدقة بالغة لضمان تنوعها وجودتها العالية، مما يضمن تجربة تعليمية وترفيهية متوازنة.',
      image: 'assets/images/logo.png',
      color: Colors.pinkAccent,
      namesTitle: 'تجميع وإعداد',
      names: ['أ. چوليا چورچ', 'م. مريم منتصر'],
    ),
    OnboardingModel(
      title: 'مختبر البرنامج',
      subtitle: 'QUALITY ASSURANCE',
      description: 'تم اختبار البرنامج وتجربته بدقة للتأكد من خلوه من الأخطاء ولضمان تجربة مستخدم مثالية وخالية من المشاكل.',
      image: 'assets/images/logo.png',
      color: Colors.orangeAccent,
      namesTitle: 'اختبار الجودة',
      names: ['م. مارينا حسني'],
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 1200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppDesign.backgroundWrapper(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return _OnboardingPageView(
                  model: _pages[index],
                  isLast: index == _pages.length - 1,
                  onNext: () {
                    if (index == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOutExpo,
                      );
                    }
                  },
                );
              },
            ),
            
            // Fixed Navigation UI (Indicators) - Optimized for Desktop & Mobile
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _pages.asMap().entries.map((entry) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == entry.key ? 40 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _currentPage == entry.key ? _pages[entry.key].color : Colors.white10,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Top Buttons with Safe Areas
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text(
                        'تخطي',
                        style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_currentPage > 0)
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOutExpo,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white30, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingModel model;
  final bool isLast;
  final VoidCallback onNext;

  const _OnboardingPageView({
    required this.model,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;
    final isSmall = size.width < 600;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: isDesktop 
            ? SingleChildScrollView(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 100, bottom: 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildDesktopLayout(context, size)],
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, size.height < 700 ? 60 : 80),
                  child: _buildMobileLayout(context, size, isSmall),
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Size size) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Image Container
        Expanded(
          flex: 1,
          child: _buildImageSection(context, 450),
        ),
        const SizedBox(width: 60),
        // Content Area
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleSection(context, isDesktop: true),
              const SizedBox(height: 32),
              _buildDescriptionSection(context, isDesktop: true),
              const SizedBox(height: 48),
              _buildCreditsSection(context, isDesktop: true),
              const SizedBox(height: 64),
              _buildActionButton(context, isDesktop: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Size size, bool isSmall) {
    final isTiny = size.height < 700;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildImageSection(context, size.height * (isTiny ? 0.15 : 0.18)),
        _buildTitleSection(context, isDesktop: false),
        _buildDescriptionSection(context, isDesktop: false),
        _buildCreditsSection(context, isDesktop: false),
        _buildActionButton(context, isDesktop: false),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _RotatingGlow(size: size, color: model.color),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Image.asset(model.image, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          model.title,
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 72 : 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
            height: isDesktop ? 1.2 : 1.3,
            shadows: [
              Shadow(color: model.color.withOpacity(0.5), blurRadius: 20),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 8),
        Text(
          model.subtitle,
          style: TextStyle(
            fontSize: isDesktop ? 20 : 11,
            color: model.color.withOpacity(0.8),
            letterSpacing: isDesktop ? 10 : 3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, {required bool isDesktop}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Text(
        model.description,
        textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: isDesktop ? 22 : 12,
          color: Colors.white70,
          height: isDesktop ? 1.8 : 1.3,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildCreditsSection(BuildContext context, {required bool isDesktop}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(isDesktop ? 30 : 20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            model.namesTitle,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white30,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 10),
          Wrap(
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            spacing: isDesktop ? 20 : 10,
            runSpacing: 8,
            children: model.names.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: model.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 18 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required bool isDesktop}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: model.color,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: isDesktop ? 24 : 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 20,
          shadowColor: model.color.withOpacity(0.6),
        ),
        child: Text(
          isLast ? 'ابدأ اللعب الآن' : 'التالي',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _RotatingGlow extends StatefulWidget {
  final double size;
  final Color color;
  const _RotatingGlow({required this.size, required this.color});

  @override
  State<_RotatingGlow> createState() => _RotatingGlowState();
}

class _RotatingGlowState extends State<_RotatingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 15), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size * 0.9,
        height: widget.size * 0.9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              widget.color.withOpacity(0.0),
              widget.color.withOpacity(0.3),
              widget.color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingModel {
  final String title;
  final String subtitle;
  final String description;
  final String image;
  final Color color;
  final String namesTitle;
  final List<String> names;

  OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.image,
    required this.color,
    required this.namesTitle,
    required this.names,
  });
}
