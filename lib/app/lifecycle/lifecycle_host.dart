import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/job_providers.dart';
import '../providers/repository_providers.dart';

/// Runs [AppJobs] on start and whenever the app returns to the
/// foreground, and replans reminders when subscriptions change.
class LifecycleHost extends ConsumerStatefulWidget {
  const LifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LifecycleHost> createState() => _LifecycleHostState();
}

class _LifecycleHostState extends ConsumerState<LifecycleHost> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<Object?>? _changes;

  @override
  void initState() {
    super.initState();
    final jobs = ref.read(appJobsProvider);
    unawaited(jobs.runAll());
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(jobs.runAll()));
    // 第一次推送是当前列表，启动任务已经覆盖。
    _changes = ref
        .read(subscriptionRepositoryProvider)
        .watchAll()
        .skip(1)
        .listen((_) => jobs.subscriptionsChanged());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_changes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
