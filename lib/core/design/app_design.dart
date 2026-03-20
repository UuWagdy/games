import 'package:flutter/material.dart';
import 'dart:ui';

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

  // Background Orbs
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

  static List<Widget> buildBackgroundOrbs() {
    return [
      buildOrb(top: -150, right: -150, size: 500, color: const Color(0xFF1E293B)),
      buildOrb(bottom: -200, left: -200, size: 600, color: const Color(0xFF334155)),
      buildOrb(top: 100, left: 100, size: 300, color: Colors.blueAccent),
      buildOrb(bottom: 200, right: 100, size: 250, color: Colors.purpleAccent),
    ];
  }

  static Widget backgroundWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: slate900,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [slate900, Color(0xFF1E293B), slate900],
        ),
      ),
      child: Stack(
        children: [
          ...buildBackgroundOrbs(),
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

  static InputDecoration searchInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.purpleAccent, width: 2)),
    );
  }
}
