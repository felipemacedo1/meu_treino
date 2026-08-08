import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../models/stats.dart';
import '../../models/user.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import '../history/history_page.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(statsOverviewProvider);
    final weekly = ref.watch(weeklyVolumeProvider);
    final groups = ref.watch(muscleGroupsProvider);
    final calendar = ref.watch(calendarProvider);
    final weights = ref.watch(bodyWeightsProvider);
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Evolução'),
        actions: [
          IconButton(
            tooltip: 'Histórico completo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: tokens.primary,
        backgroundColor: tokens.surfaceElevated,
        onRefresh: () async {
          ref.invalidate(statsOverviewProvider);
          ref.invalidate(weeklyVolumeProvider);
          ref.invalidate(muscleGroupsProvider);
          ref.invalidate(calendarProvider);
          ref.invalidate(bodyWeightsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          children: [
            overview.when(
              loading: () => const PanelSkeleton(height: 190),
              error: (error, _) => InlineError(message: '$error'),
              data: (data) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.66,
                children: [
                  StatCard(
                    label: 'Treinos realizados',
                    value: '${data.totalSessions}',
                    hint: '${data.workoutCount} fichas',
                    icon: Icons.check_circle_outline_rounded,
                    color: tokens.primary,
                  ),
                  StatCard(
                    label: 'Peso movimentado',
                    value: formatVolume(data.totalVolume),
                    icon: Icons.speed_rounded,
                    color: tokens.chartColor(1),
                  ),
                  StatCard(
                    label: 'Sequência atual',
                    value: '${data.currentStreak}',
                    hint: 'recorde ${data.longestStreak} dias',
                    icon: Icons.local_fire_department_rounded,
                    color: tokens.accent,
                  ),
                  StatCard(
                    label: 'Tempo treinando',
                    value: '${data.totalMinutes}',
                    hint: 'média ${data.avgSessionMinutes} min/treino',
                    icon: Icons.timer_outlined,
                    color: tokens.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionTitle('Volume semanal', subtitle: 'Carga × repetições por semana'),
            weekly.when(
              loading: () => const PanelSkeleton(height: 230),
              error: (error, _) => InlineError(message: '$error'),
              data: (data) => AppPanel(
                padding: const EdgeInsets.fromLTRB(8, 18, 14, 8),
                child: SizedBox(height: 210, child: _WeeklyChart(data: data)),
              ),
            ),
            const SizedBox(height: 26),
            const SectionTitle('Volume por grupo muscular', subtitle: 'Últimos 30 dias'),
            groups.when(
              loading: () => const PanelSkeleton(height: 150),
              error: (error, _) => InlineError(message: '$error'),
              data: (data) {
                if (data.isEmpty) {
                  return const InfoPanel(
                    text: 'Complete um treino para ver a distribuição por grupo muscular.',
                  );
                }
                final max = data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
                return AppPanel(
                  child: Column(
                    children: List.generate(data.length, (index) {
                      final group = data[index];
                      final color = tokens.chartColor(index);
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == data.length - 1 ? 0 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    group.group,
                                    style: context.texts.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  formatVolume(group.volume),
                                  style: AppTypography.display(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${group.sets} séries',
                                  style: AppTypography.label(9, color: tokens.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            ProgressTrack(
                              value: max == 0 ? 0 : group.volume / max,
                              height: 6,
                              color: color,
                              glow: false,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            const SizedBox(height: 26),
            const SectionTitle('Frequência', subtitle: 'Últimas 17 semanas'),
            calendar.when(
              loading: () => const PanelSkeleton(height: 150),
              error: (error, _) => InlineError(message: '$error'),
              data: (data) => AppPanel(child: _Heatmap(days: data)),
            ),
            const SizedBox(height: 26),
            const SectionTitle('Peso corporal'),
            weights.when(
              loading: () => const PanelSkeleton(height: 180),
              error: (error, _) => InlineError(message: '$error'),
              data: (points) {
                if (points.length < 2) {
                  return const InfoPanel(
                    icon: Icons.monitor_weight_outlined,
                    text: 'Registre seu peso no perfil em dias diferentes '
                        'para acompanhar a evolução.',
                  );
                }
                return AppPanel(
                  padding: const EdgeInsets.fromLTRB(8, 18, 14, 8),
                  child: SizedBox(height: 180, child: _BodyWeightChart(points: points)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Eixos e grade compartilhados pelos gráficos, para manter a mesma leitura.
class _ChartStyle {
  const _ChartStyle(this.tokens);

  final AppTokens tokens;

  FlGridData grid() => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: tokens.border, strokeWidth: 1),
      );

  TextStyle get axisLabel => AppTypography.display(
        size: 9,
        weight: FontWeight.w600,
        color: tokens.textMuted,
      );

  AxisTitles hidden() => const AxisTitles(sideTitles: SideTitles(showTitles: false));
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.data});

  final List<WeeklyVolume> data;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = _ChartStyle(tokens);
    if (data.isEmpty) {
      return Center(child: LabelText('Sem dados ainda', size: 10));
    }
    final maxVolume = data.map((e) => e.volume).fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVolume == 0 ? 10 : maxVolume * 1.2,
        gridData: style.grid(),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => tokens.surfaceElevated,
            tooltipBorderRadius: AppRadius.all(AppRadius.xs),
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${formatVolume(rod.toY)}\n${data[group.x].sessions} treino(s)',
              AppTypography.body(size: 11.5, weight: FontWeight.w600, color: tokens.textPrimary),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: style.hidden(),
          rightTitles: style.hidden(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value >= 1000
                      ? '${(value / 1000).toStringAsFixed(0)}t'
                      : value.toInt().toString(),
                  style: style.axisLabel,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(formatDayMonth(data[index].weekStart), style: style.axisLabel),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].volume,
                  width: 13,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      tokens.primary.withValues(alpha: 0.35),
                      tokens.primary,
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BodyWeightChart extends StatelessWidget {
  const _BodyWeightChart({required this.points});

  final List<BodyWeightPoint> points;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = _ChartStyle(tokens);
    final line = tokens.chartColor(1);

    // Com pouca variação de peso, rótulos inteiros repetiriam o mesmo número.
    final values = points.map((p) => p.weightKg).toList();
    final range = values.reduce((a, b) => a > b ? a : b) -
        values.reduce((a, b) => a < b ? a : b);
    final decimals = range < 5 ? 1 : 0;

    return LineChart(
      LineChartData(
        gridData: style.grid(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: style.hidden(),
          rightTitles: style.hidden(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) =>
                  Text(value.toStringAsFixed(decimals), style: style.axisLabel),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 4).ceilToDouble().clamp(1, 500),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                return Text(formatDayMonth(points[index].date), style: style.axisLabel);
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tokens.surfaceElevated,
            tooltipBorderRadius: AppRadius.all(AppRadius.xs),
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    '${formatNumber(spot.y)} kg',
                    AppTypography.body(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].weightKg),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            color: line,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.2,
                color: line,
                strokeWidth: 2,
                strokeColor: tokens.surface,
              ),
            ),
            belowBarData: BarAreaData(show: true, color: line.withValues(alpha: 0.14)),
          ),
        ],
      ),
    );
  }
}

/// Mapa de frequência: uma coluna por semana, uma célula por dia.
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});

  final List<CalendarDay> days;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final byDay = <String, CalendarDay>{};
    for (final day in days) {
      byDay['${day.date.year}-${day.date.month}-${day.date.day}'] = day;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    // domingo da semana atual, para a última coluna ser a semana corrente
    final endOfWeek = normalizedToday.add(Duration(days: 7 - normalizedToday.weekday));
    final start = endOfWeek.subtract(const Duration(days: 17 * 7 - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            children: List.generate(17, (week) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Column(
                  children: List.generate(7, (weekday) {
                    final date = start.add(Duration(days: week * 7 + weekday));
                    final key = '${date.year}-${date.month}-${date.day}';
                    final entry = byDay[key];
                    final future = date.isAfter(normalizedToday);
                    final isToday = date == normalizedToday;

                    Color color;
                    if (future) {
                      color = Colors.transparent;
                    } else if (entry == null) {
                      color = tokens.surfaceSunken;
                    } else {
                      color = tokens.primary
                          .withValues(alpha: (0.45 + 0.2 * entry.sessions).clamp(0.4, 1.0));
                    }

                    return Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                        border: isToday
                            ? Border.all(color: tokens.primary, width: 1.2)
                            : (future ? null : Border.all(color: tokens.border)),
                        boxShadow: entry != null
                            ? AppEffects.glow(tokens.glow, strength: 0.22, blur: 6)
                            : null,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            LabelText('menos', size: 9),
            const SizedBox(width: 7),
            ...List.generate(
              4,
              (index) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: index == 0
                      ? tokens.surfaceSunken
                      : tokens.primary.withValues(alpha: 0.25 + index * 0.25),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: tokens.border),
                ),
              ),
            ),
            const SizedBox(width: 3),
            LabelText('mais', size: 9),
          ],
        ),
      ],
    );
  }
}
