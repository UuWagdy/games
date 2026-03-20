import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:games/core/design/app_design.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/bank_al_haz_providers.dart';
import '../providers/game_engine_provider.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import 'station_management_page.dart';
import 'card_management_page.dart';
import 'bank_al_haz_board_page.dart';
import '../../data/sources/bank_al_haz_default_data.dart';
import '../../data/sources/bank_al_haz_csv_service.dart';
import 'package:games/core/database/database_service.dart';
import '../../../../questions/presentation/providers/question_providers.dart';

class BankAlHazSettingsPage extends ConsumerStatefulWidget {
  final bool isView;
  const BankAlHazSettingsPage({super.key, this.isView = false});

  @override
  ConsumerState<BankAlHazSettingsPage> createState() =>
      _BankAlHazSettingsPageState();
}

class _BankAlHazSettingsPageState extends ConsumerState<BankAlHazSettingsPage> {
  final TextEditingController _moneyController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _roundsController = TextEditingController(
    text: '10',
  );
  final TextEditingController _timeController = TextEditingController(
    text: '30',
  );
  final TextEditingController _salaryController = TextEditingController(
    text: '200',
  );
  final TextEditingController _winPointsController = TextEditingController(
    text: '50',
  );

  WinningCondition _winCondition = WinningCondition.rounds;
  WinCriteria _winCriteria = WinCriteria.moneyOnly;
  int? _selectedTemplateId;
  bool _bankruptcyEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(gameSettingsProvider.future);
    _moneyController.text = settings.initialMoney.toString();
    _roundsController.text = settings.maxRounds.toString();
    _timeController.text = settings.maxTimeMinutes.toString();
    _salaryController.text = settings.salaryPerLap.toString();
    _winPointsController.text = settings.winPoints.toString();
    setState(() {
      _winCondition = settings.winCondition;
      _winCriteria = settings.winCriteria;
      _selectedTemplateId = settings.activeTemplateId;
      _bankruptcyEnabled = settings.bankruptcyEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: EdgeInsets.all(widget.isView ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إعدادات اللعبة العامة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _moneyController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'فلوس البداية (نقاط)',
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _salaryController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'بركة المرور بـ البداية (المرتب)',
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _winPointsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'نقاط الفوز (تضاف لنقاط الفريق الكلية)',
              labelStyle: const TextStyle(color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_sync, color: Colors.cyanAccent),
            label: const Text('مزامنة من الAssets (لإصلاح أعطال البيانات)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              minimumSize: const Size(double.infinity, 45),
              alignment: Alignment.centerRight,
            ),
            onPressed: () => _handleForceSync(context, ref),
          ),
          const SizedBox(height: 20),
          const Text(
            'إدارة العناصر',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.location_city),
            label: const Text('إدارة المحطات (المدن)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StationManagementPage()),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.style),
            label: const Text('إدارة الكروت (فرصة/صندوق)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CardManagementPage()),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'قوالب اللعبة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          Consumer(
            builder: (context, ref, child) {
              final templatesAsync = ref.watch(templatesProvider);
              return templatesAsync.when(
                data: (templates) {
                  // Fallback for selection
                  if (_selectedTemplateId == null && templates.isNotEmpty) {
                    _selectedTemplateId = templates[0].id;
                  }
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Theme(
                              data: ThemeData.dark(),
                              child: DropdownButtonFormField<int>(
                                value: _selectedTemplateId,
                                items: templates.map((t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.name),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedTemplateId = val);
                                },
                                decoration: InputDecoration(
                                  labelText: 'القالب النشط',
                                  labelStyle: const TextStyle(color: Colors.white60),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.amberAccent),
                            onPressed: _createNewTemplate,
                            tooltip: 'إضافة قالب جديد من ملف CSV',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('خطأ في تحميل القوالب: $e', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('برجاء الضغط على زر "مزامنة من الAssets" أعلاه لإصلاح هذا الخطأ.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'قوانين الفوز',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          Theme(
            data: ThemeData.dark(),
            child: DropdownButtonFormField<WinningCondition>(
              value: _winCondition,
              items: WinningCondition.values
                  .map(
                    (w) => DropdownMenuItem(
                      value: w,
                      child: Text(
                        w == WinningCondition.rounds
                            ? 'بعد عدد دورات معين'
                            : w == WinningCondition.time
                            ? 'بعد وقت معين'
                            : 'لما تخلص أسئلة المحطات',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _winCondition = val!),
              decoration: InputDecoration(
                labelText: 'شرط الفوز',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_winCondition == WinningCondition.rounds) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _roundsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'عدد الدورات',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          if (_winCondition == WinningCondition.time) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'وقت اللعبة (بالدقائق)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 10),
          Theme(
            data: ThemeData.dark(),
            child: DropdownButtonFormField<WinCriteria>(
              initialValue: _winCriteria,
              items: WinCriteria.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c == WinCriteria.moneyOnly
                            ? 'الأكثر في فلوسه'
                            : c == WinCriteria.moneyAndStations
                            ? 'فلوسه + ثمن شراء المدن'
                            : 'فلوسه + ثمن الشراء + ثمن المباني',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _winCriteria = val!),
              decoration: InputDecoration(
                labelText: 'طريقة اختيار الفائز',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'نظام اللعب (ديون / إفلاس)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('نظام الإفلاس', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'إذا تم تفعيله: اللاعب الذي يعجز عن الدفع يخسر ويخرج.\nإذا لم يتم تفعيله: يدخل اللاعب في رصيد سالب ويكمل اللعب كـ (ديون).',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: _bankruptcyEnabled,
            onChanged: (val) => setState(() => _bankruptcyEnabled = val),
            secondary: const Icon(Icons.gavel, color: Colors.redAccent),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          if (!widget.isView) ...[
            const SizedBox(height: 40),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _startGame(true),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: AppDesign.glassDecorationWithColor(
                    Colors.blue.shade900,
                  ).copyWith(border: Border.all(color: Colors.white24)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                      SizedBox(width: 16),
                      Text(
                        'العب باستخدام القالب الديني ✨',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _startGame(false),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: AppDesign.glassDecorationWithColor(
                    Colors.blue.shade600,
                  ).copyWith(border: Border.all(color: Colors.white10)),
                  child: const Center(
                    child: Text(
                      'ابدأ اللعبة بالمدن المخصصة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final settings = BankAlHazSettings(
                  initialMoney: double.tryParse(_moneyController.text) ?? 1000,
                  salaryPerLap: double.tryParse(_salaryController.text) ?? 200,
                  winCondition: _winCondition,
                  winCriteria: _winCriteria,
                  maxRounds: int.tryParse(_roundsController.text) ?? 10,
                  maxTimeMinutes: int.tryParse(_timeController.text) ?? 30,
                  winPoints: int.tryParse(_winPointsController.text) ?? 50,
                  activeTemplateId: _selectedTemplateId,
                  bankruptcyEnabled: _bankruptcyEnabled,
                );
                await ref
                    .read(bankAlHazRepositoryProvider)
                    .saveSettings(settings);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'حفظ التغييرات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isView) return content;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('إعدادات بنك الحظ', style: AppDesign.titleStyle),
        centerTitle: true,
      ),
      body: AppDesign.backgroundWrapper(child: SafeArea(child: content)),
    );
  }

  void _createNewTemplate() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('قالب جديد', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'اسم القالب',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final repo = ref.read(bankAlHazRepositoryProvider);
      final id = await repo.saveTemplate(BankAlHazTemplate(name: name));
      
      // Import CSV for this new template
      final categories = await ref.read(categoriesProvider.future);
      final result = await BankAlHazCsvService.importFromCsv(categories);
      
      if (result.stations.isNotEmpty || result.cards.isNotEmpty) {
        for (var s in result.stations) {
          await repo.addStation(s, templateId: id);
        }
        for (var c in result.cards) {
          await repo.saveCard(c, templateId: id);
        }

        ref.invalidate(templatesProvider);
        ref.invalidate(gameSettingsProvider);
        setState(() => _selectedTemplateId = id);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('تم إنشاء قالب "$name" واستيراد ${result.stations.length + result.cards.length} عنصر')),
           );
        }
      } else {
        // If they cancelled picking file, maybe delete the template or keep it empty
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('تم إلغاء استيراد البيانات، القالب فارغ')),
           );
        }
      }
    }
  }

  void _startGame(bool isTemplate) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isTemplate) {
        final db = await DatabaseService.instance.database;
        await BankAlHazDefaultData.seed(db, force: true);
        // Re-load questions after seeding if they were added
        if (mounted) ref.invalidate(categoriesProvider);
      }

      // 2. FETCH LATEST TEAMS DIRECTLY FROM FUTURE
      if (!mounted) return;
      final freshTeams = await ref.read(teamsListProvider.future);

      if (freshTeams.isEmpty) {
        if (mounted) Navigator.pop(context); // Remove loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ لم يتم العثور على فرق. يرجى إضافة فريقين على الأقل من (الإعدادات العامة > الفرق).',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // 3. Save current settings
      final settings = BankAlHazSettings(
        initialMoney: double.tryParse(_moneyController.text) ?? 1000,
        salaryPerLap: double.tryParse(_salaryController.text) ?? 200,
        winCondition: _winCondition,
        winCriteria: _winCriteria,
        maxRounds: int.tryParse(_roundsController.text) ?? 10,
        maxTimeMinutes: int.tryParse(_timeController.text) ?? 30,
        winPoints: int.tryParse(_winPointsController.text) ?? 50,
        activeTemplateId: _selectedTemplateId,
        bankruptcyEnabled: _bankruptcyEnabled,
      );
      await ref.read(bankAlHazRepositoryProvider).saveSettings(settings);

      // Refresh providers
      ref.invalidate(stationsProvider);
      ref.invalidate(cardsProvider);
      ref.invalidate(gameEngineProvider);

      // Ensure data is fully loaded
      await Future.delayed(const Duration(milliseconds: 600));

      // Init game state with FRESH TEAMS
      final playerNames = freshTeams.map((t) => t.name).toList();
      if (!mounted) return;
      await ref
          .read(gameEngineProvider.notifier)
          .initGame(playerNames, settings);

      if (mounted) {
        Navigator.pop(context); // Remove loader
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BankAlHazBoardPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loader
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء بدء اللعبة: $e')));
      }
    }
  }

  Future<void> _handleForceSync(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد المزامنة'),
        content: const Text('سيتم استبدال قاعدة البيانات الحالية بالملف الموجود في الAssets. قد تفقد أي تعديلات قمت بها. هل تريد الاستمرار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('نعم، استبدال'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await DatabaseService.instance.forceSyncFromAssets();
        ref.invalidate(templatesProvider);
        ref.invalidate(gameSettingsProvider);
        ref.invalidate(categoriesProvider);
        _loadSettings();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت المزامنة بنجاح!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء المزامنة: $e')),
          );
        }
      }
    }
  }
}
