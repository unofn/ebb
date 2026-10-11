import 'dart:async';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';

/// Linux only: closing the window hides it to the tray, so reminder
/// timers keep running; the tray menu opens Ebb again or quits.
class LinuxTray with WindowListener {
  LinuxTray(this._l10n);

  final AppLocalizations _l10n;

  // 托盘对象被回收就会从面板上消失，要一直持有；挂上的菜单由原生端持有。
  TrayIcon? _icon;

  Future<void> start() async {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    final icon = _icon = TrayIcon.create();
    final menu = Menu.create();
    if (icon == null || menu == null) return;
    icon
      ..icon = ImageAsset.fromAsset('assets/tray/tray_icon.png')
      ..setTooltip('Ebb');
    menu
      ..addItem(_item(_l10n.trayOpen, _open))
      ..addSeparator()
      ..addItem(_item(_l10n.trayQuit, _quit));
    icon
      ..setContextMenu(menu)
      ..setVisible(true);
  }

  @override
  void onWindowClose() => unawaited(windowManager.hide());

  MenuItem? _item(String label, Future<void> Function() onClick) {
    final item = MenuItem.createWithLabelAndType(label, MenuItemType.normal);
    item?.addListener((event) {
      if (event is MenuItemClickedEvent) unawaited(onClick());
    });
    return item;
  }

  Future<void> _open() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    windowManager.removeListener(this);
    _icon?.dispose();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}
