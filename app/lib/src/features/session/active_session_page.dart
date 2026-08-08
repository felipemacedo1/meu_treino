import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/session.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import '../exercises/exercises_page.dart';
import 'rest_timer_bar.dart';
import 'session_summary_page.dart';
import 'substitute_sheet.dart';

/// Tela do treino em andamento.
///
/// Prioridade de leitura, nesta ordem: exercício, série atual, carga,
/// repetições, descanso e progresso. Tudo o que não serve para decidir a
/// próxima série fica em segundo plano ou dentro do menu do exercício.
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

  /// Executa as ações em fila: nenhum toque é descartado, mesmo com
  /// requisições em andamento (importante para marcar séries rapidamente).
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
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: LoadingView(message: 'Carregando treino'),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Treino')),
        body: ErrorView(
          message: '$error',
          onRetry: () => ref.read(activeSessionProvider.notifier).refreshActive(),
        ),
      ),
      data: (session) {
        if (session == null || !session.inProgress) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: const Text('Treino')),
            body: EmptyState(
              icon: Icons.sensors_off_rounded,
              title: 'Nenhum treino ativo',
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
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 62,
        title: Row(
          children: [
            DayBadge(label: session.dayLabel ?? 'L', size: 36),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (session.dayName ?? session.workoutName ?? 'Treino').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      size: 14.5,
                      weight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<int>(
                    valueListenable: _elapsed,
                    builder: (context, _, _) => Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 11, color: tokens.textMuted),
                        const SizedBox(width: 4),
                        MonoDigits(
                          formatClock(_currentElapsed(session)),
                          style: AppTypography.display(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary),
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
            icon: const Icon(Icons.more_vert_rounded),
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
          preferredSize: const Size.fromHeight(3),
          child: ProgressTrack(value: session.progress, height: 3),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          _SessionSummaryStrip(session: session),
          const SizedBox(height: 16),
          if (session.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: EmptyState(
                icon: Icons.add_circle_outline_rounded,
                title: 'Treino livre',
                message: 'Adicione os exercícios conforme você for fazendo.',
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
              ),
            )
          else
            ...List.generate(session.exercises.length, (index) {
              final exercise = session.exercises[index];
              final currentIndex = session.exercises.indexWhere((e) => !e.isDone);
              return _ExerciseCard(
                exercise: exercise,
                position: index + 1,
                total: session.exercises.length,
                isCurrentExercise: index == currentIndex,
                onSetCompleted: () => _startRest(exercise.restSeconds, exercise.exerciseName),
                guard: _guard,
              );
            }),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : () => _finish(session),
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Finalizar treino'),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _restRemaining,
        builder: (context, remaining, _) {
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
      builder: (context) {
        final tokens = context.tokens;
        return AlertDialog(
          title: Text(
            'FINALIZAR TREINO',
            style: AppTypography.display(size: 16, weight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MetricValue(
                      label: 'Séries',
                      value: '${session.completedSets}/${session.plannedSets}',
                      size: 22,
                      color: tokens.primary,
                    ),
                  ),
                  Expanded(
                    child: MetricValue(
                      label: 'Volume',
                      value: formatVolume(session.totalVolume),
                      size: 22,
                      color: tokens.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Como foi o treino? (opcional)'),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finalizar'),
            ),
          ],
        );
      },
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

/// Faixa com o estado geral da sessão: séries, volume e exercícios.
class _SessionSummaryStrip extends StatelessWidget {
  const _SessionSummaryStrip({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final doneExercises = session.exercises.where((e) => e.isDone).length;
    return AppPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: MetricValue(
              label: 'Séries',
              value: '${session.completedSets}',
              unit: '/ ${session.plannedSets}',
              size: 19,
              color: tokens.primary,
            ),
          ),
          _VerticalSeparator(color: tokens.border),
          Expanded(
            child: MetricValue(
              label: 'Volume',
              value: formatVolume(session.totalVolume),
              size: 19,
            ),
          ),
          _VerticalSeparator(color: tokens.border),
          Expanded(
            child: MetricValue(
              label: 'Exercícios',
              value: '$doneExercises',
              unit: '/ ${session.exercises.length}',
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: color);
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.position,
    required this.total,
    required this.isCurrentExercise,
    required this.onSetCompleted,
    required this.guard,
  });

  final SessionExerciseItem exercise;
  final int position;
  final int total;

  /// Só o exercício da vez recebe a borda iluminada, para o destaque significar
  /// algo. Os demais ficam neutros.
  final bool isCurrentExercise;
  final VoidCallback onSetCompleted;
  final Future<void> Function(Future<void> Function()) guard;

  /// Índice da próxima série a executar — recebe destaque visual.
  int get _currentSetIndex {
    final index = exercise.sets.indexWhere((s) => !s.completed);
    return index < 0 ? exercise.sets.length - 1 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final controller = ref.read(activeSessionProvider.notifier);
    final done = exercise.isDone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppPanel(
        accent: isCurrentExercise && !done,
        padding: const EdgeInsets.fromLTRB(14, 13, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------- cabeçalho ---------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseImage(url: exercise.resolvedImageUrl, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          LabelText(
                            '$position/$total',
                            size: 9,
                            color: done ? tokens.success : tokens.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              done
                                  ? 'CONCLUÍDO'
                                  : 'SÉRIE ${_currentSetIndex + 1} DE ${exercise.sets.length}',
                              style: AppTypography.label(
                                9,
                                color: done ? tokens.success : tokens.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        exercise.exerciseName,
                        style: context.texts.titleMedium?.copyWith(height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (done)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4),
                    child: Icon(Icons.check_circle_rounded, color: tokens.success, size: 22),
                  ),
                _ExerciseMenu(
                  exercise: exercise,
                  controller: controller,
                  guard: guard,
                ),
              ],
            ),

            // --------------------- contexto do exercício --------------------
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                TagChip(
                  formatRest(exercise.restSeconds),
                  icon: Icons.timer_outlined,
                  dense: true,
                ),
                if (exercise.lastWeight != null)
                  TagChip(
                    'anterior ${formatWeight(exercise.lastWeight)}'
                    '${exercise.lastReps != null ? ' x ${exercise.lastReps}' : ''}',
                    icon: Icons.history_rounded,
                    dense: true,
                  ),
                if (exercise.bestWeight != null)
                  TagChip(
                    'recorde ${formatWeight(exercise.bestWeight)}',
                    icon: Icons.emoji_events_rounded,
                    color: tokens.accent,
                    dense: true,
                  ),
                if (exercise.substituted && exercise.originalExerciseName != null)
                  TagChip(
                    'trocado',
                    icon: Icons.swap_horiz_rounded,
                    color: tokens.warning,
                    dense: true,
                  ),
              ],
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.push_pin_outlined, size: 13, color: tokens.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exercise.notes!,
                        style: context.texts.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ---------------------------- séries ---------------------------
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  const SizedBox(width: 30),
                  Expanded(child: LabelText('Carga · kg', size: 9)),
                  const SizedBox(width: 10),
                  Expanded(child: LabelText('Reps', size: 9)),
                  const SizedBox(width: 92),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...List.generate(exercise.sets.length, (index) {
              final set = exercise.sets[index];
              return _SetRow(
                key: ValueKey('set-${set.id}'),
                set: set,
                isCurrent: isCurrentExercise && !done && index == _currentSetIndex,
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
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => guard(() => controller.addSet(exercise.id)),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Série extra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu de ações do exercício dentro da sessão.
class _ExerciseMenu extends StatelessWidget {
  const _ExerciseMenu({
    required this.exercise,
    required this.controller,
    required this.guard,
  });

  final SessionExerciseItem exercise;
  final SessionController controller;
  final Future<void> Function(Future<void> Function()) guard;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (value) async {
        switch (value) {
          case 'substitute':
            final replacement = await SubstituteSheet.show(
              context,
              exerciseId: exercise.exerciseId,
              exerciseName: exercise.exerciseName,
            );
            if (replacement == null) return;
            await guard(() => controller.substitute(exercise.id, replacement.id));
            if (context.mounted) {
              showAppSnack(context, 'Trocado por ${replacement.name} (só hoje).');
            }
          case 'addSet':
            await guard(() => controller.addSet(exercise.id));
          case 'rest':
            final seconds = await _pickRest(context, exercise.restSeconds);
            if (seconds == null) return;
            await guard(() => controller.updateExercise(exercise.id, restSeconds: seconds));
          case 'notes':
            final notes = await _editNotes(context, exercise.notes);
            if (notes == null) return;
            await guard(() => controller.updateExercise(exercise.id, notes: notes));
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
    );
  }

  Future<int?> _pickRest(BuildContext context, int current) {
    const options = [0, 30, 45, 60, 90, 120, 150, 180, 240, 300];
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: SectionTitle('Descanso entre séries'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options
                    .map(
                      (seconds) => ChoiceChip(
                        label: Text(formatRest(seconds)),
                        selected: seconds == current,
                        onSelected: (_) => Navigator.pop(context, seconds),
                      ),
                    )
                    .toList(),
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
        title: Text(
          'OBSERVAÇÕES',
          style: AppTypography.display(size: 16, weight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex.: aumentar carga na próxima'),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

/// Linha de série: número, carga, repetições e conclusão.
///
/// A série atual recebe borda e brilho na cor da marca para ser identificada
/// sem leitura. Os campos usam números grandes, de leitura rápida.
class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.set,
    required this.isCurrent,
    required this.onSave,
    required this.onToggle,
    this.onDelete,
  });

  final WorkoutSet set;
  final bool isCurrent;
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
    _weightFocus.addListener(_onFocusChange);
    _repsFocus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só sobrescreve o campo quando o valor mudou no servidor. Sem isso, um
    // rebuild apagaria o que o usuário acabou de digitar e ainda não foi salvo.
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

  static String _weightText(WorkoutSet set) => set.weight == null ? '' : formatNumber(set.weight);

  double? get _weightValue => double.tryParse(_weight.text.replaceAll(',', '.'));

  int? get _repsValue => int.tryParse(_reps.text);

  void _onFocusChange() {
    setState(() {}); // realça o campo em foco
    if (_weightFocus.hasFocus || _repsFocus.hasFocus) return;
    final weightChanged = _weightValue != widget.set.weight;
    final repsChanged = _repsValue != widget.set.reps;
    if (weightChanged || repsChanged) {
      widget.onSave(_weightValue, _repsValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final set = widget.set;
    final done = set.completed;

    final Color frame;
    if (done) {
      frame = tokens.success.withValues(alpha: 0.35);
    } else if (widget.isCurrent) {
      frame = tokens.primary.withValues(alpha: 0.65);
    } else {
      frame = tokens.border;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 6),
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
      decoration: BoxDecoration(
        color: done ? tokens.success.withValues(alpha: 0.06) : tokens.surfaceSunken,
        borderRadius: AppRadius.all(AppRadius.md),
        border: Border.all(color: frame, width: widget.isCurrent ? 1.4 : 1),
        boxShadow: widget.isCurrent
            ? AppEffects.glow(tokens.glow, strength: 0.12, blur: 14)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${set.setNumber}',
              textAlign: TextAlign.center,
              style: AppTypography.metric(
                17,
                color: done
                    ? tokens.success
                    : widget.isCurrent
                        ? tokens.primary
                        : tokens.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _NumberField(
              controller: _weight,
              focus: _weightFocus,
              hint: '0',
              decimal: true,
              onSubmitted: () => widget.onSave(_weightValue, _repsValue),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumberField(
              controller: _reps,
              focus: _repsFocus,
              hint: set.targetReps ?? '0',
              decimal: false,
              onSubmitted: () => widget.onSave(_weightValue, _repsValue),
            ),
          ),
          const SizedBox(width: 8),
          _CheckButton(
            done: done,
            onTap: () {
              FocusScope.of(context).unfocus();
              widget.onToggle(!done, _weightValue, _repsValue);
            },
          ),
          if (widget.onDelete != null)
            InkWell(
              onTap: widget.onDelete,
              borderRadius: AppRadius.all(AppRadius.xs),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 15, color: tokens.textMuted),
              ),
            )
          else
            const SizedBox(width: 27),
        ],
      ),
    );
  }
}

/// Campo numérico grande, otimizado para toque e leitura rápida.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.decimal,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final bool decimal;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final focused = focus.hasFocus;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: AppRadius.all(AppRadius.sm),
        border: Border.all(
          color: focused ? tokens.primary : tokens.border,
          width: focused ? 1.4 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focus,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTypography.metric(19, color: tokens.textPrimary),
        cursorColor: tokens.primary,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          hintText: hint,
          hintStyle: AppTypography.metric(19, color: tokens.textMuted).copyWith(
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}

/// Botão de concluir série: grande, com brilho quando concluído.
class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: done ? tokens.success : Colors.transparent,
      borderRadius: AppRadius.all(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all(AppRadius.sm),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            borderRadius: AppRadius.all(AppRadius.sm),
            border: Border.all(
              color: done ? tokens.success : tokens.borderStrong,
              width: 1.4,
            ),
            boxShadow: done ? AppEffects.glow(tokens.success, strength: 0.30, blur: 12) : null,
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.check_rounded,
            color: done ? tokens.background : tokens.textMuted,
            size: 24,
          ),
        ),
      ),
    );
  }
}
