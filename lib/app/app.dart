import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'l10n/l10n.dart';
import 'theme/ebb_theme.dart';

/// Light and dark follow the system, and so does the language.
class EbbApp extends StatelessWidget {
  const EbbApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => context.l10n.appTitle,
    theme: ebbTheme(Brightness.light),
    darkTheme: ebbTheme(Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const HomeScreen(),
  );
}
