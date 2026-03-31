import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _selectedTab = 0; // 0 for Team, 1 for Sources

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
            constraints: const BoxConstraints(maxWidth: 900),
            padding: EdgeInsets.all(isSmall ? 20 : 50),
            decoration: AppDesign.glassDecoration.copyWith(
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white12, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Logo & Title
                _buildHeader(isSmall),
                
                const SizedBox(height: 32),

                // Custom Segmented Control (Tabs)
                _buildTabSwitcher(isSmall),

                const SizedBox(height: 40),

                // Content Area
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _selectedTab == 0 
                    ? _buildTeamTab(context, isSmall) 
                    : _buildSourcesTab(context, isSmall),
                ),

                const SizedBox(height: 60),

                // Footer Version
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Column(
      children: [
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
            height: isSmall ? 80 : 140,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: isSmall ? 20 : 32),
        Text(
          'GAMES PLATFORM',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmall ? 28 : 48,
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
      ],
    );
  }

  Widget _buildTabSwitcher(bool isSmall) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabButton(
            title: 'فريق العمل',
            icon: Icons.groups_rounded,
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
            isSmall: isSmall,
          ),
          _TabButton(
            title: 'المصادر',
            icon: Icons.menu_book_rounded,
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
            isSmall: isSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTab(BuildContext context, bool isSmall) {
    return Column(
      key: const ValueKey(0),
      children: [
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
          names: ['م. باڤلي باسم', 'ف. فيلوباتير باسم'],
          icon: Icons.lightbulb_outline_rounded,
          color: Colors.amberAccent,
        ),
        SizedBox(height: isSmall ? 24 : 40),
        _buildCreditSection(
          context,
          title: 'تجميع الأسئلة',
          names: ['أ. چوليا چورچ', 'م. مريم منتصر'],
          icon: Icons.quiz_rounded,
          color: Colors.pinkAccent,
        ),
        SizedBox(height: isSmall ? 24 : 40),
        _buildCreditSection(
          context,
          title: 'مختبر البرنامج',
          names: ['م. مارينا حسني'],
          icon: Icons.bug_report_rounded,
          color: Colors.orangeAccent,
        ),
        SizedBox(height: isSmall ? 40 : 60),
        _buildViewOnboardingButton(context, isSmall),
      ],
    );
  }

  Widget _buildViewOnboardingButton(BuildContext context, bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        },
        icon: Icon(Icons.auto_awesome_rounded, size: isSmall ? 20 : 24),
        label: Text(
          'شاهد عرض تقديم الفريق',
          style: TextStyle(
            fontSize: isSmall ? 14 : 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 32 : 50,
            vertical: isSmall ? 16 : 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSourcesTab(BuildContext context, bool isSmall) {
    return Column(
      key: const ValueKey(1),
      children: [
        _buildSourceCategory(
          title: 'أسئلة الكتاب المقدس',
          icon: Icons.auto_stories_rounded,
          color: Colors.blueAccent,
          sources: [
            {
              'text': 'موقع سانت تكلا - مسابقات الكتاب المقدس',
              'url': 'https://st-takla.org/Coptic-Service-Corner/Christian-n-Bible-Quizzes/Christian-Quiz-01-Bible-Questions-index-01.html'
            },
          ],
        ),
        _buildSourceCategory(
          title: 'الألغاز والفوازير',
          icon: Icons.psychology_rounded,
          color: Colors.amberAccent,
          sources: [
            {'text': 'كتاب: 200 لغز مُدهش في المنطق', 'url': 'https://xn--mgbuc2d9ao.com/'},
            {'text': 'موقع فوازير أونلاين', 'url': 'https://easyfawazir.wordpress.com/'},
            {'text': 'لغز ذكاء - الدستور', 'url': 'https://www.dostor.org/4860741'},
            {'text': 'المصري اليوم - منوعات', 'url': 'https://www.almasryalyoum.com/news/details/4212411'},
          ],
        ),
        _buildSourceCategory(
          title: 'المعلومات العامة',
          icon: Icons.public_rounded,
          color: Colors.greenAccent,
          sources: [
            {'text': 'منصة Twinkl التعليمية', 'url': 'https://www.twinkl.com.eg/blog/easy-general-questions-with-answers-ar'},
            {'text': 'Buzzfeed General Knowledge', 'url': 'https://www.buzzfeed.com/audreyworboys/general-knowledge-trivia-questions-and-answers'},
            {'text': 'أسئلة لكل المسابقات', 'url': 'https://www.twinkl.com/blog/general-questions-for-competitions-as2ela-3ama-lilmosabaqat-akhtbr-mlwmatk-wthdy-mn-hwlk'},
          ],
        ),
        _buildSourceCategory(
          title: 'الرياضة',
          icon: Icons.sports_soccer_rounded,
          color: Colors.orangeAccent,
          sources: [
            {'text': 'موقع Goal - مسابقات كروية', 'url': 'https://www.goal.com/ar-eg/%D8%A3%D8%AE%D8%A8%D8%A7%D8%B1/%D8%A7%D9%84%D8%AF%D9%88%D8%B1%D9%8A-%D8%A7%D9%84%D8%A5%D9%86%D8%AC%D9%84%D9%8A%D8%B2%D9%8A-%D9%83%D8%A3%D8%B3-%D8%A7%D9%84%D8%B9%D8%A7%D9%84%D9%85-100-%D8%B3%D8%A4%D8%A7%D9%84-%D9%83%D8%B1%D8%A9-%D8%A7%D9%84%D9%82%D8%AF%D9%85/14ykxvopw3a2b1g6ma70vbs1va'},
            {'text': 'موقع موضوع - أسئلة رياضية', 'url': 'https://mawdoo3.com/%D8%A3%D8%B3%D8%A6%D9%84%D8%A9_%D8%B1%D9%8A%D8%A7%D8%B6%D9%8A%D8%A9_%D9%82%D9%88%D9%8A%D8%A9_%D9%88%D8%B5%D8%B9%D8%A8%D8%A9'},
            {'text': 'محيط المعرفة الرياضية', 'url': 'https://knowledge-oceans.blogspot.com/2020/10/sports-questions-part1.html'},
          ],
        ),
        _buildSourceCategory(
          title: 'الطقوس والكنسيات',
          icon: Icons.church_rounded,
          color: Colors.purpleAccent,
          sources: [
            {'text': '70 سؤال في الطقس - Scribd', 'url': 'https://www.scribd.com/document/795020950/70-%D8%B3%D8%A4%D8%A7%D9%84-%D8%B7%D9%82%D8%B3'},
            {'text': 'كنيسة وقديسين - سانت تكلا', 'url': 'https://st-takla.org/Coptic-Service-Corner/Christian-n-Bible-Quizzes/Christian-Quiz-02-History-n-Saints-index-01.html'},
          ],
        ),
      ],
    );
  }

  Widget _buildSourceCategory({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> sources,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((source) => _SourceBadge(
              text: source['text']!, 
              url: source['url'],
              color: color,
            )).toList(),
          ),
        ],
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSmall;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 32,
          vertical: isSmall ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected ? [
            BoxShadow(color: Colors.black12, blurRadius: 10)
          ] : null,
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isSelected ? Colors.white : Colors.white38,
              size: isSmall ? 18 : 22,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSmall ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String text;
  final String? url;
  final Color color;

  const _SourceBadge({required this.text, this.url, required this.color});

  Future<void> _launchURL() async {
    if (url != null) {
      final Uri uri = Uri.parse(url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: url != null ? _launchURL : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (url != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.open_in_new_rounded, size: 10, color: Colors.white24),
            ],
          ],
        ),
      ),
    );
  }
}
