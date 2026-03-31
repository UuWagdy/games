import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import '../providers/snakes_ladders_providers.dart';
import '../../domain/entities/snakes_ladders_entities.dart';

class SnakesLaddersSettingsDialog extends StatelessWidget {
  const SnakesLaddersSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('إعدادات اللعبة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: const SnakesLaddersSettingsDialogContent(),
    );
  }
}

class SnakesLaddersSettingsDialogContent extends ConsumerStatefulWidget {
  const SnakesLaddersSettingsDialogContent({super.key});

  @override
  ConsumerState<SnakesLaddersSettingsDialogContent> createState() => _SnakesLaddersSettingsDialogContentState();
}

class _SnakesLaddersSettingsDialogContentState extends ConsumerState<SnakesLaddersSettingsDialogContent> {
  int _boardSize = 100;
  bool _questionsEnabled = false;
  List<int> _selectedCategoryIds = [];
  int _winPoints = 25;
  WrongAnswerPenalty _penalty = WrongAnswerPenalty.skip;
  int _snakesCount = 8;
  int _laddersCount = 8;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final currentState = ref.read(snakesLaddersGameProvider);
    _boardSize = currentState.boardSize;
    _questionsEnabled = currentState.questionsEnabled;
    _selectedCategoryIds = List.from(currentState.categoryIds);
    _winPoints = currentState.winPoints;
    _penalty = currentState.wrongAnswerPenalty;
    _snakesCount = currentState.snakesCount;
    _laddersCount = currentState.laddersCount;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      width: 800,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                // Group 1: Board & General
                _buildSection(
                  width: 380,
                  icon: Icons.grid_4x4_rounded,
                  title: 'إعدادات اللوحة',
                  child: Column(
                    children: [
                      const Text('حجم اللوحة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [50, 64, 100].map((size) {
                          final isSel = _boardSize == size;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('$size'),
                              selected: isSel,
                              onSelected: (selected) {
                                if (selected) setState(() => _boardSize = size);
                              },
                              selectedColor: Colors.amber,
                              labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white70, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                              backgroundColor: Colors.white.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text('النقاط عند الفوز', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                            onPressed: () => setState(() => _winPoints = (_winPoints - 5).clamp(5, 100)),
                          ),
                          Container(
                            width: 60,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Text('$_winPoints', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
                            onPressed: () => setState(() => _winPoints = (_winPoints + 5).clamp(5, 100)),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 32),
                      const Text('عدد السلالم والثعابين', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      _buildCounterRow('السلالم:', _laddersCount, (val) => setState(() => _laddersCount = val)),
                      const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      _buildCounterRow('الثعابين:', _snakesCount, (val) => setState(() => _snakesCount = val)),
                    ],
                  ),
                ),

                // Group 2: Questions Mode
                _buildSection(
                  width: 380,
                  icon: Icons.quiz_rounded,
                  title: 'وضع التحدي',
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('تفعيل الأسئلة', style: TextStyle(color: Colors.white, fontSize: 16)),
                        subtitle: const Text('سؤال عند كل حركة', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        value: _questionsEnabled,
                        activeColor: Colors.amber,
                        onChanged: (val) => setState(() => _questionsEnabled = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_questionsEnabled) ...[
                        const Divider(color: Colors.white10, height: 24),
                        const Text('عقاب الخطأ:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        RadioListTile<WrongAnswerPenalty>(
                          title: const Text('فوات الدور', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: WrongAnswerPenalty.skip,
                          groupValue: _penalty,
                          activeColor: Colors.amber,
                          onChanged: (val) => setState(() => _penalty = val!),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<WrongAnswerPenalty>(
                          title: const Text('نصف المسافة', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: WrongAnswerPenalty.half,
                          groupValue: _penalty,
                          activeColor: Colors.amber,
                          onChanged: (val) => setState(() => _penalty = val!),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),

                if (_questionsEnabled)
                // Group 3: Categories
                _buildSection(
                  width: 780,
                  icon: Icons.category_rounded,
                  title: 'أقسام الأسئلة المختارة',
                  child: categoriesAsync.when(
                    data: (categories) {
                      if (categories.isEmpty) return const Text('لا توجد فئات!', style: TextStyle(color: Colors.redAccent));
                      final filtered = categories.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                      return Column(
                        children: [
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => setState(() => _selectedCategoryIds = categories.map((c) => c.id!).toList()),
                                icon: const Icon(Icons.done_all, color: Colors.amber, size: 18),
                                label: const Text('تحديد الكل', style: TextStyle(color: Colors.amber)),
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => _selectedCategoryIds = []),
                                icon: const Icon(Icons.deselect, color: Colors.white38, size: 18),
                                label: const Text('إلغاء التحديد', style: TextStyle(color: Colors.white38)),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 250,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'البحث...',
                                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                    prefixIcon: const Icon(Icons.search, color: Colors.amber, size: 18),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (filtered.isEmpty) const Text('لا توجد نتائج!', style: TextStyle(color: Colors.white24)),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filtered.map((cat) {
                              final isSel = _selectedCategoryIds.contains(cat.id);
                              return FilterChip(
                                label: Text(cat.name),
                                selected: isSel,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) _selectedCategoryIds.add(cat.id!);
                                    else _selectedCategoryIds.remove(cat.id);
                                  });
                                },
                                selectedColor: Colors.amber.withOpacity(0.2),
                                checkmarkColor: Colors.amber,
                                labelStyle: TextStyle(color: isSel ? Colors.amber : Colors.white60, fontSize: 12),
                                backgroundColor: Colors.white.withOpacity(0.05),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(color: Colors.amber),
                    error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 10,
                shadowColor: Colors.amber.withOpacity(0.3),
              ),
              onPressed: () {
                ref.read(snakesLaddersGameProvider.notifier).initializeGame(
                  _boardSize,
                  _questionsEnabled,
                  _selectedCategoryIds,
                  winPoints: _winPoints,
                  penalty: _penalty,
                  snakesCount: _snakesCount,
                  laddersCount: _laddersCount,
                );
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('تطبيق وحفظ الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 20),
          onPressed: () => onChanged((value - 1).clamp(2, 20)),
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20),
          onPressed: () => onChanged((value + 1).clamp(2, 20)),
        ),
      ],
    );
  }

  Widget _buildSection({required double width, required IconData icon, required String title, required Widget child}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
