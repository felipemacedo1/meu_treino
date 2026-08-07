import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../providers/app_providers.dart';
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
    final theme = Theme.of(context);

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
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () => context.push(AppRoutes.sessionDetail(session.id)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${formatDateTime(session.startedAt)}\n'
                    '${formatVolume(session.totalVolume)} · ${session.totalSets} séries · ${formatDuration(session.durationSeconds)}',
                  ),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right_rounded),
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
                Expanded(child: Text('Histórico', style: theme.textTheme.titleLarge)),
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
      appBar: AppBar(title: const Text('Histórico')),
      body: body,
    );
  }
}
