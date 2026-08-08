import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Raios, espaçamentos e efeitos do design system.
///
/// O neon é iluminação, não preenchimento: brilhos são sutis e reservados
/// para o que precisa chamar atenção (ação primária, progresso, série ativa).
class AppRadius {
  const AppRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;

  static BorderRadius all(double value) => BorderRadius.circular(value);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  /// Respiro horizontal padrão das telas.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: 18);
}

class AppEffects {
  const AppEffects._();

  /// Brilho externo. `strength` de 0 a 1.
  static List<BoxShadow> glow(
    Color color, {
    double strength = 0.35,
    double blur = 18,
    double spread = 0,
    Offset offset = Offset.zero,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: strength.clamp(0, 1)),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }

  /// Profundidade discreta para cards sobre o fundo escuro.
  static List<BoxShadow> depth({double strength = 0.5}) => [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: strength),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Card padrão: superfície + borda de 1px. Com [accent], a borda recebe a
  /// cor da marca e um brilho leve — usado no que está ativo/selecionado.
  static BoxDecoration panel(
    AppTokens tokens, {
    double radius = AppRadius.lg,
    bool accent = false,
    bool elevated = false,
    Color? borderColor,
    double glowStrength = 0.16,
  }) {
    final border = borderColor ?? (accent ? tokens.primary.withValues(alpha: 0.55) : tokens.border);
    return BoxDecoration(
      color: elevated ? tokens.surfaceElevated : tokens.surface,
      borderRadius: AppRadius.all(radius),
      border: Border.all(color: border, width: 1),
      boxShadow: accent ? glow(tokens.glow, strength: glowStrength, blur: 22) : null,
    );
  }

  /// Superfície afundada (inputs, trilhas, slots de série).
  static BoxDecoration sunken(
    AppTokens tokens, {
    double radius = AppRadius.md,
    bool focused = false,
  }) {
    return BoxDecoration(
      color: tokens.surfaceSunken,
      borderRadius: AppRadius.all(radius),
      border: Border.all(
        color: focused ? tokens.primary : tokens.border,
        width: focused ? 1.4 : 1,
      ),
      boxShadow: focused ? glow(tokens.glow, strength: 0.18, blur: 12) : null,
    );
  }

  /// Faixa com a cor da marca (cronômetro, banners de destaque).
  static BoxDecoration brandBanner(
    AppTokens tokens, {
    double radius = AppRadius.lg,
    double glowStrength = 0.32,
  }) {
    return BoxDecoration(
      gradient: tokens.brandGradient,
      borderRadius: AppRadius.all(radius),
      boxShadow: glow(tokens.glow, strength: glowStrength, blur: 28, offset: const Offset(0, 6)),
    );
  }
}

/// Divisor com um trecho iluminado à esquerda — assinatura visual usada em
/// cabeçalhos de seção e separadores dentro de cards.
class NeonDivider extends StatelessWidget {
  const NeonDivider({
    super.key,
    required this.tokens,
    this.width = 44,
    this.thickness = 1,
  });

  final AppTokens tokens;
  final double width;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: width,
          height: thickness + 0.6,
          decoration: BoxDecoration(
            color: tokens.primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: AppEffects.glow(tokens.glow, strength: 0.5, blur: 8),
          ),
        ),
        Expanded(child: Container(height: thickness, color: tokens.border)),
      ],
    );
  }
}

/// Barra vertical luminosa que marca o início de um título de seção.
class SectionMarker extends StatelessWidget {
  const SectionMarker({super.key, required this.tokens, this.height = 16});

  final AppTokens tokens;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: tokens.primary,
        borderRadius: BorderRadius.circular(2),
        boxShadow: AppEffects.glow(tokens.glow, strength: 0.55, blur: 8),
      ),
    );
  }
}

/// Grade técnica tênue no fundo das telas. Dá a leitura de "terminal" sem
/// competir com o conteúdo.
class TechGridBackground extends StatelessWidget {
  const TechGridBackground({
    super.key,
    required this.tokens,
    required this.child,
    this.cell = 34,
    this.opacity = 0.05,
  });

  final AppTokens tokens;
  final Widget child;
  final double cell;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.backgroundGradient),
      child: CustomPaint(
        painter: _GridPainter(
          color: tokens.borderStrong.withValues(alpha: opacity),
          cell: cell,
        ),
        child: child,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color, required this.cell});

  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.cell != cell;
}
