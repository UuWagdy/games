import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/bank_al_haz_providers.dart';
import '../providers/game_engine_provider.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import 'station_management_page.dart';
import 'card_management_page.dart';
import 'bank_al_haz_board_page.dart';
import '../providers/bank_al_haz_template_seeder.dart';

class BankAlHazSettingsPage extends ConsumerStatefulWidget {
  const BankAlHazSettingsPage({super.key});

  @override
  ConsumerState<BankAlHazSettingsPage> createState() => _BankAlHazSettingsPageState();
}

class _BankAlHazSettingsPageState extends ConsumerState<BankAlHazSettingsPage> {
  final TextEditingController _moneyController = TextEditingController(text: '1000');
  final TextEditingController _roundsController = TextEditingController(text: '10');
  
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
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات بنك الحظ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إعدادات اللعبة العامة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _moneyController,
              decoration: const InputDecoration(labelText: 'فلوس البداية (نقاط)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text('إدارة العناصر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_city),
              label: const Text('إدارة المحطات (المدن)'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StationManagementPage())),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.style),
              label: const Text('إدارة الكروت (فرصة/صندوق)'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardManagementPage())),
            ),
            const SizedBox(height: 20),
            const Text('قوانين الفوز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<WinningCondition>(
              value: _winCondition,
              items: WinningCondition.values.map((w) => DropdownMenuItem(
                value: w,
                child: Text(w == WinningCondition.rounds ? 'بعد عدد دورات معين' : w == WinningCondition.time ? 'بعد وقت معين' : 'لما تخلص أسئلة المحطات'),
              )).toList(),
              onChanged: (val) => setState(() => _winCondition = val!),
              decoration: const InputDecoration(labelText: 'شرط الفوز'),
            ),
            if (_winCondition == WinningCondition.rounds)
              TextField(
                controller: _roundsController,
                decoration: const InputDecoration(labelText: 'عدد الدورات'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 10),
            DropdownButtonFormField<WinCriteria>(
              value: _winCriteria,
              items: WinCriteria.values.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c == WinCriteria.moneyOnly ? 'الأكثر في فلوسه' : c == WinCriteria.moneyAndStations ? 'فلوسه + ثمن شراء المدن' : 'فلوسه + ثمن الشراء + ثمن المباني'),
              )).toList(),
              onChanged: (val) => setState(() => _winCriteria = val!),
              decoration: const InputDecoration(labelText: 'طريقة اختيار الفائز'),
            ),
            const SizedBox(height: 40),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome, color: Colors.amber),
              label: const Text('العب باستخدام القالب الديني ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => _startGame(true),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => _startGame(false),
              child: const Text('ابدأ اللعبة بالمدن المخصصة', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
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
        await BankAlHazTemplateSeeder(ref).seedGame();
        // Refresh to get new cities
        ref.invalidate(stationsProvider);
      }

      // 2. FETCH LATEST TEAMS DIRECTLY FROM FUTURE
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
      await ref.read(gameEngineProvider.notifier).initGame(playerNames, settings);
      
      if (mounted) {
        Navigator.pop(context); // Remove loader
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAlHazBoardPage()));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loader
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء بدء اللعبة: $e')));
      }
    }
  }
}
