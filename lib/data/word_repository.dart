import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../utils/validation.dart';

class WordRepository {
  final Database db;
  final String path;
  WordRepository(this.db, this.path);

  static Future<WordRepository> open({String? overridePath}) async {
    DatabaseFactory factory;
    String target;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }
    if (overridePath != null) {
      target = overridePath;
    } else if (Platform.isWindows &&
        !p
            .split(Platform.resolvedExecutable)
            .any((part) => part.toLowerCase() == 'build')) {
      final base = p.dirname(Platform.resolvedExecutable);
      try {
        final dir = Directory(p.join(base, 'data'));
        await dir.create(recursive: true);
        final probe = File(p.join(
            dir.path, '.write-test-${DateTime.now().microsecondsSinceEpoch}'));
        await probe.writeAsString('test', flush: true);
        await probe.delete();
        await Directory(p.join(base, 'backups')).create(recursive: true);
        target = p.join(dir.path, 'words.db');
      } catch (_) {
        final dir = await getApplicationSupportDirectory();
        await dir.create(recursive: true);
        target = p.join(dir.path, 'words.db');
      }
    } else {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      target = p.join(dir.path, 'words.db');
    }
    final db = await factory.openDatabase(target,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                  'CREATE TABLE words (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL COLLATE NOCASE UNIQUE, page INTEGER NOT NULL CHECK(page > 0), created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
            }));
    return WordRepository(db, target);
  }

  Future<List<Map<String, Object?>>> list([String query = '']) =>
      db.query('words',
          where: query.isEmpty ? null : 'word LIKE ? ESCAPE ?',
          whereArgs: query.isEmpty
              ? null
              : [
                  '%${query.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%',
                  '\\'
                ],
          orderBy: 'word COLLATE NOCASE ASC');
  Future<Map<String, Object?>?> find(String word) async {
    final rows = await db
        .query('words', where: 'word = ? COLLATE NOCASE', whereArgs: [word]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> save(String word, int page, {int? id}) async {
    word = word.trim();
    if (validWord(word) != null || validPage('$page') != null) {
      throw const FormatException('单词或页数无效');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      if (id == null) {
        await txn.insert('words',
            {'word': word, 'page': page, 'created_at': now, 'updated_at': now});
      } else {
        await txn.update(
            'words', {'word': word, 'page': page, 'updated_at': now},
            where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  Future<void> delete(int id) async {
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  Future<({int added, int skipped, int updated})> importWords(
      List<({String word, int page})> words,
      {required bool update}) async {
    var added = 0, skipped = 0, updated = 0;
    await db.transaction((txn) async {
      for (final item in words) {
        if (validWord(item.word) != null || validPage('${item.page}') != null) {
          throw const FormatException('导入数据无效');
        }
        final existing = await txn.query('words',
            columns: ['id'],
            where: 'word = ? COLLATE NOCASE',
            whereArgs: [item.word]);
        final now = DateTime.now().toUtc().toIso8601String();
        if (existing.isEmpty) {
          await txn.insert('words', {
            'word': item.word,
            'page': item.page,
            'created_at': now,
            'updated_at': now
          });
          added++;
        } else if (update) {
          await txn.update('words', {'page': item.page, 'updated_at': now},
              where: 'id = ?', whereArgs: [existing.first['id']]);
          updated++;
        } else {
          skipped++;
        }
      }
    });
    return (added: added, skipped: skipped, updated: updated);
  }
}
