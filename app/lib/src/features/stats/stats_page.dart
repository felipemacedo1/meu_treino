import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/stats.dart';
import '../../providers/app_providers.dart';
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
    final theme = Theme.of(context);

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
        onRefresh: () async {
          ref.invalidate(statsOverviewProvider);
          ref.invalidate(weeklyVolumeProvider);
          ref.invalidate(muscleGroupsProvider);
          ref.invalidate(calendarProvider);
          ref.invalidate(bodyWeightsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            overview.when(
              loading: () => const SizedBox(height: 180, child: LoadingView()),
              error: (error, _) => ErrorView(message: '$error'),
              data: (data) => Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        label: 'Treinos realizados',
                        value: '${data.totalSessions}',
                        hint: '${data.workoutCount} fichas',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      StatCard(
                        label: 'Peso movimentado',
                        value: formatVolume(data.totalVolume),
                        icon: Icons.scale_rounded,
                        color: AppTheme.accent,
                      ),
                      StatCard(
                        label: 'Sequência atual',
                        value: '${data.currentStreak} dia(s)',
                        hint: 'recorde ${data.longestStreak}',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.deepOrange,
                      ),
                      StatCard(
                        label: 'Tempo treinando',
                        value: '${data.totalMinutes} min',
                        hint: 'média ${data.avgSessionMinutes} min',
                        icon: Icons.timer_outlined,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionTitle('Volume semanal', subtitle: 'Carga x repetições por semana'),
            weekly.when(
              loading: () => const SizedBox(height: 220, child: LoadingView()),
              error: (error, _) => ErrorView(message: '$error'),
              data: (data) => Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 16, 10),
                  child: SizedBox(height: 210, child: _WeeklyChart(data: data)),
                ),
              ),
            ),
            const SizedBox(height: 26),
            const SectionTitle('Volume por grupo muscular', subtitle: 'Últimos 30 dias'),
            groups.when(
              loading: () => const SizedBox(height: 140, child: LoadingView()),
              error: (error, _) => ErrorView(message: '$error'),
              data: (data) {
                if (data.isEmpty) {
                  return _InfoCard(
                    text: 'Complete um treino para ver a distribuição por grupo muscular.',
                  );
                }
                final max = data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: data
                          .map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(group.group,
                                            style: theme.textTheme.bodyMedium),
                                      ),
                                      Text(
                                        '${formatVolume(group.volume)} · ${group.sets} séries',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: max == 0 ? 0 : group.volume / max,
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 26),
            const SectionTitle('Frequência', subtitle: 'Últimas 17 semanas'),
            calendar.when(
              loading: () => const SizedBox(height: 130, child: LoadingView()),
              error: (error, _) => ErrorView(message: '$error'),
              data: (data) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _Heatmap(days: data),
                ),
              ),
            ),
            const SizedBox(height: 26),
            const SectionTitle('Peso corporal'),
            weights.when(
              loading: () => const SizedBox(height: 160, child: LoadingView()),
              error: (error, _) => ErrorView(message: '$error'),
              data: (points) {
                if (points.length < 2) {
                  return _InfoCard(
                    text:
                        'Registre seu peso no perfil em dias diferentes para acompanhar a evolução.',
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 16, 10),
                    child: SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) =>
                                FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles:
                                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles:
                                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 26,
                                interval: (points.length / 4).ceilToDouble().clamp(1, 500),
                                getTitlesWidget: (value, meta) {
                                  final index = value.round();
                                  if (index < 0 || index >= points.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    formatDayMonth(points[index].date),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < points.length; i++)
                                  FlSpot(i.toDouble(), points[i].weightKg),
                              ],
                              isCurved: true,
                              color: AppTheme.accent,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.accent.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.data});

  final List<WeeklyVolume> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) {
      return const Center(child: Text('Sem dados ainda.'));
    }
    final maxVolume = data.map((e) => e.volume).fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVolume == 0 ? 10 : maxVolume * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${formatVolume(rod.toY)}\n${data[group.x].sessions} treino(s)',
              TextStyle(color: scheme.onInverseSurface, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}t' : value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatDayMonth(data[index].weekStart),
                    style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                  ),
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
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [scheme.primary.withValues(alpha: 0.6), scheme.primary],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days});

  final List<CalendarDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                    return Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: future
                            ? Colors.transparent
                            : entry == null
                                ? scheme.surfaceContainerHighest
                                : scheme.primary.withValues(
                                    alpha: (0.45 + 0.18 * entry.sessions).clamp(0.35, 1.0),
                                  ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'menos',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 6),
            ...List.generate(
              4,
              (index) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: index == 0
                      ? scheme.surfaceContainerHighest
                      : scheme.primary.withValues(alpha: 0.3 + index * 0.23),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Text('mais', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.insights_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
