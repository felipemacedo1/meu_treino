import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

/// Perguntas rápidas depois do cadastro: peso, altura, objetivo, experiência,
/// dias disponíveis e tempo por treino.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  String _goal = 'HIPERTROFIA';
  String _experience = 'INICIANTE';
  int _availableDays = 4;
  int _sessionMinutes = 60;
  bool _saving = false;

  static const _goals = {
    'HIPERTROFIA': ('Hipertrofia', Icons.fitness_center_rounded),
    'FORCA': ('Força', Icons.bolt_rounded),
    'EMAGRECIMENTO': ('Emagrecimento', Icons.local_fire_department_rounded),
    'RESISTENCIA': ('Resistência', Icons.directions_run_rounded),
    'SAUDE': ('Saúde', Icons.favorite_rounded),
  };

  static const _experiences = {
    'INICIANTE': 'Iniciante',
    'INTERMEDIARIO': 'Intermediário',
    'AVANCADO': 'Avançado',
  };

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save({
        'weightKg': double.tryParse(_weight.text.replaceAll(',', '.')),
        'heightCm': int.tryParse(_height.text),
        'goal': _goal,
        'experience': _experience,
        'availableDays': _availableDays,
        'sessionMinutes': _sessionMinutes,
        'weeklyGoal': _availableDays,
      });
      if (mounted) context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) showAppSnack(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seu perfil'),
        actions: [
          TextButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Pular')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: appGradient(theme.colorScheme),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vamos personalizar seu treino',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Esses dados alimentam suas estatísticas e a evolução do seu treino.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 26),
          const SectionTitle('Objetivo'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _goals.entries.map((entry) {
              final selected = _goal == entry.key;
              return ChoiceChip(
                selected: selected,
                avatar: Icon(entry.value.$2, size: 16),
                label: Text(entry.value.$1),
                onSelected: (_) => setState(() => _goal = entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
          const SectionTitle('Experiência'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _experiences.entries.map((entry) {
              return ChoiceChip(
                selected: _experience == entry.key,
                label: Text(entry.value),
                onSelected: (_) => setState(() => _experience = entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
          SectionTitle('Dias disponíveis por semana', subtitle: '$_availableDays dias'),
          Slider(
            value: _availableDays.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_availableDays',
            onChanged: (value) => setState(() => _availableDays = value.round()),
          ),
          const SizedBox(height: 12),
          SectionTitle('Tempo por treino', subtitle: '$_sessionMinutes minutos'),
          Slider(
            value: _sessionMinutes.toDouble(),
            min: 20,
            max: 150,
            divisions: 13,
            label: '$_sessionMinutes min',
            onChanged: (value) => setState(() => _sessionMinutes = value.round()),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Começar a treinar'),
          ),
        ],
      ),
    );
  }
}
