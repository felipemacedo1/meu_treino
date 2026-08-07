import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/session.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import '../exercises/exercises_page.dart';
import 'rest_timer_bar.dart';
import 'session_summary_page.dart';
import 'substitute_sheet.dart';

/// Tela do treino em andamento.
class ActiveSessionPage extends ConsumerStatefulWidget {
  const ActiveSessionPage({super.key});

  @override
  ConsumerState<ActiveSessionPage> createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends ConsumerState<ActiveSessionPage> {
  Timer? _ticker;

  /// Cronômetros ficam em notifiers para que o tique de 1s não rebuilde a
  /// lista de exercícios (o que apagaria campos ainda não salvos).
  final _elapsed = ValueNotifier<int>(0);
  final _restRemaining = ValueNotifier<int>(0);
  int _restTotal = 0;
  String _restLabel = '';

  Future<void> _queue = Future<void>.value();
  int _pending = 0;

  bool get _busy => _pending > 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _elapsed.value++;
      if (_restRemaining.value > 0) {
        _restRemaining.value--;
        if (_restRemaining.value == 0) {
          HapticFeedback.mediumImpact();
          showAppSnack(context, 'Descanso terminado. Bora para a próxima série!');
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _elapsed.dispose();
    _restRemaining.dispose();
    super.dispose();
  }

  void _startRest(int seconds, String label) {
    if (seconds <= 0) return;
    _restTotal = seconds;
    _restLabel = label;
    _restRemaining.value = seconds;
  }

  /// Executa as acoes em fila: nenhum toque e descartado, mesmo com
  /// requisicoes em andamento (importante para marcar series rapidamente).
  Future<void> _guard(Future<void> Function() action) {
    final next = _queue.then((_) async {
      if (!mounted) return;
      setState(() => _pending++);
      try {
        await action();
      } catch (error) {
        if (mounted) showAppSnack(context, error.toString(), error: true);
      } finally {
        if (mounted) setState(() => _pending--);
      }
    });
    _queue = next.catchError((_) {});
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(activeSessionProvider);

    return sessionState.when(
      loading: () => const Scaffold(body: LoadingView(message: 'Carregando treino...')),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Treino')),
        body: ErrorView(
          message: '$error',
          onRetry: () => ref.read(activeSessionProvider.notifier).refreshActive(),
        ),
      ),
      data: (session) {
        if (session == null || !session.inProgress) {
          return Scaffold(
            appBar: AppBar(title: const Text('Treino')),
            body: EmptyState(
              icon: Icons.self_improvement_rounded,
              title: 'Nenhum treino em andamento',
              message: 'Escolha uma ficha na aba Treinos para começar.',
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Voltar ao início'),
              ),
            ),
          );
        }
        return _buildSession(context, session);
      },
    );
  }

