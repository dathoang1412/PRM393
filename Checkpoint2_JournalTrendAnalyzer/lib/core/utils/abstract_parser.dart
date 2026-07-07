String? parseAbstractInvertedIndex(Object? value) {
  if (value is! Map) return null;

  final positionedWords = <int, String>{};
  for (final entry in value.entries) {
    final word = entry.key;
    final positions = entry.value;
    if (word is! String || positions is! List) continue;

    for (final position in positions) {
      if (position is int) {
        positionedWords[position] = word;
      }
    }
  }

  if (positionedWords.isEmpty) return null;

  final sorted = positionedWords.keys.toList()..sort();
  return sorted.map((position) => positionedWords[position]).join(' ');
}
