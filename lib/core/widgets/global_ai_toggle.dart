import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';

class GlobalAIToggle extends ConsumerWidget {
  final Function(bool)? onToggle;
  const GlobalAIToggle({super.key, this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);
    
    return settingsAsync.when(
      data: (settings) {
        final isAi = settings['global_ai_enabled'] ?? false;
        return Tooltip(
          message: isAi ? 'الذكاء الاصطناعي نشط' : 'تفعيل الذكاء الاصطناعي',
          child: GestureDetector(
            onTap: () {
               final newState = !isAi;
               ref.read(generalSettingsProvider.notifier).setGlobalAiEnabled(newState);
               
               if (onToggle != null) {
                 onToggle!(newState);
               }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: isAi 
                    ? [Colors.cyanAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.1)]
                    : [Colors.white10, Colors.white10],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isAi ? Colors.cyanAccent.withOpacity(0.5) : Colors.white24,
                  width: 1.5,
                ),
                boxShadow: [
                  if (isAi)
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isAi)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 2),
                      builder: (context, val, child) {
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.4 * (1 - val)),
                              width: 2,
                            ),
                          ),
                        );
                      },
                      onEnd: () {}, 
                    ),
                  Icon(
                    isAi ? Icons.smart_toy : Icons.smart_toy_outlined,
                    color: isAi ? Colors.cyanAccent : Colors.white60,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}