  Widget _buildSession(BuildContext context, TrainingSession session) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.title, style: theme.textTheme.titleMedium),
            ValueListenableBuilder<int>(
              valueListenable: _elapsed,
              builder: (context, _, __) => Text(
                '${formatClock(_currentElapsed(session))} · '
                '${session.completedSets}/${session.plannedSets} séries · '
                '${formatVolume(session.totalVolume)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Adicionar exercício',
            onPressed: () async {
              final picked = await pickExercise(context, title: 'Adicionar ao treino');
              if (picked == null) return;
              await _guard(
                () => ref.read(activeSessionProvider.notifier).addExercise(picked.id),
              );
            },
            icon: const Icon(Icons.add_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'cancel') {
                final confirmed = await confirmDialog(
                  context,
                  title: 'Descartar treino',
                  message: 'Tudo que foi registrado nesta sessão será descartado. Continuar?',
                  confirmLabel: 'Descartar',
                  destructive: true,
                );
                if (!confirmed) return;
                await _guard(() async {
                  await ref.read(activeSessionProvider.notifier).cancel();
                  if (mounted) context.go(AppRoutes.home);
                });
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Descartar treino'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: session.progress, minHeight: 4),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (session.exercises.isEmpty)
            EmptyState(
              icon: Icons.add_circle_outline_rounded,
              title: 'Treino livre',
              message: 'Adicione os exercícios que você for fazendo.',
              action: FilledButton.icon(
                onPressed: () async {
                  final picked = await pickExercise(context, title: 'Adicionar exercício');
                  if (picked == null) return;
                  await _guard(
                    () => ref.read(activeSessionProvider.notifier).addExercise(picked.id),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar exercício'),
              ),
            )
          else
            ...session.exercises.map(
              (exercise) => _ExerciseCard(
                exercise: exercise,
                busy: false,
                onSetCompleted: () => _startRest(exercise.restSeconds, exercise.exerciseName),
                guard: _guard,
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _busy ? null : () => _finish(session),
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Finalizar treino'),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _restRemaining,
        builder: (context, remaining, __) {
          if (remaining <= 0) return const SizedBox.shrink();
          return RestTimerBar(
            remaining: remaining,
            total: _restTotal,
            label: _restLabel,
            onSkip: () => _restRemaining.value = 0,
            onAdd: () {
              _restRemaining.value += 15;
              if (_restTotal < _restRemaining.value) _restTotal = _restRemaining.value;
            },
            onSubtract: () => _restRemaining.value = (_restRemaining.value - 15).clamp(0, 3600),
          );
        },
      ),
    );
  }

  int _currentElapsed(TrainingSession session) =>
      session.durationSeconds ??
      DateTime.now().difference(session.startedAt.toLocal()).inSeconds;

  Future<void> _finish(TrainingSession session) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar treino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.completedSets} de ${session.plannedSets} séries concluídas · '
              '${formatVolume(session.totalVolume)} movimentados.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Como foi o treino? (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _guard(() async {
      final finished = await ref.read(activeSessionProvider.notifier).finish(
            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
            durationSeconds: _currentElapsed(session),
          );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SessionSummaryPage(session: finished)),
      );
    });
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.busy,
    required this.onSetCompleted,
    required this.guard,
  });

  final SessionExerciseItem exercise;
  final bool busy;
  final VoidCallback onSetCompleted;
  final Future<void> Function(Future<void> Function()) guard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(activeSessionProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseImage(url: exercise.resolvedImageUrl, size: 52, radius: 13),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.completedSets}/${exercise.sets.length} séries · descanso ${formatRest(exercise.restSeconds)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (exercise.isDone)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'substitute':
                        final replacement = await SubstituteSheet.show(
                          context,
                          exerciseId: exercise.exerciseId,
                          exerciseName: exercise.exerciseName,
                        );
                        if (replacement == null) return;
                        await guard(
                          () => controller.substitute(exercise.id, replacement.id),
                        );
                        if (context.mounted) {
                          showAppSnack(context, 'Trocado por ${replacement.name} (só hoje).');
                        }
                      case 'rest':
                        final seconds = await _pickRest(context, exercise.restSeconds);
                        if (seconds == null) return;
                        await guard(
                          () => controller.updateExercise(exercise.id, restSeconds: seconds),
                        );
                      case 'notes':
                        final notes = await _editNotes(context, exercise.notes);
                        if (notes == null) return;
                        await guard(() => controller.updateExercise(exercise.id, notes: notes));
                      case 'addSet':
                        await guard(() => controller.addSet(exercise.id));
                      case 'remove':
                        final confirmed = await confirmDialog(
                          context,
                          title: 'Remover exercício',
                          message: 'Remover ${exercise.exerciseName} deste treino?',
                          confirmLabel: 'Remover',
                          destructive: true,
                        );
                        if (!confirmed) return;
                        await guard(() => controller.removeExercise(exercise.id));
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'substitute',
                      child: ListTile(
                        leading: Icon(Icons.swap_horiz_rounded),
                        title: Text('Trocar exercício'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'addSet',
                      child: ListTile(
                        leading: Icon(Icons.playlist_add_rounded),
                        title: Text('Adicionar série'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rest',
                      child: ListTile(
                        leading: Icon(Icons.timer_outlined),
                        title: Text('Editar descanso'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'notes',
                      child: ListTile(
                        leading: Icon(Icons.sticky_note_2_outlined),
                        title: Text('Observações'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Remover'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (exercise.substituted && exercise.originalExerciseName != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TagChip(
                  'trocado · era ${exercise.originalExerciseName}',
                  icon: Icons.swap_horiz_rounded,
                  color: Colors.orange.shade800,
                ),
              ),
            if (exercise.lastWeight != null || exercise.bestWeight != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (exercise.lastWeight != null)
                      TagChip(
                        'anterior ${formatWeight(exercise.lastWeight)}'
                        '${exercise.lastReps != null ? ' x ${exercise.lastReps}' : ''}',
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
            if (exercise.notes != null && exercise.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  exercise.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 12, 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('#', style: theme.textTheme.labelSmall),
                  ),
                  Expanded(
                    child: Text('Carga (kg)', style: theme.textTheme.labelSmall),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Reps', style: theme.textTheme.labelSmall)),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            ...exercise.sets.map(
              (set) => _SetRow(
                key: ValueKey('set-${set.id}'),
                set: set,
                busy: busy,
                onSave: (weight, reps) => guard(
                  () => controller.updateSet(set.id, weight: weight, reps: reps),
                ),
                onToggle: (completed, weight, reps) async {
                  await guard(
                    () => controller.updateSet(
                      set.id,
                      completed: completed,
                      weight: weight,
                      reps: reps,
                    ),
                  );
                  if (completed) onSetCompleted();
                },
                onDelete: exercise.sets.length > 1
                    ? () => guard(() => controller.removeSet(set.id))
                    : null,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: busy ? null : () => guard(() => controller.addSet(exercise.id)),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Série extra'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _pickRest(BuildContext context, int current) {
    const options = [0, 30, 45, 60, 90, 120, 150, 180, 240, 300];
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Descanso', style: Theme.of(context).textTheme.titleLarge),
            ),
            ...options.map(
              (seconds) => SizedBox(
                width: double.infinity,
                child: ListTile(
                  title: Text(formatRest(seconds)),
                  trailing: seconds == current ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(context, seconds),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _editNotes(BuildContext context, String? current) {
    final controller = TextEditingController(text: current ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observações'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex.: aumentar carga na próxima'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

/// Linha de série com campos de carga e repetições.
class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.set,
    required this.busy,
    required this.onSave,
    required this.onToggle,
    this.onDelete,
  });

  final WorkoutSet set;
  final bool busy;
  final Future<void> Function(double? weight, int? reps) onSave;
  final Future<void> Function(bool completed, double? weight, int? reps) onToggle;
  final VoidCallback? onDelete;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  final _weightFocus = FocusNode();
  final _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: _weightText(widget.set));
    _reps = TextEditingController(text: widget.set.reps?.toString() ?? '');
    _weightFocus.addListener(_commitOnBlur);
    _repsFocus.addListener(_commitOnBlur);
  }

  @override
  void didUpdateWidget(_SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só sobrescreve o campo quando o valor mudou no servidor. Sem isso, um
    // rebuild (por exemplo o cronômetro que roda a cada segundo) apagaria o
    // que o usuário acabou de digitar e ainda não foi salvo.
    _sync(_weight, _weightFocus, _weightText(widget.set), _weightText(oldWidget.set));
    _sync(
      _reps,
      _repsFocus,
      widget.set.reps?.toString() ?? '',
      oldWidget.set.reps?.toString() ?? '',
    );
  }

  void _sync(TextEditingController controller, FocusNode focus, String next, String previous) {
    if (focus.hasFocus) return;
    if (next == previous) return;
    if (controller.text != next) controller.text = next;
  }

  @override
  void dispose() {
    _weightFocus.dispose();
    _repsFocus.dispose();
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  static String _weightText(WorkoutSet set) =>
      set.weight == null ? '' : formatNumber(set.weight);

  double? get _weightValue => double.tryParse(_weight.text.replaceAll(',', '.'));

  int? get _repsValue => int.tryParse(_reps.text);

  void _commitOnBlur() {
    if (_weightFocus.hasFocus || _repsFocus.hasFocus) return;
    final weightChanged = _weightValue != widget.set.weight;
    final repsChanged = _repsValue != widget.set.reps;
    if (weightChanged || repsChanged) {
      widget.onSave(_weightValue, _repsValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = widget.set;
    final done = set.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        color: done
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${set.setNumber}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _weight,
              focusNode: _weightFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                isDense: true,
                hintText: '0',
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (_) => widget.onSave(_weightValue, _repsValue),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _reps,
              focusNode: _repsFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                isDense: true,
                hintText: set.targetReps ?? '0',
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (_) => widget.onSave(_weightValue, _repsValue),
            ),
          ),
          IconButton(
            tooltip: done ? 'Desmarcar' : 'Concluir série',
            onPressed: widget.busy
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    widget.onToggle(!done, _weightValue, _repsValue);
                  },
            icon: Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: done ? theme.colorScheme.primary : theme.colorScheme.outline,
              size: 28,
            ),
          ),
          if (widget.onDelete != null)
            InkWell(
              onTap: widget.busy ? null : widget.onDelete,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
