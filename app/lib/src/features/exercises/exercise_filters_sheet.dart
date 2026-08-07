import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

/// Filtros de músculo, equipamento e categoria.
class ExerciseFiltersSheet extends ConsumerStatefulWidget {
  const ExerciseFiltersSheet({super.key, required this.initial});

  final ExerciseFilter initial;

  static Future<ExerciseFilter?> show(BuildContext context, ExerciseFilter initial) {
    return showModalBottomSheet<ExerciseFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExerciseFiltersSheet(initial: initial),
    );
  }

  @override
  ConsumerState<ExerciseFiltersSheet> createState() => _ExerciseFiltersSheetState();
}

class _ExerciseFiltersSheetState extends ConsumerState<ExerciseFiltersSheet> {
  late ExerciseFilter _filter = widget.initial;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return catalog.when(
          loading: () => const SizedBox(height: 320, child: LoadingView()),
          error: (error, _) => SizedBox(height: 320, child: ErrorView(message: '$error')),
          data: (data) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _filter = ExerciseFilter(search: _filter.search)),
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    const SectionTitle('Grupo muscular'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.muscles
                          .map(
                            (muscle) => FilterChip(
                              label: Text(muscle.name),
                              selected: _filter.muscleId == muscle.id,
                              onSelected: (selected) => setState(() {
                                _filter = selected
                                    ? _filter.copyWith(muscleId: muscle.id)
                                    : _filter.copyWith(clearMuscle: true);
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Equipamento'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.equipment
                          .map(
                            (item) => FilterChip(
                              label: Text(item.name),
                              selected: _filter.equipmentId == item.id,
                              onSelected: (selected) => setState(() {
                                _filter = selected
                                    ? _filter.copyWith(equipmentId: item.id)
                                    : _filter.copyWith(clearEquipment: true);
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Categoria'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.categories
                          .map(
                            (item) => FilterChip(
                              label: Text(item.name),
                              selected: _filter.categoryId == item.id,
                              onSelected: (selected) => setState(() {
                                _filter = selected
                                    ? _filter.copyWith(categoryId: item.id)
                                    : _filter.copyWith(clearCategory: true);
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _filter.onlyWithImage,
                      onChanged: (value) =>
                          setState(() => _filter = _filter.copyWith(onlyWithImage: value)),
                      title: const Text('Somente com imagem'),
                      subtitle: const Text('Mostra apenas exercícios ilustrados'),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _filter),
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
