import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';
import 'dart:math';
import 'dart:ui';
import '../providers/penalty_shootout_provider.dart';
import '../widgets/penalty_scoreboard.dart';
import '../../domain/entities/penalty_shootout_state.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/core/design/app_design.dart';

class PenaltyShootoutPage extends ConsumerStatefulWidget {
  const PenaltyShootoutPage({super.key});

  @override
  ConsumerState<PenaltyShootoutPage> createState() => _PenaltyShootoutPageState();
}

class _PenaltyShootoutPageState extends ConsumerState<PenaltyShootoutPage> with TickerProviderStateMixin {
  late AnimationController _goalController;
  late AnimationController _missController;
  late Animation<double> _goalScale;
  late Animation<double> _missScale;
  final FocusNode _focusNode = FocusNode();
  
  Team? _selectedTeamA;
  Team? _selectedTeamB;
  Set<int> _selectedCategoryIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _goalController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _missController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _goalScale = CurvedAnimation(parent: _goalController, curve: Curves.elasticOut);
    _missScale = CurvedAnimation(parent: _missController, curve: Curves.elasticOut);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    _missController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFeedback(bool? result) {
    if (result == true) {
      _missController.reset(); 
      _goalController.reset();
      _goalController.forward().then((_) => Future.delayed(const Duration(milliseconds: 100)).then((_) {
        if (mounted) _goalController.reverse();
      }));
    } else if (result == false) {
      _goalController.reset(); 
      _missController.reset();
      _missController.forward().then((_) => Future.delayed(const Duration(milliseconds: 100)).then((_) {
        if (mounted) _missController.reverse();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(penaltyShootoutProvider);
    final teamsAsync = ref.watch(teamsListProvider);
    
    ref.listen(penaltyShootoutProvider, (previous, next) {
      if (next.status == PenaltyGameStatus.feedback && previous?.status == PenaltyGameStatus.playing) {
          _showFeedback(next.lastResult);
      } 
      else if (next.failedTurnsInCurrentQuestion.length > (previous?.failedTurnsInCurrentQuestion.length ?? 0)) {
          if (next.status == PenaltyGameStatus.playing) {
            _showFeedback(false);
          }
      }
    });

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey.keyLabel.toLowerCase();
          if (gameState.isCompetitiveMode && gameState.status == PenaltyGameStatus.playing) {
            if (key == gameState.teamAKey.toLowerCase()) {
              ref.read(penaltyShootoutProvider.notifier).onBuzzerPressed(PenaltyTurn.teamA);
            } else if (key == gameState.teamBKey.toLowerCase()) {
              ref.read(penaltyShootoutProvider.notifier).onBuzzerPressed(PenaltyTurn.teamB);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('ضربات الجزاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 28),
              onPressed: () => _showExitDialog(),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: AppDesign.backgroundWrapper(
          child: Stack(
            children: [
              Positioned.fill(child: Opacity(opacity: 0.1, child: CustomPaint(painter: FootballFieldPainter()))),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PenaltyScoreboard(gameState: gameState),
                    ),
                    
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Center(
                          child: _buildMainContent(gameState, teamsAsync),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              IgnorePointer(
                child: Center(
                  child: ScaleTransition(
                    scale: _goalScale,
                    child: _buildResultOverlay('هـدف!', Colors.amberAccent, Colors.greenAccent, context),
                  ),
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: ScaleTransition(
                    scale: _missScale,
                    child: _buildResultOverlay('ضـاعت!', Colors.white70, Colors.redAccent, context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(PenaltyShootoutState state, AsyncValue<List<Team>> teamsAsync) {
    if (state.status == PenaltyGameStatus.idle) {
      return teamsAsync.when(
        data: (teams) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              _buildIdleStart(teams),
              const SizedBox(height: 20),
              _buildCategorySelection(),
            ],
          ),
        ),
        loading: () => const CircularProgressIndicator(color: Colors.amber),
        error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
      );
    }
    
    if (state.status == PenaltyGameStatus.playing || state.status == PenaltyGameStatus.feedback) {
      return _buildQuestionArea(state);
    }
    
    if (state.status == PenaltyGameStatus.finished) {
      return _buildWinnerArea(state);
    }

    return const SizedBox();
  }

  // Score bar removed to save space


  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إغلاق اللعبة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من رغبتك في إغلاق اللعبة والعودة للقائمة؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }


  Widget _buildIdleStart(List<Team> teams) {
    if (teams.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_off_rounded, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            const Text('يرجى إضافة فريقين على الأقل من الإعدادات للبدء', style: TextStyle(color: Colors.white70, fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsManagementPage())),
              child: const Text('إدارة الفرق'),
            ),
          ],
        ),
      );
    }
    
    // Initialize defaults if not set
    _selectedTeamA ??= teams[0];
    _selectedTeamB ??= teams.length > 1 ? teams[1] : teams[0];

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 800),
        decoration: AppDesign.glassDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_soccer_rounded, size: 50, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text('تجهيز مباراة ضربات الجزاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
            const SizedBox(height: 24),
            if (AppDesign.isSmallScreen(context))
              Column(
                children: [
                  _buildTeamSelector('الفريق الأول', teams, _selectedTeamA, (t) => setState(() => _selectedTeamA = t), Colors.blueAccent),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('VS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 32)),
                  ),
                  _buildTeamSelector('الفريق الثاني', teams, _selectedTeamB, (t) => setState(() => _selectedTeamB = t), Colors.redAccent, exclude: _selectedTeamA),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildTeamSelector('الفريق الأول', teams, _selectedTeamA, (t) => setState(() => _selectedTeamA = t), Colors.blueAccent)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('VS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 32)),
                  ),
                  Expanded(
                    child: _buildTeamSelector(
                      'الفريق الثاني', 
                      teams, 
                      _selectedTeamB, 
                      (t) => setState(() => _selectedTeamB = t), 
                      Colors.redAccent,
                      exclude: _selectedTeamA
                    )
                  ),
                ],
              ),
            SizedBox(height: AppDesign.isSmallScreen(context) ? 24 : 32),
            ElevatedButton(
              onPressed: (_selectedTeamA != null && _selectedTeamB != null && _selectedTeamA != _selectedTeamB)
                  ? () {
                      ref.read(penaltyShootoutProvider.notifier).startGame(_selectedTeamA!, _selectedTeamB!, _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList());
                      _focusNode.requestFocus();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 10,
              ),
              child: const Text('ابدأ المباراة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            if (_selectedTeamA == _selectedTeamB && _selectedTeamA != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('يجب اختيار فريقين مختلفين للمنافسة!', style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelector(String label, List<Team> allTeams, Team? selected, Function(Team) onSelected, Color color, {Team? exclude}) {
    final availableTeams = allTeams.where((t) => t != exclude).toList();
    
    // Ensure the selected team is valid if it's currently the excluded one
    final validSelected = (selected != null && availableTeams.contains(selected)) ? selected : (availableTeams.isNotEmpty ? availableTeams[0] : null);

    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Team>(
              value: validSelected,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              items: availableTeams.map((team) {
                return DropdownMenuItem<Team>(
                  value: team,
                  child: Text(team.name, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (Team? newValue) {
                if (newValue != null) onSelected(newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionArea(PenaltyShootoutState state) {
    final isCompetitive = state.isCompetitiveMode;
    final buzzedTurn = state.buzzedTurn;
    final currentlyAnswering = isCompetitive ? buzzedTurn : state.currentTurn;
    final currentTeam = currentlyAnswering == PenaltyTurn.teamA ? state.teamA : state.teamB;
    final teamColor = currentlyAnswering == PenaltyTurn.teamA ? Colors.blueAccent : Colors.redAccent;

    return Container(
      width: min(900, MediaQuery.of(context).size.width * 0.98),
      padding: EdgeInsets.symmetric(
        horizontal: AppDesign.isSmallScreen(context) ? 16 : 24, 
        vertical: AppDesign.isSmallScreen(context) ? 12 : 16
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: teamColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: teamColor.withOpacity(0.05), blurRadius: 30)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isCompetitive && buzzedTurn == null)
                Text('بانتظار الضغط...', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 16 : 20, fontWeight: FontWeight.w900, color: Colors.amberAccent))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teamColor.withOpacity(0.5)),
                  ),
                  child: Text('فريق: ${currentTeam?.name}', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 16 : 20, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              if (state.isSuddenDeath)
                Text('موت مفاجئ!', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: AppDesign.isSmallScreen(context) ? 14 : 20))
              else
                Text('المحاولة: ${state.currentRound} / 5', style: TextStyle(color: Colors.white60, fontSize: AppDesign.isSmallScreen(context) ? 12 : 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (isCompetitive && buzzedTurn == null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => ref.read(penaltyShootoutProvider.notifier).onBuzzerPressed(PenaltyTurn.teamA),
                  child: _buildKeyIndicator(state.teamAKey, Colors.blueAccent, 'أ')
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTap: () => ref.read(penaltyShootoutProvider.notifier).onBuzzerPressed(PenaltyTurn.teamB),
                  child: _buildKeyIndicator(state.teamBKey, Colors.redAccent, 'ب')
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (state.status == PenaltyGameStatus.playing) ...[
            Text(
              state.currentQuestion?.text ?? 'تحميل السؤال...', 
              style: TextStyle(
                fontSize: AppDesign.isSmallScreen(context) ? 18 : 26, 
                fontWeight: FontWeight.w900, 
                color: Colors.white, 
                height: 1.15
              ), 
              textAlign: TextAlign.center
            ),
            SizedBox(height: AppDesign.isSmallScreen(context) ? 10 : 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: AppDesign.isSmallScreen(context) ? 70 : 90, 
                  height: AppDesign.isSmallScreen(context) ? 70 : 90, 
                  child: CircularProgressIndicator(
                    value: state.timer / state.timerDuration, 
                    strokeWidth: AppDesign.isSmallScreen(context) ? 6 : 8, 
                    backgroundColor: Colors.white12, 
                    strokeCap: StrokeCap.round, 
                    color: state.timer < 4 ? Colors.redAccent : Colors.tealAccent
                  )
                ),
                Text('${state.timer}', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 24 : 32, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 24),
            if (!isCompetitive || buzzedTurn != null) ...[
              Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _buildDecisionButton('هـدف', Colors.greenAccent, () => _handleAnswerSelection(true, state)),
                  _buildDecisionButton('ضـاعت', Colors.redAccent, () => _handleAnswerSelection(false, state)),
                ],
              ),
            ] else 
              const Text('الأسرع يضغط الزر المخصص له للإجابة', style: TextStyle(fontSize: 16, color: Colors.white38, fontStyle: FontStyle.italic)),
          ],
          if (state.status == PenaltyGameStatus.feedback) ...[
            _buildAnswerFeedback(state),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(penaltyShootoutProvider.notifier).nextTurn(null), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), side: const BorderSide(color: Colors.white10)),
              child: const Text('المحاولة التالية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecisionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, side: BorderSide(color: color.withOpacity(0.5), width: 2), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
    );
  }

  void _handleAnswerSelection(bool correct, PenaltyShootoutState state) {
    if (state.isCompetitiveMode && state.buzzedTurn == null) return;
    ref.read(penaltyShootoutProvider.notifier).submitAnswer(correct);
  }

  Widget _buildAnswerFeedback(PenaltyShootoutState state) {
    final correct = state.lastResult == true;
    return Column(
      children: [
        Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: correct ? Colors.greenAccent : Colors.redAccent, size: 50),
        const SizedBox(height: 8),
        Text(correct ? 'هـدف ممـتاز!' : 'للأسف ضاعت!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: correct ? Colors.greenAccent : Colors.redAccent)),
        const SizedBox(height: 12),
        const Text('الإجابة النموذجية كانت:', style: TextStyle(fontSize: 13, color: Colors.white38)),
        const SizedBox(height: 4),
        Text(state.currentQuestion?.answer ?? '-', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildWinnerArea(PenaltyShootoutState state) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Container(
      padding: EdgeInsets.all(isSmall ? 30 : 80),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isSmall ? 30 : 50),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 3),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 60)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.amberAccent, size: isSmall ? 100 : 180),
          SizedBox(height: isSmall ? 24 : 48),
          Text('الفائز بضربات الجزاء هو:', style: TextStyle(color: Colors.white70, fontSize: isSmall ? 18 : 24)),
          SizedBox(height: isSmall ? 12 : 20),
          Text(
            state.winner ?? 'تعادل حاسم!', 
            style: TextStyle(
              fontSize: isSmall ? 36 : 72, 
              fontWeight: FontWeight.w900, 
              color: Colors.amberAccent, 
              letterSpacing: isSmall ? 2 : 4, 
              shadows: const [Shadow(color: Colors.amberAccent, blurRadius: 30)]
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmall ? 30 : 60),
          ElevatedButton(
            onPressed: () => ref.read(penaltyShootoutProvider.notifier).reset(), 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent, 
              foregroundColor: Colors.black, 
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 40 : 80, vertical: isSmall ? 16 : 28), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), 
              elevation: 20, 
              shadowColor: Colors.amberAccent.withOpacity(0.4)
            ),
            child: Text('لعب مرة أخرى', style: TextStyle(fontSize: isSmall ? 20 : 32, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('الخروج من اللعبة', style: TextStyle(color: Colors.white24, fontSize: isSmall ? 16 : 20))),
        ],
      ),
    );
  }

  Widget _buildResultOverlay(String text, Color textColor, Color strokeColor, BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Text(text, style: TextStyle(fontSize: isSmall ? 60 : 120, fontWeight: FontWeight.w900, color: textColor, shadows: [Shadow(color: strokeColor.withOpacity(0.8), blurRadius: 50)]));
  }

  Widget _buildKeyIndicator(String key, Color color, String label) {
    return Column(
      children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.5), width: 1.5)), child: Center(child: Text(key.toUpperCase(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)))),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategorySelection() {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: AppDesign.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('فئات الأسئلة (اختياري)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton(
                    onPressed: () => categoriesAsync.whenData((cats) => setState(() => _selectedCategoryIds = cats.map((e) => e.id!).toSet())),
                    child: const Text('تحديد الكل', style: TextStyle(color: Colors.blueAccent)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedCategoryIds = {}),
                    child: const Text('مسح', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن فئة...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.amberAccent, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) {
              final filtered = categories.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              if (filtered.isEmpty) return const Center(child: Text('لا توجد فئات', style: TextStyle(color: Colors.white24)));
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filtered.map((cat) {
                  final isSelected = _selectedCategoryIds.contains(cat.id);
                  return FilterChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (v) => setState(() => isSelected ? _selectedCategoryIds.remove(cat.id) : _selectedCategoryIds.add(cat.id!)),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: Colors.amberAccent.withOpacity(0.2),
                    checkmarkColor: Colors.amberAccent,
                    labelStyle: TextStyle(color: isSelected ? Colors.amberAccent : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), 
                      side: BorderSide(color: isSelected ? Colors.amberAccent : Colors.white10),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(20, 20, size.width - 40, size.height - 40), paint);
    canvas.drawLine(Offset(20, size.height / 2), Offset(size.width - 20, size.height / 2), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 80, paint);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 120, 20, 240, 100), paint);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 120, size.height - 120, 240, 100), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

