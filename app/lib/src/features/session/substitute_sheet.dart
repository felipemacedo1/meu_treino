import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import '../exercises/exercises_page.dart';

/// Troca de exercício durante a sessão: sugere equivalentes (mesmo músculo
/// principal) e permite buscar qualquer outro no catálogo.
class SubstituteSheet extends ConsumerWidget {
  const SubstituteSheet({super.key, required this.exerciseId, required this.exerciseName});

  final int exerciseId;
  final String exerciseName;

  static Future<ExerciseSummary?> show(
    BuildContext context, {
    required int exerciseId,
    required String exerciseName,
  }) {
    return showModalBottomSheet<ExerciseSummary>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SubstituteSheet(exerciseId: exerciseId, exerciseName: exerciseName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equivalents = ref.watch(equivalentsProvider(exerciseId));
    final tokens = context.tokens;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: const SectionTitle(
              'Trocar exercício',
              subtitle: 'A troca vale só para o treino de hoje. Sua ficha continua intacta.',
            ),
          ),
          Expanded(
            child: equivalents.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                message: '$error',
                onRetry: () => ref.invalidate(equivalentsProvider(exerciseId)),
              ),
              data: (list) => ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  const SectionTitle('Equivalentes sugeridos'),
                  if (list.isEmpty)
                    Text(
                      'Nenhum equivalente encontrado. Use a busca abaixo.',
                      style: context.texts.bodySmall?.copyWith(color: tokens.textMuted),
                    )
                  else
                    ...list.map(
                      (exercise) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ExerciseListTile(
                          exercise: exercise,
                          onTap: () => Navigator.pop(context, exercise),
                          trailing: Icon(Icons.swap_horiz_rounded, color: tokens.primary, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await pickExercise(context, title: 'Buscar substituto');
                  if (picked != null && context.mounted) Navigator.pop(context, picked);
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('Buscar no catálogo completo'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
