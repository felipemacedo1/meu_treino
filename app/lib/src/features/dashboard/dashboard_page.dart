import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_controller.dart';
import '../../theme/theme.dart';
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
    final tokens = context.tokens;

    return RefreshIndicator(
      color: tokens.primary,
      backgroundColor: tokens.surfaceElevated,
      onRefresh: () async {
        ref.invalidate(statsOverviewProvider);
        ref.invalidate(historyProvider);
        await ref.read(workoutsProvider.notifier).reload();
        await ref.read(activeSessionProvider.notifier).refreshActive();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          _Greeting(name: auth.user?.name, initials: auth.user?.initials ?? '?'),
          const SizedBox(height: 20),
          if (activeSession != null && activeSession.inProgress)
            _ResumeCard(
              title: activeSession.title,
              completed: activeSession.completedSets,
              planned: activeSession.plannedSets,
              progress: activeSession.progress,
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
              loading: () => const PanelSkeleton(height: 176),
              error: (error, _) => InlineError(message: '$error'),
            ),
          const SizedBox(height: 22),
          overview.when(
            data: (data) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.72,
              children: [
                StatCard(
                  label: 'Treinos realizados',
                  value: '${data.totalSessions}',
                  icon: Icons.check_circle_outline_rounded,
                  color: tokens.primary,
                ),
                StatCard(
                  label: 'Peso movimentado',
                  value: formatVolume(data.totalVolume),
                  icon: Icons.speed_rounded,
                  color: tokens.chartColor(1),
                ),
                StatCard(
                  label: 'Dias consecutivos',
                  value: '${data.currentStreak}',
                  hint: 'recorde: ${data.longestStreak}',
                  icon: Icons.local_fire_department_rounded,
                  color: tokens.accent,
                ),
                StatCard(
                  label: 'Séries totais',
                  value: '${data.totalSets}',
                  hint: 'média ${data.avgSessionMinutes} min/treino',
                  icon: Icons.repeat_rounded,
                  color: tokens.secondary,
                ),
              ],
            ),
            loading: () => const PanelSkeleton(height: 230),
            error: (error, _) => InlineError(message: '$error'),
          ),
          const SizedBox(height: 26),
          SectionTitle(
            'Meus treinos',
            action: TextButton(onPressed: onSeeAllWorkouts, child: const Text('Ver todos')),
          ),
          workouts.when(
            data: (list) {
              if (list.isEmpty) return _EmptyWorkoutsCard(onTap: onSeeAllWorkouts);
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
            loading: () => const PanelSkeleton(),
            error: (error, _) => InlineError(message: '$error'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => StartSessionFlow.freeSession(context, ref),
            icon: const Icon(Icons.bolt_rounded, size: 18),
            label: const Text('Treino livre'),
          ),
          const SizedBox(height: 26),
          const SectionTitle('Últimos treinos'),
          history.when(
            data: (paged) {
              if (paged.items.isEmpty) {
                return const InfoPanel(
                  icon: Icons.history_rounded,
                  text: 'Seu histórico aparece aqui depois do primeiro treino concluído.',
                );
              }
              return Column(
                children: paged.items
                    .take(4)
                    .map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppPanel(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          onTap: () => context.push(AppRoutes.sessionDetail(session.id)),
                          child: Row(
                            children: [
                              DayBadge(label: session.dayLabel ?? 'L', size: 34),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.dayName ?? session.workoutName ?? 'Treino',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.texts.bodyLarge
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${relativeDate(session.startedAt)} · ${session.totalSets} séries',
                                      style: context.texts.bodySmall
                                          ?.copyWith(color: tokens.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatVolume(session.totalVolume),
                                    style: AppTypography.metric(15, color: tokens.primary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatDuration(session.durationSeconds),
                                    style: context.texts.bodySmall
                                        ?.copyWith(color: tokens.textMuted, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const PanelSkeleton(height: 90),
            error: (error, _) => InlineError(message: '$error'),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.initials});

  final String? name;
  final String initials;

  String get _period {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabelText(_period, size: 10, color: tokens.primary),
              const SizedBox(height: 4),
              Text(
                (name?.split(' ').first ?? 'Atleta').toUpperCase(),
                style: AppTypography.display(
                  size: 26,
                  weight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: tokens.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          height: 46,
          width: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.all(AppRadius.sm),
            border: Border.all(color: tokens.primary.withValues(alpha: 0.5)),
          ),
          child: Text(
            initials,
            style: AppTypography.display(size: 15, weight: FontWeight.w800, color: tokens.primary),
          ),
        ),
      ],
    );
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
    final tokens = context.tokens;
    final progress = weeklyGoal == 0 ? 0.0 : (sessionsThisWeek / weeklyGoal).clamp(0.0, 1.0);
    final done = sessionsThisWeek >= weeklyGoal;

    return AppPanel(
      accent: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LabelText('Meta da semana', size: 10, color: tokens.primary),
              const Spacer(),
              if (done)
                TagChip('concluída', icon: Icons.verified_rounded, color: tokens.success, dense: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressRing(progress: progress, current: sessionsThisWeek, goal: weeklyGoal),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done
                          ? 'Meta batida.'
                          : 'Faltam ${weeklyGoal - sessionsThisWeek} treino(s).',
                      style: AppTypography.display(
                        size: 16,
                        weight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            label: 'Sequência',
                            value: '$streak',
                            unit: streak == 1 ? 'dia' : 'dias',
                            icon: Icons.local_fire_department_rounded,
                            color: tokens.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniMetric(
                            label: 'Volume',
                            value: formatVolume(volumeThisWeek),
                            icon: Icons.speed_rounded,
                            color: tokens.chartColor(1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Expanded(child: LabelText(label, size: 9)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: AppTypography.metric(17, color: tokens.textPrimary)),
            if (unit != null) ...[
              const SizedBox(width: 3),
              Text(unit!, style: AppTypography.label(9, color: tokens.textMuted)),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.current, required this.goal});

  final double progress;
  final int current;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 92,
      width: 92,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 92,
              width: 92,
              child: CircularProgressIndicator(value: 1, strokeWidth: 7, color: tokens.track),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: value > 0.01
                    ? AppEffects.glow(tokens.glow, strength: 0.20, blur: 16)
                    : null,
              ),
              child: SizedBox(
                height: 92,
                width: 92,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  color: tokens.primary,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$current', style: AppTypography.metric(30, color: tokens.primary)),
                LabelText('de $goal', size: 9),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.title,
    required this.completed,
    required this.planned,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final int completed;
  final int planned;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return BrandBanner(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sensors_rounded, size: 14, color: tokens.onPrimary),
              const SizedBox(width: 6),
              Text(
                'TREINO EM ANDAMENTO',
                style: AppTypography.label(10, color: tokens.onPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: tokens.onPrimary.withValues(alpha: 0.18),
                  borderRadius: AppRadius.all(AppRadius.xs),
                ),
                child: Icon(Icons.play_arrow_rounded, color: tokens.onPrimary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title.toUpperCase(),
            style: AppTypography.display(
              size: 19,
              weight: FontWeight.w800,
              color: tokens.onPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          ProgressTrack(
            value: progress,
            height: 5,
            glow: false,
            color: tokens.onPrimary,
            trackColor: tokens.onPrimary.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed de $planned séries concluídas',
            style: AppTypography.label(10, color: tokens.onPrimary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({required this.workout});

  final WorkoutSummary workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    return AppPanel(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(AppRoutes.workout(workout.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: context.texts.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    TagChip(splitLabel(workout.splitType), color: tokens.primary, dense: true),
                    TagChip('${workout.exerciseCount} exercícios', dense: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Último: ${relativeDate(workout.lastSessionAt)}',
                  style: context.texts.bodySmall
                      ?.copyWith(color: tokens.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PlayButton(
            onTap: () => StartSessionFlow.fromWorkout(
              context,
              ref,
              workoutId: workout.id,
              workoutName: workout.name,
              days: daysOfSummary(workout),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão redondo de iniciar treino, com brilho na cor da marca.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.primary,
      borderRadius: AppRadius.all(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all(AppRadius.sm),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            borderRadius: AppRadius.all(AppRadius.sm),
            boxShadow: AppEffects.glow(tokens.glow, strength: 0.35, blur: 16),
          ),
          child: Icon(Icons.play_arrow_rounded, color: tokens.onPrimary, size: 26),
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
    final tokens = context.tokens;
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, size: 18, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                'NENHUMA FICHA AINDA',
                style: AppTypography.label(11, color: tokens.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Monte em segundos com uma divisão pronta: ABC, ABCD, ABCDE, Push Pull Legs ou Upper/Lower.',
            style: context.texts.bodySmall?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Criar meu treino'),
          ),
        ],
      ),
    );
  }
}
