import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/session.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

/// Resumo mostrado logo depois de finalizar o treino.
class SessionSummaryPage extends ConsumerWidget {
  const SessionSummaryPage({super.key, required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          BrandBanner(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_rounded, color: tokens.onPrimary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'SESSÃO REGISTRADA',
                      style: AppTypography.label(11, color: tokens.onPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  session.title.toUpperCase(),
                  style: AppTypography.display(
                    size: 21,
                    weight: FontWeight.w800,
                    color: tokens.onPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDateTime(session.startedAt),
                  style: AppTypography.label(
                    10,
                    color: tokens.onPrimary.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.72,
            children: [
              StatCard(
                label: 'Duração',
                value: formatDuration(session.durationSeconds),
                icon: Icons.timer_outlined,
                color: tokens.primary,
              ),
              StatCard(
                label: 'Peso movimentado',
                value: formatVolume(session.totalVolume),
                icon: Icons.speed_rounded,
                color: tokens.chartColor(1),
              ),
              StatCard(
                label: 'Séries concluídas',
                value: '${session.totalSets}',
                icon: Icons.repeat_rounded,
                color: tokens.secondary,
              ),
              StatCard(
                label: 'Exercícios',
                value: '${session.exercises.length}',
                icon: Icons.fitness_center_rounded,
                color: tokens.accent,
              ),
            ],
          ),
          const SizedBox(height: 26),
          const SectionTitle('O que você fez'),
          ...session.exercises.map(
            (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppPanel(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    ExerciseImage(url: exercise.resolvedImageUrl, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.exerciseName,
                            style: context.texts.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exercise.sets
                                .where((set) => set.completed)
                                .map((set) => '${formatNumber(set.weight)}×${set.reps ?? 0}')
                                .join('   '),
                            style: AppTypography.display(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatVolume(exercise.volume),
                      style: AppTypography.metric(15, color: tokens.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            InfoPanel(icon: Icons.sticky_note_2_outlined, text: session.notes!),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Voltar ao início'),
          ),
        ],
      ),
    );
  }
}
