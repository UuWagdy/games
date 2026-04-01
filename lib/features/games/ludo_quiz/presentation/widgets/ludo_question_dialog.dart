import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/questions/domain/entities/category.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/games/ludo_quiz/presentation/providers/ludo_controller.dart';
import 'package:games/features/games/ludo_quiz/domain/entities/ludo_entities.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/core/providers/sound_effects_provider.dart';

class LudoQuestionDialog extends ConsumerStatefulWidget {
  final QuestionTriggerType trigger;
  const LudoQuestionDialog({super.key, required this.trigger});

  @override
  ConsumerState<LudoQuestionDialog> createState() => _LudoQuestionDialogState();
}

class _LudoQuestionDialogState extends ConsumerState<LudoQuestionDialog> {
  Question? _currentQuestion;
  bool _isAnswered = false;
  bool? _isCorrect;
  int? _selectedIndex;
  bool _showManualAnswer = false;
  bool _needsProtectionChoice = false;
  double? _localFontSize;

  double _getEffectiveFontSize(Map<String, dynamic> settings) {
    if (_localFontSize != null) return _localFontSize!;
    return (settings['question_font_size'] ?? 24).toDouble();
  }

  @override
  void initState() {
    super.initState();
    // If it's a protection trigger, we first ask if they want it
    if (widget.trigger == QuestionTriggerType.protect) {
      _needsProtectionChoice = true;
    }
  }

  void _onAcceptProtection() {
    setState(() {
      _needsProtectionChoice = false;
    });
    // Question will be loaded by the build's post-frame callback
  }

  void _onDeclineProtection() {
    Navigator.pop(context);
    ref.read(ludoControllerProvider.notifier).skipQuestion();
  }

  void _pickQuestion(List<Question> allQuestions, List<Category> allCategories) {
    if (_currentQuestion != null || allQuestions.isEmpty || _needsProtectionChoice) return;

    final ludoState = ref.read(ludoControllerProvider);
    final String targetCategoryLabel = widget.trigger.categoryLabel;
    final List<int> mappedIds = ludoState.triggerCategories[widget.trigger] ?? [];

    List<int> targetCatIds = List.from(mappedIds);
    if (targetCatIds.isEmpty) {
      targetCatIds = allCategories
          .where((Category c) => c.name.trim() == targetCategoryLabel)
          .map((Category c) => c.id!)
          .toList();
    }

    final List<Question> filtered = allQuestions.where((Question q) {
      return q.categoryIds.any((int id) => targetCatIds.contains(id));
    }).toList();

    setState(() {
      if (filtered.isNotEmpty) {
        _currentQuestion = filtered[Random().nextInt(filtered.length)];
      } else {
        _currentQuestion = allQuestions[Random().nextInt(allQuestions.length)];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_needsProtectionChoice) {
      return _buildChoiceDialog();
    }

    final questionsAsync = ref.watch(questionsProvider(null));
    final categoriesAsync = ref.watch(categoriesProvider);
    // Explicitly watch settings for real-time updates
    ref.watch(generalSettingsProvider);

    return questionsAsync.when(
      data: (questions) {
        return categoriesAsync.when(
          data: (categories) {
            if (_currentQuestion == null && questions.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _pickQuestion(questions, categories);
              });
            }

            if (_currentQuestion == null) {
              return _buildLoadingDialog();
            }

            return _buildMainDialog(context);
          },
          loading: () => _buildLoadingDialog(),
          error: (e, s) => _buildErrorDialog("خطأ في تحميل الفئات"),
        );
      },
      loading: () => _buildLoadingDialog(),
      error: (e, s) => _buildErrorDialog("خطأ في تحميل الأسئلة"),
    );
  }

