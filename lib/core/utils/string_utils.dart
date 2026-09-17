/// Converts a string to Title Case (e.g. "DAVID BARAHONA" -> "David Barahona",
/// "the Amritdev" -> "The Amritdev", "rubn nava" -> "Rubn Nava").
String toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    if (word.length == 1) return word.toUpperCase();
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
