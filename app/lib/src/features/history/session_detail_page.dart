import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class SessionDetailPage extends ConsumerWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionDetailProvider(sessionId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Treino realizado')),
      body: session.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(sessionDetailProvider(sessionId)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(data.title, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              formatDateTime(data.startedAt),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Duração',
                    value: formatDuration(data.durationSeconds),
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Volume',
                    value: formatVolume(data.totalVolume),
                    icon: Icons.scale_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Exercícios'),
            ...data.exercises.map(
              (exercise) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ExerciseImage(url: exercise.resolvedImageUrl, size: 46, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push(AppRoutes.exercise(exercise.exerciseId)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise.exerciseName, style: theme.textTheme.titleSmall),
                                  if (exercise.substituted)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: TagChip(
                                        'trocado · era ${exercise.originalExerciseName}',
                                        icon: Icons.swap_horiz_rounded,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exercise.sets
                            .map(
                              (set) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: set.completed
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${set.setNumber}: ${formatNumber(set.weight)}kg x ${set.reps ?? 0}',
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (exercise.notes != null && exercise.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            exercise.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (data.notes != null && data.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.sticky_note_2_outlined),
                      const SizedBox(width: 12),
                      Expanded(child: Text(data.notes!)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
