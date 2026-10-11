import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../database.dart';
import '../writer.dart';

/// Built-in category keys by statistics group, in display order. Keys are
/// permanent: they derive the stable IDs and the localized names.
const builtInCategories = <String, List<String>>{
  'entertainment': ['video', 'audio', 'gaming', 'social'],
  'learning': ['reading', 'courses', 'communities'],
  'software': [
    'ai_assistant',
    'productivity',
    'creative',
    'developer',
    'cloud',
    'storage',
    'vpn',
    'security',
    'other_software',
  ],
  'life': [
    'shopping',
    'food',
    'transport',
    'health',
    'housing',
    'utilities',
    'telecom',
  ],
  'finance': ['insurance', 'bank_fees'],
  'other': ['donation', 'other'],
};

/// Stable ID of the built-in category [key].
String categoryIdOf(String key) => stableId('category:$key');

/// Inserts every built-in category; runs once, when the database is created.
Future<void> seedCategories(AppDatabase db, Writer writer) async {
  var sort = 0;
  for (final MapEntry(key: group, value: keys) in builtInCategories.entries) {
    for (final key in keys) {
      await writer.insert(
        db.categories,
        CategoriesCompanion.insert(
          id: categoryIdOf(key),
          key: Value(key),
          groupKey: group,
          sort: sort++,
        ),
      );
    }
  }
}
