String? validWord(String? input) {
  final word = (input ?? '').trim();
  if (!RegExp(r"^[A-Za-z]+(?:[-'][A-Za-z]+)*$").hasMatch(word)) {
    return '请输入英文单词，连字符或撇号只能出现在单词内部';
  }
  return null;
}

String? validPage(String? input) {
  final value = input ?? '';
  final page = int.tryParse(value);
  if (!RegExp(r'^[0-9]+$').hasMatch(value) ||
      page == null ||
      page <= 0 ||
      page > 2147483647) {
    return '请输入大于零的整数页数';
  }
  return null;
}
