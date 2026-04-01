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
import 'templates_management_page.dart';
import 'bank_al_haz_board_page.dart';
import '../../data/sources/bank_al_haz_default_data.dart';
import '../../data/sources/bank_al_haz_csv_service.dart';
import 'package:games/core/database/database_service.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import '../../../../questions/presentation/providers/question_providers.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/core/design/themed_background.dart';


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
  final TextEditingController _loanDurationController = TextEditingController(
    text: '5',
  );
  final TextEditingController _maxLoanAmountController = TextEditingController(
    text: '2000',
  );
  final TextEditingController _loanInterestController = TextEditingController(
    text: '20',
  );
  final TextEditingController _loanPenaltyController = TextEditingController(
    text: '4',
  );
  final TextEditingController _checkInterestController = TextEditingController(
    text: '5',
  );
  final TextEditingController _checkIncrementController = TextEditingController(
    text: '0',
  );
  final TextEditingController _minCertAmountController = TextEditingController(
    text: '500',
  );
  final TextEditingController _certInterestController = TextEditingController(
    text: '25',
  );
  final TextEditingController _certCyclesController = TextEditingController(
    text: '3',
  );
  final TextEditingController _inflationIntervalController =
      TextEditingController(text: '5');
  final TextEditingController _inflationRateController = TextEditingController(
    text: '5',
  );

  WinningCondition _winCondition = WinningCondition.rounds;
  WinCriteria _winCriteria = WinCriteria.moneyOnly;
  int? _selectedTemplateId;
  bool _bankruptcyEnabled = false;
  bool _loansEnabled = false;
  bool _checksEnabled = false;
  bool _certificatesEnabled = false;
  CertificatePayoutMode _certPayoutMode = CertificatePayoutMode.perCycle;
  bool _inflationEnabled = false;
  bool _allowLoanRefinancing = false;
  BankAlHazTaxMode _taxMode = BankAlHazTaxMode.custom;
  bool _turnTimerEnabled = false;
  final TextEditingController _turnTimerSecondsController = TextEditingController(text: '30');

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
      _loansEnabled = settings.loansEnabled;
      _allowLoanRefinancing = settings.allowLoanRefinancing;
      _taxMode = settings.taxMode;
      _loanDurationController.text = settings.maxLoanDurationTurns.toString();
      _maxLoanAmountController.text = settings.maxLoanAmount.toInt().toString();
      _loanInterestController.text = (settings.loanInterestRate * 100)
          .toInt()
          .toString();
      _loanPenaltyController.text = (settings.loanInterestPenalty * 100)
          .toInt()
          .toString();
      _checksEnabled = settings.checksEnabled;
      _checkInterestController.text = (settings.checkInterestRate * 100)
          .toInt()
          .toString();
      _checkIncrementController.text = (settings.checkInterestIncrement * 100)
          .toInt()
          .toString();
      _certificatesEnabled = settings.certificatesEnabled;
      _minCertAmountController.text = settings.minCertificateAmount
          .toInt()
          .toString();
      _certInterestController.text = (settings.certificateInterestRate * 100)
          .toInt()
          .toString();
      _certCyclesController.text = settings.certificateCycles.toString();
      _certPayoutMode = settings.certificatePayoutMode;
      _inflationEnabled = settings.inflationEnabled;
      _inflationIntervalController.text = settings.inflationIntervalMinutes
          .toString();
      _inflationRateController.text = (settings.inflationRate * 100)
          .toInt()
          .toString();
      _turnTimerEnabled = settings.turnTimerEnabled;
      _turnTimerSecondsController.text = settings.turnTimerSeconds.toString();
    });
  }


  Widget _buildTurnTimerSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("تفعيل مؤقت الدور لكل لاعب", style: TextStyle(color: Colors.white, fontSize: 16)),
            subtitle: const Text("سيتم انهاء الدور تلقائياً عند انتهاء الوقت", style: TextStyle(color: Colors.white38, fontSize: 12)),
            value: _turnTimerEnabled,
            activeColor: Colors.amberAccent,
            onChanged: (val) => setState(() => _turnTimerEnabled = val),
            contentPadding: EdgeInsets.zero,
          ),
          if (_turnTimerEnabled) ...[
             const SizedBox(height: 12),
             TextField(
                controller: _turnTimerSecondsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'عدد الثواني لكل دور',
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
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;

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
                                items: templates
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t.id,
                                        child: Text(t.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() => _selectedTemplateId = val);
                                },
                                decoration: InputDecoration(
                                  labelText: 'القالب النشط',
                                  labelStyle: const TextStyle(
                                    color: Colors.white60,
                                  ),
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
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.blueAccent,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TemplatesManagementPage(),
                              ),
                            ),
                            tooltip: 'إدارة القوالب (تعديل، حذف، إنشاء)',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.amberAccent,
                            ),
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
                      Text(
                        'خطأ في تحميل القوالب: $e',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'برجاء الضغط على زر "مزامنة من الAssets" أعلاه لإصلاح هذا الخطأ.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
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
          _sectionHeader("إعدادات وقت الدور", Icons.timer_outlined),
          _buildTurnTimerSettings(),
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
            title: const Text(
              'نظام الإفلاس',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'إذا تم تفعيله: اللاعب الذي يعجز عن الدفع يخسر ويخرج.\nإذا لم يتم تفعيله: يدخل اللاعب في رصيد سالب ويكمل اللعب كـ (ديون).',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: _bankruptcyEnabled,
            onChanged: (val) => setState(() => _bankruptcyEnabled = val),
            secondary: const Icon(Icons.gavel, color: Colors.redAccent),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text(
              'نظام القروض البنكية',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'إذا تم تفعيله: يمكن للاعب أخذ قرض من البنك وسداده خلال وقت معين بفائدة.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: _loansEnabled,
            onChanged: (val) => setState(() => _loansEnabled = val),
            secondary: const Icon(
              Icons.account_balance,
              color: Colors.cyanAccent,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (_loansEnabled) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _loanDurationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الحد الأقصى لزيادة القرض (عدد الأدوار)',
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
              controller: _maxLoanAmountController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الحد الأقصى لمبلغ القرض',
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
              controller: _loanInterestController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'نسبة الفائدة (%)',
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
              controller: _loanPenaltyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'زيادة الفائدة لكل قرض إضافي (%)',
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
            SwitchListTile(
              title: const Text(
                'سداد قرض بقرض أخر',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'هل تسمح للاعب بأخذ قرض جديد لسداد القديم أو استخدامه وهو مدين؟',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _allowLoanRefinancing,
              onChanged: (val) => setState(() => _allowLoanRefinancing = val),
              secondary: const Icon(Icons.cached, color: Colors.amberAccent),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          const Divider(color: Colors.white10),
          SwitchListTile(
            title: const Text(
              'نظام الشيكات (تسليف لاعبين)',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'إذا تم تفعيله: يمكن للاعبين تسليف بعضهم البعض بفايدة للبنك.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: _checksEnabled,
            onChanged: (val) => setState(() => _checksEnabled = val),
            secondary: const Icon(
              Icons.request_quote_rounded,
              color: Colors.greenAccent,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (_checksEnabled) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _checkInterestController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'نسبة الفائدة للبنك (%)',
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
              controller: _checkIncrementController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الزيادة في الفائدة مع كل شيك (%)',
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
          const Divider(color: Colors.white10),
          const Text(
            'نظام الشهايد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text(
              'تفعيل نظام الشهايد',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'تمكن اللاعبين من استثمار أموالهم في شهايد بنكية بفايدة دورية.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: _certificatesEnabled,
            onChanged: (val) => setState(() => _certificatesEnabled = val),
            secondary: const Icon(
              Icons.card_membership,
              color: Colors.orangeAccent,
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (_certificatesEnabled) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _minCertAmountController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الحد الأدنى للشهادة',
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
              controller: _certInterestController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'نسبة الفائدة (%)',
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
              controller: _certCyclesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'عدد الدورات لاسترداد الشهادة',
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
            Theme(
              data: ThemeData.dark(),
              child: DropdownButtonFormField<CertificatePayoutMode>(
                value: _certPayoutMode,
                items: const [
                  DropdownMenuItem(
                    value: CertificatePayoutMode.perStation,
                    child: Text('بعد كل مدينة/محطة'),
                  ),
                  DropdownMenuItem(
                    value: CertificatePayoutMode.perCycle,
                    child: Text('بعد كل دورة (لفه كاملة)'),
                  ),
                ],
                onChanged: (val) => setState(() => _certPayoutMode = val!),
                decoration: InputDecoration(
                  labelText: 'توقيت صرف الفائدة',
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
          ],
          const Divider(color: Colors.white10),
          const Text(
            'نظام التضخم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text(
              'تفعيل نظام التضخم',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'كل فترة زمنية، ترتفع جميع الأسعار والفوائد والضرائب تلقائياً.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: _inflationEnabled,
            onChanged: (val) => setState(() => _inflationEnabled = val),
            secondary: const Icon(Icons.trending_up, color: Colors.redAccent),
            contentPadding: EdgeInsets.zero,
          ),
          if (_inflationEnabled) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _inflationIntervalController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الوقت بين كل زيادة (بالدقائق)',
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
              controller: _inflationRateController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'نسبة الزيادة (%)',
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

          const SizedBox(height: 20),
          const Text(
            'نظام ضرائب المرور',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _buildTaxModeOption(
                  label: 'مخصص',
                  mode: BankAlHazTaxMode.custom,
                  subtitle: 'حسب إعداد كل محطة',
                ),
                _buildTaxModeOption(
                  label: 'تفعيل للكل',
                  mode: BankAlHazTaxMode.all,
                  subtitle: 'الكل يدفع ضرائب',
                ),
                _buildTaxModeOption(
                  label: 'إلغاء للكل',
                  mode: BankAlHazTaxMode.none,
                  subtitle: 'لا ضرائب مرور',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!widget.isView) ...[
            ref
                .watch(savedGameExistsProvider)
                .when(
                  data: (exists) => exists
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BankAlHazBoardPage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                decoration:
                                    AppDesign.glassDecorationWithColor(
                                      Colors.greenAccent.shade700,
                                    ).copyWith(
                                      border: Border.all(color: Colors.white24),
                                    ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'استكمال اللعبة السابقة',
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
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            const SizedBox(height: 12),
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
                        'العب باستخدام القالب الحالي ✨',
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
                  initialMoney: double.tryParse(_moneyController.text) ?? 1500,
                  salaryPerLap: double.tryParse(_salaryController.text) ?? 200,
                  winCondition: _winCondition,
                  winCriteria: _winCriteria,
                  maxRounds: int.tryParse(_roundsController.text) ?? 10,
                  maxTimeMinutes: int.tryParse(_timeController.text) ?? 30,
                  winPoints: int.tryParse(_winPointsController.text) ?? 50,
                  activeTemplateId: _selectedTemplateId,
                  bankruptcyEnabled: _bankruptcyEnabled,
                  loansEnabled: _loansEnabled,
                  maxLoanDurationTurns:
                      int.tryParse(_loanDurationController.text) ?? 5,
                  maxLoanAmount:
                      double.tryParse(_maxLoanAmountController.text) ?? 2000,
                  loanInterestRate:
                      (double.tryParse(_loanInterestController.text) ?? 20) /
                      100,
                  loanInterestPenalty:
                      (double.tryParse(_loanPenaltyController.text) ?? 4) / 100,
                  allowLoanRefinancing: _allowLoanRefinancing,
                  checksEnabled: _checksEnabled,
                  checkInterestRate:
                      (double.tryParse(_checkInterestController.text) ?? 5) /
                      100,
                  checkInterestIncrement:
                      (double.tryParse(_checkIncrementController.text) ?? 0) /
                      100,
                  certificatesEnabled: _certificatesEnabled,
                  minCertificateAmount:
                      double.tryParse(_minCertAmountController.text) ?? 500,
                  certificateInterestRate:
                      (double.tryParse(_certInterestController.text) ?? 25) /
                      100,
                  certificateCycles:
                      int.tryParse(_certCyclesController.text) ?? 3,
                  certificatePayoutMode: _certPayoutMode,
                  inflationEnabled: _inflationEnabled,
                  inflationIntervalMinutes:
                      int.tryParse(_inflationIntervalController.text) ?? 5,
                  inflationRate:
                      (double.tryParse(_inflationRateController.text) ?? 5) /
                      100,
                  taxMode: _taxMode,
                  turnTimerEnabled: _turnTimerEnabled,
                  turnTimerSeconds: int.tryParse(_turnTimerSecondsController.text) ?? 30,
                );
                await ref
                    .read(bankAlHazRepositoryProvider)
                    .saveSettings(settings);
                // Sync with general settings
                await ref.read(generalSettingsProvider.notifier).setBankAlHazWinPoints(settings.winPoints);
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
      body: ThemedBackground(child: SafeArea(child: content)),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
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
            SnackBar(
              content: Text(
                'تم إنشاء قالب "$name" واستيراد ${result.stations.length + result.cards.length} عنصر',
              ),
            ),
          );
        }
      } else {
        // If they cancelled picking file, maybe delete the template or keep it empty
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء استيراد البيانات، القالب فارغ'),
            ),
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
        initialMoney: double.tryParse(_moneyController.text) ?? 1500,
        salaryPerLap: double.tryParse(_salaryController.text) ?? 200,
        winCondition: _winCondition,
        winCriteria: _winCriteria,
        maxRounds: int.tryParse(_roundsController.text) ?? 10,
        maxTimeMinutes: int.tryParse(_timeController.text) ?? 30,
        winPoints: int.tryParse(_winPointsController.text) ?? 50,
        activeTemplateId: _selectedTemplateId,
        bankruptcyEnabled: _bankruptcyEnabled,
        loansEnabled: _loansEnabled,
        maxLoanDurationTurns: int.tryParse(_loanDurationController.text) ?? 5,
        maxLoanAmount: double.tryParse(_maxLoanAmountController.text) ?? 2000,
        loanInterestRate:
            (double.tryParse(_loanInterestController.text) ?? 20) / 100,
        loanInterestPenalty:
            (double.tryParse(_loanPenaltyController.text) ?? 4) / 100,
        allowLoanRefinancing: _allowLoanRefinancing,
        checksEnabled: _checksEnabled,
        checkInterestRate:
            (double.tryParse(_checkInterestController.text) ?? 5) / 100,
        checkInterestIncrement:
            (double.tryParse(_checkIncrementController.text) ?? 0) / 100,
        certificatesEnabled: _certificatesEnabled,
        minCertificateAmount:
            double.tryParse(_minCertAmountController.text) ?? 500,
        certificateInterestRate:
            (double.tryParse(_certInterestController.text) ?? 25) / 100,
        certificateCycles: int.tryParse(_certCyclesController.text) ?? 3,
        certificatePayoutMode: _certPayoutMode,
        inflationEnabled: _inflationEnabled,
        inflationIntervalMinutes:
            int.tryParse(_inflationIntervalController.text) ?? 5,
        inflationRate:
            (double.tryParse(_inflationRateController.text) ?? 5) / 100,
        taxMode: _taxMode,
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
        content: const Text(
          'سيتم استبدال قاعدة البيانات الحالية بالملف الموجود في الAssets. قد تفقد أي تعديلات قمت بها. هل تريد الاستمرار؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تمت المزامنة بنجاح!')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ أثناء المزامنة: $e')));
        }
      }
    }
  }

  Widget _buildTaxModeOption({
    required String label,
    required String subtitle,
    required BankAlHazTaxMode mode,
  }) {
    final bool isSelected = _taxMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _taxMode = mode),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.amberAccent.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.amberAccent : Colors.white10,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.amberAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected
                      ? Colors.amberAccent.withOpacity(0.6)
                      : Colors.white38,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
