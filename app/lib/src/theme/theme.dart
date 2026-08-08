import 'package:flutter/material.dart';

import 'app_tokens.dart';

export 'app_effects.dart';
export 'app_themes.dart';
export 'app_tokens.dart';
export 'app_typography.dart';
export 'theme_builder.dart';

/// Atalho para os tokens do tema ativo.
///
/// Uso nas telas: `final t = context.tokens;` e então `t.primary`,
/// `t.textSecondary`, `t.surface`… Nunca cores literais.
extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;

  TextTheme get texts => Theme.of(this).textTheme;
}
