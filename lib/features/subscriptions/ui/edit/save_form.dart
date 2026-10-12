import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/job_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../data/enums.dart';
import 'form/edit_form.dart';
import 'form/form_rows.dart';

/// Writes a valid [form]: a new active subscription when [id] is null,
/// else the form's columns and tags of [id]. Then starts the jobs (without
/// waiting) so due payments and reminders follow at once.
Future<void> saveForm(WidgetRef ref, EditForm form, String? id) async {
  final repository = ref.read(subscriptionRepositoryProvider);
  final jobs = ref.read(appJobsProvider);
  final columns = columnsOf(form);
  if (id == null) {
    await repository.create(
      columns.copyWith(status: const Value(SubscriptionStatus.active)),
      tagIds: form.tagIds,
    );
  } else {
    await repository.update(id, columns, tagIds: form.tagIds);
  }
  unawaited(jobs.runAll());
}
