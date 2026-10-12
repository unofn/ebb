import 'package:ebb/features/subscriptions/domain/search_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool finds(String query) => matchesSearch(
    query,
    name: 'Netflix 标准',
    category: '视频',
    tags: ['家庭共享', 'Shared'],
  );

  test('finds by name, category or tag', () {
    expect(finds('flix'), isTrue);
    expect(finds('视频'), isTrue);
    expect(finds('家庭'), isTrue);
    expect(finds('shared'), isTrue);
    expect(finds('音乐'), isFalse);
  });

  test('ignores case, full-width forms and extra spacing', () {
    expect(finds('ＮＥＴＦＬＩＸ'), isTrue);
    expect(finds('  netflix   标准 '), isTrue);
  });

  test('a blank query finds everything', () {
    expect(finds(''), isTrue);
    expect(finds('   '), isTrue);
  });

  test('without category or tags only the name counts', () {
    expect(matchesSearch('视频', name: 'Netflix'), isFalse);
  });
}
