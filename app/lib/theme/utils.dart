import 'package:flutter/material.dart';

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.r.toInt(), g = color.g.toInt(), b = color.b.toInt();

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.toARGB32(), swatch);
}

Color darkenColor(Color color) {
  final hslColor = HSLColor.fromColor(color);
  final hslDarken = HSLColor.fromAHSL(hslColor.alpha, hslColor.hue,
      hslColor.saturation, hslColor.lightness - 0.2);
  return hslDarken.toColor();
}

Color fromColorToColor(Color c1, Color c2, double percent) {
  return Color.lerp(c1, c2, percent)!;
}
