import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

// ===========================================================================
// Superfícies
// ===========================================================================

/// Painel padrão do design system: superfície + borda de 1px.
/// Com [accent] a borda recebe a cor da marca e um brilho leve.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.lg,
    this.accent = false,
    this.elevated = false,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool accent;
  final bool elevated;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: AppEffects.panel(
        tokens,
        radius: radius,
        accent: accent,
        elevated: elevated,
        borderColor: borderColor,
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: AppRadius.all(radius),
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.all(radius),
                child: content,
              ),
            ),
    );
  }
}

/// Faixa de destaque com o gradiente da marca. Usada com parcimônia:
/// meta da semana, treino em andamento e resumo do treino.
class BrandBanner extends StatelessWidget {
  const BrandBanner({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: AppEffects.brandBanner(tokens, radius: radius),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: AppRadius.all(radius),
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.all(radius),
                splashColor: tokens.onPrimary.withValues(alpha: 0.08),
                child: content,
              ),
            ),
    );
  }
}

// ===========================================================================
// Texto e títulos
// ===========================================================================

/// Rótulo técnico em caixa alta. Assinatura tipográfica do app.
class LabelText extends StatelessWidget {
  const LabelText(this.text, {super.key, this.size = 11, this.color, this.weight});

  final String text;
  final double size;
  final Color? color;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.label(
        size,
        color: color ?? context.tokens.textMuted,
        weight: weight,
      ),
    );
  }
}

/// Cabeçalho de seção: marcador luminoso + título + ação opcional.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 10),
            child: SectionMarker(tokens: tokens, height: subtitle == null ? 16 : 30),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: AppTypography.label(12.5, color: tokens.textPrimary)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      subtitle!,
                      style: context.texts.bodySmall?.copyWith(color: tokens.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ===========================================================================
// Métricas
// ===========================================================================

/// Número grande com rótulo. Base de todos os indicadores do app.
class MetricValue extends StatelessWidget {
  const MetricValue({
    super.key,
    required this.value,
    this.label,
    this.unit,
    this.size = 28,
    this.color,
    this.align = CrossAxisAlignment.start,
  });

  final String value;
  final String? label;
  final String? unit;
  final double size;
  final Color? color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          LabelText(label!, size: 10),
          const SizedBox(height: 5),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align == CrossAxisAlignment.center
              ? Alignment.center
              : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTypography.metric(size, color: color ?? tokens.textPrimary)),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: AppTypography.label(size * 0.36, color: tokens.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Card de estatística: ícone tingido, rótulo, número em destaque e dica.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    this.color,
    this.valueSize = 26,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final Color? color;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tint = color ?? tokens.primary;
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all(AppRadius.xs),
                  border: Border.all(color: tint.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, size: 15, color: tint),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.label(9.5, color: tokens.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.metric(valueSize, color: tokens.textPrimary),
              maxLines: 1,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                hint!,
                style: context.texts.bodySmall?.copyWith(color: tokens.textMuted, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// Barra de progresso fina com brilho — usada em metas, sessão e gráficos.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
    this.glow = true,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fill = color ?? tokens.progress;
    final safe = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: trackColor ?? tokens.track,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: safe == 0 ? 0.0001 : safe,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(height),
                boxShadow: glow ? AppEffects.glow(fill, strength: 0.55, blur: 10) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Chips e badges
// ===========================================================================

/// Etiqueta de informação. Sem preenchimento sólido: borda + tinta leve.
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.icon, this.color, this.dense = false});

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tint = color ?? tokens.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 9, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: AppRadius.all(AppRadius.xs),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 12.5, color: tint),
            const SizedBox(width: 5),
          ],
          Text(label, style: AppTypography.label(dense ? 9.5 : 10.5, color: tint)),
        ],
      ),
    );
  }
}

/// Etiqueta de rótulo de dia (A, B, PUSH...). Quadrada e luminosa.
class DayBadge extends StatelessWidget {
  const DayBadge({super.key, required this.label, this.size = 38, this.active = true});

  final String label;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tint = active ? tokens.primary : tokens.textMuted;
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: AppRadius.all(AppRadius.sm),
        border: Border.all(color: tint.withValues(alpha: 0.55)),
        boxShadow: active ? AppEffects.glow(tokens.glow, strength: 0.14, blur: 12) : null,
      ),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: AppTypography.display(
          size: label.length > 3 ? size * 0.24 : size * 0.4,
          weight: FontWeight.w800,
          color: tint,
        ),
      ),
    );
  }
}

