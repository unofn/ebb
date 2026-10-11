import 'source_timezone.dart';

/// What every record of one export is mapped against.
class TillaContext {
  const TillaContext({
    required this.zone,
    required this.methodNames,
    required this.today,
  });

  final SourceTimezone zone;

  /// Payment method titles by uuid.
  final Map<String, String> methodNames;
  final DateTime today;
}
