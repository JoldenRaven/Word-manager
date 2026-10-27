/// Flatten sorted records into lazy-list headers and rows with exact jump indices.
({List<Object> items, Map<String, int> positions}) groupWords(
    List<Map<String, Object?>> words) {
  final items = <Object>[];
  final positions = <String, int>{};
  for (final row in words) {
    final letter = (row['word'] as String)[0].toUpperCase();
    if (!positions.containsKey(letter)) {
      positions[letter] = items.length;
      items.add(letter);
    }
    items.add(row);
  }
  return (items: items, positions: positions);
}
