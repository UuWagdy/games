import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/database/database_service.dart';
import '../../../../core/design/app_design.dart';
import '../../../../core/design/themed_background.dart';

class BackupRestorePage extends ConsumerWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('النسخ الاحتياطي والاستعادة', style: AppDesign.titleStyle),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildActionCard(
                title: 'نسخ احتياطي للبيانات',
                subtitle: 'قم بحفظ نسخة من كافة بيانات البرنامج (الأسئلة، الفئات، الإعدادات) لاستعادتها لاحقاً.',
                icon: Icons.cloud_upload_outlined,
                color: Colors.blueAccent,
                onTap: () => _handleBackup(context),
              ),
              const SizedBox(height: 20),
              _buildActionCard(
                title: 'استعادة البيانات',
                subtitle: 'قم باختيار ملف نسخة احتياطية (games.db) لاستبدال البيانات الحالية.',
                icon: Icons.settings_backup_restore_outlined,
                color: Colors.orangeAccent,
                onTap: () => _handleRestore(context),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تنبيه: استعادة البيانات ستقوم بمسح كافة البيانات الحالية واستبدالها بالنسخة المختارَة.',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    try {
      final dbFile = await DatabaseService.instance.getDatabaseFile();
      if (!await dbFile.exists()) throw 'ملف قاعدة البيانات غير موجود';

      if (Platform.isWindows) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'احفظ النسخة الاحتياطية',
          fileName: 'games_backup_${DateTime.now().millisecondsSinceEpoch}.db',
          type: FileType.any,
        );
        if (outputFile != null) {
          await dbFile.copy(outputFile);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ النسخة الاحتياطية بنجاح'), backgroundColor: Colors.green));
          }
        }
      } else {
        // Mobile (Android / iOS)
        final xFile = XFile(dbFile.path);
        await Share.shareXFiles([xFile], text: 'نسخة احتياطية من تطبيق بنك الحظ');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في النسخ الاحتياطي: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;

      final sourcePath = result.files.single.path!;
      
      // Basic check
      if (!sourcePath.endsWith('.db') && !sourcePath.contains('games')) {
         final confirm = await showDialog<bool>(
           context: context,
           builder: (ctx) => AlertDialog(
             backgroundColor: const Color(0xFF1E293B),
             title: const Text('تنبيه الملف', style: TextStyle(color: Colors.white)),
             content: const Text('الملف المختار لا يبدو كملف قاعدة بيانات للبرنامج. هل تريد المتابعة على أية حال؟'),
             actions: [
               TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
               TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('متابعة')),
             ],
           ),
         );
         if (confirm != true) return;
      }

      final confirmRestore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('تأكيد الاستعادة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('سيتم إغلاق البرنامج واستبدال كافة البيانات. هل أنت متأكد؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text('تأكيد الاستعادة'),
            ),
          ],
        ),
      );

      if (confirmRestore == true) {
        await DatabaseService.instance.restoreFromPath(sourcePath);
        if (context.mounted) {
           showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => AlertDialog(
               backgroundColor: const Color(0xFF1E293B),
               title: const Text('اكتملت الاستعادة', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
               content: const Text('تم استعادة البيانات بنجاح. يرجى إغلاق البرنامج وإعادة تشغيله لتطبيق التغييرات.'),
               actions: [
                 ElevatedButton(
                   onPressed: () => exit(0), 
                   child: const Text('إغلاق البرنامج الآن'),
                 ),
               ],
             ),
           );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاستعادة: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
