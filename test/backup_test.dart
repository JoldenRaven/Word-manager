import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_contacts/services/backup.dart';

void main() {
  Map<String, Object> backup(Object words) => {
        'format': 'word-contacts-backup',
        'schemaVersion': 1,
        'exportedAt': '2026-01-01T00:00:00Z',
        'words': words
      };
  test('rejects unsupported versions and malformed records before import', () {
    final badVersion = backup([])..['schemaVersion'] = 99;
    expect(() => Backup.parse(jsonEncode(badVersion)), throwsFormatException);
    for (final row in [
      {'word': 'a', 'page': 1.5},
      {'word': 'a', 'page': '1'},
      {'word': '-a', 'page': 1},
      {'word': 'a', 'page': -1},
      {'word': 'a'}
    ]) {
      expect(
          () => Backup.parse(jsonEncode(backup([row]))), throwsFormatException);
    }
    expect(
        Backup.parse(jsonEncode(backup([
          {'word': " don't ", 'page': 5}
        ]))).single.word,
        "don't");
  });
}
