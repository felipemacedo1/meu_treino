import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
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
    final theme = Theme.of(context);

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
            Text('Montar ficha pronta', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'A gente já preenche os exercícios, séries, repetições e descanso. Depois você ajusta tudo.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ...options.map(
              (option) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(
                    context,
                    (splitType: option.code, name: 'Treino ${option.name}'),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${option.dayNames.length}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(option.name, style: theme.textTheme.titleSmall),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          option.description,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
