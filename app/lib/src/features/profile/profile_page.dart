import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env.dart';
import '../../core/formatters.dart';
import '../../core/router.dart';
import '../../models/user.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_controller.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final theme = Theme.of(context);

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    auth.user?.initials ?? '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.name, style: theme.textTheme.titleLarge),
                      Text(
                        data.email,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Peso atual',
                    value: data.weightKg == null ? '--' : formatWeight(data.weightKg),
                    icon: Icons.monitor_weight_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'IMC',
                    value: data.bmi == null ? '--' : formatNumber(data.bmi),
                    hint: data.heightCm == null ? null : '${data.heightCm} cm',
                    icon: Icons.straighten_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.flag_rounded,
                    label: 'Objetivo',
                    value: goalLabel(data.goal),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.military_tech_rounded,
                    label: 'Experiência',
                    value: experienceLabel(data.experience),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Dias disponíveis',
                    value: data.availableDays == null ? '--' : '${data.availableDays} por semana',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Tempo por treino',
                    value: data.sessionMinutes == null ? '--' : '${data.sessionMinutes} min',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'Meta semanal',
                    value: '${data.weeklyGoal ?? 4} treinos',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _editProfile(context, ref, data),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar perfil'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _logWeight(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Novo peso'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const SectionTitle('Aparência'),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (mode) =>
                        ref.read(themeControllerProvider.notifier).set(mode ?? ThemeMode.system),
                    title: const Text('Seguir o sistema'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (mode) =>
                        ref.read(themeControllerProvider.notifier).set(mode ?? ThemeMode.light),
                    title: const Text('Tema claro'),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (mode) =>
                        ref.read(themeControllerProvider.notifier).set(mode ?? ThemeMode.dark),
                    title: const Text('Tema escuro'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionTitle('Catálogo de exercícios'),
            const _CatalogCard(),
            const SizedBox(height: 26),
            OutlinedButton.icon(
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
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair da conta'),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Meu Treino · API ${Env.apiBaseUrl}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
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
        title: const Text('Registrar peso'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.labelLarge),
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
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Editar perfil', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 20),
            Text('Objetivo', style: theme.textTheme.labelLarge),
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
            Text('Experiência', style: theme.textTheme.labelLarge),
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
            Text('Dias disponíveis: $_availableDays', style: theme.textTheme.labelLarge),
            Slider(
              value: _availableDays.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) => setState(() => _availableDays = value.round()),
            ),
            Text('Meta semanal: $_weeklyGoal treinos', style: theme.textTheme.labelLarge),
            Slider(
              value: _weeklyGoal.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) => setState(() => _weeklyGoal = value.round()),
            ),
            Text('Tempo por treino: $_sessionMinutes min', style: theme.textTheme.labelLarge),
            Slider(
              value: _sessionMinutes.toDouble(),
              min: 20,
              max: 150,
              divisions: 13,
              onChanged: (value) => setState(() => _sessionMinutes = value.round()),
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
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            catalog.when(
              loading: () => const Text('Carregando catálogo...'),
              error: (error, _) => Text('$error'),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.totalExercises} exercícios no banco local',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.muscles.length} grupos musculares · ${data.equipment.length} equipamentos · ${data.categories.length} categorias',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fonte: wger.de (CC-BY-SA 4.0). Tudo fica salvo localmente, o app funciona sem internet.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: const Text('Atualizar catálogo (wger)'),
            ),
          ],
        ),
      ),
    );
  }
}
