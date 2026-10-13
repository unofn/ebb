import 'dart:async';
import 'dart:developer';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';
import 'close_to_tray.dart';
import 'tray_host.dart';

/// Linux only: closing the window hides it to the tray, so reminder
/// timers keep running; the tray menu opens Ebb again or quits. Without
/// a session bus or a tray host closing quits as usual.
class LinuxTray with WindowListener {
  LinuxTray(this._l10n);

  final AppLocalizations _l10n;
  CloseToTray? _closeToTray;

  // 托盘对象被回收就会从面板上消失，要一直持有；挂上的菜单由原生端持有。
  TrayIcon? _icon;

  Future<void> start() async {
    // 没有会话总线时图标照样建得出来但不显示；先查，免得关窗后再也找不回来。
    if (!TrayManager.instance.isSupported()) {
      log('no session bus; running without the tray', name: 'ebb.tray');
      return;
    }
    final icon = _icon = TrayIcon.create();
    final menu = Menu.create();
    if (icon == null || menu == null) {
      log('tray icon unavailable; running without it', name: 'ebb.tray');
      return;
    }
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
    await windowManager.ensureInitialized();
    // 有总线不等于有托盘宿主（GNOME 没装扩展时图标不出现），等宿主在了才拦关窗。
    _closeToTray = CloseToTray(DBusTrayHost(), apply: _hideOnClose)..start();
  }

  Future<void> _hideOnClose(bool hide) async {
    if (hide) {
      windowManager.addListener(this);
    } else {
      windowManager.removeListener(this);
    }
    await windowManager.setPreventClose(hide);
    // 宿主走了，藏起来的窗口就再也找不回来，先显示出来。
    if (!hide && !await windowManager.isVisible()) await _open();
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
    await _closeToTray?.stop();
    windowManager.removeListener(this);
    _icon?.dispose();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}
