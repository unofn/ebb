// 冒烟：dart run tool/import_smoke.dart <导出文件>...
// 所有文件导入同一个内存库（两个 App 的文件一起给时能看到跨 App 同名），
// 每个文件再导入一次验证幂等。只打印，不写任何文件。
import 'dart:io';

import 'package:drift/native.dart';
import 'package:ebb/data/database.dart';

import 'smoke/smoke_file.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/import_smoke.dart <file>...');
    exitCode = 64;
    return;
  }
  final db = AppDatabase(NativeDatabase.memory());
  try {
    for (final path in args) {
      await smokeFile(db, path);
    }
  } finally {
    await db.close();
  }
}
