import 'package:flutter/material.dart';
import 'package:games/core/design/app_design.dart';
import '../widgets/hazer_fazer_settings_dialog.dart';

class HazerFazerSettingsPage extends StatelessWidget {
  const HazerFazerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(28),
            decoration: AppDesign.dialogDecoration,
            child: const HazerFazerSettingsContent(),
          ),
        ),
      ),
    );
  }
}
