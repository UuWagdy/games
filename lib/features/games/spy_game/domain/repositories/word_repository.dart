import '../models/word.dart';

class SpyWordRepository {
  static final Map<String, List<String>> _allWords = {
    'أماكن': [
      'مطعم', 'مدرسة', 'مستشفى', 'حديقة', 'متحف', 'ملعب', 'مطار', 'محطة قطار', 'فندق', 'مسرح',
      'سينما', 'غابة', 'شاطئ', 'صحراء', 'جبل', 'جامعة', 'مكتبة', 'سجن', 'مركز شرطة', 'بنك',
      'كنيسة', 'مسجد', 'محطة بنزين', 'معرض فني', 'قصر', 'كهف', 'سوق', 'قرية', 'مدينة', 'قمر'
    ],
    'وظائف': [
      'طبيب', 'مهندس', 'مدرس', 'ضابط شرطة', 'محامي', 'محاسب', 'نجار', 'سباك', 'كهربائي', 'طيار',
      'ممثل', 'مغني', 'فنان', 'كاتب', 'خياط', 'حلاق', 'جزار', 'بائع', 'طباخ', 'مزارع',
      'عامل بناء', 'صحفي', 'مبرمج', 'سائق', 'مضيف طيار', 'عسكري', 'وزير', 'رئيس', 'مترجم', 'مدرب'
    ],
    'أشياء': [
      'تليفون', 'سيارة', 'حاسوب', 'كتاب', 'كرسي', 'طاولة', 'تلفاز', 'ساعة', 'مفتاح', 'حقيبة',
      'نظارة', 'قلم', 'باب', 'نافذة', 'سرير', 'ملعقة', 'سكين', 'شوكة', 'طبق', 'كأس',
      'كاميرا', 'قبعة', 'حذاء', 'مروحة', 'مكيف', 'ثلاجة', 'راديو', 'دراجة', 'كرة', 'مظلة'
    ],
    'أكلات': [
      'بيتزا', 'برجر', 'شاورما', 'ملوخية', 'كشري', 'محشي', 'مكرونة', 'سمك', 'دجاج', 'لحم',
      'حواوشي', 'فلافل', 'فول', 'سلطة', 'خبز', 'أرز', 'كباب', 'كفتة', 'شوربة', 'بشاميل',
      'مانجو', 'تفاح', 'موز', 'برتقال', 'بطيخ', 'فراولة', 'عنب', 'خوخ', 'مشمش', 'رمان'
    ],
    'حيوانات': [
      'أسد', 'نمر', 'فيل', 'زرافة', 'قرد', 'جمل', 'حصان', 'حمار', 'كلب', 'قطة',
      'ذئب', 'ثعلب', 'دب', 'أرنب', 'غزال', 'صقر', 'نسر', 'بومة', 'غراب', 'عصفور',
      'ثعبان', 'تمساح', 'سمكة', 'قرش', 'حوت', 'دلفين', 'أخطبوط', 'سلحفاة', 'قنديل', 'بطريق'
    ],
  };

  static void addCategory(String category) {
    if (!_allWords.containsKey(category)) {
      _allWords[category] = [];
    }
  }

  static void editCategory(String oldName, String newName) {
    if (oldName == newName || newName.isEmpty) return;
    if (_allWords.containsKey(oldName)) {
      final items = _allWords.remove(oldName);
      _allWords[newName] = items ?? [];
    }
  }

  static void deleteCategory(String category) {
    _allWords.remove(category);
  }

  static void addItem(String category, String item) {
    if (_allWords.containsKey(category)) {
      if (!_allWords[category]!.contains(item)) {
        _allWords[category]!.add(item);
      }
    }
  }

  static void editItem(String category, String oldItem, String newItem) {
    if (oldItem == newItem || newItem.isEmpty) return;
    if (_allWords.containsKey(category)) {
      final index = _allWords[category]!.indexOf(oldItem);
      if (index != -1) {
        _allWords[category]![index] = newItem;
      }
    }
  }

  static void deleteItem(String category, String item) {
    if (_allWords.containsKey(category)) {
      _allWords[category]!.remove(item);
    }
  }

  static List<SpyWord> getWords(List<String> categories) {
    List<SpyWord> words = [];
    final actualCategories = categories.isEmpty ? getAllCategories() : categories;
    for (var category in actualCategories) {
      if (_allWords.containsKey(category)) {
        words.addAll(_allWords[category]!.map((text) => SpyWord(text: text, category: category)));
      }
    }
    return words;
  }

  static List<String> getItemsByCategory(String category) {
    return _allWords[category] ?? [];
  }

  static List<String> getAllCategories() {
    return _allWords.keys.toList();
  }
}
