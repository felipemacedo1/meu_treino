import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/common.dart';
import '../session/start_session.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key, required this.onSeeAllWorkouts});

  final VoidCallback onSeeAllWorkouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final overview = ref.watch(statsOverviewProvider);
    final workouts = ref.watch(workoutsProvider);
    final history = ref.watch(historyProvider);
    final activeSession = ref.watch(activeSessionProvider).value;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(statsOverviewProvider);
        ref.invalidate(historyProvider);
        await ref.read(workoutsProvider.notifier).reload();
        await ref.read(activeSessionProvider.notifier).refreshActive();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      auth.user?.name.split(' ').first ?? 'Atleta',
                      style: theme.textTheme.headlineSmall?.copyWith(fontSize: 26),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  auth.user?.initials ?? '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (activeSession != null && activeSession.inProgress)
            _ResumeCard(
              title: activeSession.title,
              completed: activeSession.completedSets,
              planned: activeSession.plannedSets,
              onTap: () => context.push(AppRoutes.session),
            )
          else
            overview.when(
              data: (data) => _WeekCard(
                sessionsThisWeek: data.sessionsThisWeek,
                weeklyGoal: data.weeklyGoal,
                streak: data.currentStreak,
                volumeThisWeek: data.volumeThisWeek,
              ),
              loading: () => const _CardSkeleton(height: 168),
              error: (error, _) => _CardError(message: '$error'),
            ),
          const SizedBox(height: 22),
          overview.when(
            data: (data) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                StatCard(
                  label: 'Treinos realizados',
                  value: '${data.totalSessions}',
                  icon: Icons.check_circle_outline_rounded,
                ),
                StatCard(
                  label: 'Peso movimentado',
                  value: formatVolume(data.totalVolume),
                  icon: Icons.scale_rounded,
                  color: AppTheme.accent,
                ),
                StatCard(
                  label: 'Dias consecutivos',
                  value: '${data.currentStreak}',
                  hint: 'recorde: ${data.longestStreak}',
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.deepOrange,
                ),
                StatCard(
                  label: 'Séries totais',
                  value: '${data.totalSets}',
                  hint: 'média ${data.avgSessionMinutes} min/treino',
                  icon: Icons.repeat_rounded,
                  color: Colors.indigo,
                ),
              ],
            ),
            loading: () => const _CardSkeleton(height: 220),
            error: (error, _) => _CardError(message: '$error'),
          ),
          const SizedBox(height: 26),
          SectionTitle(
            'Meus treinos',
            action: TextButton(onPressed: onSeeAllWorkouts, child: const Text('Ver todos')),
          ),
          workouts.when(
            data: (list) {
              if (list.isEmpty) {
                return _EmptyWorkoutsCard(onTap: onSeeAllWorkouts);
              }
              return Column(
                children: list
                    .take(3)
                    .map(
                      (workout) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WorkoutCard(workout: workout),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const _CardSkeleton(height: 120),
            error: (error, _) => _CardError(message: '$error'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => StartSessionFlow.freeSession(context, ref),
            icon: const Icon(Icons.bolt_rounded),
            label: const Text('Treino livre (sem ficha)'),
          ),
          const SizedBox(height: 26),
          const SectionTitle('Últimos treinos'),
          history.when(
            data: (paged) {
              if (paged.items.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Seu histórico aparece aqui depois do primeiro treino.'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: paged.items
                    .take(4)
                    .map(
                      (session) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => context.push(AppRoutes.sessionDetail(session.id)),
                          leading: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fitness_center_rounded,
                              size: 18,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${relativeDate(session.startedAt)} · ${formatVolume(session.totalVolume)} · ${session.totalSets} séries',
                          ),
                          trailing: Text(formatDuration(session.durationSeconds)),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const _CardSkeleton(height: 90),
            error: (error, _) => _CardError(message: '$error'),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.sessionsThisWeek,
    required this.weeklyGoal,
    required this.streak,
    required this.volumeThisWeek,
  });

  final int sessionsThisWeek;
  final int weeklyGoal;
  final int streak;
  final double volumeThisWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = weeklyGoal == 0 ? 0.0 : (sessionsThisWeek / weeklyGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: appGradient(theme.colorScheme),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 96,
            width: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 96,
                  width: 96,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$sessionsThisWeek',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      'de $weeklyGoal',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meta da semana',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  sessionsThisWeek >= weeklyGoal
                      ? 'Meta batida. Excelente!'
                      : 'Faltam ${weeklyGoal - sessionsThisWeek} treino(s).',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _WhiteChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '$streak dia(s)',
                    ),
                    _WhiteChip(icon: Icons.scale_rounded, label: formatVolume(volumeThisWeek)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteChip extends StatelessWidget {
  const _WhiteChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.title,
    required this.completed,
    required this.planned,
    required this.onTap,
  });

  final String title;
  final int completed;
  final int planned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: appGradient(theme.colorScheme),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Treino em andamento',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$completed de $planned séries concluídas',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.play_arrow_rounded, color: theme.colorScheme.primary, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({required this.workout});

  final WorkoutSummary workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(AppRoutes.workout(workout.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      '${splitLabel(workout.splitType)} · ${workout.dayCount} dias · ${workout.exerciseCount} exercícios',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Último: ${relativeDate(workout.lastSessionAt)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => StartSessionFlow.fromWorkout(
                  context,
                  ref,
                  workoutId: workout.id,
                  workoutName: workout.name,
                  days: daysOfSummary(workout),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Treinar'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkoutsCard extends StatelessWidget {
  const _EmptyWorkoutsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Você ainda não tem uma ficha', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Crie em segundos usando uma divisão pronta: ABC, ABCD, ABCDE, Push Pull Legs ou Upper/Lower.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar meu treino'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _CardError extends StatelessWidget {
  const _CardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
