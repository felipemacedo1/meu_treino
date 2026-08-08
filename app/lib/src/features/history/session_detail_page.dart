import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

class SessionDetailPage extends ConsumerWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionDetailProvider(sessionId));
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            Text(
              data.title.toUpperCase(),
              style: AppTypography.display(
                size: 21,
                weight: FontWeight.w800,
                letterSpacing: -0.5,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            LabelText(formatDateTime(data.startedAt), size: 10),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Duração',
                    value: formatDuration(data.durationSeconds),
                    icon: Icons.timer_outlined,
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Volume',
                    value: formatVolume(data.totalVolume),
                    icon: Icons.speed_rounded,
                    color: tokens.chartColor(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Exercícios'),
            ...data.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppPanel(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ExerciseImage(url: exercise.resolvedImageUrl, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push(AppRoutes.exercise(exercise.exerciseId)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise.exerciseName, style: context.texts.titleSmall),
                                  if (exercise.substituted)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: TagChip(
                                        'trocado · era ${exercise.originalExerciseName}',
                                        icon: Icons.swap_horiz_rounded,
                                        color: tokens.warning,
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
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  color: set.completed
                                      ? tokens.primary.withValues(alpha: 0.12)
                                      : tokens.surfaceSunken,
                                  borderRadius: AppRadius.all(AppRadius.xs),
                                  border: Border.all(
                                    color: set.completed
                                        ? tokens.primary.withValues(alpha: 0.35)
                                        : tokens.border,
                                  ),
                                ),
                                child: Text(
                                  '${formatNumber(set.weight)}×${set.reps ?? 0}',
                                  style: AppTypography.display(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: set.completed ? tokens.primary : tokens.textMuted,
                                  ),
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
                            style: context.texts.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ),
            if (data.notes != null && data.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InfoPanel(icon: Icons.sticky_note_2_outlined, text: data.notes!),
            ],
          ],
        ),
      ),
    );
  }
}
