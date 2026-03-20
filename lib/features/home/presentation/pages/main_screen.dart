import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';
import '../../../../features/games/bank_al_haz/presentation/pages/bank_al_haz_settings_page.dart';
import '../../../../features/games/wheel/presentation/pages/wheel_game_page.dart';
import '../../../../features/games/penalty_shootout/presentation/pages/penalty_shootout_page.dart';
import '../../../../features/games/under_pressure/presentation/pages/under_pressure_page.dart';
import '../../../../features/games/snakes_and_ladders/presentation/pages/snakes_ladders_game_page.dart';
import '../../../../features/games/quiz_arena/presentation/pages/quiz_arena_settings_page.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppDesign.backgroundWrapper(
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppDesign.isSmallScreen(context) ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: AppDesign.isSmallScreen(context) ? 24 : 32,
                height: AppDesign.isSmallScreen(context) ? 24 : 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'GAMES PLATFORM',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: AppDesign.isSmallScreen(context) ? 18 : 26,
                color: Colors.white,
                letterSpacing: AppDesign.isSmallScreen(context) ? 1 : 2,
                shadows: const [Shadow(color: Colors.blueAccent, blurRadius: 15)],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppDesign.isSmallScreen(context) ? 16 : 24,
                right: AppDesign.isSmallScreen(context) ? 16 : 24,
                top: AppDesign.isSmallScreen(context) ? 110 : 140, 
                bottom: 40
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'اختر لعبتك المفضلة',
                    style: TextStyle(
                      fontSize: AppDesign.isSmallScreen(context) ? 28 : 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'استمتع بأفضل الألعاب التنافسية مع أصدقائك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: AppDesign.isSmallScreen(context) ? 14 : 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildGamesGrid(context),
                  const SizedBox(height: 80),
                  _buildFooter(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesGrid(BuildContext context) {
    final isSmall = AppDesign.isSmallScreen(context);
    final List<_GameCardData> games = [
      _GameCardData(
        title: 'عجلة الحظ',
        subtitle: 'لف العجلة واربح النقاط',
        icon: Icons.casino_outlined,
        color: Colors.blueAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelGamePage())),
      ),
      _GameCardData(
        title: 'بنك الحظ',
        subtitle: 'اللعبة اللوحية الشهيرة',
        icon: Icons.map_outlined,
        color: Colors.tealAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAlHazSettingsPage())),
      ),
      _GameCardData(
        title: 'ضربات الجزاء',
        subtitle: 'المواجهة المباشرة والمثيرة',
        icon: Icons.sports_soccer_outlined,
        color: Colors.cyanAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenaltyShootoutPage())),
      ),
      _GameCardData(
        title: 'تحت الضغط',
        subtitle: 'اختبار السرعة والذكاء',
        icon: Icons.timer_outlined,
        color: Colors.purpleAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UnderPressurePage())),
      ),
      _GameCardData(
        title: 'السلم والثعبان',
        subtitle: 'اصعد للقمة وتجنب الثعابين',
        icon: Icons.grid_4x4_outlined,
        color: Colors.orangeAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SnakesLaddersGamePage())),
      ),
      _GameCardData(
        title: 'ساحة التحدي',
        subtitle: 'تحدى أصدقائك في مسابقة ثقافية',
        icon: Icons.quiz_outlined,
        color: Colors.deepPurpleAccent,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizArenaSettingsPage())),
      ),
    ];

    if (isSmall) {
      // Force 2-column grid on mobile
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final g = games[index];
          return _GameCard(
            title: g.title,
            subtitle: g.subtitle,
            icon: g.icon,
            color: g.color,
            onTap: g.onTap,
          );
        },
      );
    }

    return Wrap(
      spacing: 40,
      runSpacing: 40,
      alignment: WrapAlignment.center,
      children: games.map((g) => _GameCard(
        title: g.title,
        subtitle: g.subtitle,
        icon: g.icon,
        color: g.color,
        onTap: g.onTap,
      )).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage(initialIndex: 9)),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: AppDesign.glassDecoration,
        child: const Text(
          'تصميم عصري • أداء سريع • تجربة ممتعة',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSmall = AppDesign.isSmallScreen(context);
    // On mobile GridView: fill available width; On desktop: fixed 280
    final cardWidth = isSmall ? double.infinity : 280.0;
    final cardHeight = isSmall ? null : 320.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: isSmall ? null : cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(isSmall ? 24 : 32),
              border: Border.all(
                color: _isHovered 
                  ? widget.color.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: widget.color.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSmall ? 24 : 32),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: isSmall ? 80 : 120,
                      height: isSmall ? 80 : 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.color.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isSmall ? 16 : 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: isSmall ? 64 : 100,
                          height: isSmall ? 64 : 100,
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.color.withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size: isSmall ? 28 : 50,
                            color: widget.color,
                          ),
                        ),
                        SizedBox(height: isSmall ? 12 : 32),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 16 : 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: isSmall ? 8 : 12),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: isSmall ? 10 : 15,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _GameCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
