import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/team_providers.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/themed_background.dart';

class TeamsManagementPage extends ConsumerWidget {
  const TeamsManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: Navigator.of(context).canPop() 
        ? AppBar(
            backgroundColor: Colors.transparent, 
            elevation: 0, 
            centerTitle: true,
            title: Text('إدارة الفرق', style: AppDesign.titleStyle),
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          )
        : null,
      body: ThemedBackground(
        child: SafeArea(
          child: teamsAsync.when(
            data: (teams) => teams.isEmpty
              ? const Center(child: Text('لا توجد فرق مضافة', style: TextStyle(color: Colors.white60, fontSize: 18)))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = AppDesign.isSmallScreen(context);
                      final isWide = constraints.maxWidth > 600;
                      return GridView.builder(
                        padding: EdgeInsets.all(isSmall ? 16 : 24),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isWide ? 400 : 800,
                          mainAxisExtent: isSmall ? 120 : 110,
                          crossAxisSpacing: isSmall ? 12 : 20,
                          mainAxisSpacing: isSmall ? 12 : 20,
                        ),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          return Container(
                            decoration: AppDesign.glassDecoration,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 8),
                              title: Text(
                                team.name, 
                                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: isSmall ? 18 : 22),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: 'النقاط: ', style: TextStyle(color: Colors.white38, fontSize: isSmall ? 12 : 13)),
                                    TextSpan(text: '${team.score}', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 16)),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: isSmall ? VisualDensity.compact : null,
                                    icon: Icon(Icons.edit_outlined, color: Colors.blueAccent, size: isSmall ? 20 : 24),
                                    onPressed: () => _showEditTeamDialog(context, ref, team),
                                  ),
                                  IconButton(
                                    visualDensity: isSmall ? VisualDensity.compact : null,
                                    icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: isSmall ? 20 : 24),
                                    onPressed: () => ref.read(teamsListProvider.notifier).deleteTeam(team.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
            error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final isSmall = AppDesign.isSmallScreen(context);
          return FloatingActionButton.extended(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            elevation: 10,
            onPressed: () => _showAddTeamDialog(context, ref),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(isSmall ? 'إضافة' : 'إضافة فريق جديد', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, WidgetRef ref, dynamic team) {
    final controller = TextEditingController(text: team.name);
    _showTeamEditor(context, ref, 'تعديل الفريق', controller, () {
      if (controller.text.isNotEmpty) {
        ref.read(teamsListProvider.notifier).updateTeam(team.copyWith(name: controller.text));
        Navigator.pop(context);
      }
    });
  }

  void _showAddTeamDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    _showTeamEditor(context, ref, 'إضافة فريق جديد', controller, () {
      if (controller.text.isNotEmpty) {
        ref.read(teamsListProvider.notifier).addTeam(controller.text);
        Navigator.pop(context);
      }
    });
  }

  void _showTeamEditor(BuildContext context, WidgetRef ref, String title, TextEditingController controller, VoidCallback onSave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'اسم الفريق',
            labelStyle: const TextStyle(color: Colors.white60),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.amber)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: onSave,
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
