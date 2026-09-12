import '../features/reader/reader_models.dart';

class ReadingLibraryException implements Exception {
  const ReadingLibraryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FeedRefreshResult {
  const FeedRefreshResult(this.succeeded, this.errors);
  final int succeeded;
  final List<String> errors;
}

class ReadingLibraryData {
  const ReadingLibraryData({
    required this.sources,
    required this.articles,
    this.preferences = const {},
  });

  final List<FeedSource> sources;
  final List<ReaderArticle> articles;
  final Map<String, dynamic> preferences;
}

/// The durable reading library. Its owner closes it when the reader is disposed.
abstract interface class ReadingLibrary {
  ReadingLibraryData load();
  Future<void> subscribe(String name, String url, String category);
  Future<FeedRefreshResult> refresh({
    void Function(int completed, int total)? onProgress,
  });
  void saveState({
    required Iterable<ReaderArticle> articles,
    required Map<String, dynamic> preferences,
  });
  void close();
}
