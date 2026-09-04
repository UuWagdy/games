import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import '../../domain/entities/saint_picture.dart';

class HazerFazerGuessDialog extends ConsumerStatefulWidget {
  final SaintPicture correctSaint;
  final int defaultPoints;
  final int? initialTeamId;
  final void Function({
    required bool isCorrect,
    required int? teamId,
    required String? teamName,
    required int points,
  }) onGuessResult;

  const HazerFazerGuessDialog({
    super.key,
    required this.correctSaint,
    required this.defaultPoints,
    this.initialTeamId,
    required this.onGuessResult,
  });

  @override
  ConsumerState<HazerFazerGuessDialog> createState() => _HazerFazerGuessDialogState();
}

class _HazerFazerGuessDialogState extends ConsumerState<HazerFazerGuessDialog> {
  int? _selectedTeamId;
  late int _points;
  String? _selectedSaintId;
  bool _showCorrectAnswerForHost = false;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.initialTeamId;
    _points = widget.defaultPoints;
  }

  void _handleGuessSubmit(bool isCorrect) {
    final teams = ref.read(teamsListProvider).value ?? [];
    Team? selectedTeam;
    if (_selectedTeamId != null) {
      selectedTeam = teams.where((t) => t.id == _selectedTeamId).firstOrNull;
    } else if (teams.isNotEmpty) {
      selectedTeam = teams.first;
    }

    Navigator.pop(context);
    widget.onGuessResult(
      isCorrect: isCorrect,
      teamId: selectedTeam?.id,
      teamName: selectedTeam?.name,
      points: _points,
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsListProvider).value ?? [];
    if (_selectedTeamId == null && teams.isNotEmpty) {
      _selectedTeamId = teams.first.id;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.25),
                blurRadius: 35,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purpleAccent),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: Colors.purpleAccent, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'تخمين صاحب الصورة',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Team Selection
                if (teams.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: Colors.cyanAccent, size: 22),
                        const SizedBox(width: 12),
                        const Text(
                          'الفريق الذي يخمن:',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        DropdownButton<int?>(
                          value: _selectedTeamId,
                          dropdownColor: const Color(0xFF1E293B),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: teams.map((t) => DropdownMenuItem<int?>(
                            value: t.id,
                            child: Text(t.name, style: const TextStyle(fontSize: 14)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedTeamId = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Points Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 22),
                      const SizedBox(width: 12),
                      const Text(
                        'نقاط الفوز بالتخمين:',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          if (_points > 5) setState(() => _points -= 5);
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                        tooltip: 'إنقاص النقاط',
                      ),
                      Text(
                        '$_points',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _points += 5),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                        tooltip: 'زيادة النقاط',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Saint Options Chooser
                const Text(
                  'اختر اسم القديس أو تحقق مباشرة:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: SaintPicture.defaultSaints.map((saint) {
                    final isSelected = _selectedSaintId == saint.id;
                    return ChoiceChip(
                      label: Text(
                        saint.name,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.amberAccent,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.amberAccent : Colors.white24,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedSaintId = selected ? saint.id : null;
                        });
                        if (selected) {
                          final isRight = saint.id == widget.correctSaint.id;
                          _handleGuessSubmit(isRight);
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Host Peek Button
                TextButton.icon(
                  onPressed: () => setState(() => _showCorrectAnswerForHost = !_showCorrectAnswerForHost),
                  icon: Icon(
                    _showCorrectAnswerForHost ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: Colors.white54,
                  ),
                  label: Text(
                    _showCorrectAnswerForHost
                        ? 'إخفاء اسم القديس للمنسق'
                        : 'عرض اسم صاحب الصورة للمنسق',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),

                if (_showCorrectAnswerForHost) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Text(
                      'الصورة الحالية هي: ${widget.correctSaint.name}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 12),

                // Facilitator Manual Evaluation Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleGuessSubmit(false),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text('تخمين خاطئ (متابعة)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.85),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleGuessSubmit(true),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('تخمين صحيح (فوز!)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
