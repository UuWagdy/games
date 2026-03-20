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
import '../providers/bank_al_haz_template_seeder.dart';

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

  WinningCondition _winCondition = WinningCondition.rounds;
  WinCriteria _winCriteria = WinCriteria.moneyOnly;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(gameSettingsProvider.future);
    _moneyController.text = settings.initialMoney.toString();
    _roundsController.text = settings.maxRounds.toString();
    setState(() {
      _winCondition = settings.winCondition;
      _winCriteria = settings.winCriteria;
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
              initialValue: _winCondition,
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
                  winCondition: _winCondition,
                  winCriteria: _winCriteria,
                  maxRounds: int.tryParse(_roundsController.text) ?? 10,
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

  void _startGame(bool isTemplate) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isTemplate) {
        // 1. Seed the religious template FIRST to ensure we have cities
        await BankAlHazTemplateSeeder().seedGame();
        // Refresh to get new cities
        if (mounted) ref.invalidate(stationsProvider);
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
        winCondition: _winCondition,
        winCriteria: _winCriteria,
        maxRounds: int.tryParse(_roundsController.text) ?? 10,
      );
      await ref.read(bankAlHazRepositoryProvider).saveSettings(settings);

      // Refresh providers
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
}
