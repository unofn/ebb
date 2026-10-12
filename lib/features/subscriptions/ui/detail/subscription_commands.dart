import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/providers/job_providers.dart';
import '../../../../app/providers/rate_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../app/widgets/confirm_dialog.dart';
import '../../../../core/local_date.dart';
import '../../../../data/database.dart';
import '../../../../data/enums.dart';
import '../../../payments/domain/mark_paid.dart';
import '../../domain/resume_date.dart';

/// What the home rows and the detail page do to a subscription; every
/// write goes through the repositories.
extension SubscriptionCommands on WidgetRef {
  /// Confirms paying the charge due on [sub]'s next date (manual renewal).
  Future<void> markPaidNow(BuildContext context, Subscription sub) async {
    final due = sub.nextDate;
    if (due == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final text = context.l10n.homePaidRecorded(sub.name);
    final base = await read(localSettingsProvider).baseCurrency();
    final rates = await read(rateRepositoryProvider).current(base);
    final run = markPaid(sub, due, rates: rates);
    if (run.isEmpty) return;
    await read(paymentRepositoryProvider).recordManual(sub.id, run);
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  /// Not renewing: it ends on its next date.
  Future<void> setEnding(Subscription sub) =>
      read(subscriptionRepositoryProvider).update(
        sub.id,
        SubscriptionsCompanion(
          status: const Value(SubscriptionStatus.ending),
          endDate: Value(sub.nextDate),
        ),
      );

  /// Back from not renewing to renewing, same next date.
  Future<void> keepRenewing(Subscription sub) =>
      read(subscriptionRepositoryProvider).update(
        sub.id,
        const SubscriptionsCompanion(
          status: Value(SubscriptionStatus.active),
          endDate: Value(null),
        ),
      );

  Future<void> pause(Subscription sub) => read(subscriptionRepositoryProvider)
      .update(
        sub.id,
        const SubscriptionsCompanion(status: Value(SubscriptionStatus.paused)),
      );

  /// Active again (restored or unpaused) from the first charge on or after
  /// today; the time away is not charged. Runs the jobs so a charge due
  /// today is recorded now.
  Future<void> resume(Subscription sub) async {
    // 先取好：恢复后这一行离开「已归档」，调用它的行可能随之销毁。
    final jobs = read(appJobsProvider);
    await read(subscriptionRepositoryProvider)
        .restore(sub.id, nextDate: resumeDateOf(sub, today()));
    unawaited(jobs.runAll());
  }

  /// Archives [sub] after asking; true when it did.
  Future<bool> archiveAsking(BuildContext context, Subscription sub) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.detailArchiveTitle(sub.name),
      body: l10n.detailArchiveBody,
      action: l10n.detailArchive,
    );
    if (confirmed) await read(subscriptionRepositoryProvider).archive(sub.id);
    return confirmed;
  }

  /// Deletes [sub] and its payments after asking; true when it did.
  Future<bool> deleteAsking(BuildContext context, Subscription sub) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.detailDeleteTitle(sub.name),
      body: l10n.detailDeleteBody,
      action: l10n.detailDelete,
    );
    if (confirmed) await read(subscriptionRepositoryProvider).delete(sub.id);
    return confirmed;
  }
}
