import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_contacts/data/word_repository.dart';
import 'package:word_contacts/screens/home.dart';

void main() {
  late Directory directory;
  late WordRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wc_widget_');
    repository =
        await WordRepository.open(overridePath: '${directory.path}/words.db');
  });
  tearDown(() async {
    await repository.db.close();
    await directory.delete(recursive: true);
  });
  testWidgets(
      'editor has only Word/Page, rejects negative pages and closes cleanly',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: Home(repository: repository)));
      for (var i = 0;
          i < 50 &&
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('没有找到单词'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).first, 'apple');
    await tester.enterText(find.byType(TextFormField).last, '-1');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入大于零的整数页数'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
