enum SearchMode {
  youtube._('YouTube'),
  youtubeMusic._('YouTube Music');

  final String label;

  const SearchMode._(this.label);

  factory SearchMode.fromString(String key) {
    return SearchMode.values.firstWhere((e) => e.name == key);
  }
}