// ===========================================================================
// Mídia
// ===========================================================================

/// Imagem do exercício, servida pelo nosso backend (que faz cache do wger).
class ExerciseImage extends StatelessWidget {
  const ExerciseImage({
    super.key,
    required this.url,
    this.size = 56,
    this.radius = AppRadius.sm,
    this.fallbackIcon = Icons.fitness_center_rounded,
  });

  final String? url;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surfaceSunken,
        borderRadius: AppRadius.all(radius),
        border: Border.all(color: tokens.border),
      ),
      child: Icon(fallbackIcon, color: tokens.primary.withValues(alpha: 0.55), size: size * 0.42),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: AppRadius.all(radius),
        border: Border.all(color: tokens.border),
        color: tokens.surfaceSunken,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.all(radius - 1),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => placeholder,
        ),
      ),
    );
  }
}

// ===========================================================================
// Estados
// ===========================================================================

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.08),
                borderRadius: AppRadius.all(AppRadius.lg),
                border: Border.all(color: tokens.primary.withValues(alpha: 0.30)),
                boxShadow: AppEffects.glow(tokens.glow, strength: 0.12, blur: 24),
              ),
              child: Icon(icon, size: 34, color: tokens.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title.toUpperCase(),
              style: AppTypography.display(size: 15, weight: FontWeight.w700, color: tokens.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_tethering_error_rounded,
      title: 'Falha na conexão',
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar de novo'),
            ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 34,
            width: 34,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: tokens.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            LabelText(message!, size: 10.5),
          ],
        ],
      ),
    );
  }
}

/// Bloco de carregamento com a altura de um card, para não "pular" o layout.
class PanelSkeleton extends StatelessWidget {
  const PanelSkeleton({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: tokens.border),
      ),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary),
        ),
      ),
    );
  }
}

/// Erro compacto, para usar dentro de uma lista sem ocupar a tela toda.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppPanel(
      borderColor: tokens.error.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: tokens.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card informativo neutro (dicas, estados "ainda sem dados").
class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.text, this.icon = Icons.insights_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppPanel(
      child: Row(
        children: [
          Icon(icon, color: tokens.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Feedback
// ===========================================================================

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final tokens = context.tokens;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: Duration(seconds: error ? 4 : 2),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 18,
              color: error ? tokens.error : tokens.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodyMedium?.copyWith(color: tokens.textPrimary),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          side: BorderSide(color: error ? tokens.error.withValues(alpha: 0.5) : tokens.borderStrong),
        ),
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final tokens = context.tokens;
      return AlertDialog(
        title: Text(title.toUpperCase(), style: AppTypography.display(size: 16, weight: FontWeight.w700)),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: tokens.error,
                    foregroundColor: tokens.textPrimary,
                    minimumSize: const Size(0, 46),
                  )
                : FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}


// ===========================================================================
// Números estáveis
// ===========================================================================

/// Renderiza números com largura de caractere uniforme.
///
/// As fontes do app (Chakra Petch e Rajdhani) não têm `tnum` e seus dígitos
/// têm larguras diferentes — em um cronômetro isso faz o texto "tremer" a cada
/// segundo. Aqui cada caractere é desenhado em uma célula do tamanho do dígito
/// mais largo, medido em tempo de execução (funciona com qualquer fonte).
class MonoDigits extends StatelessWidget {
  const MonoDigits(
    this.text, {
    super.key,
    required this.style,
    this.separatorFactor = 0.5,
  });

  final String text;
  final TextStyle style;

  /// Caracteres como `:` e `/` não precisam de uma célula inteira.
  final double separatorFactor;

  static const _separators = {':', '/', '.', ',', ' '};

  double _widestDigit(TextStyle style, double scale) {
    var widest = 0.0;
    for (var digit = 0; digit <= 9; digit++) {
      final painter = TextPainter(
        text: TextSpan(text: '$digit', style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.linear(scale),
      )..layout();
      widest = widest > painter.width ? widest : painter.width;
    }
    return widest;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final cell = _widestDigit(style, scale);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) {
        final isSeparator = _separators.contains(char);
        return SizedBox(
          width: isSeparator ? cell * separatorFactor : cell,
          child: Text(char, style: style, textAlign: TextAlign.center),
        );
      }).toList(),
    );
  }
}
