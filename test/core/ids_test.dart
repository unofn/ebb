import 'package:ebb/core/ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final uuidV = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-([45])[0-9a-f]{3}-');

  test('stableId is a deterministic v5 UUID', () {
    final id = stableId('category:video');
    expect(id, stableId('category:video'));
    expect(uuidV.firstMatch(id)![1], '5');
    expect(id, isNot(stableId('category:audio')));
  });

  test('stableId is pinned to the Ebb namespace', () {
    // Reference value from Python's uuid.uuid5; a change orphans imports.
    expect(stableId('tilla:abc'), '90630090-fdb1-5755-b983-a4a8d8710771');
  });

  test('newId is a random v4 UUID', () {
    expect(uuidV.firstMatch(newId())![1], '4');
    expect(newId(), isNot(newId()));
  });
}
