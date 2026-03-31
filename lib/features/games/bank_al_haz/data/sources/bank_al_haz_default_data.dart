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

      // 3. Create/Link Categories (Owner/Passerby)
      // We look for existing categories first to avoid duplicates
      Future<int?> findOrLinkCategory(String name, List<Map<String, String>> defaultData) async {
        // Try exact match
        final existing = await txn.query('categories', where: 'name = ?', whereArgs: [name], limit: 1);
        if (existing.isNotEmpty) return existing.first['id'] as int;
        
        // Try base name match (e.g. "أريحا" instead of "أريحا - مالك")
        final baseName = name.split(' - ').first;
        final baseMatch = await txn.query('categories', where: 'name = ?', whereArgs: [baseName], limit: 1);
        if (baseMatch.isNotEmpty) return baseMatch.first['id'] as int;

        // If no default data and no existing match, return null to avoid creating empty categories
        if (defaultData.isEmpty) return null;

        // Otherwise create it
        return await _txnCreateCategoryAndQuestions(txn, name, defaultData);
      }

      // Old Testament Cities
      final jerusalemOldOwner = await findOrLinkCategory("أورشليم (ق) - مالك", _jerusalemOldQuestions);
      final jerusalemOldPasser = await findOrLinkCategory("أورشليم (ق) - عابر", _jerusalemOldQuestions);
      
      final babelOwner = await findOrLinkCategory("بابل - مالك", _babelQuestions);
      final babelPasser = await findOrLinkCategory("بابل - عابر", _babelQuestions);
      
      final egyptOwner = await findOrLinkCategory("مصر - مالك", _egyptQuestions);
      final egyptPasser = await findOrLinkCategory("مصر - عابر", _egyptQuestions);
      
      final jerichoOwner = await findOrLinkCategory("أريحا - مالك", _jerichoQuestions);
      final jerichoPasser = await findOrLinkCategory("أريحا - عابر", _jerichoQuestions);
      
      final hebronOwner = await findOrLinkCategory("حبرون - مالك", _hebronQuestions);
      final hebronPasser = await findOrLinkCategory("حبرون - عابر", _hebronQuestions);
      
      final sodomOwner = await findOrLinkCategory("سدوم وعمورة - مالك", _sodomQuestions);
      final sodomPasser = await findOrLinkCategory("سدوم وعمورة - عابر", _sodomQuestions);
      
      final beitElOwner = await findOrLinkCategory("بيت إيل - مالك", _beitElQuestions);
      final beitElPasser = await findOrLinkCategory("بيت إيل - عابر", _beitElQuestions);

      // New Testament Cities
      final jerusalemNewOwner = await findOrLinkCategory("أورشليم (ج) - مالك", _jerusalemNewQuestions);
      final jerusalemNewPasser = await findOrLinkCategory("أورشليم (ج) - عابر", _jerusalemNewQuestions);

      final bethlehemOwner = await findOrLinkCategory("بيت لحم - مالك", _bethlehemQuestions);
      final bethlehemPasser = await findOrLinkCategory("بيت لحم - عابر", _bethlehemQuestions);

      final nazarethOwner = await findOrLinkCategory("الناصرة - مالك", _nazarethQuestions);
      final nazarethPasser = await findOrLinkCategory("الناصرة - عابر", _nazarethQuestions);

      final capernaumOwner = await findOrLinkCategory("كفرناحوم - مالك", _capernaumQuestions);
      final capernaumPasser = await findOrLinkCategory("كفرناحوم - عابر", _capernaumQuestions);

      final bethanyOwner = await findOrLinkCategory("بيت عنيا - مالك", _bethanyQuestions);
      final bethanyPasser = await findOrLinkCategory("بيت عنيا - عابر", _bethanyQuestions);

      final damascusOwner = await findOrLinkCategory("دمشق - مالك", _damascusQuestions);
      final damascusPasser = await findOrLinkCategory("دمشق - عابر", _damascusQuestions);

      final antiochOwner = await findOrLinkCategory("أنطاكية - مالك", _antiochQuestions);
      final antiochPasser = await findOrLinkCategory("أنطاكية - عابر", _antiochQuestions);

      final romeOwner = await findOrLinkCategory("روما - مالك", _romeQuestions);
      final romePasser = await findOrLinkCategory("روما - عابر", _romeQuestions);


      // 4. Add Stations
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
          ownerCategoryId: jerusalemOldOwner,
          passerCategoryId: jerusalemOldPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "الهيكل", buyPrice: 300, additionalRent: 150),
            const Building(name: "خيمة الاجتماع", buyPrice: 200, additionalRent: 100),
            const Building(name: "المجمع اليهودي", buyPrice: 100, additionalRent: 50),
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
          ownerCategoryId: babelOwner,
          passerCategoryId: babelPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "المجمع اليهودي", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 5,
          name: "مصر",
          buyPrice: 220,
          ownerCategoryId: egyptOwner,
          passerCategoryId: egyptPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "المجمع اليهودي", buyPrice: 100, additionalRent: 50),
          ],
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
          ownerCategoryId: jerichoOwner,
          passerCategoryId: jerichoPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "المجمع اليهودي", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 8,
          name: "بيت إيل",
          buyPrice: 140,
          ownerCategoryId: beitElOwner,
          passerCategoryId: beitElPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "المجمع اليهودي", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 9,
          name: "حبرون",
          buyPrice: 150,
          ownerCategoryId: hebronOwner,
          passerCategoryId: hebronPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "المجمع اليهودي", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 10,
          name: "سدوم وعمورة",
          buyPrice: 130,
          ownerCategoryId: sodomOwner,
          passerCategoryId: sodomPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.oldTestament,
          buildings: [
            const Building(name: "المجمع اليهودي", buyPrice: 100, additionalRent: 50),
          ],
        ),

        Station(
          id: 11,
          name: "بيت لحم",
          buyPrice: 240,
          ownerCategoryId: bethlehemOwner,
          passerCategoryId: bethlehemPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
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
          ownerCategoryId: nazarethOwner,
          passerCategoryId: nazarethPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 14,
          name: "كفرناحوم",
          buyPrice: 220,
          ownerCategoryId: capernaumOwner,
          passerCategoryId: capernaumPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
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
          ownerCategoryId: jerusalemNewOwner,
          passerCategoryId: jerusalemNewPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 17,
          name: "بيت عنيا",
          buyPrice: 190,
          ownerCategoryId: bethanyOwner,
          passerCategoryId: bethanyPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),

        Station(
          id: 18,
          name: "دمشق",
          buyPrice: 170,
          ownerCategoryId: damascusOwner,
          passerCategoryId: damascusPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
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
          ownerCategoryId: antiochOwner,
          passerCategoryId: antiochPasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
            const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
            const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
          ],
        ),
        Station(
          id: 21,
          name: "روما",
          buyPrice: 260,
          ownerCategoryId: romeOwner,
          passerCategoryId: romePasser,
          requiresQuestion: true,
          type: StationType.question,
          era: Era.newTestament,
          buildings: [
            const Building(name: "دير", buyPrice: 200, additionalRent: 100),
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
      int questionId;
      if (existingQ.isNotEmpty) {
        questionId = existingQ.first['id'] as int;
      } else {
        questionId = await txn.insert('questions', {
          'text': qText,
          'answer': q['a']!,
          'type': 'essay',
          'is_multiple': 0,
        });
      }

      // Ensure linked to this category
      final linked = await txn.query('question_categories', 
        where: 'question_id = ? AND category_id = ?', 
        whereArgs: [questionId, catId]);
      
      if (linked.isEmpty) {
        await txn.insert('question_categories', {
          'question_id': questionId,
          'category_id': catId,
          'is_used': 0,
        });
      }
    }
    return catId;
  }

  // Question Data - Cleared to ensure all questions come from imported data only
  static final List<Map<String, String>> _jerusalemOldQuestions = [];
  static final List<Map<String, String>> _jerusalemNewQuestions = [];
  static final List<Map<String, String>> _babelQuestions = [];
  static final List<Map<String, String>> _egyptQuestions = [];
  static final List<Map<String, String>> _jerichoQuestions = [];
  static final List<Map<String, String>> _bethlehemQuestions = [];
  static final List<Map<String, String>> _nazarethQuestions = [];
  static final List<Map<String, String>> _capernaumQuestions = [];
  static final List<Map<String, String>> _bethanyQuestions = [];
  static final List<Map<String, String>> _damascusQuestions = [];
  static final List<Map<String, String>> _antiochQuestions = [];
  static final List<Map<String, String>> _romeQuestions = [];
  static final List<Map<String, String>> _hebronQuestions = [];
  static final List<Map<String, String>> _sodomQuestions = [];
  static final List<Map<String, String>> _beitElQuestions = [];
}
