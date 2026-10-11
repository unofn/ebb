import 'package:ebb/features/import/plan/normalize_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trims, collapses whitespace and lowercases', () {
    expect(normalizeName('  Fake   Stream\tPlus '), 'fake stream plus');
  });

  test('folds full-width ASCII and the ideographic space', () {
    expect(normalizeName('ＦＡＫＥ　Ｓｔｒｅａｍ１２３！'), 'fake stream123!');
  });

  test('keeps CJK text as is', () {
    expect(normalizeName(' 假视频 会员 '), '假视频 会员');
  });

  test('names that differ only in width or case match', () {
    expect(normalizeName('Ｆａｋｅ ＡＩ'), normalizeName('fake  ai'));
  });

  test('applies NFKC beyond full-width ASCII', () {
    expect(normalizeName('Ｆｉｌｅ ﬁx ①'), 'file fix 1');
  });
}
