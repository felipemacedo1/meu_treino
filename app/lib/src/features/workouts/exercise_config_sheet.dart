import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/workout.dart';
import '../../widgets/common.dart';

/// Ajuste de séries, repetições, carga alvo, descanso e observações.
class ExerciseConfigSheet extends StatefulWidget {
  const ExerciseConfigSheet({super.key, required this.item});

  final WorkoutExerciseItem item;

  static Future<WorkoutExerciseItem?> show(BuildContext context, WorkoutExerciseItem item) {
    return showModalBottomSheet<WorkoutExerciseItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ExerciseConfigSheet(item: item),
      ),
    );
  }

  @override
  State<ExerciseConfigSheet> createState() => _ExerciseConfigSheetState();
}

class _ExerciseConfigSheetState extends State<ExerciseConfigSheet> {
  late int _sets = widget.item.targetSets;
  late final TextEditingController _reps =
      TextEditingController(text: widget.item.targetReps);
  late final TextEditingController _weight = TextEditingController(
    text: widget.item.targetWeight == null ? '' : formatNumber(widget.item.targetWeight),
  );
  late final TextEditingController _notes = TextEditingController(text: widget.item.notes ?? '');
  late int _rest = widget.item.restSeconds;

  static const _restOptions = [30, 45, 60, 90, 120, 150, 180, 240];

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      widget.item.copyWith(
        targetSets: _sets,
        targetReps: _reps.text.trim().isEmpty ? '10' : _reps.text.trim(),
        targetWeight: double.tryParse(_weight.text.replaceAll(',', '.')),
        clearTargetWeight: _weight.text.trim().isEmpty,
        restSeconds: _rest,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExerciseImage(url: widget.item.resolvedImageUrl, size: 48, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.item.exerciseName, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Séries', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _sets > 1 ? () => setState(() => _sets--) : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Expanded(
                            child: Text(
                              '$_sets',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _sets < 12 ? () => setState(() => _sets++) : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _reps,
                    decoration: const InputDecoration(
                      labelText: 'Repetições',
                      hintText: '8-12',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Carga inicial (opcional)',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 22),
            Text('Descanso entre séries', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _restOptions
                  .map(
                    (seconds) => ChoiceChip(
                      label: Text(formatRest(seconds)),
                      selected: _rest == seconds,
                      onSelected: (_) => setState(() => _rest = seconds),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Ex.: cadência 3s na descida',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}
