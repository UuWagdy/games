import 'dart:convert';
import 'package:csv/csv.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../../../../questions/domain/entities/category.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class BankAlHazCsvService {
  static const List<String> _headers = [
    'نوع السجل (station / card)',
    'الاسم/العنوان (Name/Title)',
    'الوصف (Description)',
    'النوع الرئيسي (property/question/card/none OR chance/chest)',
    'القيمة/الثمن (BuyPrice/EffectValue)',
    'الإيجار (BaseRent/Nullable)',
    'فئة المالك (OwnerCategoryName)',
    'فئة المار (PasserCategoryName)',
    'يتطلب سؤال (RequiresQuestion: 1/0)',
    'نوع الكارت للمحطة (chance/chest)',
    'نوع تأثير الكارت (addMoney/removeMoney/skipTurn/moveSteps/moveToStation)',
    'هدف الانتقال (TargetStationName)',
    'مسموح بالضرائب (AllowsTax: 1/0)',
    'المباني (Name:Price:Rent;...)',
    'العهد (Era: oldTestament/newTestament/none)',
  ];

  static Future<void> exportTemplate(
    List<Station> stations,
    List<BankAlHazCard> cards,
    List<Category> allCategories,
  ) async {
    List<List<dynamic>> rows = [_headers];
    
    // Add Stations
    for (var s in stations) {
      String ownerCatName = _findCategoryName(s.ownerCategoryId, allCategories);
      String passerCatName = _findCategoryName(s.passerCategoryId, allCategories);
      
      // Serialize buildings: Name:Price:Rent;...
      String buildingsStr = s.buildings.map((b) => "${b.name}:${b.buyPrice.toInt()}:${b.additionalRent.toInt()}").join(';');

      rows.add([
        'station',
        s.name,
        '', // Description
        s.type.name,
        s.buyPrice,
        s.baseRent,
        ownerCatName,
        passerCatName,
        s.requiresQuestion ? 1 : 0,
        s.cardType ?? '',
        '', // EffectType
        '', // TargetStation
        s.allowsTax ? 1 : 0,
        buildingsStr,
        s.era.name,
      ]);
    }

    // Add Cards
    for (var c in cards) {
      rows.add([
        'card',
        c.title,
        c.description,
        c.type ?? 'chance',
        c.effectValue,
        0, // BaseRent
        '', // OwnerCat
        '', // PasserCat
        0, // RequiresQuestion
        '', // StationTrigger
        c.effectType.name,
        c.targetStationName ?? '',
        0, // AllowsTax
        '', // Buildings
      ]);
    }

    String csvData = const ListToCsvConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      eol: '\n',
    ).convert(rows);
    
    // Ensure UTF8 BOM for Excel compatibility
    String bom = '\uFEFF';
    String csvWithBom = bom + csvData;
    final bytes = Uint8List.fromList(utf8.encode(csvWithBom));

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop: Use FilePicker to save directly
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ قالب بنك الحظ',
        fileName: 'bank_al_haz_template.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );
      
      if (outputPath != null) {
        // Ensure path has .csv extension
        String finalPath = outputPath;
        if (!finalPath.toLowerCase().endsWith('.csv')) {
          finalPath += '.csv';
        }
        await File(finalPath).writeAsBytes(bytes);
      }
    } else {
      // Mobile: Use Share API
      // On mobile, we write to a temporary file then share it.
      final directory = await getTemporaryDirectory();
      final String fileName = 'bank_al_haz_template.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path, name: fileName, mimeType: 'text/csv')], 
        text: 'تحميل قالب بنك الحظ',
      );
    }
  }

  static String _findCategoryName(int? id, List<Category> categories) {
    if (id == null) return '';
    try {
      return categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return '';
    }
  }

  static Future<({List<Station> stations, List<BankAlHazCard> cards})> importFromCsv(
    List<Category> allCategories,
  ) async {
    // For mobile/Android, using withData: true is more reliable than path
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || (result.files.single.path == null && result.files.single.bytes == null)) {
      return (stations: <Station>[], cards: <BankAlHazCard>[]);
    }

    Uint8List? bytes = result.files.single.bytes;
    if (bytes == null && result.files.single.path != null) {
      bytes = await File(result.files.single.path!).readAsBytes();
    }
    
    if (bytes == null) return (stations: <Station>[], cards: <BankAlHazCard>[]);

    String csvString = utf8.decode(bytes);
    if (csvString.startsWith('\uFEFF')) {
      csvString = csvString.substring(1);
    }
    
    final fields = const CsvToListConverter().convert(csvString);
    if (fields.length <= 1) return (stations: <Station>[], cards: <BankAlHazCard>[]);

    List<Station> stations = [];
    List<BankAlHazCard> cards = [];

    for (int i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.isEmpty) continue;

      String recordType = row[0].toString().toLowerCase();
      
      if (recordType == 'station') {
        String typeStr = row[3].toString();
        StationType sType = StationType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => StationType.question,
        );

        int? ownerCatId = _findCategoryId(row[6].toString(), allCategories);
        int? passerCatId = _findCategoryId(row[7].toString(), allCategories);
        
        // Parse buildings string: Name:Price:Rent;...
        List<Building> bList = [];
        try {
          String bStr = row.length > 13 ? row[13].toString() : '';
          if (bStr.isNotEmpty) {
            for (var bPart in bStr.split(';')) {
              var bits = bPart.split(':');
              if (bits.length >= 3) {
                bList.add(Building(
                  name: bits[0],
                  buyPrice: double.tryParse(bits[1]) ?? 0,
                  additionalRent: double.tryParse(bits[2]) ?? 0,
                ));
              }
            }
          }
        } catch (_) {}

        stations.add(Station(
          name: row[1].toString(),
          type: sType,
          buyPrice: double.tryParse(row[4].toString()) ?? 0,
          baseRent: double.tryParse(row[5].toString()) ?? 0,
          ownerCategoryId: ownerCatId,
          passerCategoryId: passerCatId,
          requiresQuestion: row[8].toString() == '1',
          cardType: row[9].toString().isEmpty ? null : row[9].toString(),
          allowsTax: row.length > 12 ? row[12].toString() == '1' : true,
          buildings: bList,
          era: row.length > 14 
            ? Era.values.firstWhere((e) => e.name == row[14].toString(), orElse: () => Era.none)
            : Era.none,
        ));
      } else if (recordType == 'card') {
        String effectTypeStr = row[10].toString();
        CardEffectType eType = CardEffectType.values.firstWhere(
          (e) => e.name == effectTypeStr,
          orElse: () => CardEffectType.addMoney,
        );

        cards.add(BankAlHazCard(
          title: row[1].toString(),
          description: row[2].toString(),
          type: row[3].toString(),
          effectValue: int.tryParse(row[4].toString()) ?? 0,
          effectType: eType,
          targetStationName: row[11].toString().isEmpty ? null : row[11].toString(),
        ));
      }
    }

    return (stations: stations, cards: cards);
  }

  static int? _findCategoryId(String name, List<Category> categories) {
    if (name.isEmpty) return null;
    try {
      return categories.firstWhere((c) => c.name.trim() == name.trim()).id;
    } catch (_) {
      return null;
    }
  }
}
