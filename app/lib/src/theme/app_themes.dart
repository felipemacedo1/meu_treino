import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Um tema é apenas um conjunto de tokens + metadados para o seletor.
/// A tipografia, os espaçamentos e as formas são iguais em todos eles:
/// o que muda é a iluminação da interface.
@immutable
class ThemeDefinition {
  const ThemeDefinition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.tokens,
  });

  /// Identificador persistido (local e no perfil do usuário).
  final String id;

  /// Nome exibido no seletor.
  final String name;

  /// Frase curta que aparece embaixo do nome.
  final String tagline;

  final AppTokens tokens;
}

/// Catálogo de temas do aplicativo.
class AppThemes {
  const AppThemes._();

  static const String defaultId = 'neon_orange';

  // ------------------------ base compartilhada -----------------------------
  //
  // Todos os temas partem da mesma estrutura de superfícies e neutros para
  // manter a identidade. Cada tema troca a família de cor da marca.

  static const Color _ink = Color(0xFF07070A); // fundo quase preto
  static const Color _inkDeep = Color(0xFF040406); // fim do gradiente
  static const Color _panel = Color(0xFF101116); // card
  static const Color _panelUp = Color(0xFF16181F); // sheet / dialog
  static const Color _panelDown = Color(0xFF0B0C10); // input / trilha
  static const Color _line = Color(0xFF23252E); // borda
  static const Color _lineStrong = Color(0xFF343747); // borda em evidência

  static const Color _textHigh = Color(0xFFF2F4F8);
  static const Color _textMid = Color(0xFFA6ABBA);
  static const Color _textLow = Color(0xFF6B7080);

  static const Color _success = Color(0xFF2BD98B);
  static const Color _warning = Color(0xFFFFB020);
  static const Color _error = Color(0xFFFF4D5E);

  /// Monta um tema a partir da cor da marca, garantindo que superfícies,
  /// neutros e estados fiquem consistentes entre todas as variantes.
  static AppTokens _build({
    required Color primary,
    required Color primaryVariant,
    required Color accent,
    required Color secondary,
    required Color onPrimary,
    required List<Color> chartColors,
    Color? primarySoft,
  }) {
    return AppTokens(
      background: _ink,
      backgroundGradientEnd: _inkDeep,
      surface: _panel,
      surfaceElevated: _panelUp,
      surfaceSunken: _panelDown,
      primary: primary,
      primaryVariant: primaryVariant,
      primarySoft: primarySoft ?? primary.withValues(alpha: 0.14),
      onPrimary: onPrimary,
      secondary: secondary,
      accent: accent,
      textPrimary: _textHigh,
      textSecondary: _textMid,
      textMuted: _textLow,
      textOnGlow: onPrimary,
      border: _line,
      borderStrong: _lineStrong,
      success: _success,
      warning: _warning,
      error: _error,
      progress: primary,
      track: const Color(0xFF1C1E26),
      glow: primary,
      scrim: const Color(0xE60A0A0D),
      chartColors: chartColors,
    );
  }

  // --------------------------- 1. NEON ORANGE ------------------------------

  static final ThemeDefinition neonOrange = ThemeDefinition(
    id: 'neon_orange',
    name: 'Neon Orange',
    tagline: 'A identidade oficial. Preto e laranja neon.',
    tokens: _build(
      primary: const Color(0xFFFF6A00),
      primaryVariant: const Color(0xFFFF9E2C),
      accent: const Color(0xFFFFC14D),
      secondary: const Color(0xFF8A6BFF),
      onPrimary: const Color(0xFF120600),
      chartColors: const [
        Color(0xFFFF6A00), // laranja neon (série principal)
        Color(0xFF8A6BFF), // violeta
        Color(0xFFFFC14D), // âmbar
        Color(0xFF3FA9FF), // azul
        Color(0xFF2BD98B), // verde
        Color(0xFFFF9E2C), // laranja claro
      ],
    ),
  );

  // ---------------------------- 2. CYBER RED -------------------------------

