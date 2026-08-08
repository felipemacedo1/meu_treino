import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key, this.insideSheet = false});

  final bool insideSheet;

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent - 300) {
        ref.read(historyProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final tokens = context.tokens;

    final body = history.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: '$error',
        onRetry: () => ref.invalidate(historyProvider),
      ),
      data: (paged) {
        if (paged.items.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'Sem treinos ainda',
            message: 'Depois do primeiro treino concluído, tudo aparece aqui.',
          );
        }
        return ListView.separated(
          controller: _controller,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: paged.items.length + (paged.last ? 0 : 1),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= paged.items.length) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final session = paged.items[index];
            return AppPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              onTap: () => context.push(AppRoutes.sessionDetail(session.id)),
              child: Row(
                children: [
                  DayBadge(label: session.dayLabel ?? 'L', size: 40),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.dayName ?? session.workoutName ?? 'Treino',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatDateTime(session.startedAt),
                          style: context.texts.bodySmall
                              ?.copyWith(color: tokens.textMuted, fontSize: 11.5),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            _HistoryMetric(
                              icon: Icons.speed_rounded,
                              value: formatVolume(session.totalVolume),
                            ),
                            const SizedBox(width: 12),
                            _HistoryMetric(
                              icon: Icons.repeat_rounded,
                              value: '${session.totalSets}',
                            ),
                            const SizedBox(width: 12),
                            _HistoryMetric(
                              icon: Icons.schedule_rounded,
                              value: formatDuration(session.durationSeconds),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: tokens.textMuted, size: 20),
                ],
              ),
            );
          },
        );
      },
    );

    if (widget.insideSheet) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'HISTÓRICO',
                    style: AppTypography.display(size: 16, weight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Histórico')),
      body: body,
    );
  }
}

/// Métrica compacta usada nos cartões do histórico.
class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: tokens.textMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.display(
            size: 11,
            weight: FontWeight.w700,
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
