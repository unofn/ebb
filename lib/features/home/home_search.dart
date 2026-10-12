import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_search.g.dart';

/// The home list's search text: null while the phone's search field is
/// closed (the wide layout always shows it).
@Riverpod(keepAlive: true)
class HomeSearch extends _$HomeSearch {
  @override
  String? build() => null;

  void open() => state = state ?? '';

  void set(String query) => state = query;

  void close() => state = null;
}
