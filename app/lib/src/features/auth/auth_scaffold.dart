import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../widgets/common.dart';

/// Layout compartilhado pelas telas de login e cadastro.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _LogoMark(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabelText('Meu Treino', size: 10, color: tokens.primary),
                            const SizedBox(height: 3),
                            Text(
                              title.toUpperCase(),
                              style: AppTypography.display(
                                size: 24,
                                weight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  NeonDivider(tokens: tokens),
                  const SizedBox(height: 14),
                  Text(
                    subtitle,
                    style: context.texts.bodyMedium?.copyWith(color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  ...children,
                  const SizedBox(height: 18),
                  footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        gradient: tokens.brandGradient,
        borderRadius: AppRadius.all(AppRadius.md),
        boxShadow: AppEffects.glow(tokens.glow, strength: 0.42, blur: 24),
      ),
      child: Icon(Icons.bolt_rounded, color: tokens.onPrimary, size: 32),
    );
  }
}

/// Botão de ação das telas de autenticação, com estado de carregamento.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: tokens.onPrimary),
            )
          : Text(label),
    );
  }
}
