import 'package:eco_guess_game/src/domain/services/letter_normalizer.dart';

String buildMaskedWord({
  required String originalWord,
  required Set<String> guessedBase,
}) {
  final normalized = LetterNormalizer.normalizeWord(originalWord);
  final out = StringBuffer();

  for (var i = 0; i < originalWord.length; i++) {
    final originalChar = originalWord[i];
    final base = normalized[i];

    if (base == ' ' || base == '-' ) {
      out.write(originalChar); // mantém separadores (se existirem)
    } else if (guessedBase.contains(base)) {
      out.write(originalChar); // revela com acento/ç
    } else {
      out.write('_');
    }
    if (i != originalWord.length - 1) out.write(' ');
  }
  return out.toString();
}