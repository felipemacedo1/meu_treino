import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import '../session/start_session.dart';
import 'split_picker_sheet.dart';

class WorkoutsPage extends ConsumerWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Meus treinos'),
        actions: [
          IconButton(
            tooltip: 'Criar do zero',
            onPressed: () => context.push(AppRoutes.workoutNew),
            icon: const Icon(Icons.edit_note_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createFromTemplate(context, ref),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Ficha pronta'),
      ),
      body: workouts.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.read(workoutsProvider.notifier).reload(),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.list_alt_rounded,
              title: 'Nenhum treino ainda',
              message:
                  'Escolha uma divisão pronta (ABC, ABCD, ABCDE, Push Pull Legs, Upper/Lower) ou monte do zero.',
              action: Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => _createFromTemplate(context, ref),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Usar ficha pronta'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.workoutNew),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Montar do zero'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(workoutsProvider.notifier).reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _WorkoutTile(
                workout: list[index],
                onDuplicate: () => _duplicate(context, ref, list[index]),
                onDelete: () => _delete(context, ref, list[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createFromTemplate(BuildContext context, WidgetRef ref) async {
    final choice = await SplitPickerSheet.show(context);
    if (choice == null || !context.mounted) return;
    try {
      final workout = await ref
          .read(workoutsProvider.notifier)
          .createFromTemplate(choice.splitType, name: choice.name);
      if (context.mounted) {
        showAppSnack(context, 'Ficha "${workout.name}" criada!');
        context.push(AppRoutes.workout(workout.id));
      }
    } catch (error) {
      if (context.mounted) showAppSnack(context, error.toString(), error: true);
    }
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref, WorkoutSummary workout) async {
    try {
      await ref.read(workoutsProvider.notifier).duplicate(workout.id);
      if (context.mounted) showAppSnack(context, 'Treino duplicado.');
    } catch (error) {
      if (context.mounted) showAppSnack(context, error.toString(), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, WorkoutSummary workout) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir treino',
      message: 'Excluir "${workout.name}"? O histórico das sessões é mantido.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(workoutsProvider.notifier).delete(workout.id);
      if (context.mounted) showAppSnack(context, 'Treino excluído.');
    } catch (error) {
      if (context.mounted) showAppSnack(context, error.toString(), error: true);
    }
  }
}

class _WorkoutTile extends ConsumerWidget {
  const _WorkoutTile({
    required this.workout,
    required this.onDuplicate,
    required this.onDelete,
  });

  final WorkoutSummary workout;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(AppRoutes.workout(workout.id)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workout.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${splitLabel(workout.splitType)} · ${workout.exerciseCount} exercícios · último ${relativeDate(workout.lastSessionAt)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => switch (value) {
                      'edit' => context.push(AppRoutes.workoutEdit(workout.id)),
                      'duplicate' => onDuplicate(),
                      'delete' => onDelete(),
                      _ => null,
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy_rounded),
                          title: Text('Duplicar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Excluir'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: workout.days
                    .map((day) => TagChip('${day.label} · ${day.exerciseCount}'))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => StartSessionFlow.fromWorkout(
                        context,
                        ref,
                        workoutId: workout.id,
                        workoutName: workout.name,
                        days: daysOfSummary(workout),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Treinar agora'),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.workout(workout.id)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text('Ver ficha'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
