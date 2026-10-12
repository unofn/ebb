import 'package:clock/clock.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';

import '../../support/fake_rows.dart';
import '../../support/fake_subscription.dart';
import 'backup_bench.dart';

/// Fills [db] with one of everything, live and soft-deleted, settings and
/// rates included; stamps are taken at [at].
Future<void> seedEverything(BackupBench bench, {DateTime? at}) =>
    withClock(Clock.fixed(at ?? DateTime.utc(2026, 10, 1)), () async {
      final db = bench.db;
      final w = db.writer;
      final icon = await bench.store.put(iconBytes, mime: 'image/png');
      await w.insert(
        db.paymentMethods,
        PaymentMethodsCompanion.insert(id: 'pm-1', name: 'Card'),
      );
      await w.insert(db.tags, TagsCompanion.insert(id: 'tag-1', name: 'AI'));
      await w.insert(
        db.subscriptions,
        fakeSubscription(id: 'sub-1').copyWith(
          paymentMethodId: const Value('pm-1'),
          iconAttachmentId: const Value('att-1'),
        ),
      );
      await w.insert(
        db.subscriptions,
        fakeSubscription(id: 'sub-2', name: 'Music'),
      );
      await w.delete(db.subscriptions, 'sub-2');
      await w.insert(
        db.subscriptionTags,
        SubscriptionTagsCompanion.insert(
          id: 'st-1',
          subscriptionId: 'sub-1',
          tagId: 'tag-1',
        ),
      );
      await w.insert(
        db.payments,
        fakePayment(
          'pay-1',
          'sub-1',
          utcDate(2026, 9, 1),
          1200,
          rateToBase: '1',
          baseCurrency: 'CNY',
        ),
      );
      await w.insert(
        db.payments,
        fakePayment('pay-2', 'sub-2', utcDate(2026, 8, 1), 900),
      );
      await w.delete(db.payments, 'pay-2');
      await w.insert(
        db.importLinks,
        ImportLinksCompanion.insert(
          id: 'link-1',
          subscriptionId: 'sub-1',
          sourceApp: 'tilla',
          sourceId: 'T1',
          importedAt: DateTime.utc(2026, 9, 30, 8),
        ),
      );
      await w.insert(
        db.attachments,
        AttachmentsCompanion.insert(
          id: 'att-1',
          subscriptionId: const Value('sub-1'),
          kind: AttachmentKind.icon,
          fileName: 'icon.png',
          mime: 'image/png',
          sha256: icon.sha256,
          size: icon.size,
        ),
      );

      final settings = bench.settings;
      await settings.setReminderDays(7);
      await settings.setReminderTime(20 * 60);
      await settings.setBudgetMonthlyMinor(50000);
      await settings.setReviewLastCompletedOn(utcDate(2026, 7, 1));
      await settings.dismissDuplicate('hash-1');
      final rates = RateRepository(db, settings);
      await rates.save(
        FetchedRates(
          base: 'CNY',
          updatedAt: DateTime.utc(2026, 10, 1),
          rates: {'USD': Decimal.parse('0.14'), 'JPY': Decimal.parse('21')},
        ),
      );
      await rates.setOverride('CNY', 'USD', Decimal.parse('0.15'));
    });
