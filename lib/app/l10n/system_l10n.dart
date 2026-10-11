import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Strings in the system language, resolved the way `MaterialApp` does,
/// for text made outside the widget tree (notifications, tray menu).
AppLocalizations systemL10n() => lookupAppLocalizations(
  basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  ),
);
