import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/exercise.dart';
import '../../models/stats.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(exerciseDetailProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercício')),
      body: detail.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(exerciseDetailProvider(exerciseId)),
        ),
        data: (exercise) => _Content(exercise: exercise),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.exercise});

  final ExerciseDetail exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final images = exercise.resolvedImages;
    final videos = exercise.resolvedVideos;
    final progression = ref.watch(exerciseProgressionProvider(exercise.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (images.isNotEmpty)
          _ImageCarousel(images: images)
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 64,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        const SizedBox(height: 20),
        Text(exercise.name, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24)),
        if (exercise.name != exercise.originalName)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              exercise.originalName,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (exercise.categoryName != null)
              TagChip(exercise.categoryName!, icon: Icons.category_rounded),
            ...exercise.equipment.map(
              (item) => TagChip(item.name, icon: Icons.fitness_center_rounded, color: Colors.teal),
            ),
          ],
        ),
        if (videos.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionTitle('Vídeo de execução'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              videos.length,
              (index) => FilledButton.tonalIcon(
                onPressed: () => launchUrl(
                  Uri.parse(videos[index]),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text('Vídeo ${index + 1}'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const SectionTitle('Músculos trabalhados'),
        _MuscleGroup(title: 'Principais', muscles: exercise.primaryMuscles, primary: true),
        if (exercise.secondaryMuscles.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MuscleGroup(title: 'Auxiliares', muscles: exercise.secondaryMuscles, primary: false),
        ],
        if (exercise.description != null && exercise.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionTitle('Execução'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                exercise.description!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const SectionTitle('Sua evolução neste exercício'),
        progression.when(
          loading: () => const SizedBox(height: 120, child: LoadingView()),
          error: (error, _) => Card(
            child: Padding(padding: const EdgeInsets.all(18), child: Text('$error')),
          ),
          data: (data) {
            if (data.points.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.show_chart_rounded, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Faça esse exercício em um treino para ver a evolução aqui.'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Melhor carga',
                        value: formatWeight(data.bestWeight),
                        icon: Icons.emoji_events_rounded,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Última carga',
                        value: formatWeight(data.lastWeight),
                        hint: relativeDate(data.lastDate),
                        icon: Icons.history_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 18, 8),
                    child: SizedBox(
                      height: 200,
                      child: _ProgressionChart(points: data.points),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.go('${AppRoutes.home}?tab=2'),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Buscar outros exercícios'),
        ),
      ],
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images});

  final List<String> images;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 260,
            color: Colors.white,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  width: _index == index ? 20 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _index == index ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MuscleGroup extends StatelessWidget {
  const _MuscleGroup({required this.title, required this.muscles, required this.primary});

  final String title;
  final List<Muscle> muscles;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (muscles.isEmpty) {
      return Text(
        'Sem informação de músculos ${primary ? 'principais' : 'auxiliares'}.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles
                  .map(
                    (muscle) => TagChip(
                      muscle.name,
                      icon: primary ? Icons.bolt_rounded : Icons.circle_outlined,
                      color: primary ? theme.colorScheme.primary : Colors.blueGrey,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressionChart extends StatelessWidget {
  const _ProgressionChart({required this.points});

  final List<ProgressionPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final weight = points[i].topWeight;
      if (weight != null) spots.add(FlSpot(i.toDouble(), weight));
    }
    if (spots.isEmpty) {
      return const Center(child: Text('Sem cargas registradas ainda.'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (points.length / 4).ceilToDouble().clamp(1, 100),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatDayMonth(points[index].date),
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: scheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.5,
                color: scheme.primary,
                strokeWidth: 2,
                strokeColor: scheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}
