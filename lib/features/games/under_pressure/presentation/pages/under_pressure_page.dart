import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/games/under_pressure/presentation/providers/under_pressure_provider.dart';
import 'package:games/features/games/under_pressure/presentation/providers/under_pressure_settings_provider.dart';
import 'package:games/features/games/under_pressure/domain/entities/under_pressure_state.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/games/under_pressure/presentation/pages/under_pressure_settings_page.dart';
import 'dart:ui';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/core/design/app_design.dart';

class UnderPressurePage extends ConsumerStatefulWidget {
  const UnderPressurePage({super.key});

  @override
  ConsumerState<UnderPressurePage> createState() => _UnderPressurePageState();
}

class _UnderPressurePageState extends ConsumerState<UnderPressurePage> {
  Set<int> _selectedCategoryIds = {};
  Team? _teamA;
  Team? _teamB;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(underPressureProvider);
    final settingsAsync = ref.watch(underPressureSettingsProvider);
    final settings = settingsAsync.value ?? {};
    final String correctKey = (settings['correct_key'] ?? '1').toString().toUpperCase();
    final String wrongKey = (settings['wrong_key'] ?? '2').toString().toUpperCase();
    final String skipKey = (settings['skip_key'] ?? '3').toString().toUpperCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('تحت الضغط', style: AppDesign.titleStyle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt, color: Colors.orangeAccent),
              tooltip: 'تصفير النقاط',
              onPressed: () => _confirmResetScores(),
            ),
          if (state.status == UnderPressureStatus.idle)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      extendBodyBehindAppBar: true,
                      appBar: AppBar(
                        title: const Text('إعدادات تحت الضغط', style: AppDesign.titleStyle),
                        centerTitle: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      body: AppDesign.backgroundWrapper(
                        child: const SafeArea(child: UnderPressureSettingsPage()),
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppDesign.backgroundWrapper(
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && state.status == UnderPressureStatus.playing) {
              final String label = event.logicalKey.keyLabel.toUpperCase();
              if (label == correctKey) {
                ref.read(underPressureProvider.notifier).nextQuestion(true);
                return KeyEventResult.handled;
              } else if (label == wrongKey) {
                ref.read(underPressureProvider.notifier).nextQuestion(false);
                return KeyEventResult.handled;
              } else if (label == skipKey) {
                ref.read(underPressureProvider.notifier).skipQuestion();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: state.status == UnderPressureStatus.idle
                      ? _buildIdleScreen(context, state)
                      : state.status == UnderPressureStatus.finished
                          ? _buildFinishedScreen(state, settings)
                          : state.status == UnderPressureStatus.paused
                              ? _buildTransitionScreen(state)
                              : _buildGamingScreen(state),
                ),
                if (state.status != UnderPressureStatus.finished) _buildGlobalTeamsScore(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalTeamsScore(UnderPressureState state) {
    final currentActingTeam = state.isTeam2Turn ? state.team2 : state.team1;
    final isSmall = AppDesign.isSmallScreen(context);
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, isSmall ? 12 : 16, 16, isSmall ? 25 : 16),
          decoration: BoxDecoration(
            color: Colors.black45,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: state.teams.map((team) {
                final isPlaying = currentActingTeam?.id == team.id;
                return Container(
                  width: isSmall ? 100 : 150,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 12),
                    decoration: BoxDecoration(
                      gradient: isPlaying 
                          ? LinearGradient(colors: [Colors.purpleAccent.withOpacity(0.3), Colors.purpleAccent.withOpacity(0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isPlaying ? Colors.purpleAccent.withOpacity(0.6) : Colors.white10, width: isPlaying ? 2 : 1),
                      boxShadow: isPlaying ? [BoxShadow(color: Colors.purpleAccent.withOpacity(0.2), blurRadius: 10)] : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          team.name, 
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlaying ? Colors.purpleAccent : Colors.white60, 
                            fontWeight: FontWeight.w900, 
                            fontSize: isSmall ? 10 : 14,
                            letterSpacing: 0.5,
                          )
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${team.score}', 
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: isSmall ? 20 : 28, 
                            fontWeight: FontWeight.w900,
                            height: 1,
                          )
                        ),
                        Text(
                          'نقطة', 
                          style: TextStyle(color: Colors.white38, fontSize: isSmall ? 8 : 10, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleScreen(BuildContext context, UnderPressureState state) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final List<Team> teams = state.teams;
    
    // Validate current selections against fresh teams list
    if (_teamA != null && !teams.any((t) => t.id == _teamA!.id)) _teamA = null;
    if (_teamB != null && !teams.any((t) => t.id == _teamB!.id)) _teamB = null;

    // Default selections
    if (_teamA == null && teams.isNotEmpty) _teamA = teams[0];
    if (_teamB == null && teams.length > 1) {
      _teamB = teams.firstWhere((t) => t.id != _teamA?.id, orElse: () => teams[1]);
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppDesign.isSmallScreen(context) ? 16 : 24),
      child: Column(
        children: [
          if (!AppDesign.isSmallScreen(context)) ...[
            const SizedBox(height: 10),
            const Icon(Icons.timer_outlined, size: 80, color: Colors.purpleAccent),
            const SizedBox(height: 15),
            const Text(
              'استعد للضغط!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const Text(
              'اختر فريقين لبدء المواجهة التنافسية',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),
          ] else ...[
            const SizedBox(height: 4),
          ],
          
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: AppDesign.isSmallScreen(context) ? 500 : 1100),
            padding: EdgeInsets.all(AppDesign.isSmallScreen(context) ? 12 : 40),
            decoration: AppDesign.glassDecoration,
            child: Column(
              children: [
                Text('تجهيز الفرق المتبارية:', style: AppDesign.titleStyle.copyWith(fontSize: AppDesign.isSmallScreen(context) ? 20 : 26)),
                SizedBox(height: AppDesign.isSmallScreen(context) ? 16 : 32),
                if (AppDesign.isSmallScreen(context))
                  Column(
                    children: [
                      _buildTeamPicker('الفريق الأول', _teamA, teams, (t) => setState(() => _teamA = t), Colors.blueAccent),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('VS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 20)),
                      ),
                      _buildTeamPicker('الفريق الثاني', _teamB, teams, (t) => setState(() => _teamB = t), Colors.tealAccent),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: _buildTeamPicker('الفريق الأول', _teamA, teams, (t) => setState(() => _teamA = t), Colors.blueAccent)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('VS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 32)),
                      ),
                      Expanded(child: _buildTeamPicker('الفريق الثاني', _teamB, teams, (t) => setState(() => _teamB = t), Colors.tealAccent)),
                    ],
                  ),
                SizedBox(height: AppDesign.isSmallScreen(context) ? 24 : 48),
                ElevatedButton(
                  onPressed: (_teamA != null && _teamB != null && _teamA != _teamB)
                    ? () => ref.read(underPressureProvider.notifier).startGame(_teamA!, _teamB!, _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList())
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDesign.isSmallScreen(context) ? 32 : 64,
                      vertical: AppDesign.isSmallScreen(context) ? 12 : 24,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                  ),
                  child: Text('ابدأ المواجهة', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 18 : 28, fontWeight: FontWeight.w900)),
                ),
                if (_teamA == _teamB && _teamA != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('لا يمكن اختيار نفس الفريق للمواجهة!', style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 16),
                if (state.templateName != null && state.templateQuestions != null && state.templateQuestions!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description, color: Colors.purpleAccent),
                        const SizedBox(width: 8),
                        Flexible(child: Text('القالب الحالي: ${state.templateName}', style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.download, size: 16, color: Colors.purpleAccent),
                          label: const Text('تنزيل', style: TextStyle(color: Colors.purpleAccent)),
                          onPressed: () => _downloadCurrentTemplatePdf(context, ref, state),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                          label: const Text('قالب جديد', style: TextStyle(color: Colors.white70)),
                          onPressed: () => _generateNewTemplatePdf(context, ref, state),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () => _generateNewTemplatePdf(context, ref, state),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.purpleAccent),
                    label: const Text('تصدير القالب وتوليد الأسئلة PDF', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      side: const BorderSide(color: Colors.purpleAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(height: AppDesign.isSmallScreen(context) ? 20 : 40),
          _buildCategorySelection(categoriesAsync),
        ],
      ),
    ),
  );
}

  Future<void> _downloadCurrentTemplatePdf(BuildContext context, WidgetRef ref, UnderPressureState state) async {
    if (state.templateQuestions == null || state.templateQuestions!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد قالب حالي لتنزيله')));
      return;
    }
    
    final name = state.templateName ?? 'قالب ${DateTime.now().toString().substring(0, 16).replaceAll(':', '-')}';
    
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      final ttfBold = pw.Font.ttf(boldFontData);

      final myTheme = pw.ThemeData.withFont(base: ttf, bold: ttfBold);

      final questions = state.templateQuestions!;

      pdf.addPage(
        pw.MultiPage(
          theme: myTheme,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
             return pw.Container(
               alignment: pw.Alignment.center,
               margin: const pw.EdgeInsets.only(bottom: 20),
               child: pw.Text('قالب لعبة تحت الضغط: $name', style: pw.TextStyle(font: ttfBold, fontSize: 24, color: PdfColors.deepPurple)),
             );
          },
          build: (pw.Context context) {
            return [
              pw.Text('عدد الأسئلة في الجولة: ${questions.length}', style: pw.TextStyle(font: ttfBold, fontSize: 16)),
              pw.SizedBox(height: 20),
              ...questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${idx + 1}- ${q.text}', textDirection: pw.TextDirection.rtl, style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                      pw.SizedBox(height: 5),
                      pw.Text('الإجابة: ${q.answer}', textDirection: pw.TextDirection.rtl, style: const pw.TextStyle(color: PdfColors.green), textAlign: pw.TextAlign.right),
                    ]
                  )
                );
              }),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ PDF: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _generateNewTemplatePdf(BuildContext context, WidgetRef ref, UnderPressureState state) async {
    final nameController = TextEditingController(text: 'قالب ${DateTime.now().toString().substring(0, 16).replaceAll(':', '-')}');
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('اسم القالب', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1E293B),
      content: TextField(
        controller: nameController,
        style: const TextStyle(color: Colors.white),
        decoration: AppDesign.searchInputDecoration('أدخل اسماً للقالب'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, nameController.text), style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent), child: const Text('مصادقة')),
      ],
    ));

    if (name == null || name.isEmpty) return;

    await ref.read(underPressureProvider.notifier).generateTemplate(
      _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList(),
      name,
    );
    final newState = ref.read(underPressureProvider);

    if (newState.templateQuestions == null || newState.templateQuestions!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد أسئلة كافية')));
      }
      return;
    }

    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      final boldFontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      final ttfBold = pw.Font.ttf(boldFontData);

      final myTheme = pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      );

      final questions = newState.templateQuestions!;

      pdf.addPage(
        pw.MultiPage(
          theme: myTheme,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
             return pw.Container(
               alignment: pw.Alignment.center,
               margin: const pw.EdgeInsets.only(bottom: 20),
               child: pw.Text('قالب لعبة تحت الضغط: $name', style: pw.TextStyle(font: ttfBold, fontSize: 24, color: PdfColors.deepPurple)),
             );
          },
          build: (pw.Context context) {
            return [
              pw.Text('عدد الأسئلة في الجولة: ${questions.length}', style: pw.TextStyle(font: ttfBold, fontSize: 16)),
              pw.SizedBox(height: 20),
              ...questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${idx + 1}- ${q.text}', textDirection: pw.TextDirection.rtl, style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                      pw.SizedBox(height: 5),
                      pw.Text('الإجابة: ${q.answer}', textDirection: pw.TextDirection.rtl, style: const pw.TextStyle(color: PdfColors.green), textAlign: pw.TextAlign.right),
                    ]
                  )
                );
              }),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ PDF: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildTeamPicker(String label, Team? selected, List<Team> allTeams, Function(Team) onSelected, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Team>(
              value: allTeams.contains(selected) ? selected : null,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              items: allTeams.map((team) => DropdownMenuItem(value: team, child: Text(team.name))).toList(),
              onChanged: (val) => val != null ? onSelected(val) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransitionScreen(UnderPressureState state) {
    final isSmall = AppDesign.isSmallScreen(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, size: isSmall ? 60 : 100, color: Colors.amberAccent),
            SizedBox(height: isSmall ? 16 : 24),
            Text(
              'انتهى دور فريق ${state.isTeam2Turn ? state.team1?.name : state.team2?.name}', 
              style: TextStyle(color: Colors.white70, fontSize: isSmall ? 18 : 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Text(
              'الدور الآن على فريق ${state.isTeam2Turn ? state.team2?.name : state.team1?.name}', 
              style: TextStyle(color: Colors.white, fontSize: isSmall ? 28 : 36, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmall ? 32 : 48),
            ElevatedButton(
              onPressed: () => state.isTeam2Turn ? ref.read(underPressureProvider.notifier).startTeam2() : ref.read(underPressureProvider.notifier).startTeam1(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 32 : 50, vertical: isSmall ? 16 : 22),
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                state.isTeam2Turn ? 'ابدأ دور الفريق الثاني' : 'ابدأ دور الفريق الأول', 
                style: TextStyle(fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection(AsyncValue categoriesAsync) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16, runSpacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.category_rounded, color: Colors.purpleAccent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تصنيف الأسئلة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('اختر نوعية الأسئلة', style: TextStyle(fontSize: 14, color: Colors.white38)),
                    ],
                  ),
                ],
              ),
              _buildCategoryTopControls(categoriesAsync),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'البحث عن فئة...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          categoriesAsync.when(
            data: (categories) {
              final filteredCategories = (categories as List).where((cat) => cat.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              if (filteredCategories.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('لا توجد فئات مطابقة للبحث', style: TextStyle(color: Colors.white38)),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.2,
                ),
                itemCount: filteredCategories.length,
                itemBuilder: (ctx, index) {
                  final cat = filteredCategories[index];
                  final isSelected = _selectedCategoryIds.contains(cat.id);
                  return InkWell(
                    onTap: () => setState(() {
                      if (isSelected) _selectedCategoryIds.remove(cat.id!);
                      else _selectedCategoryIds.add(cat.id!);
                    }),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? Colors.purpleAccent.withOpacity(0.6) : Colors.white10, width: 2),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.purpleAccent.withOpacity(0.1), blurRadius: 10)] : [],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10, bottom: -10,
                            child: Icon(Icons.category_outlined, size: 40, color: isSelected ? Colors.purpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.02)),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: isSelected ? Colors.purpleAccent : Colors.white24),
                                  const SizedBox(width: 10),
                                  Flexible(child: Text(cat.name, style: TextStyle(fontSize: 14, color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold), textAlign: TextAlign.center, maxLines: 2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.purpleAccent))),
            error: (e, s) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTopControls(AsyncValue categoriesAsync) {
    return Row(
      children: [
        _buildActionIconButton(
          icon: Icons.select_all_rounded,
          color: Colors.blueAccent,
          tooltip: 'اختيار الكل',
          onPressed: () {
            categoriesAsync.whenData((cats) {
              setState(() => _selectedCategoryIds = (cats as List).map((e) => e.id as int).toSet());
            });
          },
        ),
        const SizedBox(width: 12),
        _buildActionIconButton(
          icon: Icons.deselect_rounded,
          color: Colors.redAccent,
          tooltip: 'مسح الكل',
          onPressed: () => setState(() => _selectedCategoryIds = {}),
        ),
      ],
    );
  }

  Widget _buildActionIconButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildGamingScreen(UnderPressureState state) {
    final question = state.currentQuestion;
    final isSmall = AppDesign.isSmallScreen(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: isSmall ? 2 : 20, horizontal: isSmall ? 10 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressTrack(state),
          SizedBox(height: isSmall ? 6 : 24),
          _buildTimer(state),
          SizedBox(height: isSmall ? 6 : 24),
          if (question != null)
            _buildQuestionCard(question)
          else
            const Text('انتهت الأسئلة!', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: isSmall ? 6 : 24),
          _buildControls(),
          SizedBox(height: isSmall ? 10 : 24),
          _buildScoreBoard(state),
        ],
      ),
    );
  }

  Widget _buildTimer(UnderPressureState state) {
    final bool warning = state.timeLeft < 10;
    final color = warning ? Colors.redAccent : Colors.purpleAccent;
    final currentlyAnswering = state.isTeam2Turn ? state.team2 : state.team1;
    final isSmall = AppDesign.isSmallScreen(context);

    return Container(
      width: isSmall ? 70 : 100,
      height: isSmall ? 70 : 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: isSmall ? 3 : 6),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: isSmall ? 5 : 20, spreadRadius: 2)
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.timeLeft}',
              style: TextStyle(
                fontSize: isSmall ? 24 : 36,
                fontWeight: FontWeight.w900,
                color: warning ? Colors.redAccent : Colors.white,
                shadows: [Shadow(color: (warning ? Colors.redAccent : Colors.blueAccent).withOpacity(0.5), blurRadius: 10)],
              ),
            ),
            Text(
              '${currentlyAnswering?.name}',
              style: TextStyle(fontSize: isSmall ? 10 : 13, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    final isSmall = AppDesign.isSmallScreen(context);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: AppDesign.isSmallScreen(context) ? 800 : 1000),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 24, vertical: isSmall ? 6 : 12),
      decoration: AppDesign.glassDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (question.imageData != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                question.imageData!,
                height: isSmall ? 80 : 180,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: isSmall ? 4 : 16),
          ],
          Text(
            question.text,
            style: TextStyle(fontSize: isSmall ? 16 : 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppDesign.isSmallScreen(context) ? 10 : 20,
      runSpacing: 10,
      children: [
        _ControlButton(
          label: 'صح',
          icon: Icons.check_circle_rounded,
          color: Colors.greenAccent,
          onPressed: () => ref.read(underPressureProvider.notifier).nextQuestion(true),
        ),
        _ControlButton(
          label: 'خـطأ',
          icon: Icons.cancel_rounded,
          color: Colors.redAccent,
          onPressed: () => ref.read(underPressureProvider.notifier).nextQuestion(false),
        ),
        _ControlButton(
          label: 'تخطي',
          icon: Icons.skip_next_rounded,
          color: Colors.orangeAccent,
          isProminent: true,
          onPressed: () => ref.read(underPressureProvider.notifier).skipQuestion(),
        ),
      ],
    );
  }

  Widget _buildScoreBoard(UnderPressureState state) {
    final score = state.isTeam2Turn ? state.team2Score : state.team1Score;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 10),
          Text(
            'الحصيلة: $score', 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.amber)
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedScreen(UnderPressureState state, Map<String, dynamic> allSettings) {
    final winner = state.winnerTeamId == state.team1?.id ? state.team1 : (state.winnerTeamId == state.team2?.id ? state.team2 : null);

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(AppDesign.isSmallScreen(context) ? 4 : 16),
            margin: EdgeInsets.symmetric(horizontal: AppDesign.isSmallScreen(context) ? 4 : 16, vertical: 4),
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: AppDesign.isSmallScreen(context) ? 8 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(Icons.emoji_events_rounded, size: AppDesign.isSmallScreen(context) ? 40 : 80, color: Colors.amberAccent),
                   SizedBox(height: AppDesign.isSmallScreen(context) ? 4 : 16),
                   Text('انتهت المواجهة!', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 18 : 26, fontWeight: FontWeight.w900, color: Colors.white)),
                   SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 20),
                   
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       Expanded(
                         child: _buildResultColumn(
                           state.team1?.name ?? 'فريق 1', 
                           state.team1PointsAdded, 
                           state.teams.firstWhere((t) => t.id == state.team1?.id, orElse: () => state.team1!).score,
                           state.winnerTeamId == state.team1?.id || state.isTie,
                           state.team1Results.where((r) => r == QuestionResult.correct).length,
                           allSettings['points_per_question'] ?? 1,
                           (state.winnerTeamId == state.team1?.id || state.isTie) ? (allSettings['bonus_points'] ?? 10) : 0,
                           state.team1Results.length
                         )
                       ),
                       Container(width: 1, height: AppDesign.isSmallScreen(context) ? 80 : 100, color: Colors.white10),
                       Expanded(
                         child: _buildResultColumn(
                           state.team2?.name ?? 'فريق 2', 
                           state.team2PointsAdded, 
                           state.teams.firstWhere((t) => t.id == state.team2?.id, orElse: () => state.team1!).score,
                           state.winnerTeamId == state.team2?.id || state.isTie,
                           state.team2Results.where((r) => r == QuestionResult.correct).length,
                           allSettings['points_per_question'] ?? 1,
                           (state.winnerTeamId == state.team2?.id || state.isTie) ? (allSettings['bonus_points'] ?? 10) : 0,
                           state.team2Results.length
                         )
                       ),
                     ],
                   ),
                  SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 20),
                  _buildProgressTrack(state),
                  SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 16),
                  
                  if (state.isTie)
                    Text('تعادل حاسم! حصل الفريقان على البونص', textAlign: TextAlign.center, style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 12 : 18, color: Colors.amberAccent, fontWeight: FontWeight.bold))
                  else if (winner != null)
                    Text('الفائز فريق ${winner.name} وحصل على البونص!', textAlign: TextAlign.center, style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 12 : 18, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  
                  SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref.read(underPressureProvider.notifier).restartGame(),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: AppDesign.isSmallScreen(context) ? 6 : 14),
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('إعادة التحدي', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 14 : 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref.read(underPressureProvider.notifier).reset(),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: AppDesign.isSmallScreen(context) ? 6 : 14),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('موافق', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 14 : 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultColumn(String name, int pointsAdded, int totalScore, bool isWinner, int correctCount, int pointsPerQuestion, int bonusGotten, int totalQuestions) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Column(
      children: [
        Text(name, style: TextStyle(fontSize: isSmall ? 16 : 20, fontWeight: FontWeight.bold, color: isWinner ? Colors.amberAccent : Colors.white70)),
        SizedBox(height: isSmall ? 4 : 8),
        Text('+$pointsAdded', style: TextStyle(fontSize: isSmall ? 24 : 36, fontWeight: FontWeight.w900, color: isWinner ? Colors.greenAccent : Colors.white54)),
        if (isSmall) ...[
          Text('$correctCount صح من $totalQuestions', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          Text('$correctCount × $pointsPerQuestion نقاط = ${correctCount * pointsPerQuestion}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
          if (bonusGotten > 0) Text('بونص +$bonusGotten', style: const TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        ] else
          const Text('نقطة مكتسبة', style: TextStyle(fontSize: 12, color: Colors.white38)),
        SizedBox(height: isSmall ? 6 : 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('الإجمالي: $totalScore', style: TextStyle(fontSize: isSmall ? 12 : 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildProgressTrack(UnderPressureState state) {
    final isSmall = AppDesign.isSmallScreen(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 4 : 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildTeamProgress(state.team1?.name ?? 'فريق 1', state.team1Results, !state.isTeam2Turn && state.status == UnderPressureStatus.playing)),
          SizedBox(width: isSmall ? 12 : 40),
          Expanded(child: _buildTeamProgress(state.team2?.name ?? 'فريق 2', state.team2Results, state.isTeam2Turn && state.status == UnderPressureStatus.playing)),
        ],
      ),
    );
  }

  Widget _buildTeamProgress(String name, List<QuestionResult> results, bool isActive) {
    return Column(
      children: [
        Text(
          name, 
          style: TextStyle(
            color: isActive ? Colors.purpleAccent : Colors.white70, 
            fontWeight: FontWeight.bold, 
            fontSize: 14,
            shadows: isActive ? [const Shadow(color: Colors.purpleAccent, blurRadius: 10)] : [],
          )
        ),
        SizedBox(height: AppDesign.isSmallScreen(context) ? 2 : 12),
        Wrap(
          spacing: AppDesign.isSmallScreen(context) ? 4 : 8,
          runSpacing: AppDesign.isSmallScreen(context) ? 4 : 8,
          alignment: WrapAlignment.center,
          children: results.asMap().entries.map((entry) {
            final res = entry.value;
            Color color;
            IconData? icon;
            switch (res) {
              case QuestionResult.correct:
                color = Colors.greenAccent;
                icon = Icons.check;
                break;
              case QuestionResult.wrong:
                color = Colors.redAccent;
                icon = Icons.close;
                break;
              case QuestionResult.skipped:
                color = Colors.orangeAccent;
                icon = Icons.skip_next_rounded;
                break;
              case QuestionResult.pending:
                color = Colors.white.withOpacity(0.1);
                icon = null;
                break;
            }
            return Container(
              width: AppDesign.isSmallScreen(context) ? 22 : 32,
              height: AppDesign.isSmallScreen(context) ? 22 : 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                boxShadow: (res != QuestionResult.pending) ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4)] : [],
              ),
              child: Center(child: icon != null ? Icon(icon, size: AppDesign.isSmallScreen(context) ? 12 : 18, color: color) : Text('${entry.key + 1}', style: const TextStyle(color: Colors.white12, fontSize: 10))),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _confirmResetScores() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تصفير النقاط وحذف السجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'هل أنت متأكد من تصفير نقاط كل الفرق وحذف سجل النقاط بالكامل؟ سيتم إعادة تشغيل اللعبة أيضاً.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(teamsListProvider.notifier).resetScoresAndClearLogs();
              ref.read(underPressureProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('تصفير الكل'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isProminent;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isProminent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = AppDesign.isSmallScreen(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isSmall ? 80 : 100,
        padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 12),
        decoration: BoxDecoration(
          color: isProminent ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isProminent ? color : color.withOpacity(0.3), width: isProminent ? 2 : 1),
          boxShadow: isProminent ? [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
          ] : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isSmall ? 24 : 40, color: isProminent ? color : color.withOpacity(0.8)),
            SizedBox(height: isSmall ? 4 : 8),
            Text(label, style: TextStyle(fontSize: isSmall ? 14 : 20, fontWeight: FontWeight.w900, color: isProminent ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
