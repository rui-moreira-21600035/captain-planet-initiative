class LetterNormalizer {
  static const Map<String, String> _map = {
    'Á':'A','À':'A','Â':'A','Ã':'A',
    'É':'E','Ê':'E',
    'Í':'I',
    'Ó':'O','Ô':'O','Õ':'O',
    'Ú':'U',
    'Ç':'C',
  };

  static String normalizeChar(String ch) => _map[ch] ?? ch;

  static String normalizeWord(String word) {
    final upper = word.toUpperCase();
    final b = StringBuffer();
    for (final rune in upper.runes) {
      final ch = String.fromCharCode(rune);
      b.write(normalizeChar(ch));
    }
    return b.toString();
  }
}