import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = AppDesign.isSmallScreen(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 40,
          vertical: isSmall ? 24 : 60,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.all(isSmall ? 24 : 60),
            decoration: AppDesign.glassDecoration.copyWith(
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white12, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Section
                Container(
                  padding: EdgeInsets.all(isSmall ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: isSmall ? 120 : 180,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: isSmall ? 32 : 48),

                // Title
                Text(
                  'GAMES PLATFORM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 32 : 54,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.blueAccent.withOpacity(0.8),
                        blurRadius: 25,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'EXPERIENCE EXCELLENCE',
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 16,
                    color: Colors.amberAccent.withOpacity(0.7),
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: isSmall ? 32 : 48),
                  child: Divider(
                    color: Colors.white.withOpacity(0.05),
                    indent: 40,
                    endIndent: 40,
                  ),
                ),

                // Credits Section
                _buildCreditSection(
                  context,
                  title: 'تطوير البرنامج',
                  names: ['د. يوساب وجدي'],
                  icon: Icons.code_rounded,
                  color: Colors.blueAccent,
                ),

                SizedBox(height: isSmall ? 24 : 40),

                _buildCreditSection(
                  context,
                  title: 'أفكار الألعاب',
                  names: ['م. بافلي باسم', 'فيلوباتير باسم'],
                  icon: Icons.lightbulb_outline_rounded,
                  color: Colors.amberAccent,
                ),

                SizedBox(height: isSmall ? 24 : 40),

                 _buildCreditSection(
                  context,
                  title: 'تجميع الأسئلة',
                  names: ['أ. چوليا چورچ'],
                  icon: Icons.quiz_rounded,
                  color: Colors.pinkAccent,
                ),

                SizedBox(height: isSmall ? 40 : 64),

                // Footer Version
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: const Text(
                    'الإصدار 2.5.0 • 2026',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreditSection(
    BuildContext context, {
    required String title,
    required List<String> names,
    required IconData icon,
    required Color color,
  }) {
    final isSmall = AppDesign.isSmallScreen(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isSmall ? 20 : 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmall ? 16 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...names.map(
          (name) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              name,
              style: TextStyle(
                fontSize: isSmall ? 24 : 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: color.withOpacity(0.3), blurRadius: 15),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
