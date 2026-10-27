import 'package:flutter_test/flutter_test.dart';
import 'package:word_contacts/utils/grouping.dart';

void main() {
  test('letter jump indices point to headers including offscreen groups', () {
    final rows = [
      for (var i = 0; i < 1000; i++)
        <String, Object?>{'word': 'apple', 'page': i + 1},
      <String, Object?>{'word': 'Zoo', 'page': 2}
    ];
    final groups = groupWords(rows);
    expect(groups.positions, {'A': 0, 'Z': 1001});
    expect(groups.items[groups.positions['Z']!], 'Z');
    expect(groupWords([]).positions, isEmpty);
  });
}
