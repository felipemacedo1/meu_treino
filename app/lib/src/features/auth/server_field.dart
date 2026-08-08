import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../providers/providers.dart';
import '../../theme/theme.dart';
import '../../widgets/common.dart';

/// Permite apontar o app para o servidor do usuário.
///
/// No app web o backend é servido pelo mesmo host (`/api`), então isso não
/// aparece. No APK é essencial: a API roda na máquina do usuário e o IP muda.
class ServerSelector extends ConsumerWidget {
  const ServerSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Na web o proxy do nginx resolve; expor isso só confundiria.
    if (kIsWeb) return const SizedBox.shrink();

    final tokens = context.tokens;
    final url = ref.watch(serverUrlProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AppPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => _edit(context, ref, url),
        child: Row(
          children: [
            Icon(Icons.dns_outlined, size: 16, color: tokens.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LabelText('Servidor', size: 9),
                  const SizedBox(height: 2),
                  Text(
                    url,
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
            Icon(Icons.edit_rounded, size: 15, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'SERVIDOR',
          style: AppTypography.display(size: 16, weight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endereço da API do Meu Treino na sua rede. '
              'Pode ser só o IP e a porta.',
              style: context.texts.bodySmall
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                hintText: '192.168.0.8:8080',
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Padrão'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;
    final notifier = ref.read(serverUrlProvider.notifier);
    if (result.trim().isEmpty) {
      await notifier.reset();
    } else {
      await notifier.set(result);
    }
    if (context.mounted) {
      showAppSnack(context, 'Servidor: ${Env.activeBaseUrl}');
    }
  }
}
