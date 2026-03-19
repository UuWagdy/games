import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:games/core/database/database_service.dart';
import '../../domain/entities/bank_al_haz_entities.dart';

class BankAlHazTemplateSeeder {
  final WidgetRef ref;
  BankAlHazTemplateSeeder(this.ref);

  Future<void> seedGame() async {
    final db = await DatabaseService.instance.database;
    
    // Execute everything in ONE transaction to prevent hangs
    await db.transaction((txn) async {
      // 1. Clear existing Bank Al Haz data
      await txn.delete('bah_stations');
      await txn.delete('bah_cards');
      await txn.delete('bah_buildings');

      // 2. Create Categories & Questions
      final jerusalemOldCat = await _txnCreateCategoryAndQuestions(txn, "أورشليم (القديم)", _jerusalemOldQuestions);
      final jerusalemNewCat = await _txnCreateCategoryAndQuestions(txn, "أورشليم (الجديد)", _jerusalemNewQuestions);
      final babelCat = await _txnCreateCategoryAndQuestions(txn, "بابل", _babelQuestions);
      final egyptCat = await _txnCreateCategoryAndQuestions(txn, "مصر", _egyptQuestions);
      final jerichoCat = await _txnCreateCategoryAndQuestions(txn, "أريحا", _jerichoQuestions);
      final bethlehemCat = await _txnCreateCategoryAndQuestions(txn, "بيت لحم", _bethlehemQuestions);
      final nazarethCat = await _txnCreateCategoryAndQuestions(txn, "الناصرة", _nazarethQuestions);
      final capernaumCat = await _txnCreateCategoryAndQuestions(txn, "كفرناحوم", _capernaumQuestions);
      final bethanyCat = await _txnCreateCategoryAndQuestions(txn, "بيت عنيا", _bethanyQuestions);
      final damascusCat = await _txnCreateCategoryAndQuestions(txn, "دمشق", _damascusQuestions);
      final antiochCat = await _txnCreateCategoryAndQuestions(txn, "أنطاكية", _antiochQuestions);
      final romeCat = await _txnCreateCategoryAndQuestions(txn, "روما", _romeQuestions);

      // 3. Add Stations
      final stations = [
        const Station(id: 1, name: "البداية", type: StationType.none),
        Station(id: 2, name: "أورشليم (القديم)", buyPrice: 200, ownerCategoryId: jerusalemOldCat, passerCategoryId: jerusalemOldCat, requiresQuestion: true, type: StationType.question),
        const Station(id: 3, name: "حظك اليوم", type: StationType.card, cardType: "chance"),
        Station(id: 4, name: "بابل", buyPrice: 180, ownerCategoryId: babelCat, passerCategoryId: babelCat, requiresQuestion: true, type: StationType.question),
        Station(id: 5, name: "مصر", buyPrice: 220, ownerCategoryId: egyptCat, passerCategoryId: egyptCat, requiresQuestion: true, type: StationType.question),
        const Station(id: 6, name: "المحكمة", type: StationType.card, cardType: "chest"),
        Station(id: 7, name: "أريحا", buyPrice: 160, ownerCategoryId: jerichoCat, passerCategoryId: jerichoCat, requiresQuestion: true, type: StationType.question),
        const Station(id: 8, name: "بيت إيل", buyPrice: 140, type: StationType.property), 
        Station(id: 9, name: "حبرون", buyPrice: 150, type: StationType.property),
        Station(id: 10, name: "سدوم وعمورة", buyPrice: 130, type: StationType.property),
        
        Station(id: 11, name: "بيت لحم", buyPrice: 240, ownerCategoryId: bethlehemCat, passerCategoryId: bethlehemCat, requiresQuestion: true, type: StationType.question),
        const Station(id: 12, name: "حظك اليوم", type: StationType.card, cardType: "chance"),
        Station(id: 13, name: "الناصرة", buyPrice: 200, ownerCategoryId: nazarethCat, passerCategoryId: nazarethCat, requiresQuestion: true, type: StationType.question),
        Station(id: 14, name: "كفرناحوم", buyPrice: 220, ownerCategoryId: capernaumCat, passerCategoryId: capernaumCat, requiresQuestion: true, type: StationType.question),
        const Station(id: 15, name: "المحكمة", type: StationType.card, cardType: "chest"),
        Station(id: 16, name: "أورشليم (الجديد)", buyPrice: 300, ownerCategoryId: jerusalemNewCat, passerCategoryId: jerusalemNewCat, requiresQuestion: true, type: StationType.question),
        Station(id: 17, name: "بيت عنيا", buyPrice: 190, ownerCategoryId: bethanyCat, passerCategoryId: bethanyCat, requiresQuestion: true, type: StationType.question),
        
        Station(id: 18, name: "دمشق", buyPrice: 170, ownerCategoryId: damascusCat, passerCategoryId: damascusCat, requiresQuestion: true, type: StationType.question),
        const Station(id: 19, name: "حظك اليوم", type: StationType.card, cardType: "chance"),
        Station(id: 20, name: "أنطاكية", buyPrice: 210, ownerCategoryId: antiochCat, passerCategoryId: antiochCat, requiresQuestion: true, type: StationType.question),
        Station(id: 21, name: "روما", buyPrice: 260, ownerCategoryId: romeCat, passerCategoryId: romeCat, requiresQuestion: true, type: StationType.question),
        const Station(id: 22, name: "المحكمة", type: StationType.card, cardType: "chest"),
      ];

      for (var s in stations) {
        // Calculate a default base rent if not provided (20% of buy price)
        double rent = s.baseRent > 0 ? s.baseRent : (s.buyPrice * 0.2).floorToDouble();
        
        await txn.insert('bah_stations', {
          'id': s.id,
          'name': s.name,
          'type': s.type.name,
          'owner_category_id': s.ownerCategoryId,
          'passer_category_id': s.passerCategoryId,
          'requires_question': s.requiresQuestion ? 1 : 0,
          'card_type': s.cardType,
          'buy_price': s.buyPrice,
          'base_rent': rent,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final cards = [
        const BankAlHazCard(title: "بركة الصباح", description: "حصلت على 200 نقطة هدية", effectType: CardEffectType.addMoney, effectValue: 200, type: "chance"),
        const BankAlHazCard(title: "عشور المحاصيل", description: "ادفع 100 ثمن العشور للفقراء", effectType: CardEffectType.removeMoney, effectValue: 100, type: "chance"),
        const BankAlHazCard(title: "جولة تبشيرية", description: "اذهب إلى أنطاكية فوراً", effectValue: 0, targetStationName: "أنطاكية", effectType: CardEffectType.moveToStation, type: "chance"),
        const BankAlHazCard(title: "رحلة مقدسة", description: "اذهب إلى نقطة البداية (احصل على مكافأة المرور)", effectValue: 0, targetStationName: "البداية", effectType: CardEffectType.moveToStation, type: "chance"),
        
        const BankAlHazCard(title: "سجن فيلبي", description: "تسبيح في السجن (توقف عن اللعب دور واحد)", effectType: CardEffectType.skipTurn, effectValue: 1, type: "chest"),
        const BankAlHazCard(title: "محكمة الهيكل", description: "ادفع ضريبة للمقدس 150", effectType: CardEffectType.removeMoney, effectValue: 150, type: "chest"),
        const BankAlHazCard(title: "هدية الملوك", description: "المجوس أرسلوا لك 300", effectType: CardEffectType.addMoney, effectValue: 300, type: "chest"),
        const BankAlHazCard(title: "عجلة الزمان", description: "تحرك 3 خطوات للأمام", effectType: CardEffectType.moveSteps, effectValue: 3, type: "chest"),
      ];
      for (var c in cards) {
        await txn.insert('bah_cards', {
          'title': c.title,
          'description': c.description,
          'type': c.type,
          'effect_type': c.effectType.name,
          'effect_value': c.effectValue,
          'target_station_name': c.targetStationName,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<int> _txnCreateCategoryAndQuestions(Transaction txn, String name, List<Map<String, String>> data) async {
    // Check if category already exists to avoid duplication
    final existing = await txn.query('categories', where: 'name = ?', whereArgs: [name]);
    int catId;
    if (existing.isNotEmpty) {
      catId = existing.first['id'] as int;
      // Optionally clear existing questions for this category to prevent accumulation
      await txn.delete('question_categories', where: 'category_id = ?', whereArgs: [catId]);
    } else {
      catId = await txn.insert('categories', {'name': name});
    }

    for (var q in data) {
        // Check if question exists in this category to avoid exact duplicates
        final qText = q['q']!;
        int questionId = await txn.insert('questions', {
          'text': qText,
          'answer': q['a']!,
          'type': 'essay', // ← Changed to essay for open-ended questions
          'options_json': null, // No dummy options
          'correct_options_json': null,
          'is_multiple': 0,
        });

       await txn.insert('question_categories', {
          'question_id': questionId,
          'category_id': catId,
          'is_used': 0,
       });
    }
    return catId;
  }

  // Question Data
  final List<Map<String, String>> _jerusalemOldQuestions = [
    {'q': 'ما هي المدينة التي كانت عاصمة داود؟', 'a': 'أورشليم'},
    {'q': 'أين بُني هيكل سليمان؟', 'a': 'أورشليم'},
    {'q': 'من هو الملك الذي أخذ أورشليم من اليبوسيين؟', 'a': 'داود'},
    {'q': 'ما اسم الجبل الذي بُني عليه الهيكل؟', 'a': 'جبل المريا'},
    {'q': 'من هو النبي الذي تنبأ بخراب أورشليم؟', 'a': 'إرميا'},
    {'q': 'من الملك الذي خرب أورشليم وأخذ الشعب للسبي؟', 'a': 'نبوخذنصر'},
    {'q': 'من أعاد بناء أسوار أورشليم بعد السبي؟', 'a': 'نحميا'},
    {'q': 'ما اسم الوادي المرتبط بالدينونة بجوار أورشليم؟', 'a': 'وادي هنوم'},
    {'q': 'من الملك الذي وسع أورشليم وبنى الهيكل الثاني؟', 'a': 'هيرودس'},
    {'q': 'ماذا قال المسيح عن خراب أورشليم؟', 'a': 'لا يُترك حجر على حجر'},
  ];

  final List<Map<String, String>> _jerusalemNewQuestions = [
    {'q': 'أين صُلب السيد المسيح؟', 'a': 'أورشليم'},
    {'q': 'أين حدثت قيامة المسيح؟', 'a': 'أورشليم'},
    {'q': 'أين حوكم المسيح أمام بيلاطس؟', 'a': 'أورشليم'},
    {'q': 'في أي مدينة حدث يوم الخمسين؟', 'a': 'أورشليم'},
    {'q': 'أين كان يجتمع التلاميذ بعد القيامة؟', 'a': 'أورشليم'},
    {'q': 'أين دخل المسيح دخولاً ملوكياً؟', 'a': 'أورشليم'},
  ];

  final List<Map<String, String>> _babelQuestions = [
    {'q': 'ما المدينة التي سُبي إليها اليهود؟', 'a': 'بابل'},
    {'q': 'من الملك المرتبط ببابل؟', 'a': 'نبوخذنصر'},
    {'q': 'أين أُلقي الثلاثة فتية في الأتون؟', 'a': 'بابل'},
    {'q': 'أين عاش دانيال النبي؟', 'a': 'بابل'},
    {'q': 'ما اسم البرج المرتبط ببابل؟', 'a': 'برج بابل'},
    {'q': 'ما معنى كلمة بابل؟', 'a': 'بلبل (تشويش)'},
    {'q': 'من الملك الذي أسقط بابل؟', 'a': 'كورش الفارسي'},
    {'q': 'كم سنة استمر السبي البابلي؟', 'a': '70 سنة'},
  ];

  final List<Map<String, String>> _egyptQuestions = [
    {'q': 'في أي بلد عاش بنو إسرائيل في العبودية؟', 'a': 'مصر'},
    {'q': 'من قاد الشعب للخروج من مصر؟', 'a': 'موسى'},
    {'q': 'ما اسم البحر الذي انشق أمام الشعب؟', 'a': 'البحر الأحمر'},
    {'q': 'من النبي الذي بيع إلى مصر عبداً؟', 'a': 'يوسف'},
    {'q': 'كم عدد الضربات التي ضرب بها الله مصر؟', 'a': '10 ضربات'},
    {'q': 'أين هربت العائلة المقدسة؟', 'a': 'مصر'},
    {'q': 'ما اسم الأرض التي سكن فيها يعقوب في مصر؟', 'a': 'أرض جاسان'},
    {'q': 'كم سنة عاش بنو إسرائيل في مصر؟', 'a': 'حوالي 430 سنة'},
  ];

  final List<Map<String, String>> _jerichoQuestions = [
    {'q': 'ما أول مدينة فتحها يشوع؟', 'a': 'أريحا'},
    {'q': 'كيف سقطت أسوار أريحا؟', 'a': 'بالدوران والهتاف'},
    {'q': 'كم يوم دار الشعب حول المدينة؟', 'a': '7 أيام'},
    {'q': 'من المرأة التي ساعدت الجاسوسين؟', 'a': 'راحب'},
    {'q': 'أين سكن زكا العشار؟', 'a': 'أريحا'},
    {'q': 'ما المعنى الروحي لأريحا؟', 'a': 'رمز للخطية التي تسقط بالإيمان'},
  ];

  final List<Map<String, String>> _bethlehemQuestions = [
    {'q': 'أين وُلد المسيح؟', 'a': 'بيت لحم'},
    {'q': 'من الملك الذي وُلد في بيت لحم قديماً؟', 'a': 'داود'},
    {'q': 'ماذا تعني بيت لحم؟', 'a': 'بيت الخبز'},
    {'q': 'من زار الطفل يسوع؟', 'a': 'المجوس'},
    {'q': 'أين وُضع الطفل يسوع في ميلاده؟', 'a': 'مذود'},
    {'q': 'ما لقب بيت لحم في العهد القديم؟', 'a': 'أفراتة'},
  ];

  final List<Map<String, String>> _nazarethQuestions = [
    {'q': 'أين نشأ المسيح؟', 'a': 'الناصرة'},
    {'q': 'من بشر العذراء مريم؟', 'a': 'الملاك جبرائيل'},
    {'q': 'ماذا كان عمل يوسف النجار؟', 'a': 'نجار'},
    {'q': 'ماذا قال نثنائيل عن الناصرة؟', 'a': 'أمن الناصرة يمكن أن يكون شيء صالح؟'},
  ];

  final List<Map<String, String>> _capernaumQuestions = [
    {'q': 'ما المدينة التي كانت مركز خدمة المسيح في الجليل؟', 'a': 'كفرناحوم'},
    {'q': 'على أي بحر تقع كفرناحوم؟', 'a': 'بحر الجليل'},
    {'q': 'من التلاميذ الذين عاشوا بالقرب منها؟', 'a': 'بطرس'},
    {'q': 'أين شفى المسيح حماة بطرس؟', 'a': 'كفرناحوم'},
  ];

  final List<Map<String, String>> _bethanyQuestions = [
    {'q': 'أين عاش لعازر؟', 'a': 'بيت عنيا'},
    {'q': 'من أختا لعازر؟', 'a': 'مريم ومرثا'},
    {'q': 'ماذا فعل المسيح للعازر؟', 'a': 'أقامه من الموت'},
    {'q': 'كم يوم كان لعازر ميتاً؟', 'a': '4 أيام'},
  ];

  final List<Map<String, String>> _damascusQuestions = [
    {'q': 'أين اهتدى بولس الرسول؟', 'a': 'دمشق'},
    {'q': 'من صلى لأجل بولس في دمشق؟', 'a': 'حنانيا'},
    {'q': 'كيف هرب بولس من دمشق؟', 'a': 'في سل من السور'},
  ];

  final List<Map<String, String>> _antiochQuestions = [
    {'q': 'أين دُعي التلاميذ مسيحيين أولاً؟', 'a': 'أنطاكية'},
    {'q': 'من كرز هناك مع بولس؟', 'a': 'برنابا'},
  ];

  final List<Map<String, String>> _romeQuestions = [
    {'q': 'ما عاصمة الإمبراطورية الرومانية؟', 'a': 'روما'},
    {'q': 'من كتب رسالة إلى أهل روما؟', 'a': 'بولس'},
    {'q': 'كيف ذهب بولس إلى روما؟', 'a': 'كأسير'},
  ];
}
