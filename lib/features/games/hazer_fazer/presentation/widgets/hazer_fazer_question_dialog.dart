import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/providers/sound_effects_provider.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';

class HazerFazerQuestionDialog extends ConsumerStatefulWidget {
  final int tileIndex;
  final ValueChanged<bool> onResult;

  const HazerFazerQuestionDialog({
    super.key,
    required this.tileIndex,
    required this.onResult,
  });

  @override
  ConsumerState<HazerFazerQuestionDialog> createState() => _HazerFazerQuestionDialogState();
}

class _HazerFazerQuestionDialogState extends ConsumerState<HazerFazerQuestionDialog> {
  Question? _question;
  int? _questionCategoryId;
  bool _isAnswered = false;
  bool? _isCorrect;
  int? _selectedIndex;
  bool _showAnswer = false;
  double? _localFontSize;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestion());
  }

  Future<void> _loadQuestion() async {
    try {
      final settings = ref.read(generalSettingsProvider).value ?? {};
      final List<int> categoryIds = (settings['hazer_fazer_category_ids'] as List<int>?) ?? [];
      final bool repeatQuestions = settings['repeat_questions'] ?? true;

      List<Question> pool = [];
      int? matchedCategoryId;

      if (categoryIds.isNotEmpty) {
        for (final catId in categoryIds) {
          final qs = await ref.read(questionsProvider(catId).future);
          final valid = repeatQuestions ? qs : qs.where((q) => !q.isUsedIn(catId)).toList();
          if (valid.isNotEmpty) {
            pool.addAll(valid);
            matchedCategoryId = catId;
          }
        }
      }

      // If category pool is empty or no category selected, fallback to all questions
      if (pool.isEmpty) {
        final allCategories = await ref.read(categoriesProvider.future);
        for (final cat in allCategories) {
          if (cat.id == null) continue;
          final qs = await ref.read(questionsProvider(cat.id).future);
          final valid = repeatQuestions ? qs : qs.where((q) => !q.isUsedIn(cat.id!)).toList();
          if (valid.isNotEmpty) {
            pool.addAll(valid);
            matchedCategoryId ??= cat.id;
          }
        }
      }

      if (pool.isEmpty) {
        // Fallback: take any questions even if used
        final all = await ref.read(questionsProvider(null).future);
        pool.addAll(all);
      }

      if (pool.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'لا توجد أسئلة متاحة في بنك الأسئلة! يمكنك إضافة أسئلة من الإعدادات.';
          });
        }
        return;
      }

      final random = Random();
      final picked = pool[random.nextInt(pool.length)];

      if (mounted) {
        setState(() {
          _question = picked;
          _questionCategoryId = matchedCategoryId ?? (picked.categoryIds.isNotEmpty ? picked.categoryIds.first : null);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء تحميل السؤال: $e';
        });
      }
    }
  }

  double _getEffectiveFontSize(Map<String, dynamic> settings) {
    if (_localFontSize != null) return _localFontSize!;
    return ((settings['question_font_size'] ?? 24.0) as num).toDouble();
  }

  void _submitAnswer({required bool isCorrect, int? index}) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedIndex = index;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      SoundEffectsManager.playCorrect();
      // Mark question as used if repeat_questions is false
      final settings = ref.read(generalSettingsProvider).value ?? {};
      final bool repeatQuestions = settings['repeat_questions'] ?? true;
      if (!repeatQuestions && _question?.id != null && _questionCategoryId != null) {
        ref.read(questionsProvider(_questionCategoryId).notifier).setQuestionUsed(
              _question!.id!,
              true,
              categoryId: _questionCategoryId,
            );
      }
    } else {
      SoundEffectsManager.playIncorrect();
    }

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onResult(isCorrect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(generalSettingsProvider).value ?? {};
    final fontSize = _getEffectiveFontSize(settings);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          padding: const EdgeInsets.all(24),
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
            border: Border.all(color: Colors.amberAccent.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 25,
                spreadRadius: 4,
              ),
            ],
          ),
          child: _buildBody(context, fontSize),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double fontSize) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.amberAccent),
            SizedBox(height: 16),
            Text(
              'جارِ تجهيز السؤال...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 50),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onResult(false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
            ),
            child: const Text('إغلاق'),
          ),
        ],
      );
    }

    final hasOptions = _question!.options != null && _question!.options!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Tile Number & Font Size Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 16, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Text(
                      'مربع رقم ${widget.tileIndex + 1}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _localFontSize = (fontSize - 2).clamp(14, 50);
                      });
                    },
                    icon: const Icon(Icons.zoom_out, color: Colors.white70),
                    tooltip: 'تصغير الخط',
                  ),
                  Text(
                    '${fontSize.toInt()}',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _localFontSize = (fontSize + 2).clamp(14, 50);
                      });
                    },
                    icon: const Icon(Icons.zoom_in, color: Colors.white70),
                    tooltip: 'تكبير الخط',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question Text
          Text(
            _question!.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Options or Manual Grading
          if (hasOptions)
            _buildOptionsSection()
          else
            _buildManualGradingSection(),

          // Result Overlay Indicator
          if (_isAnswered && _isCorrect != null) ...[
            const SizedBox(height: 16),
            _buildResultFeedback(),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: List.generate(_question!.options!.length, (index) {
        final correctIndices = _question!.correctOptionIndices ?? [];
        final isCorrectOption = correctIndices.contains(index);
        final isSelected = _selectedIndex == index;

        Color bgColor = Colors.white.withOpacity(0.06);
        Color borderColor = Colors.white12;

        if (_isAnswered) {
          if (isCorrectOption) {
            bgColor = Colors.green.withOpacity(0.25);
            borderColor = Colors.greenAccent;
          } else if (isSelected && !isCorrectOption) {
            bgColor = Colors.red.withOpacity(0.25);
            borderColor = Colors.redAccent;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: _isAnswered ? null : () => _submitAnswer(isCorrect: isCorrectOption, index: index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (_isAnswered && isCorrectOption) ? 2 : 1,
                ),
              ),
              child: Text(
                _question!.options![index],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: (isSelected || (_isAnswered && isCorrectOption)) ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildManualGradingSection() {
    if (_isAnswered) return const SizedBox.shrink();

    return Column(
      children: [
        if (!_showAnswer)
          ElevatedButton.icon(
            onPressed: () => setState(() => _showAnswer = true),
            icon: const Icon(Icons.visibility_rounded, size: 20),
            label: const Text('عرض الإجابة النموذجية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.15),
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                const Text(
                  'الإجابة الصحيحة:',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _question!.answer.isNotEmpty ? _question!.answer : 'لا توجد إجابة مسجلة',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _submitAnswer(isCorrect: false),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  label: const Text('إجابة خاطئة', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.85),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _submitAnswer(isCorrect: true),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text('إجابة صحيحة', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResultFeedback() {
    final isCorrect = _isCorrect == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCorrect ? Colors.greenAccent : Colors.redAccent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? Colors.greenAccent : Colors.redAccent,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            isCorrect ? 'إجابة صحيحة! تم كشف المربع 👏' : 'إجابة خاطئة! المربع يبقى مغطى ❌',
            style: TextStyle(
              color: isCorrect ? Colors.greenAccent : Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
