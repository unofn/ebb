import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/providers/update_providers.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:ebb/features/updates/data/update_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  const title = 'Ebb 0.2.0 可以更新了';

  /// One subscription (so home shows its list) and release 0.2.0 found.
  Future<void> seed({String? note = '新增备份恢复和附件'}) async {
    await SubscriptionRepository(db).create(
      seedable('Stream')
          .toCompanion(false)
          .copyWith(updatedAt: const Value.absent()),
    );
    await UpdateSettings(db).setLatest(
      jsonEncode({
        'version': '0.2.0',
        'note': note,
        'url': 'https://github.com/unofn/ebb/releases/tag/v0.2.0',
      }),
    );
  }

  final onOldVersion = [
    appVersionProvider.overrideWith((ref) async => '0.1.4'),
  ];

  testWidgets('a newer release: its own card until closed', (tester) async {
    await seed();
    await pumpEbb(tester, db, overrides: onOldVersion);

    expect(find.text(title), findsOneWidget);
    expect(find.text('新增备份恢复和附件'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '查看'), findsOneWidget);

    await tester.tap(find.byTooltip('不再提示这个版本'));
    await settleWrites(tester);
    expect(find.text(title), findsNothing);
    final dismissed = await tester.runAsync(
      () => UpdateSettings(db).watchDismissedVersion().first,
    );
    expect(dismissed, '0.2.0');
    await unmountEbb(tester);
  });

  testWidgets('without notes, only the title line', (tester) async {
    await seed(note: null);
    await pumpEbb(tester, db, overrides: onOldVersion);

    final card = find.ancestor(
      of: find.text(title),
      matching: find.byType(Column),
    );
    expect(
      find.descendant(of: card.first, matching: find.byType(Text)),
      findsOneWidget,
    );
    await unmountEbb(tester);
  });

  testWidgets('already on that version: no card', (tester) async {
    await seed();
    await pumpEbb(
      tester,
      db,
      overrides: [appVersionProvider.overrideWith((ref) async => '0.2.0')],
    );

    expect(find.text(title), findsNothing);
    await unmountEbb(tester);
  });

  testWidgets('the wide list column shows it too', (tester) async {
    await seed();
    await pumpEbb(
      tester,
      db,
      size: const Size(1200, 900),
      overrides: onOldVersion,
    );

    expect(find.text(title), findsOneWidget);
    await unmountEbb(tester);
  });
}
