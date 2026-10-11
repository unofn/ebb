import 'dart:convert';

import 'package:ebb/features/import/decode/base64_payload.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/export_files.dart';

void main() {
  // 足够长，保证 base64 换成多行；含中文以验证 UTF-8。
  final json = {
    'version': 4,
    'subscriptions': [
      for (var i = 0; i < 5; i++) {'uuid': 'fake-$i', 'title': '视频会员 $i'},
    ],
    'paymentMethods': [],
  };

  test('decodes a whole-file payload wrapped at 76 columns', () {
    final file = tillaFile(json);
    expect(file.split('\n').first, hasLength(76));
    expect(decodePayload(file), json);
  });

  test('tolerates CRLF, trailing newline and missing padding', () {
    final unpadded = base64Export(json).replaceAll('=', '');
    expect(decodePayload('${unpadded.replaceAll('\n', '\r\n')}\r\n'), json);
  });

  test('decodes only what follows the all-dashes line', () {
    final file = subscriptionManagerFile({
      'appVersion': 79,
      'subscriptions': [],
    });
    expect(file, startsWith('Subscription Manager backup\n'));
    expect(decodePayload(file), {'appVersion': 79, 'subscriptions': []});
  });

  test('the header may have any number of lines', () {
    final body = base64Export({'appVersion': 79, 'subscriptions': []});
    final file = '-----\r\none line only\r\n------\r\n$body';
    expect(decodePayload(file)['appVersion'], 79);
  });

  test('rejects bad base64, bad JSON and non-object roots', () {
    expect(() => decodePayload('not base64!'), throwsFormatException);
    final notJson = base64.encode(utf8.encode('{oops'));
    expect(() => decodePayload(notJson), throwsFormatException);
    expect(() => decodePayload(base64Export([1, 2])), throwsFormatException);
  });
}
