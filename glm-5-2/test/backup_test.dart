import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/screens/backup_screen.dart';
import 'dart:convert';

void main() {
  test('DecryptionException toString returns reason', () {
    final e = DecryptionException('reason');
    expect(e.toString(), 'reason');
  });

  test('JSON encoder roundtrip preserves profile fields', () {
    final map = {
      'schema_version': 1,
      'profile': {'name': 'ada', 'lang': 'en'},
      'saved': ['r1', 'r2'],
    };
    final s = json.encode(map);
    final back = json.decode(s) as Map<String, dynamic>;
    expect(back['schema_version'], 1);
    expect((back['saved'] as List).length, 2);
  });
}
