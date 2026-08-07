import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/router.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
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
    if (dayId == null) {
      dayId = await showModalBottomSheet<int>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qual treino de hoje?',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      workoutName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              ...days.map(
                (day) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      day.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: day.label.length > 2 ? 11 : 15,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(day.name),
                  subtitle: Text('${day.exerciseCount} exercícios'),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => Navigator.pop(context, day.id),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

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
            title: const Text('Treino em andamento'),
            content: const Text(
              'Você já tem um treino aberto. Quer continuar de onde parou ou começar este novo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'new'),
                child: const Text('Começar novo'),
              ),
              FilledButton(
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
