import 'package:flutter/material.dart';

import '../../core/formatters.dart';

/// Cronômetro de descanso entre séries.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({
    super.key,
    required this.remaining,
    required this.total,
    required this.label,
    required this.onSkip,
    required this.onAdd,
    required this.onSubtract,
  });

  final int remaining;
  final int total;
  final String label;
  final VoidCallback onSkip;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    final almostDone = remaining <= 5;

    return Material(
      color: almostDone ? scheme.tertiary : scheme.primary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    formatClock(remaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Descanso · $label',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ),
                  IconButton(
                    tooltip: '-15s',
                    onPressed: onSubtract,
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: '+15s',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Pular'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
