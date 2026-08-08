import 'package:flutter/material.dart';

/// Tokens semânticos de cor do aplicativo.
///
/// Nenhum componente deve usar cor literal (`Color(0x...)` ou `Colors.x`).
/// Tudo passa por aqui, e cada tema define seus valores.
///
/// Acesso nas telas: `context.tokens` (extension em `theme.dart`).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.backgroundGradientEnd,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.primary,
    required this.primaryVariant,
    required this.primarySoft,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnGlow,
    required this.border,
    required this.borderStrong,
    required this.success,
    required this.warning,
    required this.error,
    required this.progress,
    required this.track,
    required this.glow,
    required this.scrim,
    required this.chartColors,
  });

  // ------------------------------ superfícies ------------------------------

  /// Fundo da aplicação (quase preto).
  final Color background;

  /// Fim do gradiente de fundo — dá profundidade sem poluir.
  final Color backgroundGradientEnd;

  /// Cards e painéis.
  final Color surface;

  /// Superfície acima de card: sheets, dialogs, itens destacados.
  final Color surfaceElevated;

  /// Superfície "afundada": campos de entrada, trilhas, slots de série.
  final Color surfaceSunken;

  // -------------------------------- marca ----------------------------------

  /// Cor da identidade. Usada com parcimônia: ações primárias, seleção,
  /// números importantes, progresso e acentos.
  final Color primary;

  /// Variação para gradientes e estados ativos/hover.
  final Color primaryVariant;

  /// Fundo tênue derivado da primária (chips, ícones, seleção suave).
  final Color primarySoft;

  /// Conteúdo sobre a cor primária.
  final Color onPrimary;

  /// Apoio à primária em elementos secundários e séries de gráfico.
  final Color secondary;

  /// Realce pontual (badges de recorde, métricas de destaque).
  final Color accent;

  // ------------------------------- tipografia ------------------------------

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Texto sobre áreas iluminadas pelo neon (barra de descanso, banners).
  final Color textOnGlow;

  // -------------------------------- bordas ---------------------------------

  final Color border;
  final Color borderStrong;

  // -------------------------------- estados --------------------------------

  final Color success;
  final Color warning;
  final Color error;

  /// Indicadores de progresso (barras, anéis, cronômetro).
  final Color progress;

  /// Trilha vazia do progresso.
  final Color track;

  /// Cor do brilho (glow). Normalmente a primária com alpha aplicado no uso.
  final Color glow;

  /// Véu sobre o conteúdo em dialogs e sheets.
  final Color scrim;

  /// Paleta para gráficos, na ordem de uso.
  final List<Color> chartColors;

  // ------------------------------- derivados -------------------------------

  /// Gradiente da marca, usado em destaques e no cronômetro.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryVariant],
      );

  /// Gradiente do fundo da aplicação.
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [background, backgroundGradientEnd],
      );

  /// Cor de série de gráfico por índice, com repetição segura.
  Color chartColor(int index) => chartColors[index % chartColors.length];

  @override
  AppTokens copyWith({
    Color? background,
    Color? backgroundGradientEnd,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSunken,
    Color? primary,
    Color? primaryVariant,
    Color? primarySoft,
    Color? onPrimary,
    Color? secondary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnGlow,
    Color? border,
    Color? borderStrong,
    Color? success,
    Color? warning,
    Color? error,
    Color? progress,
    Color? track,
    Color? glow,
    Color? scrim,
    List<Color>? chartColors,
  }) {
    return AppTokens(
      background: background ?? this.background,
      backgroundGradientEnd: backgroundGradientEnd ?? this.backgroundGradientEnd,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnGlow: textOnGlow ?? this.textOnGlow,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      progress: progress ?? this.progress,
      track: track ?? this.track,
      glow: glow ?? this.glow,
      scrim: scrim ?? this.scrim,
      chartColors: chartColors ?? this.chartColors,
    );
  }

  /// Permite que a troca de tema seja animada em vez de "piscar".
  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      background: mix(background, other.background),
      backgroundGradientEnd: mix(backgroundGradientEnd, other.backgroundGradientEnd),
      surface: mix(surface, other.surface),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      primary: mix(primary, other.primary),
      primaryVariant: mix(primaryVariant, other.primaryVariant),
      primarySoft: mix(primarySoft, other.primarySoft),
      onPrimary: mix(onPrimary, other.onPrimary),
      secondary: mix(secondary, other.secondary),
      accent: mix(accent, other.accent),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      textOnGlow: mix(textOnGlow, other.textOnGlow),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      progress: mix(progress, other.progress),
      track: mix(track, other.track),
      glow: mix(glow, other.glow),
      scrim: mix(scrim, other.scrim),
      chartColors: [
        for (var i = 0; i < chartColors.length; i++)
          mix(chartColors[i], other.chartColors[i % other.chartColors.length]),
      ],
    );
  }
}
