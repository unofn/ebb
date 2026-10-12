import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';
import 'router/app_router.dart';
import 'theme/ebb_theme.dart';

/// Light and dark follow the system, and so does the language.
class EbbApp extends ConsumerWidget {
  const EbbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    onGenerateTitle: (context) => context.l10n.appTitle,
    theme: ebbTheme(Brightness.light),
    darkTheme: ebbTheme(Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: ref.watch(appRouterProvider),
  );
}
