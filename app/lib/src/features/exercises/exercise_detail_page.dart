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
import '../../theme/theme.dart';
import '../../widgets/common.dart';

class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(exerciseDetailProvider(exerciseId));

    return Scaffold(
      backgroundColor: Colors.transparent,
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
    final tokens = context.tokens;
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
              color: tokens.surface,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(color: tokens.border),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 56,
              color: tokens.primary.withValues(alpha: 0.4),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          exercise.name.toUpperCase(),
          style: AppTypography.display(
            size: 21,
            weight: FontWeight.w800,
            letterSpacing: -0.5,
            color: tokens.textPrimary,
          ),
        ),
        if (exercise.name != exercise.originalName)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: LabelText(exercise.originalName, size: 9.5),
          ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (exercise.categoryName != null)
              TagChip(
                exercise.categoryName!,
                icon: Icons.category_rounded,
                color: tokens.primary,
              ),
            ...exercise.equipment.map(
              (item) => TagChip(
                item.name,
                icon: Icons.fitness_center_rounded,
                color: tokens.secondary,
              ),
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
          AppPanel(
            padding: const EdgeInsets.all(16),
            child: Text(
              exercise.description!,
              style: context.texts.bodyMedium
                  ?.copyWith(height: 1.6, color: tokens.textSecondary),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const SectionTitle('Sua evolução neste exercício'),
        progression.when(
          loading: () => const SizedBox(height: 120, child: LoadingView()),
          error: (error, _) => InlineError(message: '$error'),
          data: (data) {
            if (data.points.isEmpty) {
              return const InfoPanel(
                icon: Icons.show_chart_rounded,
                text: 'Faça esse exercício em um treino para ver a evolução aqui.',
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
                        color: tokens.accent,
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
                AppPanel(
                  padding: const EdgeInsets.fromLTRB(6, 18, 16, 6),
                  child: SizedBox(height: 200, child: _ProgressionChart(points: data.points)),
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
    final tokens = context.tokens;
    return Column(
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: AppRadius.all(AppRadius.lg),
            border: Border.all(color: tokens.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 260,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => Container(
                color: tokens.textPrimary,
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  placeholder: (_, _) => Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary),
                  ),
                  errorWidget: (_, _, _) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 36,
                      color: tokens.textMuted,
                    ),
                  ),
                ),
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
                    color: _index == index ? tokens.primary : tokens.borderStrong,
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
    final tokens = context.tokens;
    if (muscles.isEmpty) {
      return Text(
        'Sem informação de músculos ${primary ? 'principais' : 'auxiliares'}.',
        style: context.texts.bodySmall?.copyWith(color: tokens.textMuted),
      );
    }
    return AppPanel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabelText(title, size: 9.5),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles
                  .map(
                    (muscle) => TagChip(
                      muscle.name,
                      icon: primary ? Icons.bolt_rounded : Icons.circle_outlined,
                      color: primary ? tokens.primary : tokens.textMuted,
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
    final tokens = context.tokens;
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
          getDrawingHorizontalLine: (_) => FlLine(color: tokens.border, strokeWidth: 1),
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
                style: AppTypography.display(size: 9.5, weight: FontWeight.w600, color: tokens.textMuted),
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
                    style: AppTypography.display(size: 9.5, weight: FontWeight.w600, color: tokens.textMuted),
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
            color: tokens.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.5,
                color: tokens.primary,
                strokeWidth: 2,
                strokeColor: tokens.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: tokens.primary.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}
