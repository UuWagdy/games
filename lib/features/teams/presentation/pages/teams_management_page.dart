import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/team_providers.dart';

class TeamsManagementPage extends ConsumerWidget {
  const TeamsManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      body: teamsAsync.when(
        data: (teams) => teams.isEmpty
          ? const Center(child: Text('لا توجد فرق مضافة'))
          : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isWide ? 400 : 800,
                      mainAxisExtent: 80,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('النقاط: ${team.score}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showEditTeamDialog(context, ref, team),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  ref.read(teamsListProvider.notifier).deleteTeam(team.id!);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTeamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, WidgetRef ref, dynamic team) {
    final controller = TextEditingController(text: team.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الفريق'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'اسم الفريق'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(teamsListProvider.notifier).updateTeam(team.copyWith(name: controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة فريق جديد'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'اسم الفريق'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(teamsListProvider.notifier).addTeam(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
