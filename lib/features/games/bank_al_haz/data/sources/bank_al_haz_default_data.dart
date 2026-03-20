import 'package:sqflite/sqflite.dart';
import '../../domain/entities/bank_al_haz_entities.dart';

class BankAlHazDefaultData {
  static Future<void> seed(
    Database db, {
    bool force = false,
    int templateId = 1,
  }) async {
    // Ensure the template record exists in bah_templates before seeding its stations/cards
    await db.insert('bah_templates', {
      'id': templateId,
      'name': 'القالب الديني (إفتراضي)',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1. Check if already seeded to avoid duplicates on every upgrade if not needed
    if (!force) {
      final existingStations = await db.query(
        'bah_stations',
        where: 'template_id = ?',
        whereArgs: [templateId],
        limit: 1,
      );
      if (existingStations.isNotEmpty) return;
    }

    await db.transaction((txn) async {
      // 2. Clear existing Bank Al Haz data for this template if forcing
      if (force) {
        await txn.delete(
          'bah_stations',
          where: 'template_id = ?',
          whereArgs: [templateId],
        );
        await txn.delete(
          'bah_cards',
          where: 'template_id = ?',
          whereArgs: [templateId],
        );
        await txn.delete('bah_buildings');
      }
      // 2. Create Categories & Questions
      final jerusalemOldCat = await _txnCreateCategoryAndQuestions(
        txn,
        "أورشليم (القديم)",
        _jerusalemOldQuestions,
      );
      final jerusalemNewCat = await _txnCreateCategoryAndQuestions(
        txn,
        "أورشليم (الجديد)",
        _jerusalemNewQuestions,
      );
      final babelCat = await _txnCreateCategoryAndQuestions(
        txn,
        "بابل",
        _babelQuestions,
      );
      final egyptCat = await _txnCreateCategoryAndQuestions(
        txn,
        "مصر",
        _egyptQuestions,
      );
      final jerichoCat = await _txnCreateCategoryAndQuestions(
        txn,
        "أريحا",
        _jerichoQuestions,
      );
      final bethlehemCat = await _txnCreateCategoryAndQuestions(
        txn,
        "بيت لحم",
        _bethlehemQuestions,
      );
      final nazarethCat = await _txnCreateCategoryAndQuestions(
        txn,
        "الناصرة",
        _nazarethQuestions,
      );
      final capernaumCat = await _txnCreateCategoryAndQuestions(
        txn,
        "كفرناحوم",
        _capernaumQuestions,
      );
      final bethanyCat = await _txnCreateCategoryAndQuestions(
        txn,
        "بيت عنيا",
        _bethanyQuestions,
      );
      final damascusCat = await _txnCreateCategoryAndQuestions(
        txn,
        "دمشق",
        _damascusQuestions,
      );
      final antiochCat = await _txnCreateCategoryAndQuestions(
        txn,
        "أنطاكية",
        _antiochQuestions,
      );
      final romeCat = await _txnCreateCategoryAndQuestions(
        txn,
        "روما",
        _romeQuestions,
      );

      // 3. Add Stations
      final stations = [
        const Station(
          id: 1,
          name: "البداية",
          type: StationType.none,
          allowsTax: false,
        ),
        Station(
          id: 2,
          name: "أورشليم(ق)",
          buyPrice: 200,
          ownerCategoryId: jerusalemOldCat,
          passerCategoryId: jerusalemOldCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "الهيكل", buyPrice: 300, additionalRent: 150),
            const Building(
              name: "خيمة الاجتماع",
              buyPrice: 200,
              additionalRent: 100,
            ),
          ],
        ),
        const Station(
          id: 3,
          name: "حظك اليوم",
          type: StationType.card,
          cardType: "chance",
        ),
        Station(
          id: 4,
          name: "بابل",
          buyPrice: 180,
          ownerCategoryId: babelCat,
          passerCategoryId: babelCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
        ),
        Station(
          id: 5,
          name: "مصر",
          buyPrice: 220,
          ownerCategoryId: egyptCat,
          passerCategoryId: egyptCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
        ),
        const Station(
          id: 6,
          name: "المحكمة",
          type: StationType.card,
          cardType: "chest",
        ),
        Station(
          id: 7,
          name: "أريحا",
          buyPrice: 160,
          ownerCategoryId: jerichoCat,
          passerCategoryId: jerichoCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
        ),
        const Station(
          id: 8,
          name: "بيت إيل",
          buyPrice: 140,
          type: StationType.property,
          era: Era.oldTestament,
        ),
        Station(
          id: 9,
          name: "حبرون",
          buyPrice: 150,
          type: StationType.property,
          era: Era.oldTestament,
        ),
        Station(
          id: 10,
          name: "سدوم وعمورة",
          buyPrice: 130,
          type: StationType.property,
          era: Era.oldTestament,
        ),

        Station(
          id: 11,
          name: "بيت لحم",
          buyPrice: 240,
          ownerCategoryId: bethlehemCat,
          passerCategoryId: bethlehemCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        const Station(
          id: 12,
          name: "حظك اليوم",
          type: StationType.card,
          cardType: "chance",
        ),
        Station(
          id: 13,
          name: "الناصرة",
          buyPrice: 200,
          ownerCategoryId: nazarethCat,
          passerCategoryId: nazarethCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 14,
          name: "كفرناحوم",
          buyPrice: 220,
          ownerCategoryId: capernaumCat,
          passerCategoryId: capernaumCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        const Station(
          id: 15,
          name: "المحكمة",
          type: StationType.card,
          cardType: "chest",
        ),
        Station(
          id: 16,
          name: "أورشليم(ج)",
          buyPrice: 300,
          ownerCategoryId: jerusalemNewCat,
          passerCategoryId: jerusalemNewCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 17,
          name: "بيت عنيا",
          buyPrice: 190,
          ownerCategoryId: bethanyCat,
          passerCategoryId: bethanyCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),

        Station(
          id: 18,
          name: "دمشق",
          buyPrice: 170,
          ownerCategoryId: damascusCat,
          passerCategoryId: damascusCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        const Station(
          id: 19,
          name: "حظك اليوم",
          type: StationType.card,
          cardType: "chance",
        ),
        Station(
          id: 20,
          name: "أنطاكية",
          buyPrice: 210,
          ownerCategoryId: antiochCat,
          passerCategoryId: antiochCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 21,
          name: "روما",
          buyPrice: 260,
          ownerCategoryId: romeCat,
          passerCategoryId: romeCat,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(
              name: "دير",
              buyPrice: 200,
              additionalRent: 100,
            ),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        const Station(
          id: 22,
          name: "المحكمة",
          type: StationType.card,
          cardType: "chest",
        ),
      ];

      for (var s in stations) {
        double rent = s.baseRent > 0
            ? s.baseRent
            : (s.buyPrice * 0.2).floorToDouble();

        int stationId = await txn.insert('bah_stations', {
          'id': s.id,
          'name': s.name,
          'type': s.type.name,
          'owner_category_id': s.ownerCategoryId,
          'passer_category_id': s.passerCategoryId,
          'requires_question': s.requiresQuestion ? 1 : 0,
          'card_type': s.cardType,
          'buy_price': s.buyPrice,
          'base_rent': rent,
          'template_id': templateId,
          'era': s.era.name,
          'has_tax': s.hasTax ? 1 : 0,
          'tax_amount': s.taxAmount,
          'allows_tax': s.allowsTax ? 1 : 0,
          'is_unbuyable': s.isUnbuyable ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (var b in s.buildings) {
          await txn.insert('bah_buildings', {
            'station_id': stationId,
            'name': b.name,
            'buy_price': b.buyPrice,
            'additional_rent': b.additionalRent,
            'is_purchased': 0,
          });
        }
      }

      final cards = [
        const BankAlHazCard(
          title: "بركة الصباح",
          description: "حصلت على 200 نقطة هدية",
          effectType: CardEffectType.addMoney,
          effectValue: 200,
          type: "chance",
        ),
        const BankAlHazCard(
          title: "عشور المحاصيل",
          description: "ادفع 100 ثمن العشور للفقراء",
          effectType: CardEffectType.removeMoney,
          effectValue: 100,
          type: "chance",
        ),
        const BankAlHazCard(
          title: "جولة تبشيرية",
          description: "اذهب إلى أنطاكية فوراً",
          effectValue: 0,
          targetStationName: "أنطاكية",
          effectType: CardEffectType.moveToStation,
          type: "chance",
        ),
        const BankAlHazCard(
          title: "رحلة مقدسة",
          description: "اذهب إلى نقطة البداية (احصل على مكافأة المرور)",
          effectValue: 0,
          targetStationName: "البداية",
          effectType: CardEffectType.moveToStation,
          type: "chance",
        ),

        const BankAlHazCard(
          title: "سجن فيلبي",
          description: "تسبيح في السجن (توقف عن اللعب دور واحد)",
          effectType: CardEffectType.skipTurn,
          effectValue: 1,
          type: "chest",
        ),
        const BankAlHazCard(
          title: "محكمة الهيكل",
          description: "ادفع ضريبة للمقدس 150",
          effectType: CardEffectType.removeMoney,
          effectValue: 150,
          type: "chest",
        ),
        const BankAlHazCard(
          title: "هدية الملوك",
          description: "المجوس أرسلوا لك 300",
          effectType: CardEffectType.addMoney,
          effectValue: 300,
          type: "chest",
        ),
        const BankAlHazCard(
          title: "عجلة الزمان",
          description: "تحرك 3 خطوات للأمام",
          effectType: CardEffectType.moveSteps,
          effectValue: 3,
          type: "chest",
        ),
      ];
      for (var c in cards) {
        await txn.insert('bah_cards', {
          'title': c.title,
          'description': c.description,
          'type': c.type,
          'effect_type': c.effectType.name,
          'effect_value': c.effectValue,
          'target_station_name': c.targetStationName,
          'template_id': templateId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<int> _txnCreateCategoryAndQuestions(
    Transaction txn,
    String name,
    List<Map<String, String>> data,
  ) async {
    final existing = await txn.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    int catId;
    if (existing.isNotEmpty) {
      catId = existing.first['id'] as int;
    } else {
      catId = await txn.insert('categories', {'name': name});
    }

    for (var q in data) {
      final qText = q['q']!;
      final existingQ = await txn.query(
        'questions',
        where: 'text = ?',
        whereArgs: [qText],
      );
      if (existingQ.isNotEmpty) continue;

      int questionId = await txn.insert('questions', {
        'text': qText,
        'answer': q['a']!,
        'type': 'essay',
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

  // Question Data (Truncated for brevity, but I should include enough)
  static final List<Map<String, String>> _jerusalemOldQuestions = [
    {'q': 'ما هي المدينة التي كانت عاصمة داود؟', 'a': 'أورشليم'},
    {'q': 'أين بُني هيكل سليمان؟', 'a': 'أورشليم'},
  ];
  static final List<Map<String, String>> _jerusalemNewQuestions = [
    {'q': 'أين صُلب السيد المسيح؟', 'a': 'أورشليم'},
    {'q': 'أين حدثت قيامة المسيح؟', 'a': 'أورشليم'},
  ];
  static final List<Map<String, String>> _babelQuestions = [
    {'q': 'ما المدينة التي سُبي إليها اليهود؟', 'a': 'بابل'},
    {'q': 'من الملك المرتبط ببابل؟', 'a': 'نبوخذنصر'},
  ];
  static final List<Map<String, String>> _egyptQuestions = [
    {'q': 'في أي بلد عاش بنو إسرائيل في العبودية؟', 'a': 'مصر'},
    {'q': 'من قاد الشعب للخروج من مصر؟', 'a': 'موسى'},
  ];
  static final List<Map<String, String>> _jerichoQuestions = [
    {'q': 'ما أول مدينة فتحها يشوع؟', 'a': 'أريحا'},
    {'q': 'كيف سقطت أسوار أريحا؟', 'a': 'بالدوران والهتاف'},
  ];
  static final List<Map<String, String>> _bethlehemQuestions = [
    {'q': 'أين وُلد المسيح؟', 'a': 'بيت لحم'},
    {'q': 'ماذا تعني بيت لحم؟', 'a': 'بيت الخبز'},
  ];
  static final List<Map<String, String>> _nazarethQuestions = [
    {'q': 'أين نشأ المسيح؟', 'a': 'الناصرة'},
    {'q': 'من بشر العذراء مريم؟', 'a': 'الملاك جبرائيل'},
  ];
  static final List<Map<String, String>> _capernaumQuestions = [
    {'q': 'ما المدينة التي كانت مركز خدمة المسيح في الجليل؟', 'a': 'كفرناحوم'},
    {'q': 'على أي بحر تقع كفرناحوم؟', 'a': 'بحر الجليل'},
  ];
  static final List<Map<String, String>> _bethanyQuestions = [
    {'q': 'أين عاش لعازر؟', 'a': 'بيت عنيا'},
    {'q': 'من أختا لعازر؟', 'a': 'مريم ومرثا'},
  ];
  static final List<Map<String, String>> _damascusQuestions = [
    {'q': 'أين اهتدى بولس الرسول؟', 'a': 'دمشق'},
    {'q': 'من صلى لأجل بولس في دمشق؟', 'a': 'حنانيا'},
  ];
  static final List<Map<String, String>> _antiochQuestions = [
    {'q': 'أين دُعي التلاميذ مسيحيين أولاً؟', 'a': 'أنطاكية'},
    {'q': 'من كرز هناك مع بولس؟', 'a': 'برنابا'},
  ];
  static final List<Map<String, String>> _romeQuestions = [
    {'q': 'ما عاصمة الإمبراطورية الرومانية؟', 'a': 'روما'},
    {'q': 'من كتب رسالة إلى أهل روما؟', 'a': 'بولس'},
  ];
}
