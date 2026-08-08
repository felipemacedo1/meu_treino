import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'src/core/router.dart';
import 'src/core/storage.dart';
import 'src/providers/providers.dart';
import 'src/providers/theme_controller.dart';
import 'src/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs limpas na web (/workouts/3 em vez de /#/workouts/3)
  usePathUrlStrategy();
  initializeDateFormatting('pt_BR');
  final storage = await Storage.create();

  runApp(
    ProviderScope(
      overrides: [storageProvider.overrideWithValue(storage)],
      child: const MeuTreinoApp(),
    ),
  );
}

class MeuTreinoApp extends ConsumerWidget {
  const MeuTreinoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeControllerProvider);
    final data = ThemeBuilder.build(theme);

    // A barra de status acompanha o tema (todos são escuros).
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: theme.tokens.surfaceElevated,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp.router(
      title: 'Meu Treino',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: data,
      darkTheme: data,
      themeMode: ThemeMode.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Fundo técnico compartilhado por todas as telas.
      builder: (context, child) => AppBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Aplica o gradiente e a grade sutil do tema atrás de toda a navegação,
/// para que nenhuma tela precise se preocupar com o fundo.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TechGridBackground(
      tokens: tokens,
      child: child,
    );
  }
}
