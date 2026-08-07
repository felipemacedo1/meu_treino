import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/session.dart';
import '../../widgets/common.dart';

/// Resumo mostrado logo depois de finalizar o treino.
class SessionSummaryPage extends ConsumerWidget {
  const SessionSummaryPage({super.key, required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Treino concluído'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: appGradient(theme.colorScheme),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 14),
                Text(
                  'Boa! Treino registrado.',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  '${session.title} · ${formatDateTime(session.startedAt)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              StatCard(
                label: 'Duração',
                value: formatDuration(session.durationSeconds),
                icon: Icons.timer_outlined,
              ),
              StatCard(
                label: 'Peso movimentado',
                value: formatVolume(session.totalVolume),
                icon: Icons.scale_rounded,
                color: AppTheme.accent,
              ),
              StatCard(
                label: 'Séries concluídas',
                value: '${session.totalSets}',
                icon: Icons.repeat_rounded,
                color: Colors.indigo,
              ),
              StatCard(
                label: 'Exercícios',
                value: '${session.exercises.length}',
                icon: Icons.fitness_center_rounded,
                color: Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: 26),
          const SectionTitle('O que você fez'),
          ...session.exercises.map(
            (exercise) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ExerciseImage(url: exercise.resolvedImageUrl, size: 46, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.exerciseName,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            exercise.sets
                                .where((set) => set.completed)
                                .map((set) =>
                                    '${formatNumber(set.weight)}kg x ${set.reps ?? 0}')
                                .join('  ·  '),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(formatVolume(exercise.volume), style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
            ),
          ),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.sticky_note_2_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(session.notes!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Voltar ao início'),
          ),
        ],
      ),
    );
  }
}
