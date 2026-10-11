import 'package:ebb/features/import/decode/detect_format.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tilla: numeric version, subscriptions array, paymentMethods key', () {
    expect(
      detectFormat({'version': 4, 'subscriptions': [], 'paymentMethods': []}),
      SourceApp.tilla,
    );
    // 未验证过的版本也识别，由导入器给警告。
    expect(
      detectFormat({'version': 5, 'subscriptions': [], 'paymentMethods': null}),
      SourceApp.tilla,
    );
  });

  test('SubscriptionManager: numeric appVersion and subscriptions array', () {
    expect(
      detectFormat({'appVersion': 79, 'subscriptions': []}),
      SourceApp.subscriptionManager,
    );
  });

  test('anything else is unknown', () {
    expect(detectFormat({}), isNull);
    expect(detectFormat({'version': 4, 'subscriptions': []}), isNull);
    expect(
      detectFormat({'version': '4', 'subscriptions': [], 'paymentMethods': []}),
      isNull,
    );
    expect(detectFormat({'appVersion': 79, 'subscriptions': {}}), isNull);
  });

  test('source app keys are the stable-ID prefixes', () {
    expect(SourceApp.tilla.key, 'tilla');
    expect(SourceApp.subscriptionManager.key, 'subscription_manager');
  });
}
