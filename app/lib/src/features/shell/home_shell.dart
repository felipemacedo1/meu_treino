import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import '../dashboard/dashboard_page.dart';
import '../exercises/exercises_page.dart';
import '../profile/profile_page.dart';
import '../stats/stats_page.dart';
import '../workouts/workouts_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialTab.clamp(0, 4);

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Início',
    ),
    NavigationDestination(
      icon: Icon(Icons.view_agenda_outlined),
      selectedIcon: Icon(Icons.view_agenda_rounded),
      label: 'Treinos',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search_rounded),
      label: 'Exercícios',
    ),
    NavigationDestination(
      icon: Icon(Icons.show_chart_outlined),
      selectedIcon: Icon(Icons.show_chart_rounded),
      label: 'Evolução',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider).value;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            DashboardPage(onSeeAllWorkouts: () => setState(() => _index = 1)),
            const WorkoutsPage(),
            const ExercisesPage(),
            const StatsPage(),
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeSession != null && activeSession.inProgress)
            _ActiveSessionBar(
              title: activeSession.title,
              progress: activeSession.progress,
              completed: activeSession.completedSets,
              planned: activeSession.plannedSets,
              onTap: () => context.push(AppRoutes.session),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.border)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: _destinations,
            ),
          ),
        ],
      ),
    );
  }
}

/// Faixa persistente de treino em andamento. Fica acima da navegação para o
/// usuário voltar ao treino de qualquer aba com um toque.
class _ActiveSessionBar extends StatelessWidget {
  const _ActiveSessionBar({
    required this.title,
    required this.progress,
    required this.completed,
    required this.planned,
    required this.onTap,
  });

  final String title;
  final double progress;
  final int completed;
  final int planned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.primary,
      child: InkWell(
        onTap: onTap,
        splashColor: tokens.onPrimary.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: AppEffects.glow(tokens.glow, strength: 0.35, blur: 20),
          ),
          padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
          child: Row(
            children: [
              _LiveDot(color: tokens.onPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(10.5, color: tokens.onPrimary),
                    ),
                    const SizedBox(height: 5),
                    ProgressTrack(
                      value: progress,
                      height: 4,
                      glow: false,
                      color: tokens.onPrimary,
                      trackColor: tokens.onPrimary.withValues(alpha: 0.28),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completed/$planned',
                style: AppTypography.metric(15, color: tokens.onPrimary),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ponto pulsante indicando sessão ativa.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        height: 9,
        width: 9,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
