import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/workout.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import '../exercises/exercises_page.dart';
import 'exercise_config_sheet.dart';

/// Editor de ficha: cria um treino novo ou edita um existente.
class WorkoutEditorPage extends ConsumerStatefulWidget {
  const WorkoutEditorPage({super.key, this.workoutId});

  final int? workoutId;

  @override
  ConsumerState<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends ConsumerState<WorkoutEditorPage> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  String _splitType = 'CUSTOM';
  List<WorkoutDayItem> _days = [];
  int _dayIndex = 0;
  bool _loaded = false;
  bool _saving = false;

  static const _splitOptions = ['CUSTOM', 'ABC', 'ABCD', 'ABCDE', 'PPL', 'UPPER_LOWER', 'FULL_BODY'];

  bool get isNew => widget.workoutId == null;

  @override
  void initState() {
    super.initState();
    if (isNew) {
      _name.text = 'Meu treino';
      _days = [const WorkoutDayItem(label: 'A', name: 'Treino A', exercises: [])];
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate(Workout workout) {
    if (_loaded) return;
    _name.text = workout.name;
    _notes.text = workout.notes ?? '';
    _splitType = workout.splitType;
    _days = workout.days
        .map((day) => WorkoutDayItem(
              id: day.id,
              label: day.label,
              name: day.name,
              exercises: List.of(day.exercises),
            ))
        .toList();
    if (_days.isEmpty) {
      _days = [const WorkoutDayItem(label: 'A', name: 'Treino A', exercises: [])];
    }
    _loaded = true;
  }

  WorkoutDayItem get _currentDay => _days[_dayIndex.clamp(0, _days.length - 1)];

  void _updateCurrentDay(WorkoutDayItem day) {
    setState(() => _days[_dayIndex] = day);
  }

  Future<void> _addExercise() async {
    final picked = await pickExercise(context, title: 'Adicionar exercício');
    if (picked == null) return;
    final item = WorkoutExerciseItem(
      exerciseId: picked.id,
      exerciseName: picked.name,
      imageUrl: picked.imageUrl,
      primaryMuscles: picked.primaryMuscles,
      equipment: picked.equipment,
      targetSets: 3,
      targetReps: '10',
      restSeconds: 90,
    );
    _updateCurrentDay(_currentDay.copyWith(exercises: [..._currentDay.exercises, item]));
  }

  Future<void> _configureExercise(int index) async {
    final updated = await ExerciseConfigSheet.show(context, _currentDay.exercises[index]);
    if (updated == null) return;
    final list = List.of(_currentDay.exercises);
    list[index] = updated;
    _updateCurrentDay(_currentDay.copyWith(exercises: list));
  }

  void _removeExercise(int index) {
    final list = List.of(_currentDay.exercises)..removeAt(index);
    _updateCurrentDay(_currentDay.copyWith(exercises: list));
  }

  void _reorder(int oldIndex, int newIndex) {
    final list = List.of(_currentDay.exercises);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _updateCurrentDay(_currentDay.copyWith(exercises: list));
  }

  Future<void> _addDay() async {
    final nextLabel = String.fromCharCode('A'.codeUnitAt(0) + _days.length.clamp(0, 20));
    final result = await _dayDialog(label: nextLabel, name: 'Treino $nextLabel');
    if (result == null) return;
    setState(() {
      _days.add(WorkoutDayItem(label: result.label, name: result.name, exercises: const []));
      _dayIndex = _days.length - 1;
    });
  }

  Future<void> _editDay() async {
    final result = await _dayDialog(label: _currentDay.label, name: _currentDay.name);
    if (result == null) return;
    _updateCurrentDay(_currentDay.copyWith(label: result.label, name: result.name));
  }

  Future<({String label, String name})?> _dayDialog({
    required String label,
    required String name,
  }) {
    final labelController = TextEditingController(text: label);
    final nameController = TextEditingController(text: name);
    return showDialog<({String label, String name})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dia do treino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              maxLength: 12,
              decoration: const InputDecoration(labelText: 'Rótulo', hintText: 'A, B, PUSH...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome', hintText: 'Peito e Tríceps'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final labelValue = labelController.text.trim();
              final nameValue = nameController.text.trim();
              if (labelValue.isEmpty || nameValue.isEmpty) return;
              Navigator.pop(context, (label: labelValue, name: nameValue));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeDay() async {
    if (_days.length == 1) {
      showAppSnack(context, 'O treino precisa de pelo menos um dia.', error: true);
      return;
    }
    final confirmed = await confirmDialog(
      context,
      title: 'Remover dia',
      message: 'Remover "${_currentDay.name}" e seus exercícios?',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!confirmed) return;
    setState(() {
      _days.removeAt(_dayIndex);
      _dayIndex = _dayIndex.clamp(0, _days.length - 1);
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showAppSnack(context, 'Dê um nome ao treino.', error: true);
      return;
    }
    if (_days.every((day) => day.exercises.isEmpty)) {
      showAppSnack(context, 'Adicione ao menos um exercício.', error: true);
      return;
    }
    setState(() => _saving = true);
    final body = {
      'name': _name.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'splitType': _splitType,
      'days': _days.map((day) => day.toRequest()).toList(),
    };
    try {
      final controller = ref.read(workoutsProvider.notifier);
      final workout = isNew
          ? await controller.create(body)
          : await controller.updateWorkout(widget.workoutId!, body);
      if (mounted) {
        showAppSnack(context, 'Treino salvo!');
        context.pushReplacement(AppRoutes.workout(workout.id));
      }
    } catch (error) {
      if (mounted) showAppSnack(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isNew) {
      final workout = ref.watch(workoutDetailProvider(widget.workoutId!));
      return workout.when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Editar treino')),
          body: ErrorView(
            message: '$error',
            onRetry: () => ref.invalidate(workoutDetailProvider(widget.workoutId!)),
          ),
        ),
        data: (data) {
          _hydrate(data);
          return _buildEditor(context);
        },
      );
    }
    return _buildEditor(context);
  }

  Widget _buildEditor(BuildContext context) {
    final tokens = context.tokens;
    final day = _currentDay;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isNew ? 'Novo treino' : 'Editar treino'),
        actions: [
          if (!isNew)
            IconButton(
              tooltip: 'Remover dia atual',
              onPressed: _removeDay,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: context.tokens.onPrimary,
                ),
              )
            : const Icon(Icons.check_rounded, size: 18),
        label: const Text('Salvar treino'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome do treino'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _splitType,
            decoration: const InputDecoration(labelText: 'Divisão'),
            items: _splitOptions
                .map((code) => DropdownMenuItem(value: code, child: Text(splitLabel(code))))
                .toList(),
            onChanged: (value) => setState(() => _splitType = value ?? 'CUSTOM'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Observações (opcional)'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: LabelText('Dias', size: 11, color: tokens.textPrimary)),
              TextButton.icon(
                onPressed: _addDay,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Novo dia'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_days.length, (index) {
                final selected = index == _dayIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _dayIndex = index),
                    label: Text('${_days[index].label} · ${_days[index].exercises.length}'),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          AppPanel(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day.name, style: context.texts.titleMedium),
                            Text(
                              '${day.exercises.length} exercícios · ${day.totalSets} séries',
                              style: context.texts.bodySmall
                                  ?.copyWith(color: tokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Renomear dia',
                        onPressed: _editDay,
                        icon: const Icon(Icons.drive_file_rename_outline_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (day.exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Nenhum exercício. Toque em "Adicionar exercício".',
                          style: context.texts.bodySmall
                              ?.copyWith(color: tokens.textMuted),
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: day.exercises.length,
                      onReorder: _reorder,
                      itemBuilder: (context, index) {
                        final item = day.exercises[index];
                        return Container(
                          key: ValueKey('${item.exerciseId}-$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: tokens.surfaceSunken,
                            borderRadius: AppRadius.all(AppRadius.md),
                            border: Border.all(color: tokens.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: tokens.textMuted,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ExerciseImage(url: item.resolvedImageUrl, size: 42),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.exerciseName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.texts.bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.targetSets} x ${item.targetReps} · ${formatRest(item.restSeconds)}'
                                        '${item.targetWeight != null ? ' · ${formatWeight(item.targetWeight)}' : ''}',
                                        style: AppTypography.display(
                                          size: 10.5,
                                          weight: FontWeight.w600,
                                          color: tokens.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Ajustar',
                                  onPressed: () => _configureExercise(index),
                                  icon: const Icon(Icons.tune_rounded, size: 20),
                                ),
                                IconButton(
                                  tooltip: 'Remover',
                                  onPressed: () => _removeExercise(index),
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar exercício'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
