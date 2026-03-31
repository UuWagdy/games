import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/questions/domain/entities/category.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/questions/presentation/pages/questions_management_page.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import '../../domain/entities/ludo_entities.dart';
import '../providers/ludo_controller.dart';
import '../../domain/models/ludo_state.dart';

class LudoSettingsPage extends ConsumerStatefulWidget {
  final bool isView;
  const LudoSettingsPage({super.key, this.isView = false});

  @override
  ConsumerState<LudoSettingsPage> createState() => _LudoSettingsPageState();
}

class _LudoSettingsPageState extends ConsumerState<LudoSettingsPage> {
  late TextEditingController _winPointsController;
  
  final Map<int, LudoColor?> _teamColorMapping = {};
  final Map<QuestionTriggerType, List<int>> _triggerCategoryMapping = {};
  final Map<QuestionTriggerType, bool> _triggerEnabledMapping = {};
  late bool _isVisionModeEnabled;
  late VisionModeScope _visionModeScope;
  late bool _isTeamMode;
  final Map<LudoColor, int> _playerTeamsMapping = {};
  late List<int> _exitNumbers;
  late bool _isDoubleMoveEnabled;
  late bool _isVsComputer;

  @override
  void initState() {
    super.initState();
    final LudoState currentState = ref.read(ludoControllerProvider);
    _winPointsController = TextEditingController(text: currentState.winPoints.toString());
    
    _triggerCategoryMapping.addAll(currentState.triggerCategories);
    _triggerEnabledMapping.addAll(currentState.triggerEnabled);
    _isVisionModeEnabled = currentState.isVisionModeEnabled;
    _visionModeScope = currentState.visionModeScope;
    _isTeamMode = currentState.isTeamMode;
    _playerTeamsMapping.addAll(currentState.playerTeams);
    _exitNumbers = List<int>.from(currentState.exitNumbers);
    _isDoubleMoveEnabled = currentState.isDoubleMoveEnabled;
    if (_playerTeamsMapping.isEmpty) {
        _playerTeamsMapping[LudoColor.red] = 0;
        _playerTeamsMapping[LudoColor.yellow] = 0;
        _playerTeamsMapping[LudoColor.green] = 1;
        _playerTeamsMapping[LudoColor.blue] = 1;
    }
    
    final settings = ref.read(generalSettingsProvider).value;
    final globalAiEnabled = settings?['global_ai_enabled'] ?? false;
    final allTeams = ref.read(teamsListProvider).value ?? [];
    final teams = globalAiEnabled ? allTeams : allTeams.where((t) => t.name != 'AI' && t.name != 'الآلي' && t.name != 'COMPUTER').toList();
    
    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      final existingColor = currentState.colorTeamNames.entries
          .where((e) => e.value == team.name)
          .map((e) => e.key)
          .firstOrNull;
          
      if (existingColor != null) {
        _teamColorMapping[team.id!] = existingColor;
      } else {
        // Default assignment: Red, Green, Yellow, Blue in order
        if (i < LudoColor.values.length) {
          final color = LudoColor.values[i];
          // Ensure this color isn't already assigned to another team
          final isAssigned = _teamColorMapping.values.contains(color);
          if (!isAssigned) {
            _teamColorMapping[team.id!] = color;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _winPointsController.dispose();
    super.dispose();
  }

  void _onColorSelected(int teamId, LudoColor color) {
    setState(() {
      _teamColorMapping.forEach((tid, c) {
        if (tid != teamId && c == color) _teamColorMapping[tid] = null;
      });
      _teamColorMapping[teamId] = color;
    });
  }

  void _selectAllCategories(QuestionTriggerType trigger, List<Category> categories) {
    setState(() {
       _triggerCategoryMapping[trigger] = categories.map((e) => e.id!).toList();
    });
  }

  void _saveSettings() {
    final int winPoints = int.tryParse(_winPointsController.text) ?? 100;
    ref.read(ludoControllerProvider.notifier).updateSettings(
      winPoints: winPoints,
      triggerCategories: _triggerCategoryMapping,
      triggerEnabled: _triggerEnabledMapping,
      isVisionModeEnabled: _isVisionModeEnabled,
      visionModeScope: _visionModeScope,
      isTeamMode: _isTeamMode,
      playerTeams: _playerTeamsMapping,
      exitNumbers: _exitNumbers,
      isDoubleMoveEnabled: _isDoubleMoveEnabled,
    );
  }

  void _startNewGame() {
    final Map<LudoColor, String> selection = {};
    final teams = ref.read(teamsListProvider).value ?? [];
    
    _teamColorMapping.forEach((teamId, color) {
      if (color != null) {
        final team = teams.firstWhere((t) => t.id == teamId);
        selection[color] = team.name;
      }
    });

    if (selection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يجب اختيار لون واحد على الأقل لفريق واحد")));
      return;
    }

    if (_isTeamMode) {
      final activeColors = selection.keys.toList();
      if (activeColors.length < 2) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يجب اختيار لاعبين على الأقل لتفعيل وضع الفرق")));
         return;
      }
      // Check if all active colors are assigned to a team
      for (var color in activeColors) {
        if (!_playerTeamsMapping.containsKey(color)) {
          _playerTeamsMapping[color] = 0;
        }
      }
    }

    _saveSettings();
    ref.read(ludoControllerProvider.notifier).initGame(
      selection, 
      isTeamMode: _isTeamMode, 
      playerTeams: _playerTeamsMapping,
      vsComputer: _isVsComputer,
    );
    Navigator.pop(context);
  }

  Color _getUiColor(LudoColor color) {
    switch (color) {
      case LudoColor.red: return Colors.red;
      case LudoColor.green: return Colors.green;
      case LudoColor.yellow: return Colors.amber;
      case LudoColor.blue: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final settingsAsync = ref.watch(generalSettingsProvider);
    final globalAiEnabled = settingsAsync.value?['global_ai_enabled'] ?? false;

    final content = ListView(
        padding: EdgeInsets.all(widget.isView ? 16 : 20),
        children: [
          _sectionHeader("اختيار ألوان الفرق", Icons.group_outlined),
          teamsAsync.when(
            data: (rawTeams) {
              final allTeams = List<Team>.from(rawTeams);
              final filteredTeams = globalAiEnabled ? allTeams : allTeams.where((t) => t.name != 'AI' && t.name != 'الآلي' && t.name != 'COMPUTER').toList();
              return Column(
                children: filteredTeams.map((team) => _buildTeamColorTile(team)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text("خطأ في تحميل الفرق: $e", style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 24),
          _buildTeamModeSettings(),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          
          InkWell(
            onTap: _startNewGame,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.cyanAccent.withOpacity(0.3), Colors.cyanAccent.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.play_circle_fill, color: Colors.cyanAccent, size: 28),
                   SizedBox(width: 12),
                   Text("بدء اللعب بالفرق المختارة", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
          _sectionHeader("وضع الرؤيا", Icons.visibility_outlined),
          _buildVisionSettings(),
          const SizedBox(height: 32),

          _sectionHeader("إعدادات الخروج والحركة", Icons.casino_outlined),
          _buildExitSettings(),
          const SizedBox(height: 32),

          _sectionHeader("إعدادات الأسئلة", Icons.help_outline),
          categoriesAsync.when(
            data: (categories) => Column(
              children: QuestionTriggerType.values.map((trigger) {
                return _buildTriggerCategoryTile(trigger, categories);
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Text("خطأ في تحميل الفئات", style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 16),
          _settingsTile(
            icon: Icons.settings_suggest_outlined,
            title: "إدارة الفئات",
            subtitle: "فتح قسم إدارة الأسئلة والفئات",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionsManagementPage())),
          ),

          const SizedBox(height: 32),

          _sectionHeader("قواعد اللعبة", Icons.gavel_outlined),
          _settingsTile(
            icon: Icons.emoji_events_outlined,
            title: "نقاط الفوز",
            subtitle: "جائزة الفوز بالمركز الأول",
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: _winPointsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => _saveSettings(),
              ),
            ),
          ),
        ],
      );

    if (widget.isView) return content;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(
        title: const Text("إعدادات لودو الأسئلة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            _saveSettings();
            Navigator.pop(context);
          },
        ),
      ),
      body: content,
    );
  }

  Widget _buildVisionSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("تفعيل وضع الرؤيا", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Switch(
                value: _isVisionModeEnabled,
                activeColor: Colors.cyanAccent,
                onChanged: (val) => setState(() => _isVisionModeEnabled = val),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "عند وصول اللاعب لأكثر من نص المسافة يمكنه أن يصل للنهاية إذا جاوب على سؤال من الأسئلة المحددة",
              style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
              textAlign: TextAlign.start,
            ),
          ),
          if (_isVisionModeEnabled) ...[
            const Divider(color: Colors.white10, height: 24),
            const Text("نطاق تفعيل الرؤية:", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _scopeButton(
                      label: "لكل قطعة",
                      active: _visionModeScope == VisionModeScope.token,
                      onTap: () => setState(() => _visionModeScope = VisionModeScope.token),
                    ),
                  ),
                  Expanded(
                    child: _scopeButton(
                      label: "للاعب (مرة واحدة)",
                      active: _visionModeScope == VisionModeScope.player,
                      onTap: () => setState(() => _visionModeScope = VisionModeScope.player),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExitSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("أرقام الخروج من القاعدة:", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) {
              final val = i + 1;
              final isSelected = _exitNumbers.contains(val);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_exitNumbers.length > 1) _exitNumbers.remove(val);
                    } else {
                      _exitNumbers.add(val);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.white : Colors.white10),
                  ),
                  child: Center(
                    child: Text(
                      "$val",
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("حركة مضاعفة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("لعب نرد إضافي عند الخروج أو الحركة بأرقام الخروج", style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              Switch(
                value: _isDoubleMoveEnabled,
                activeColor: Colors.cyanAccent,
                onChanged: (val) => setState(() => _isDoubleMoveEnabled = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scopeButton({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.cyanAccent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: Colors.cyanAccent.withOpacity(0.3)) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.cyanAccent : Colors.white38,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamColorTile(Team team) {
    final LudoColor? selectedColor = _teamColorMapping[team.id!];
    final List<LudoColor> takenColors = _teamColorMapping.entries
        .where((e) => e.key != team.id && e.value != null)
        .map((e) => e.value!)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: LudoColor.values.map((color) {
              final bool isPickedByThisTeam = selectedColor == color;
              final bool isTakenByOthers = takenColors.contains(color);
              final Color uiColor = _getUiColor(color);
              
              return GestureDetector(
                onTap: isTakenByOthers ? null : () => _onColorSelected(team.id!, color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isTakenByOthers 
                        ? Colors.grey.withOpacity(0.05) 
                        : (isPickedByThisTeam ? uiColor : uiColor.withOpacity(0.12)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPickedByThisTeam 
                          ? Colors.white 
                          : (isTakenByOthers ? Colors.transparent : uiColor.withOpacity(0.3)),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isPickedByThisTeam 
                        ? const Icon(Icons.check, color: Colors.white, size: 20) 
                        : (isTakenByOthers ? Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.1), size: 18) : null),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerCategoryTile(QuestionTriggerType trigger, List<Category> categories) {
    final List<int> currentSelected = _triggerCategoryMapping[trigger] ?? [];
    final bool isEnabled = _triggerEnabledMapping[trigger] ?? true;
    final bool isAllSelected = currentSelected.length == categories.length && categories.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isEnabled ? 0.03 : 0.01),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isEnabled ? Colors.white12 : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    trigger.categoryLabel,
                    style: TextStyle(
                      color: isEnabled ? Colors.cyanAccent : Colors.white24,
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isEnabled,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _triggerEnabledMapping[trigger] = val),
                    ),
                  ),
                ],
              ),
              if (isEnabled)
                TextButton.icon(
                  onPressed: () => _selectAllCategories(trigger, categories),
                  icon: Icon(isAllSelected ? Icons.done_all : Icons.select_all, size: 14, color: Colors.white38),
                  label: Text(isAllSelected ? "الكل" : "تحديد الكل", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final bool isSelected = currentSelected.contains(cat.id);
                return FilterChip(
                  label: Text(cat.name, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 11)),
                  selected: isSelected,
                  selectedColor: Colors.cyanAccent,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _triggerCategoryMapping.putIfAbsent(trigger, () => []).add(cat.id!);
                      } else {
                        _triggerCategoryMapping[trigger]?.remove(cat.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ] else
            const Text(
              "الأسئلة معطلة لهذا الإجراء، سيتم تنفيذ الحركة مباشرة.",
              style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamModeSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("تفعيل نظام الفرق (2 ضد 2)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Switch(
                value: _isTeamMode,
                activeColor: Colors.cyanAccent,
                onChanged: (val) => setState(() => _isTeamMode = val),
              ),
            ],
          ),
          if (_isTeamMode) ...[
            const Divider(color: Colors.white10, height: 24),
            const Text("اختر الفريق لكل لون (الألوان المتقابلة تكوّن فريقاً عادةً):", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            ...LudoColor.values.map((color) {
              final teamIndex = _playerTeamsMapping[color] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: _getUiColor(color), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        color == LudoColor.red ? "الأحمر" : color == LudoColor.green ? "الأخضر" : color == LudoColor.yellow ? "الأصفر" : "الأزرق",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    _partnershipToggle(
                      label: "الفريق 1",
                      active: teamIndex == 0,
                      onTap: () => setState(() => _playerTeamsMapping[color] = 0),
                    ),
                    const SizedBox(width: 8),
                    _partnershipToggle(
                      label: "الفريق 2",
                      active: teamIndex == 1,
                      onTap: () => setState(() => _playerTeamsMapping[color] = 1),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _partnershipToggle({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? Colors.cyanAccent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.cyanAccent : Colors.white38,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 22),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24) : null),
        onTap: onTap,
      ),
    );
  }
}
