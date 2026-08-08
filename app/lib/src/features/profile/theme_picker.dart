import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

/// Seção APARÊNCIA: escolha do tema visual com preview de cada opção.
///
/// A troca é aplicada imediatamente (sem reiniciar o app) e persistida
/// localmente e no perfil do usuário.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Aparência',
          subtitle: 'Tema ativo: ${current.name}',
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.86,
          children: AppThemes.all
              .map(
                (definition) => ThemePreviewCard(
                  definition: definition,
                  selected: definition.id == current.id,
                  onTap: () => ref.read(themeControllerProvider.notifier).select(definition.id),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// Preview de um tema: fundo, card, cor primária, botão e texto.
///
/// O preview é desenhado com os tokens **do tema representado**, não do tema
/// ativo — é o que permite comparar antes de escolher.
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.definition,
    required this.selected,
    required this.onTap,
  });

  final ThemeDefinition definition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = context.tokens; // tokens do tema ATIVO (moldura/seleção)
    final t = definition.tokens; // tokens do tema REPRESENTADO (preview)

    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema ${definition.name}',
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.all(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all(AppRadius.lg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active.surface,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(
                color: selected ? active.primary : active.border,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? AppEffects.glow(active.glow, strength: 0.20, blur: 20)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------- preview --------------------------
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: t.backgroundGradient,
                      borderRadius: AppRadius.all(AppRadius.sm),
                      border: Border.all(color: t.border),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // card com número em destaque
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius: AppRadius.all(AppRadius.xs),
                            border: Border.all(color: t.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 14,
                                width: 3,
                                decoration: BoxDecoration(
                                  color: t.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '82,5',
                                style: AppTypography.metric(13, color: t.textPrimary),
                              ),
                              const SizedBox(width: 3),
                              Text('KG', style: AppTypography.label(6.5, color: t.textMuted)),
                              const Spacer(),
                              Icon(Icons.check_circle_rounded, size: 11, color: t.primary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // barra de progresso
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            height: 4,
                            child: Row(
                              children: [
                                Expanded(flex: 7, child: ColoredBox(color: t.primary)),
                                Expanded(flex: 3, child: ColoredBox(color: t.track)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // linhas de texto
                        _FakeLine(color: t.textSecondary, widthFactor: 0.9),
                        const SizedBox(height: 4),
                        _FakeLine(color: t.textMuted, widthFactor: 0.6),
                        const Spacer(),
                        // botão primário
                        Container(
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.primary,
                            borderRadius: AppRadius.all(AppRadius.xs),
                            boxShadow: AppEffects.glow(t.glow, strength: 0.35, blur: 8),
                          ),
                          child: Text(
                            'TREINAR',
                            style: AppTypography.label(6.5, color: t.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // --------------------------- rótulo -------------------------
                Row(
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: AppEffects.glow(t.glow, strength: 0.5, blur: 6),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        definition.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                          size: 11,
                          weight: FontWeight.w700,
                          color: active.textPrimary,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded, size: 15, color: active.primary),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  definition.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    color: active.textMuted,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FakeLine extends StatelessWidget {
  const _FakeLine({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
