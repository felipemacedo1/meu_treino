import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

/// Cronômetro de descanso.
///
/// É o elemento mais visível do treino: ocupa a base da tela, com dígitos
/// grandes em Orbitron e brilho na cor da marca. Nos últimos segundos muda
/// para o tom de alerta, para ser percebido de longe sem precisar ler.
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
    final tokens = context.tokens;
    final progress = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    final ending = remaining <= 5;
    final tint = ending ? tokens.accent : tokens.primary;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(top: BorderSide(color: tint.withValues(alpha: 0.55), width: 1.4)),
        boxShadow: AppEffects.glow(tint, strength: 0.24, blur: 26, offset: const Offset(0, -4)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, color: tint, size: 20),
                  const SizedBox(width: 10),
                  // dígitos grandes e de largura fixa: legíveis de relance e
                  // sem tremer a cada segundo
                  MonoDigits(
                    formatClock(remaining),
                    style: AppTypography.metric(38, color: tint),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabelText('Descanso', size: 9.5, color: tint),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TimerAction(icon: Icons.remove_rounded, onTap: onSubtract, label: '15s'),
                  const SizedBox(width: 6),
                  _TimerAction(icon: Icons.add_rounded, onTap: onAdd, label: '15s'),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(foregroundColor: tint),
                    child: const Text('Pular'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ProgressTrack(value: progress, height: 5, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerAction extends StatelessWidget {
  const _TimerAction({required this.icon, required this.onTap, required this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Tooltip(
      message: '${icon == Icons.add_rounded ? '+' : '-'}$label',
      child: Material(
        color: tokens.surfaceSunken,
        borderRadius: AppRadius.all(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all(AppRadius.xs),
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              borderRadius: AppRadius.all(AppRadius.xs),
              border: Border.all(color: tokens.border),
            ),
            child: Icon(icon, size: 18, color: tokens.textSecondary),
          ),
        ),
      ),
    );
  }
}
