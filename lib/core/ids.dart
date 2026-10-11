import 'package:uuid/uuid.dart';

/// UUID v5 namespace for every deterministic ID in Ebb. Never change it.
const ebbNamespace = '763c2abf-15b7-44d9-a70a-7f0af1ff655b';

const _uuid = Uuid();

/// Random ID (v4) for records the user creates.
String newId() => _uuid.v4();

/// Deterministic ID (v5) derived from [name], e.g. `category:video` or
/// `tilla:<sourceId>`; the same name always yields the same ID.
String stableId(String name) => _uuid.v5(ebbNamespace, name);
