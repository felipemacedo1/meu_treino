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
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
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
              icon: Icons.view_agenda_rounded,
              title: 'Nenhum treino ainda',
              message:
                  'Escolha uma divisão pronta (ABC, ABCD, ABCDE, Push Pull Legs, Upper/Lower) ou monte do zero.',
              action: Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => _createFromTemplate(context, ref),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Usar ficha pronta'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.workoutNew),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Montar do zero'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: context.tokens.primary,
            backgroundColor: context.tokens.surfaceElevated,
            onRefresh: () => ref.read(workoutsProvider.notifier).reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    final tokens = context.tokens;
    return AppPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
      onTap: () => context.push(AppRoutes.workout(workout.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText(splitLabel(workout.splitType), size: 9.5, color: tokens.primary),
                    const SizedBox(height: 5),
                    Text(
                      workout.name,
                      style: context.texts.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${workout.exerciseCount} exercícios · último ${relativeDate(workout.lastSessionAt)}',
                      style: context.texts.bodySmall
                          ?.copyWith(color: tokens.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: workout.days
                          .map(
                            (day) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _DayPill(label: day.label, count: day.exerciseCount),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => StartSessionFlow.fromWorkout(
                    context,
                    ref,
                    workoutId: workout.id,
                    workoutName: workout.name,
                    days: daysOfSummary(workout),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Treinar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilha compacta de dia: rótulo + quantidade de exercícios.
class _DayPill extends StatelessWidget {
  const _DayPill({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceSunken,
        borderRadius: AppRadius.all(AppRadius.xs),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.display(size: 10, weight: FontWeight.w800, color: tokens.primary),
          ),
          const SizedBox(width: 5),
          Text('$count', style: AppTypography.label(9.5, color: tokens.textMuted)),
        ],
      ),
    );
  }
}
