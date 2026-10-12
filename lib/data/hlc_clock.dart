import 'package:clock/clock.dart';
import 'package:crdt/crdt.dart' show Hlc;

import '../core/ids.dart';
import 'database.dart';
import 'local_meta_store.dart';
import 'tables/local_meta.dart';

/// Issues strictly increasing HLC stamps for this device. The device ID and
/// the latest stamp persist in local_meta, so stamps keep increasing across
/// restarts. Use one instance per database: [AppDatabase.hlcClock].
class HlcClock {
  HlcClock(this._db);

  final AppDatabase _db;
  late final Future<Hlc> _loaded = _load();
  Hlc? _last;

  /// This device's ID (UUID v4, created on first use).
  Future<String> get deviceId async => (await _loaded).nodeId;

  /// The next stamp as a string; persisted before it is returned.
  Future<String> next() async {
    final loaded = await _loaded;
    final previous = _last ?? loaded;
    // 截到毫秒：toIso8601String 定宽，字符串顺序即时间顺序（第二版按字符串比较）。
    // 墙钟落后于上次时间戳（例如系统时间被调回）时沿用上次时间只加计数，
    // 不让 crdt 抛 ClockDriftException。
    final now = DateTime.fromMillisecondsSinceEpoch(
      clock.now().millisecondsSinceEpoch,
      isUtc: true,
    );
    final wall = now.isAfter(previous.dateTime) ? now : previous.dateTime;
    final hlc = _last = previous.increment(wallTime: wall);
    await _db.writeMeta(LocalMetaKeys.hlc, hlc.toString());
    return hlc.toString();
  }

  /// Moves the clock up to [stamp] (e.g. the newest one in a restored
  /// backup) when it is ahead, so later stamps sort after it. The device
  /// ID stays this device's.
  Future<void> advanceTo(Hlc stamp) async {
    final loaded = await _loaded;
    final previous = _last ?? loaded;
    // 只比较不合并：Hlc.merge 遇到同一设备 ID（恢复本机的备份）或时间超前
    // 太多都会抛错。
    final target = stamp.apply(nodeId: previous.nodeId);
    if (target <= previous) return;
    _last = target;
    await _db.writeMeta(LocalMetaKeys.hlc, target.toString());
  }

  Future<Hlc> _load() async {
    var deviceId = await _db.readMeta(LocalMetaKeys.deviceId);
    if (deviceId == null) {
      deviceId = newId();
      await _db.writeMeta(LocalMetaKeys.deviceId, deviceId);
    }
    final stored = await _db.readMeta(LocalMetaKeys.hlc);
    if (stored == null) return Hlc.zero(deviceId);
    return Hlc.parse(stored).apply(nodeId: deviceId);
  }
}
