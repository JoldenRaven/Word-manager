import 'dart:convert';
import '../data/word_repository.dart';
import '../utils/validation.dart';

class Backup {
  static Future<String> export(WordRepository repo) async {
    final words = await repo.list();
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'word-contacts-backup',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'words': words.map((w) => {'word': w['word'], 'page': w['page']}).toList()
    });
  }

  static List<({String word, int page})> parse(String content) {
    final data = jsonDecode(content);
    if (data is! Map ||
        data['format'] != 'word-contacts-backup' ||
        data['schemaVersion'] != 1 ||
        data['words'] is! List ||
        data['exportedAt'] is! String ||
        DateTime.tryParse(data['exportedAt']) == null) {
      throw const FormatException('备份格式或版本无效');
    }
    final result = <({String word, int page})>[];
    for (final row in data['words']) {
      if (row is! Map ||
          row['word'] is! String ||
          row['page'] is! int ||
          validWord(row['word']) != null ||
          validPage('${row['page']}') != null) {
        throw const FormatException('备份包含无效单词或页数');
      }
      result.add(
          (word: (row['word'] as String).trim(), page: row['page'] as int));
    }
    return result;
  }
}
