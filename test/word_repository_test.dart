import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_contacts/data/word_repository.dart';
import 'package:word_contacts/services/backup.dart';
import 'package:word_contacts/utils/validation.dart';

void main() {
  test('validates word and page', () {
    expect(validWord(" mother-in-law "), isNull);
    expect(validWord("don't"), isNull);
    for (final word in ['', '1word', '-word', 'two words', 'word-']) {
      expect(validWord(word), isNotNull);
    }
    for (final page in ['', '0', '-1', '1.2', 'x']) {
      expect(validPage(page), isNotNull);
    }
    expect(validPage('12'), isNull);
  });
  late Directory dir;
  late WordRepository repo;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('word_contacts_test');
    repo = await WordRepository.open(overridePath: '${dir.path}/words.db');
  });
  tearDown(() async {
    await repo.db.close();
    await dir.delete(recursive: true);
  });
  test('CRUD, sorting, searching, duplicates and persistence', () async {
    await repo.save('Banana', 2);
    await repo.save('apple', 1);
    expect((await repo.list()).map((w) => w['word']), ['apple', 'Banana']);
    expect((await repo.list('ANA')).single['word'], 'Banana');
    expect((await repo.list('app')).single['word'], 'apple');
    await expectLater(repo.save('APPLE', 5), throwsA(anything));
    final apple = (await repo.find('APPLE'))!;
    await repo.save('Apricot', 4, id: apple['id'] as int);
    await repo.db.close();
    repo = await WordRepository.open(overridePath: '${dir.path}/words.db');
    expect((await repo.list()).map((w) => w['word']), ['Apricot', 'Banana']);
    await repo.delete((await repo.find('banana'))!['id'] as int);
    expect((await repo.list()).length, 1);
  });
  test('backup validation, duplicates, and rollback', () async {
    await repo.save('apple', 1);
    final decoded = Backup.parse(await Backup.export(repo));
    expect(decoded.single.word, 'apple');
    expect(() => Backup.parse('{bad'), throwsFormatException);
    expect(
        () => Backup.parse(
            '{"format":"word-contacts-backup","schemaVersion":1,"exportedAt":"2025-01-01T00:00:00Z","words":[{"word":"x","page":0}]}'),
        throwsFormatException);
    var result = await repo.importWords(
        [(word: 'APPLE', page: 9), (word: 'banana', page: 2)],
        update: false);
    expect((result.added, result.skipped), (1, 1));
    result = await repo.importWords([(word: 'apple', page: 3)], update: true);
    expect(result.updated, 1);
    expect((await repo.find('APPLE'))!['page'], 3);
    await expectLater(
        repo.importWords([(word: 'cherry', page: 1), (word: 'bad', page: 0)],
            update: false),
        throwsA(anything));
    expect(await repo.find('cherry'), isNull);
    expect((await repo.find('apple'))!['page'], 3);
  });
  test('backup restores into empty database and includes every record',
      () async {
    await repo.save("mother-in-law", 12);
    await repo.save("don't", 7);
    final content = await Backup.export(repo);
    for (final row in await repo.list()) {
      await repo.delete(row['id'] as int);
    }
    final report = await repo.importWords(Backup.parse(content), update: false);
    expect(report.added, 2);
    expect((await repo.list()).map((row) => row['word']),
        ["don't", "mother-in-law"]);
  });
  test('failed import rolls back an earlier update as well as insertion',
      () async {
    await repo.save('apple', 1);
    await expectLater(
        repo.importWords([
          (word: 'apple', page: 99),
          (word: 'banana', page: 2),
          (word: 'invalid', page: 0)
        ], update: true),
        throwsA(anything));
    expect((await repo.find('apple'))!['page'], 1);
    expect(await repo.find('banana'), isNull);
  });
}
