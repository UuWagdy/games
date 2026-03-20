import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/games/quiz_arena/presentation/providers/quiz_arena_provider.dart';
import 'package:games/features/games/quiz_arena/domain/models/quiz_arena_settings.dart';
import 'package:games/features/games/quiz_arena/presentation/pages/quiz_arena_game_page.dart';
import 'package:games/features/questions/domain/entities/category.dart';
import 'package:games/features/teams/domain/entities/team.dart';

class QuizArenaSettingsPage extends ConsumerStatefulWidget {
  final bool isView;
  const QuizArenaSettingsPage({super.key, this.isView = false});

  @override
  ConsumerState<QuizArenaSettingsPage> createState() => _QuizArenaSettingsPageState();
}

class _QuizArenaSettingsPageState extends ConsumerState<QuizArenaSettingsPage> {
  final TextEditingController _roundsController = TextEditingController(text: '10');
  final TextEditingController _timeLimitController = TextEditingController(text: '30');
  final TextEditingController _negativePointsController = TextEditingController(text: '0');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _roundsController.dispose();
    _timeLimitController.dispose();
    _negativePointsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(quizArenaSettingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final teamsAsync = ref.watch(teamsListProvider);

    // Auto-initialize if empty
    if (categoriesAsync.hasValue && teamsAsync.hasValue) {
      Future.microtask(() {
        final allCatIds = categoriesAsync.value?.map((c) => c.id!).toList() ?? [];
        final allTeamIds = teamsAsync.value?.map((t) => t.id!).toList() ?? [];
        if (allCatIds.isNotEmpty && allTeamIds.isNotEmpty) {
           ref.read(quizArenaSettingsProvider.notifier).initializeSelections(allCatIds, allTeamIds);
        }
      });
    }

    final content = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (!widget.isView) _buildAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(widget.isView ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('الفرق المشاركة'),
                const SizedBox(height: 20),
                _buildTeamsList(teamsAsync, settings),
                const SizedBox(height: 40),
                _buildSectionHeader('اعدادات اللعبة'),
                const SizedBox(height: 20),
                _buildSettingsCard(settings),
                const SizedBox(height: 40),
                _buildCategoryManagementHeader(categoriesAsync, settings),
                const SizedBox(height: 20),
                _buildCategoriesList(categoriesAsync, settings),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.isView) return content;

    return Scaffold(
      body: AppDesign.backgroundWrapper(
        child: content,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startGame(settings, teamsAsync),
        label: const Text('ابدأ التحدي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        icon: const Icon(Icons.play_arrow_rounded),
        backgroundColor: Colors.purpleAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'ساحة التحدي',
        style: AppDesign.titleStyle,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 10)],
      ),
    );
  }  Widget _buildCategoryManagementHeader(AsyncValue<List<Category>> categoriesAsync, QuizArenaSettings settings) {
    final isSmall = AppDesign.isSmallScreen(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isSmall 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('الفئات المسؤولة'),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (List<Category> categories) => TextButton.icon(
                    onPressed: () {
                      final allIds = categories.map((c) => c.id!).toList();
                      ref.read(quizArenaSettingsProvider.notifier).selectAllCategories(allIds);
                    },
                    icon: Icon(
                      settings.categoryIds.length == categories.length
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      color: Colors.purpleAccent,
                      size: 20,
                    ),
                    label: Text(
                      settings.categoryIds.length == categories.length ? 'إلغاء الكل' : 'تحديد الكل',
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('الفئات المسؤولة'),
                categoriesAsync.when(
                  data: (List<Category> categories) => TextButton.icon(
                    onPressed: () {
                      final allIds = categories.map((c) => c.id!).toList();
                      ref.read(quizArenaSettingsProvider.notifier).selectAllCategories(allIds);
                    },
                    icon: Icon(
                      settings.categoryIds.length == categories.length
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      color: Colors.purpleAccent,
                    ),
                    label: Text(
                      settings.categoryIds.length == categories.length ? 'إلغاء الكل' : 'تحديد الكل',
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
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
      ],
    );
  }

  Widget _buildSettingsCard(QuizArenaSettings settings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDesign.glassDecoration,
      child: Column(
        children: [
          _buildNumberSetting(
            'عدد الجولات',
            _roundsController,
            Icons.repeat_rounded,
            (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(
              settings.copyWith(rounds: int.tryParse(val) ?? 10),
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildNumberSetting(
            'وقت السؤال (ثانية)',
            _timeLimitController,
            Icons.timer_outlined,
            (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(
              settings.copyWith(timeLimitSeconds: int.tryParse(val) ?? 30),
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildNumberSetting(
            'نقاط الخطأ (سالبة)',
            _negativePointsController,
            Icons.remove_circle_outline,
            (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(
              settings.copyWith(negativePoints: int.tryParse(val) ?? 0),
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          SwitchListTile(
            title: const Text('تفعيل العداد الزمني', style: TextStyle(color: Colors.white)),
            value: settings.timerEnabled,
            onChanged: (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(
              settings.copyWith(timerEnabled: val),
            ),
            activeColor: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSetting(String title, TextEditingController controller, IconData icon, Function(String) onChanged) {
    return Row(
      children: [
        Icon(icon, color: Colors.purpleAccent, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList(AsyncValue<List<Category>> categoriesAsync, QuizArenaSettings settings) {
    return categoriesAsync.when(
      data: (List<Category> categories) {
        final filteredCategories = categories.where((Category c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
        final isSmall = AppDesign.isSmallScreen(context);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isSmall ? 400 : 200,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: isSmall ? 65 : 75,
          ),
          itemCount: filteredCategories.length,
          itemBuilder: (context, index) {
            final category = filteredCategories[index];
            final isSelected = settings.categoryIds.contains(category.id);
            final points = settings.categoryPoints[category.id] ?? 10;

            return GestureDetector(
              onTap: () => ref.read(quizArenaSettingsProvider.notifier).toggleCategory(category.id!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: isSelected 
                    ? LinearGradient(
                        colors: [Colors.purpleAccent.withOpacity(0.3), Colors.indigoAccent.withOpacity(0.3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.purpleAccent : Colors.white10,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 12, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: isSmall ? 15 : 13,
                              ),
                              maxLines: 2,
                            ),
                            Text(
                              isSelected ? 'مختار' : '${category.questionsCount ?? 0} سؤال',
                              style: TextStyle(
                                color: isSelected ? Colors.greenAccent : Colors.white24, 
                                fontSize: isSmall ? 11 : 9,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: isSmall ? 50 : 40,
                          height: isSmall ? 32 : 26,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.amberAccent, fontSize: isSmall ? 14 : 12, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              final pts = int.tryParse(val) ?? 10;
                              ref.read(quizArenaSettingsProvider.notifier).updateCategoryPoints(category.id!, pts);
                            },
                            controller: TextEditingController(text: points.toString()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: Column(children: [CircularProgressIndicator(color: Colors.purpleAccent), SizedBox(height: 10), Text('جاري تحميل الفئات...', style: TextStyle(color: Colors.white60))])),
      error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildTeamsList(AsyncValue<List<Team>> teamsAsync, QuizArenaSettings settings) {
    return teamsAsync.when(
      data: (List<Team> teams) => Column(
        children: [
          for (final team in teams)
            GestureDetector(
              onTap: () => ref.read(quizArenaSettingsProvider.notifier).toggleTeamSelection(team.id!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: AppDesign.glassDecoration.copyWith(
                  color: settings.selectedTeamIds.contains(team.id)
                      ? Colors.purpleAccent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color: settings.selectedTeamIds.contains(team.id)
                          ? Colors.purpleAccent
                          : Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: settings.selectedTeamIds.contains(team.id)
                          ? Colors.purpleAccent
                          : Colors.purpleAccent.withOpacity(0.1),
                      child: Icon(
                        settings.selectedTeamIds.contains(team.id) ? Icons.check : Icons.people_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(team.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (settings.selectedTeamIds.contains(team.id))
                      const Text('مختار',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 12))
                    else
                      const Text('انقر للاختيار',
                          style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  void _startGame(QuizArenaSettings settings, AsyncValue teamsAsync) {
    if (settings.categoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار فئة واحدة على الأقل')),
      );
      return;
    }

    teamsAsync.whenData((teams) {
        final selectedTeams = teams.where((t) => settings.selectedTeamIds.contains(t.id)).toList();
        
        if (selectedTeams.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب اختيار فريقين على الأقل للعب')),
          );
          return;
        }

        ref.read(quizArenaGameProvider.notifier).startGame(settings, selectedTeams);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuizArenaGamePage()),
        );
    });
  }
}