  Widget _buildChoiceDialog() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: const Color(0xFF1B1B2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, color: Colors.greenAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "هل تريد تفعيل الحماية؟",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "مقابل إجابة سؤال صحيح على هذه النجمة",
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onDeclineProtection,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("لا، شكراً"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _onAcceptProtection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.withOpacity(0.2),
                              foregroundColor: Colors.greenAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text("نعم، أريد"),
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

  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: const Color(0xFF1B1B2F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(height: 20),
            Text("جارِ جلب السؤال...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDialog(String message) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1B1B2F),
      title: Text(message, style: const TextStyle(color: Colors.red)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("موافق")),
      ],
    );
  }

  Widget _buildMainDialog(BuildContext context) {
    final bool hasOptions = _currentQuestion!.options != null && _currentQuestion!.options!.isNotEmpty;
    final settings = ref.read(generalSettingsProvider).value ?? {};
    final fontSize = _getEffectiveFontSize(settings);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF1B1B2F).withOpacity(0.95),
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 20),
            ],
          ),
          child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTriggerColor(widget.trigger).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getTriggerColor(widget.trigger)),
                        ),
                        child: Text(
                          widget.trigger.categoryLabel,
                          style: TextStyle(color: _getTriggerColor(widget.trigger), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _localFontSize = (fontSize - 2).clamp(12, 100);
                              });
                            },
                            icon: const Icon(Icons.zoom_out, color: Colors.white70),
                            iconSize: 20,
                          ),
                          Text(
                            fontSize.toInt().toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _localFontSize = fontSize + 2;
                              });
                            },
                            icon: const Icon(Icons.zoom_in, color: Colors.white70),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentQuestion!.text,
                    style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  if (hasOptions) 
                    _buildOptions(context)
                  else ...[
                    _buildManualGrading(context),
                    if (_isAnswered && _isCorrect != null)
                      _buildResultOverlay(),
                  ],
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: List<Widget>.generate(_currentQuestion!.options!.length, (int index) {
            final List<int> correctIndices = _currentQuestion!.correctOptionIndices ?? <int>[];
            final bool isCorrectOption = correctIndices.contains(index);
            final bool isSelected = _selectedIndex == index;

            Color bgColor;
            Color borderColor;
            if (_isAnswered) {
              if (isCorrectOption) {
                bgColor = Colors.green.withOpacity(0.3);
                borderColor = Colors.green;
              } else if (isSelected && !isCorrectOption) {
                bgColor = Colors.red.withOpacity(0.3);
                borderColor = Colors.red;
              } else {
                bgColor = Colors.white.withOpacity(0.03);
                borderColor = Colors.white12;
              }
            } else {
              bgColor = Colors.white.withOpacity(0.06);
              borderColor = Colors.white24;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _isAnswered ? null : () => _submitAnswer(isCorrect: isCorrectOption, index: index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: isSelected || (_isAnswered && isCorrectOption) ? 2 : 1),
                  ),
                  child: Text(
                    _currentQuestion!.options![index],
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 15,
                      fontWeight: (isSelected || (_isAnswered && isCorrectOption)) ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ),
        
        if (_isAnswered && _isCorrect != null)
          _buildResultOverlay(),
      ],
    );
  }

  Widget _buildManualGrading(BuildContext context) {
    if (_isAnswered) return const SizedBox(height: 100);

    return Column(
      children: [
        if (!_showManualAnswer)
          ElevatedButton.icon(
            onPressed: () => setState(() => _showManualAnswer = true),
            icon: const Icon(Icons.visibility),
            label: const Text("عرض الإجابة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
              foregroundColor: Colors.cyanAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              _currentQuestion!.answer ?? "لا توجد إجابة مسجلة",
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _manualButton(label: "بإجابة خاطئة", color: Colors.redAccent, icon: Icons.close, isCorrect: false),
              _manualButton(label: "بإجابة صحيحة", color: Colors.greenAccent, icon: Icons.check, isCorrect: true),
            ],
          ),
        ],
      ],
    );
  }

  Widget _manualButton({required String label, required Color color, required IconData icon, required bool isCorrect}) {
    return InkWell(
      onTap: () => _submitAnswer(isCorrect: isCorrect),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isCorrect! ? Icons.check_circle : Icons.cancel,
            color: _isCorrect! ? Colors.greenAccent : Colors.redAccent,
            size: 80,
          ),
          const SizedBox(height: 12),
          Text(
            _isCorrect! ? "إجابة صحيحة" : "إجابة خاطئة",
            style: TextStyle(
              color: _isCorrect! ? Colors.greenAccent : Colors.redAccent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 15)],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTriggerColor(QuestionTriggerType trigger) {
    switch (trigger) {
      case QuestionTriggerType.exit: return Colors.orangeAccent;
      case QuestionTriggerType.pass: return Colors.cyanAccent;
      case QuestionTriggerType.protect: return Colors.greenAccent;
      case QuestionTriggerType.attack: return Colors.redAccent;
      case QuestionTriggerType.vision: return Colors.purpleAccent;
    }
  }

  void _submitAnswer({required bool isCorrect, int? index}) {
    setState(() {
      _isAnswered = true;
      _selectedIndex = index;
      _isCorrect = isCorrect;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pop(context);
      if (_isCorrect!) {
        SoundEffectsManager.playCorrect();
        ref.read(ludoControllerProvider.notifier).onQuestionAnsweredCorrectly();
      } else {
        SoundEffectsManager.playIncorrect();
        ref.read(ludoControllerProvider.notifier).onQuestionAnsweredWrong();
      }
    });
  }
}
