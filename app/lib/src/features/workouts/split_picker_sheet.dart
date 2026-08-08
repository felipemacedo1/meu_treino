import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

/// Escolha da divisão para montar a ficha automaticamente.
class SplitPickerSheet extends ConsumerWidget {
  const SplitPickerSheet({super.key});

  static Future<({String splitType, String name})?> show(BuildContext context) {
    return showModalBottomSheet<({String splitType, String name})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SplitPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splits = ref.watch(splitOptionsProvider);
    final tokens = context.tokens;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scrollController) => splits.when(
        loading: () => const SizedBox(height: 300, child: LoadingView()),
        error: (error, _) => SizedBox(
          height: 300,
          child: ErrorView(
            message: '$error',
            onRetry: () => ref.invalidate(splitOptionsProvider),
          ),
        ),
        data: (options) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const SectionTitle(
              'Montar ficha pronta',
              subtitle: 'Exercícios, séries, repetições e descanso já preenchidos. '
                  'Depois você ajusta tudo.',
            ),
            const SizedBox(height: 6),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppPanel(
                  onTap: () => Navigator.pop(
                    context,
                    (splitType: option.code, name: 'Treino ${option.name}'),
                  ),
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            DayBadge(label: '${option.dayNames.length}x', size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(option.name, style: context.texts.titleMedium),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: tokens.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          option.description,
                          style: context.texts.bodySmall?.copyWith(color: tokens.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: option.dayNames.map((name) => TagChip(name)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
