import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import '../../../../features/settings/presentation/providers/settings_providers.dart';
import '../../../../features/games/bank_al_haz/presentation/pages/bank_al_haz_settings_page.dart';
import '../../../../features/games/wheel/presentation/pages/wheel_game_page.dart';
import '../../../../features/games/penalty_shootout/presentation/pages/penalty_shootout_page.dart';
import '../../../../features/games/under_pressure/presentation/pages/under_pressure_page.dart';
import '../../../../features/games/snakes_and_ladders/presentation/pages/snakes_ladders_game_page.dart';
import '../../../../features/games/quiz_arena/presentation/pages/quiz_arena_settings_page.dart';
import '../../../../features/games/ludo_quiz/presentation/pages/ludo_game_page.dart';
import '../../../../features/games/spy_game/presentation/pages/spy_setup_page.dart';
import '../../../../features/games/tic_tac_toe/presentation/pages/tic_tac_toe_page.dart';
import '../../../../features/games/hazer_fazer/presentation/pages/hazer_fazer_page.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ThemedBackground(
        child: _buildContent(context, ref),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    // We can also watch the theme here if we want colors for other things
    final settingsAsync = ref.watch(generalSettingsProvider);
    final themeId = settingsAsync.when(
      data: (s) => s['app_theme'] as String? ?? 'default',
      loading: () => 'default',
      error: (_, __) => 'default',
    );
    final theme = AppThemes.getThemeById(themeId);
    
    final teamsAsync = ref.watch(teamsListProvider);
    final teams = teamsAsync.value ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white, size: 24),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GAMES PLATFORM',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  theme.icon,
                  color: theme.primaryColor,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                "استمتع بأفضل الألعاب التنافسية مع أصدقائك",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          _buildElegantLeaderboard(teams),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildGamesGrid(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantLeaderboard(List<dynamic> teams) {
    if (teams.isEmpty) return const SizedBox.shrink();
    return Builder(
      builder: (context) {
        final isSmall = AppDesign.isSmallScreen(context);
        return Container(
          height: isSmall ? 50 : 65,
          margin: EdgeInsets.symmetric(vertical: isSmall ? 5 : 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 24),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Container(
                margin: EdgeInsets.only(right: isSmall ? 8 : 16),
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 20, vertical: isSmall ? 6 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(isSmall ? 25 : 35),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isSmall ? 6 : 8,
                      height: isSmall ? 6 : 8,
                      decoration: BoxDecoration(
                        color: _getTeamColor(index),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _getTeamColor(index).withOpacity(0.6), blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                    ),
                    SizedBox(width: isSmall ? 6 : 12),
                    Text(
                      team.name,
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: isSmall ? 10 : 13, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: isSmall ? 6 : 10),
                    Text(
                      "${team.score}",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: isSmall ? 16 : 22, 
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    );
  }

  Color _getTeamColor(int index) {
    final colors = [Colors.redAccent, Colors.greenAccent, Colors.blueAccent, Colors.orangeAccent, Colors.purpleAccent];
    return colors[index % colors.length];
  }

  Widget _buildGamesGrid(BuildContext context, WidgetRef ref) {
    final games = [
      {
        'title': 'تحت الضغط',
        'subtitle': 'اختبار السرعة والذكاء',
        'icon': Icons.bolt_rounded,
        'color': Colors.purpleAccent,
        'page': const UnderPressurePage(),
      },
      {
        'title': 'ضربات الجزاء',
        'subtitle': 'المواجهة المباشرة والمثيرة',
        'icon': Icons.sports_soccer_rounded,
        'color': Colors.cyanAccent,
        'page': const PenaltyShootoutPage(),
      },
      {
        'title': 'بنك الحظ',
        'subtitle': 'اللعبة اللوحية الشهيرة',
        'icon': Icons.account_balance_rounded,
        'color': Colors.tealAccent,
        'page': const BankAlHazSettingsPage(),
      },
      {
        'title': 'عجلة الحظ',
        'subtitle': 'لف العجلة واربح النقاط',
        'icon': Icons.adjust_rounded,
        'color': Colors.blueAccent,
        'page': const WheelGamePage(),
      },
      {
        'title': 'ساحة التحدي',
        'subtitle': 'تحدى أصدقائك في مسابقة ثقافية',
        'icon': Icons.workspace_premium_rounded,
        'color': Colors.indigoAccent,
        'page': const QuizArenaSettingsPage(),
      },
      {
        'title': 'السلم والثعبان',
        'subtitle': 'اصعد للقمة وتجنب الثعابين',
        'icon': Icons.grid_4x4_rounded,
        'color': Colors.orangeAccent,
        'page': const SnakesLaddersGamePage(),
      },
      {
        'title': 'لودو الأسئلة',
        'subtitle': 'لعبة اللودو الكلاسيكية بلمسة ثقافية',
        'icon': Icons.grid_view_rounded,
        'color': Colors.pinkAccent,
        'page': const LudoGamePage(),
      },
      {
        'title': 'لعبة الجاسوس',
        'subtitle': 'احذر من الجاسوس بينكم',
        'icon': Icons.person_search_rounded,
        'color': Colors.redAccent,
        'page': const SpyGameMainScreen(),
      },
      {
        'title': 'لعبة XO',
        'subtitle': 'تحدى الكمبيوتر في لعبة إكس أو',
        'icon': Icons.grid_3x3_rounded,
        'color': Colors.blueAccent,
        'page': const TicTacToePage(),
      },
      {
        'title': 'حزر فزر',
        'subtitle': 'اكشف المربعات وخمن صاحب الصورة',
        'icon': Icons.extension_rounded,
        'color': Colors.amberAccent,
        'page': const HazerFazerPage(),
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppDesign.isSmallScreen(context) ? 2 : 4,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final game = games[index];
            return _buildGameCard(context, ref, game);
          },
          childCount: games.length,
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, WidgetRef ref, Map<String, dynamic> game) {
    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;
    final bool isThemed = theme.id != 'default';

    final Color originalColor = game['color'] as Color;
    final Color color = isThemed ? theme.primaryColor : originalColor;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => game['page'] as Widget),
      ),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          color: Color.lerp(theme.backgroundDeep, Colors.black, 0.3)!.withOpacity(0.75),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
             BoxShadow(
               color: color.withOpacity(0.08),
               blurRadius: 20,
               spreadRadius: 2,
             )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(game['icon'] as IconData, size: 40, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              game['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                game['subtitle'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
