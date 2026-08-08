import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import '../session/start_session.dart';

class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({super.key, required this.workoutId});

  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutDetailProvider(workoutId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ficha de treino'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () => context.push(AppRoutes.workoutEdit(workoutId)),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Duplicar',
            onPressed: () async {
              try {
                final copy = await ref.read(workoutsProvider.notifier).duplicate(workoutId);
                if (context.mounted) {
                  showAppSnack(context, 'Criado: ${copy.name}');
                  context.pushReplacement(AppRoutes.workout(copy.id));
                }
              } catch (error) {
                if (context.mounted) showAppSnack(context, error.toString(), error: true);
              }
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: workout.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(workoutDetailProvider(workoutId)),
        ),
        data: (data) => _Content(workout: data),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    return RefreshIndicator(
      color: tokens.primary,
      backgroundColor: tokens.surfaceElevated,
      onRefresh: () async => ref.invalidate(workoutDetailProvider(workout.id)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            workout.name.toUpperCase(),
            style: AppTypography.display(
              size: 23,
              weight: FontWeight.w800,
              letterSpacing: -0.6,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TagChip(
                splitLabel(workout.splitType),
                icon: Icons.calendar_view_week_rounded,
                color: tokens.primary,
              ),
              TagChip('${workout.days.length} dias', icon: Icons.today_rounded),
              TagChip('${workout.exerciseCount} exercícios', icon: Icons.fitness_center_rounded),
            ],
          ),
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              workout.notes!,
              style: context.texts.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => StartSessionFlow.fromWorkout(
              context,
              ref,
              workoutId: workout.id,
              workoutName: workout.name,
              days: daysOfWorkout(workout),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Iniciar treino'),
          ),
          const SizedBox(height: 26),
          ...workout.days.map((day) => _DayCard(day: day, workout: workout)),
        ],
      ),
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({required this.day, required this.workout});

  final WorkoutDayItem day;
  final Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DayBadge(label: day.label),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.name, style: context.texts.titleSmall),
                      Text(
                        '${day.exercises.length} exercícios · ${day.totalSets} séries',
                        style: context.texts.bodySmall?.copyWith(color: tokens.textMuted),
                      ),
                    ],
                  ),
                ),
                if (day.id != null)
                  IconButton.filledTonal(
                    tooltip: 'Treinar este dia',
                    onPressed: () => StartSessionFlow.fromWorkout(
                      context,
                      ref,
                      workoutId: workout.id,
                      workoutName: workout.name,
                      days: [
                        (
                          id: day.id!,
                          label: day.label,
                          name: day.name,
                          exerciseCount: day.exercises.length,
                        )
                      ],
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
              ],
            ),
            if (day.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Nenhum exercício neste dia ainda.',
                  style: context.texts.bodySmall?.copyWith(color: tokens.textMuted),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              const Divider(),
              ...day.exercises.map(
                (exercise) => InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push(AppRoutes.exercise(exercise.exerciseId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        ExerciseImage(url: exercise.resolvedImageUrl, size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.exerciseName,
                                style: context.texts.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${exercise.targetSets} x ${exercise.targetReps} · descanso ${formatRest(exercise.restSeconds)}',
                                style: context.texts.bodySmall
                                    ?.copyWith(color: tokens.textMuted, fontSize: 12),
                              ),
                              if (exercise.lastWeight != null || exercise.bestWeight != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Wrap(
                                    spacing: 6,
                                    children: [
                                      if (exercise.lastWeight != null)
                                        TagChip(
                                          'anterior ${formatWeight(exercise.lastWeight)}',
                                          icon: Icons.history_rounded,
                                        ),
                                      if (exercise.bestWeight != null)
                                        TagChip(
                                          'recorde ${formatWeight(exercise.bestWeight)}',
                                          icon: Icons.emoji_events_rounded,
                                          color: tokens.accent,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: tokens.textMuted, size: 20),
                      ],
                    ),
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
