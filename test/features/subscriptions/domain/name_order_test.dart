import 'package:ebb/features/subscriptions/domain/name_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('case, full-width forms and spacing do not matter', () {
    final names = ['Netflix', 'iCloud+', 'ChatGPT', 'ｂilibili', '中国移动'];
    expect(names..sort(compareNames), [
      'ｂilibili',
      'ChatGPT',
      'iCloud+',
      'Netflix',
      '中国移动',
    ]);
  });

  test('the raw name breaks ties between equal normalized names', () {
    expect(compareNames('Apple', 'apple'), lessThan(0));
    expect(compareNames('apple', 'apple'), 0);
  });
}
