import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import '../session/start_session.dart';

class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({super.key, required this.workoutId});

  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutDetailProvider(workoutId));

    return Scaffold(
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
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(workoutDetailProvider(workout.id)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(workout.name, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TagChip(splitLabel(workout.splitType), icon: Icons.calendar_view_week_rounded),
              TagChip('${workout.days.length} dias', icon: Icons.today_rounded),
              TagChip('${workout.exerciseCount} exercícios', icon: Icons.fitness_center_rounded),
            ],
          ),
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              workout.notes!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    day.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: day.label.length > 2 ? 10 : 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.name, style: theme.textTheme.titleSmall),
                      Text(
                        '${day.exercises.length} exercícios · ${day.totalSets} séries',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                        ExerciseImage(url: exercise.resolvedImageUrl, size: 48, radius: 12),
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
                                '${exercise.targetSets} x ${exercise.targetReps} · descanso ${formatRest(exercise.restSeconds)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                                          color: Colors.amber.shade800,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
