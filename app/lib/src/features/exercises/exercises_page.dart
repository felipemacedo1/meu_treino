import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../models/exercise.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import 'exercise_filters_sheet.dart';

/// Aba de exercícios: busca no catálogo local (834 exercícios do wger).
class ExercisesPage extends ConsumerWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExerciseBrowser(
      title: 'Exercícios',
      onSelect: (exercise) => context.push(AppRoutes.exercise(exercise.id)),
    );
  }
}

/// Lista de exercícios reutilizada na aba e no seletor (montar treino / trocar).
class ExerciseBrowser extends ConsumerStatefulWidget {
  const ExerciseBrowser({
    super.key,
    required this.title,
    required this.onSelect,
    this.subtitle,
    this.showAppBar = true,
    this.trailingBuilder,
  });

  final String title;
  final String? subtitle;
  final bool showAppBar;
  final void Function(ExerciseSummary exercise) onSelect;
  final Widget Function(ExerciseSummary exercise)? trailingBuilder;

  @override
  ConsumerState<ExerciseBrowser> createState() => _ExerciseBrowserState();
}

class _ExerciseBrowserState extends ConsumerState<ExerciseBrowser> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 400) {
        ref.read(exerciseSearchProvider.notifier).loadMore();
      }
    });
    _searchController.text = ref.read(exerciseSearchProvider).filter.search;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseSearchProvider);
    final controller = ref.read(exerciseSearchProvider.notifier);

    final header = Padding(
      padding: EdgeInsets.fromLTRB(20, widget.showAppBar ? 0 : 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showAppBar)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: AppTypography.display(size: 16, weight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: controller.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              controller.search('');
                              setState(() {});
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: state.filter.activeCount > 0,
                label: Text('${state.filter.activeCount}'),
                child: IconButton.filledTonal(
                  onPressed: () async {
                    final result = await ExerciseFiltersSheet.show(context, state.filter);
                    if (result != null) controller.applyFilter(result);
                  },
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filtros',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LabelText(
            state.loading ? 'Buscando...' : '${state.total} exercícios encontrados',
            size: 9.5,
          ),
        ],
      ),
    );

    final body = Column(
      children: [
        header,
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.loading && state.items.isEmpty) {
                return const LoadingView();
              }
              if (state.error != null && state.items.isEmpty) {
                return ErrorView(message: state.error!, onRetry: controller.reload);
              }
              if (state.items.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nada encontrado',
                  message: 'Tente outro termo ou remova alguns filtros.',
                  action: state.filter.hasFilters
                      ? FilledButton.tonal(
                          onPressed: controller.clearFilters,
                          child: const Text('Limpar filtros'),
                        )
                      : null,
                );
              }
              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: state.items.length + (state.last ? 0 : 1),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final exercise = state.items[index];
                  return ExerciseListTile(
                    exercise: exercise,
                    onTap: () => widget.onSelect(exercise),
                    trailing: widget.trailingBuilder?.call(exercise),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: body,
    );
  }
}

class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.onTap,
    this.trailing,
  });

  final ExerciseSummary exercise;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppPanel(
      padding: const EdgeInsets.all(11),
      onTap: onTap,
      child: Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              ExerciseImage(url: exercise.resolvedImageUrl, size: 56),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: context.texts.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exercise.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.subtitle,
                        style: context.texts.bodySmall
                            ?.copyWith(color: tokens.textMuted, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (exercise.hasVideo) ...[
                      const SizedBox(height: 6),
                      TagChip(
                        'vídeo',
                        icon: Icons.play_circle_outline_rounded,
                        color: tokens.primary,
                        dense: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Icon(Icons.chevron_right_rounded, color: tokens.textMuted, size: 20),
            ],
          ),
        ),
    );
  }
}

/// Abre o seletor de exercícios e devolve o escolhido.
Future<ExerciseSummary?> pickExercise(BuildContext context, {String title = 'Escolher exercício'}) {
  return Navigator.of(context).push<ExerciseSummary>(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ExerciseBrowser(
            title: title,
            showAppBar: false,
            onSelect: (exercise) => Navigator.pop(context, exercise),
            trailingBuilder: (_) => const Icon(Icons.add_circle_outline_rounded),
          ),
        ),
      ),
    ),
  );
}
