import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../data/word_repository.dart';
import '../services/backup.dart';
import '../utils/validation.dart';
import '../utils/grouping.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.repository});
  final WordRepository? repository;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  WordRepository? repo;
  String? error;
  String query = '';
  List<Map<String, Object?>> words = [];
  final scroll = ItemScrollController();
  int request = 0;
  Timer? debounce;
  @override
  void dispose() {
    debounce?.cancel();
    if (widget.repository == null) repo?.db.close();
    super.dispose();
  }

  static const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      repo = widget.repository ?? await WordRepository.open();
      await refresh();
    } catch (e) {
      if (mounted) setState(() => error = '无法打开数据库：$e');
    }
  }

  Future<void> refresh() async {
    final n = ++request;
    final items = await repo!.list(query);
    if (mounted && n == request) setState(() => words = items);
  }

  void message(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  }

  Future<void> edit([Map<String, Object?>? row]) async {
    final form = GlobalKey<FormState>();
    final word = TextEditingController(text: row?['word'] as String? ?? '');
    final page =
        TextEditingController(text: row == null ? '' : '${row['page']}');
    var saving = false;
    final route = DialogRoute<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                scrollable: true,
                title: Text(row == null ? '新增单词' : '编辑单词'),
                content: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextFormField(
                          controller: word,
                          decoration: const InputDecoration(labelText: 'Word'),
                          validator: validWord,
                          autofocus: true),
                      TextFormField(
                          controller: page,
                          decoration: const InputDecoration(labelText: 'Page'),
                          keyboardType: TextInputType.number,
                          validator: validPage)
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () async {
                        if (saving || !form.currentState!.validate()) return;
                        saving = true;
                        try {
                          final value = word.text.trim();
                          final number = int.parse(page.text);
                          final duplicate = await repo!.find(value);
                          if (duplicate != null &&
                              duplicate['id'] != row?['id']) {
                            if (!dialogContext.mounted) return;
                            final update = await showDialog<bool>(
                                context: dialogContext,
                                builder: (c) => AlertDialog(
                                        title: const Text('单词已存在'),
                                        content: Text(
                                            '是否更新已有单词 ${duplicate['word']} 的页数？当前编辑记录将保留。'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: const Text('取消')),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: const Text('更新页数'))
                                        ]));
                            if (update != true) return;
                            await repo!.save(
                                duplicate['word'] as String, number,
                                id: duplicate['id'] as int);
                          } else {
                            await repo!
                                .save(value, number, id: row?['id'] as int?);
                          }
                          await refresh();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          message('保存失败：$e');
                        } finally {
                          saving = false;
                        }
                      },
                      child: const Text('保存'))
                ]));
    await Navigator.of(context).push(route);
    await route.completed;
    word.dispose();
    page.dispose();
  }

  Future<void> remove(Map<String, Object?> row) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('删除单词？'),
                content: Text('${row['word']}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('删除'))
                ]));
    if (yes == true) {
      try {
        await repo!.delete(row['id'] as int);
        await refresh();
      } catch (e) {
        message('删除失败：$e');
      }
    }
  }

  Future<void> menu(String action) async {
    try {
      if (action == 'path') {
        await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('数据库位置'),
                    content: SelectableText(repo!.path),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('关闭'))
                    ]));
      }
      if (action == 'export') {
        final content = await Backup.export(repo!);
        final path = await FilePicker.platform.saveFile(
            dialogTitle: '导出备份',
            fileName: 'word_contacts_backup.json',
            type: FileType.custom,
            allowedExtensions: ['json'],
            bytes: Uint8List.fromList(utf8.encode(content)));
        if (path != null) message('备份已导出');
      }
      if (action == 'import') {
        final file = await FilePicker.platform.pickFiles(
            type: FileType.custom, allowedExtensions: ['json'], withData: true);
        if (file == null) return;
        final bytes = file.files.single.bytes;
        if (bytes == null) throw const FormatException('无法读取文件');
        final items = Backup.parse(utf8.decode(bytes));
        if (!mounted) return;
        final choice = await showDialog<String>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('导入备份'),
                    content: Text('已验证 ${items.length} 条记录。请选择重复单词的处理方式。'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('取消')),
                      TextButton(
                          onPressed: () => Navigator.pop(c, 'skip'),
                          child: const Text('跳过重复')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, 'update'),
                          child: const Text('更新已有页数'))
                    ]));
        if (choice == null) return;
        final result =
            await repo!.importWords(items, update: choice == 'update');
        await refresh();
        message(
            '导入完成：新增 ${result.added}，跳过 ${result.skipped}，更新 ${result.updated}');
      }
    } catch (e) {
      message('操作失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupWords(words);
    final items = grouped.items;
    final positions = grouped.positions;
    return Scaffold(
      appBar: AppBar(title: const Text('Word Contacts'), actions: [
        PopupMenuButton<String>(
            onSelected: repo == null ? null : menu,
            itemBuilder: (_) => const [
                  PopupMenuItem(value: 'import', child: Text('导入备份')),
                  PopupMenuItem(value: 'export', child: Text('导出备份')),
                  PopupMenuItem(value: 'path', child: Text('数据存储位置')),
                ]),
      ]),
      body: error != null
          ? Center(child: Text(error!))
          : repo == null
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: '搜索单词',
                            border: OutlineInputBorder()),
                        onChanged: (s) {
                          query = s.trim();
                          request++;
                          debounce?.cancel();
                          debounce = Timer(const Duration(milliseconds: 180),
                              () async {
                            try {
                              await refresh();
                            } catch (e) {
                              message('搜索失败：$e');
                            }
                          });
                        },
                      )),
                  Expanded(
                      child: Row(children: [
                    Expanded(
                        child: items.isEmpty
                            ? const Center(child: Text('没有找到单词'))
                            : ScrollablePositionedList.builder(
                                itemScrollController: scroll,
                                itemCount: items.length,
                                itemBuilder: (c, i) {
                                  final item = items[i];
                                  if (item is String) {
                                    return Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                        child: Text(item));
                                  }
                                  final row = item as Map<String, Object?>;
                                  return ListTile(
                                      title: Text(row['word'] as String),
                                      trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('P.${row['page']}'),
                                            IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline),
                                                tooltip: '删除',
                                                onPressed: () => remove(row)),
                                          ]),
                                      onTap: () => edit(row));
                                },
                              )),
                    SizedBox(
                        width: 35,
                        child: Column(children: [
                          for (final letter in alphabet.split(''))
                            Expanded(
                                child: InkWell(
                              onTap: positions[letter] == null
                                  ? null
                                  : () => scroll.scrollTo(
                                      index: positions[letter]!,
                                      duration:
                                          const Duration(milliseconds: 250)),
                              child: Center(
                                  child: FittedBox(
                                      child: Text(letter,
                                          style: TextStyle(
                                              color: positions[letter] == null
                                                  ? Colors.grey.shade400
                                                  : Colors.green.shade800)))),
                            )),
                        ])),
                  ])),
                  const SafeArea(
                      top: false,
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.contacts),
                                SizedBox(width: 8),
                                Text('通讯录')
                              ]))),
                ]),
      floatingActionButton: repo == null
          ? null
          : FloatingActionButton(
              onPressed: () => edit(), child: const Icon(Icons.add)),
    );
  }
}
