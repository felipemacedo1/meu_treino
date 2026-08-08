import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/user.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_controller.dart';
import '../../providers/providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';
import 'theme_picker.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authControllerProvider);
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Perfil')),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          children: [
            AppPanel(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.all(AppRadius.sm),
                      border: Border.all(color: tokens.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      auth.user?.initials ?? '?',
                      style: AppTypography.display(
                        size: 19,
                        weight: FontWeight.w800,
                        color: tokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name.toUpperCase(),
                          style: AppTypography.display(
                            size: 16,
                            weight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          data.email,
                          style: context.texts.bodySmall
                              ?.copyWith(color: tokens.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Peso atual',
                    value: data.weightKg == null ? '--' : formatNumber(data.weightKg),
                    hint: data.weightKg == null ? null : 'kg',
                    icon: Icons.monitor_weight_outlined,
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'IMC',
                    value: data.bmi == null ? '--' : formatNumber(data.bmi),
                    hint: data.heightCm == null ? null : '${data.heightCm} cm',
                    icon: Icons.straighten_rounded,
                    color: tokens.chartColor(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Dados de treino'),
            AppPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.flag_rounded,
                    label: 'Objetivo',
                    value: goalLabel(data.goal),
                  ),
                  _Separator(),
                  _InfoRow(
                    icon: Icons.military_tech_rounded,
                    label: 'Experiência',
                    value: experienceLabel(data.experience),
                  ),
                  _Separator(),
                  _InfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Dias disponíveis',
                    value: data.availableDays == null ? '--' : '${data.availableDays}/semana',
                  ),
                  _Separator(),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Tempo por treino',
                    value: data.sessionMinutes == null ? '--' : '${data.sessionMinutes} min',
                  ),
                  _Separator(),
                  _InfoRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'Meta semanal',
                    value: '${data.weeklyGoal ?? 4} treinos',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editProfile(context, ref, data),
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _logWeight(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Novo peso'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const AppearanceSection(),
            const SizedBox(height: 28),
            const SectionTitle('Catálogo de exercícios'),
            const _CatalogCard(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.error,
                side: BorderSide(color: tokens.error.withValues(alpha: 0.45)),
              ),
              onPressed: () async {
                final confirmed = await confirmDialog(
                  context,
                  title: 'Sair da conta',
                  message: 'Você precisará entrar novamente.',
                  confirmLabel: 'Sair',
                  destructive: true,
                );
                if (!confirmed) return;
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout_rounded, size: 17),
              label: const Text('Sair da conta'),
            ),
            const SizedBox(height: 20),
            Center(child: LabelText('Meu Treino · ${ref.watch(serverUrlProvider)}', size: 9)),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref, UserProfile profile) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ProfileForm(profile: profile),
      ),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(profileProvider.notifier).save(result);
      if (result['name'] is String) {
        ref.read(authControllerProvider.notifier).updateUserName(result['name'] as String);
      }
      ref.invalidate(bodyWeightsProvider);
      if (context.mounted) showAppSnack(context, 'Perfil atualizado.');
    } catch (error) {
      if (context.mounted) showAppSnack(context, error.toString(), error: true);
    }
  }

  Future<void> _logWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'REGISTRAR PESO',
          style: AppTypography.display(size: 16, weight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (value == null || !context.mounted) return;
    try {
      await ref.read(profileRepositoryProvider).addBodyWeight(value);
      ref.invalidate(bodyWeightsProvider);
      ref.invalidate(profileProvider);
      if (context.mounted) showAppSnack(context, 'Peso registrado.');
    } catch (error) {
      if (context.mounted) showAppSnack(context, error.toString(), error: true);
    }
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.tokens.border);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 17, color: tokens.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: context.texts.bodyMedium)),
          Text(
            value,
            style: AppTypography.display(
              size: 12,
              weight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.profile});

  final UserProfile profile;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final TextEditingController _name = TextEditingController(text: widget.profile.name);
  late final TextEditingController _weight = TextEditingController(
    text: widget.profile.weightKg == null ? '' : formatNumber(widget.profile.weightKg),
  );
  late final TextEditingController _height =
      TextEditingController(text: widget.profile.heightCm?.toString() ?? '');
  late String _goal = widget.profile.goal ?? 'HIPERTROFIA';
  late String _experience = widget.profile.experience ?? 'INICIANTE';
  late int _availableDays = widget.profile.availableDays ?? 4;
  late int _sessionMinutes = widget.profile.sessionMinutes ?? 60;
  late int _weeklyGoal = widget.profile.weeklyGoal ?? 4;

  static const _goals = ['HIPERTROFIA', 'FORCA', 'EMAGRECIMENTO', 'RESISTENCIA', 'SAUDE'];
  static const _experiences = ['INICIANTE', 'INTERMEDIARIO', 'AVANCADO'];

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Editar perfil'),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const LabelText('Objetivo', size: 10),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goals
                  .map(
                    (goal) => ChoiceChip(
                      label: Text(goalLabel(goal)),
                      selected: _goal == goal,
                      onSelected: (_) => setState(() => _goal = goal),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const LabelText('Experiência', size: 10),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _experiences
                  .map(
                    (item) => ChoiceChip(
                      label: Text(experienceLabel(item)),
                      selected: _experience == item,
                      onSelected: (_) => setState(() => _experience = item),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            _SliderField(
              label: 'Dias disponíveis',
              value: _availableDays,
              suffix: _availableDays == 1 ? 'dia' : 'dias',
              min: 1,
              max: 7,
              onChanged: (value) => setState(() => _availableDays = value),
            ),
            _SliderField(
              label: 'Meta semanal',
              value: _weeklyGoal,
              suffix: 'treinos',
              min: 1,
              max: 7,
              onChanged: (value) => setState(() => _weeklyGoal = value),
            ),
            _SliderField(
              label: 'Tempo por treino',
              value: _sessionMinutes,
              suffix: 'min',
              min: 20,
              max: 150,
              divisions: 13,
              onChanged: (value) => setState(() => _sessionMinutes = value),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'name': _name.text.trim(),
                'weightKg': double.tryParse(_weight.text.replaceAll(',', '.')),
                'heightCm': int.tryParse(_height.text),
                'goal': _goal,
                'experience': _experience,
                'availableDays': _availableDays,
                'sessionMinutes': _sessionMinutes,
                'weeklyGoal': _weeklyGoal,
              }),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider com rótulo e valor em destaque, no padrão do design system.
class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final int value;
  final String suffix;
  final int min;
  final int max;
  final int? divisions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: LabelText(label, size: 10)),
            Text(
              '$value',
              style: AppTypography.metric(16, color: tokens.primary),
            ),
            const SizedBox(width: 4),
            Text(suffix, style: AppTypography.label(9, color: tokens.textMuted)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions ?? (max - min),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

/// Mostra o tamanho do catálogo local e permite sincronizar com o wger.
class _CatalogCard extends ConsumerStatefulWidget {
  const _CatalogCard();

  @override
  ConsumerState<_CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends ConsumerState<_CatalogCard> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final tokens = context.tokens;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          catalog.when(
            loading: () => const LabelText('Carregando catálogo...', size: 10),
            error: (error, _) => Text('$error', style: context.texts.bodySmall),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${data.totalExercises}',
                      style: AppTypography.metric(24, color: tokens.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'EXERCÍCIOS NO BANCO LOCAL',
                      style: AppTypography.label(9.5, color: tokens.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.muscles.length} grupos musculares · ${data.equipment.length} equipamentos · ${data.categories.length} categorias',
                  style: context.texts.bodySmall
                      ?.copyWith(color: tokens.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fonte: wger.de (CC-BY-SA 4.0). Tudo salvo localmente — o app funciona sem internet.',
                  style: context.texts.bodySmall
                      ?.copyWith(color: tokens.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _syncing
                ? null
                : () async {
                    setState(() => _syncing = true);
                    try {
                      await ref.read(syncRepositoryProvider).sync();
                      if (context.mounted) {
                        showAppSnack(
                          context,
                          'Sincronização iniciada em background. Pode levar alguns minutos.',
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        showAppSnack(context, error.toString(), error: true);
                      }
                    } finally {
                      if (mounted) setState(() => _syncing = false);
                    }
                  },
            icon: _syncing
                ? SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary),
                  )
                : const Icon(Icons.sync_rounded, size: 17),
            label: const Text('Atualizar catálogo (wger)'),
          ),
        ],
      ),
    );
  }
}
