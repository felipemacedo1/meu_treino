import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/router.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

/// Fluxo de inicio de treino, compartilhado pelo dashboard e pela lista de treinos.
class StartSessionFlow {
  const StartSessionFlow._();

  /// Escolhe o dia (A/B/C...) e inicia a sessao.
  static Future<void> fromWorkout(
    BuildContext context,
    WidgetRef ref, {
    required int workoutId,
    required String workoutName,
    required List<({int id, String label, String name, int exerciseCount})> days,
  }) async {
    if (days.isEmpty) {
      showAppSnack(context, 'Esse treino ainda não tem exercícios.', error: true);
      return;
    }

    int? dayId = days.length == 1 ? days.first.id : null;
    dayId ??= await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        final tokens = context.tokens;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                child: SectionTitle('Qual treino de hoje?', subtitle: workoutName),
              ),
              ...days.map(
                (day) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: AppPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => Navigator.pop(context, day.id),
                    child: Row(
                      children: [
                        DayBadge(label: day.label, size: 40),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day.name, style: context.texts.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                '${day.exerciseCount} exercícios',
                                style: context.texts.bodySmall
                                    ?.copyWith(color: tokens.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.play_arrow_rounded, color: tokens.primary, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (dayId == null || !context.mounted) return;
    await _start(context, ref, workoutId: workoutId, workoutDayId: dayId);
  }

  /// Treino livre: sessao vazia onde o usuario adiciona exercicios na hora.
  static Future<void> freeSession(BuildContext context, WidgetRef ref) =>
      _start(context, ref, workoutId: null, workoutDayId: null);

  static Future<void> _start(
    BuildContext context,
    WidgetRef ref, {
    int? workoutId,
    int? workoutDayId,
    bool discardActive = false,
  }) async {
    try {
      await ref.read(activeSessionProvider.notifier).start(
            workoutId: workoutId,
            workoutDayId: workoutDayId,
            discardActive: discardActive,
          );
      if (context.mounted) context.push(AppRoutes.session);
    } on ApiException catch (error) {
      if (!context.mounted) return;
      if (error.isConflict) {
        final resume = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'TREINO EM ANDAMENTO',
              style: AppTypography.display(size: 16, weight: FontWeight.w700),
            ),
            content: const Text(
              'Você já tem um treino aberto. Quer continuar de onde parou ou começar este novo?',
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'new'),
                child: const Text('Começar novo'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: () => Navigator.pop(context, 'resume'),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        if (resume == 'resume') {
          await ref.read(activeSessionProvider.notifier).refreshActive();
          if (context.mounted) context.push(AppRoutes.session);
        } else if (resume == 'new') {
          await _start(
            context,
            ref,
            workoutId: workoutId,
            workoutDayId: workoutDayId,
            discardActive: true,
          );
        }
      } else {
        showAppSnack(context, error.message, error: true);
      }
    } catch (error) {
      if (context.mounted) showAppSnack(context, error.toString(), error: true);
    }
  }
}

/// Converte os dias de um resumo/treino para o formato usado no seletor.
List<({int id, String label, String name, int exerciseCount})> daysOfSummary(
  WorkoutSummary summary,
) =>
    summary.days
        .map((d) => (id: d.id, label: d.label, name: d.name, exerciseCount: d.exerciseCount))
        .toList();

List<({int id, String label, String name, int exerciseCount})> daysOfWorkout(Workout workout) =>
    workout.days
        .where((d) => d.id != null)
        .map((d) => (
              id: d.id!,
              label: d.label,
              name: d.name,
              exerciseCount: d.exercises.length,
            ))
        .toList();
