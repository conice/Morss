import '../features/reader/reader_models.dart';

Uri normalizeFeedUrl(String value) {
  final uri = Uri.parse(value.trim()).removeFragment();
  if (!['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) {
    throw const FormatException('请填写完整的 HTTP / HTTPS RSS 或 Atom 地址。');
  }
  return uri;
}

class OpmlImportResult {
  const OpmlImportResult(this.added, this.merged, this.skipped);
  final int added;
  final int merged;
  final int skipped;
}

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
  OpmlImportResult importOpml(String text);
  String exportOpml();
  void updateSubscription(String id, String name, String category);
  void unsubscribe(String id);
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
