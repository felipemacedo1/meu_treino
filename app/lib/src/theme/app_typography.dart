import 'package:flutter/material.dart';

/// Identidade tipográfica do aplicativo. **Não muda com o tema.**
///
/// - `Chakra Petch`: títulos, números e cronômetro. Os cortes angulares nas
///   hastes dão a leitura sci-fi/HUD sem sacrificar clareza.
/// - `Rajdhani`: interface e leitura longa. Desenho técnico e boa legibilidade
///   em telas pequenas.
///
/// Nenhuma das duas define `tnum`, e os dígitos não têm largura uniforme. Onde
/// a estabilidade importa (cronômetro, tempo decorrido) use o widget
/// `MonoDigits`, que alinha cada caractere em uma célula de largura fixa.
class AppTypography {
  const AppTypography._();

  static const String displayFamily = 'ChakraPetch';
  static const String bodyFamily = 'Rajdhani';

  /// Estilo com a fonte de display (títulos e números).
  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w700,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  /// Estilo com a fonte de interface.
  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w500,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  /// Números grandes de leitura rápida (carga, cronômetro, métricas).
  static TextStyle metric(double size, {Color? color, FontWeight? weight}) => display(
        size: size,
        weight: weight ?? FontWeight.w700,
        letterSpacing: size > 40 ? -1.2 : -0.4,
        color: color,
      );

  /// Rótulo técnico em caixa alta, usado em cabeçalhos de seção e legendas.
  static TextStyle label(double size, {Color? color, FontWeight? weight}) => body(
        size: size,
        weight: weight ?? FontWeight.w600,
        letterSpacing: 1.4,
        color: color,
      );

  /// TextTheme completo. As cores vêm depois, no construtor do tema.
  static TextTheme textTheme() {
    return TextTheme(
      // Chakra Petch: títulos e números
      displayLarge: display(size: 44, weight: FontWeight.w700, letterSpacing: -1.4, height: 1.06),
      displayMedium: display(size: 36, weight: FontWeight.w700, letterSpacing: -1.0, height: 1.08),
      displaySmall: display(size: 30, weight: FontWeight.w700, letterSpacing: -0.7, height: 1.1),
      headlineLarge: display(size: 26, weight: FontWeight.w700, letterSpacing: -0.5, height: 1.14),
      headlineMedium: display(size: 22, weight: FontWeight.w700, letterSpacing: -0.3, height: 1.18),
      headlineSmall: display(size: 19, weight: FontWeight.w700, letterSpacing: -0.1, height: 1.22),
      titleLarge: display(size: 18, weight: FontWeight.w700, letterSpacing: 0.2, height: 1.26),

      // Rajdhani: interface
      titleMedium: body(size: 16, weight: FontWeight.w700, letterSpacing: 0.1, height: 1.3),
      titleSmall: body(size: 14.5, weight: FontWeight.w700, letterSpacing: 0.2, height: 1.3),
      bodyLarge: body(size: 16, weight: FontWeight.w500, height: 1.42),
      bodyMedium: body(size: 14.5, weight: FontWeight.w500, height: 1.45),
      bodySmall: body(size: 13, weight: FontWeight.w500, height: 1.4),
      labelLarge: body(size: 14, weight: FontWeight.w700, letterSpacing: 0.6),
      labelMedium: body(size: 12.5, weight: FontWeight.w600, letterSpacing: 0.6),
      labelSmall: body(size: 11, weight: FontWeight.w600, letterSpacing: 1.2),
    );
  }
}
