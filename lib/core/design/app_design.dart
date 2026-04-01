import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'app_themes.dart';

class AppDesign {
  static bool isSmallScreen(BuildContext context) => MediaQuery.of(context).size.width < 900;

  // Colors
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  
  // Gradients
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [slate900, slate800, slate900],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white10, Colors.white12],
  );

  // Decorators
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white10),
  );

  static BoxDecoration get dialogDecoration => BoxDecoration(
        color: slate800.withOpacity(0.95), // Highly opaque for clarity
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      );

  static BoxDecoration glassDecorationWithColor(Color color) => BoxDecoration(
    color: color.withOpacity(0.05),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: color.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.05),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
    fontWeight: FontWeight.w300,
  );

  static Widget buildOrb({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> buildBackgroundOrbs(ThemeConfig theme) {
    Color getOrbColor(int i) => theme.orbColors.length > i ? theme.orbColors[i] : theme.primaryColor.withOpacity(0.1);
    
    return [
      buildOrb(top: -150, right: -150, size: 500, color: getOrbColor(0)),
      buildOrb(bottom: -200, left: -200, size: 600, color: getOrbColor(1)),
      buildOrb(top: 100, left: 100, size: 300, color: getOrbColor(2)),
      buildOrb(bottom: 200, right: 100, size: 250, color: getOrbColor(3)),
    ];
  }

  static Widget backgroundWrapper({required Widget child, ThemeConfig? theme}) {
    final curTheme = theme ?? AppThemes.defaultTheme;
    final bgImage = curTheme.backgroundImage;
    
    if (bgImage != null && bgImage.isNotEmpty) {
      // When a background image exists, show it prominently
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: curTheme.backgroundDeep,
        ),
        child: Stack(
          children: [
            // Background image - fills entire screen
            Positioned.fill(
              child: Image(
                image: bgImage.startsWith('assets/')
                  ? AssetImage(bgImage) as ImageProvider
                  : FileImage(File(bgImage)),
                fit: BoxFit.fill,
                opacity: const AlwaysStoppedAnimation(0.6),
              ),
            ),
            // Subtle gradient overlay to ensure text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      curTheme.backgroundDeep.withOpacity(0.3),
                      Colors.transparent,
                      curTheme.backgroundDeep.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      );
    }
    
    // No background image: use gradient + orbs + blur
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: curTheme.backgroundDeep,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [curTheme.backgroundDeep, curTheme.backgroundSoft, curTheme.backgroundDeep],
        ),
      ),
      child: Stack(
        children: [
          ...buildBackgroundOrbs(curTheme),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),
          child,
        ],
      ),
    );
  }

  static InputDecoration searchInputDecoration(String hint, {Color? focusColor}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: focusColor ?? Colors.blueAccent, width: 2)),
    );
  }
}