  static final ThemeDefinition cyberRed = ThemeDefinition(
    id: 'cyber_red',
    name: 'Cyber Red',
    tagline: 'Preto e vermelho neon. Agressivo.',
    tokens: _build(
      primary: const Color(0xFFFF2D4B),
      primaryVariant: const Color(0xFFFF6B5A),
      accent: const Color(0xFFFF9E7A),
      secondary: const Color(0xFF7B61FF),
      onPrimary: const Color(0xFF160004),
      chartColors: const [
        Color(0xFFFF2D4B),
        Color(0xFF7B61FF),
        Color(0xFFFF9E7A),
        Color(0xFF3FA9FF),
        Color(0xFF2BD98B),
        Color(0xFFFF6B5A),
      ],
    ),
  );

  // -------------------------- 3. PLASMA PURPLE -----------------------------

  static final ThemeDefinition plasmaPurple = ThemeDefinition(
    id: 'plasma_purple',
    name: 'Plasma Purple',
    tagline: 'Preto e violeta neon. Futurista.',
    tokens: _build(
      primary: const Color(0xFF9B5CFF),
      primaryVariant: const Color(0xFFC77DFF),
      accent: const Color(0xFFFF6FD8),
      secondary: const Color(0xFF3FA9FF),
      onPrimary: const Color(0xFF0B0016),
      chartColors: const [
        Color(0xFF9B5CFF),
        Color(0xFFFF6FD8),
        Color(0xFF3FA9FF),
        Color(0xFFFFB020),
        Color(0xFF2BD98B),
        Color(0xFFC77DFF),
      ],
    ),
  );

  // -------------------------- 4. ELECTRIC BLUE -----------------------------

  static final ThemeDefinition electricBlue = ThemeDefinition(
    id: 'electric_blue',
    name: 'Electric Blue',
    tagline: 'Preto e azul elétrico. Clínico e preciso.',
    tokens: _build(
      primary: const Color(0xFF1F8BFF),
      primaryVariant: const Color(0xFF39D0FF),
      accent: const Color(0xFF7BE7FF),
      secondary: const Color(0xFF8A6BFF),
      onPrimary: const Color(0xFF00080F),
      chartColors: const [
        Color(0xFF1F8BFF),
        Color(0xFF8A6BFF),
        Color(0xFF39D0FF),
        Color(0xFFFFB020),
        Color(0xFF2BD98B),
        Color(0xFF7BE7FF),
      ],
    ),
  );

  // --------------------------- 5. TOXIC GREEN ------------------------------

  static final ThemeDefinition toxicGreen = ThemeDefinition(
    id: 'toxic_green',
    name: 'Toxic Green',
    tagline: 'Preto e verde neon. Terminal.',
    tokens: _build(
      primary: const Color(0xFF39FF88),
      primaryVariant: const Color(0xFF9BFF4D),
      accent: const Color(0xFFD4FF3F),
      secondary: const Color(0xFF3FA9FF),
      onPrimary: const Color(0xFF001309),
      chartColors: const [
        Color(0xFF39FF88),
        Color(0xFF3FA9FF),
        Color(0xFFD4FF3F),
        Color(0xFF8A6BFF),
        Color(0xFFFFB020),
        Color(0xFF9BFF4D),
      ],
    ),
  );

  // --------------------------- 6. MINIMAL DARK -----------------------------

  static final ThemeDefinition minimalDark = ThemeDefinition(
    id: 'minimal_dark',
    name: 'Minimal Dark',
    tagline: 'Só o essencial. Acentos discretos.',
    tokens: _build(
      primary: const Color(0xFFE7EAF2),
      primaryVariant: const Color(0xFFB9BFD0),
      accent: const Color(0xFFFF6A00),
      secondary: const Color(0xFF8A90A3),
      onPrimary: const Color(0xFF0A0A0D),
      primarySoft: const Color(0x1FE7EAF2),
      chartColors: const [
        Color(0xFFE7EAF2),
        Color(0xFFB9BFD0),
        Color(0xFF8A90A3),
        Color(0xFF6B7080),
        Color(0xFF4C5160),
        Color(0xFFFF6A00),
      ],
    ),
  );

  /// Ordem em que os temas aparecem no seletor.
  static final List<ThemeDefinition> all = [
    neonOrange,
    cyberRed,
    plasmaPurple,
    electricBlue,
    toxicGreen,
    minimalDark,
  ];

  static ThemeDefinition byId(String? id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => neonOrange,
    );
  }
}
