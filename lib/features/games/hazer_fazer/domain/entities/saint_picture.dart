import 'dart:io';
import 'package:flutter/material.dart';

class SaintPicture {
  final String id;
  final String name;
  final String title;
  final String? assetPath;
  final String? filePath;
  final bool isCustom;

  const SaintPicture({
    required this.id,
    required this.name,
    required this.title,
    this.assetPath,
    this.filePath,
    this.isCustom = false,
  });

  bool get isAsset => (filePath == null || filePath!.isEmpty) && assetPath != null && assetPath!.isNotEmpty;

  Widget buildImage({BoxFit fit = BoxFit.fill, double? width, double? height}) {
    if (!isAsset && filePath != null && filePath!.isNotEmpty) {
      final file = File(filePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _errorPlaceholder(),
        );
      }
    }
    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }
    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, size: 40, color: Colors.white38),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'assetPath': assetPath,
        'filePath': filePath,
        'isCustom': isCustom,
      };

  factory SaintPicture.fromJson(Map<String, dynamic> json) => SaintPicture(
        id: json['id'] as String,
        name: json['name'] as String,
        title: json['title'] as String? ?? '',
        assetPath: json['assetPath'] as String?,
        filePath: json['filePath'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  SaintPicture copyWith({
    String? id,
    String? name,
    String? title,
    String? assetPath,
    String? filePath,
    bool? isCustom,
  }) {
    return SaintPicture(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  static const List<SaintPicture> defaultSaints = [
    SaintPicture(
      id: 'anba_antony',
      name: 'الأنبا أنطونيوس',
      title: 'أبو الرهبان',
      assetPath: 'assets/images/الأنبا أنطونيوس.png',
    ),
    SaintPicture(
      id: 'anba_paula',
      name: 'الأنبا بولا',
      title: 'أول السواح',
      assetPath: 'assets/images/الأبنا بولا.png',
    ),
    SaintPicture(
      id: 'anba_bishoy',
      name: 'الأنبا بيشوي',
      title: 'حبيب مخلصنا الصالح',
      assetPath: 'assets/images/الأنبا بيشوي.png',
    ),
    SaintPicture(
      id: 'anba_thomas',
      name: 'الأنبا توماس',
      title: 'السائح بجبل شنشيف',
      assetPath: 'assets/images/الأنبا توماس.png',
    ),
    SaintPicture(
      id: 'anba_abraam',
      name: 'الأنبا إبرآم أسقف الفيوم',
      title: 'رجل العطاء ومحب الفقراء',
      assetPath: 'assets/images/الانبا ابرام اسقف الفيوم.png',
    ),
  ];
}
