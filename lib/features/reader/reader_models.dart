enum ReaderView { today, unread, favorites, archives }

enum ArticleFilter { all, unread, favorites }

enum BodyKind { rss, full }

enum GenerationTask { summary, translation, question }

class FeedSource {
  const FeedSource({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.color,
    required this.background,
    this.url,
  });

  factory FeedSource.fromJson(Map<String, dynamic> json) => FeedSource(
    id: json['id'] as String,
    name: json['name'] as String,
    shortName: json['short'] as String,
    category: json['category'] as String,
    color: json['color'] as String,
    background: json['bg'] as String,
    url: json['url'] as String?,
  );

  final String id;
  final String name;
  final String shortName;
  final String category;
  final String color;
  final String background;
  final String? url;
}

class ArchiveSnapshot {
  ArchiveSnapshot({
    required this.id,
    required this.kind,
    required this.savedLabel,
    required List<String> paragraphs,
    required List<String> translations,
    List<String> resultLabels = const [],
  }) : paragraphs = List.unmodifiable(paragraphs),
       translations = List.unmodifiable(translations),
       resultLabels = List.unmodifiable(resultLabels);

  final String id;
  final BodyKind kind;
  final String savedLabel;
  final List<String> paragraphs;
  final List<String> translations;
  final List<String> resultLabels;
}

class GeneratedResult {
  GeneratedResult({
    required this.task,
    required this.articleId,
    required this.bodyKey,
    required this.kind,
    required this.language,
    required this.service,
    required this.model,
    required List<String> original,
    required List<String> content,
    this.archiveId,
    this.question = '',
  }) : original = List.unmodifiable(original),
       content = List.unmodifiable(content);

  final GenerationTask task;
  final String articleId;
  final String bodyKey;
  final BodyKind kind;
  final String language;
  final String service;
  final String model;
  final List<String> original;
  final List<String> content;
  final String? archiveId;
  final String question;

  String get label => switch (task) {
    GenerationTask.summary => '文章摘要',
    GenerationTask.translation => '译文',
    GenerationTask.question => '文章问答',
  };
}

class ReaderArticle {
  ReaderArticle({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.deck,
    required this.image,
    required this.minutes,
    required this.timeLabel,
    required this.order,
    required this.paragraphs,
    required this.rss,
    required this.english,
    required this.summary,
    required this.isRead,
    required this.isFavorite,
    required this.fullAvailable,
    required this.progress,
    required this.archives,
  }) : positions = {'rss': 0, 'full': progress};

  factory ReaderArticle.fromJson(Map<String, dynamic> json, int order) {
    List<String> strings(Object? value) =>
        (value as List? ?? []).map((value) => value as String).toList();
    final paragraphs = strings(json['paragraphs']);
    final rss = strings(json['rss']);
    final english = strings(json['english']);
    return ReaderArticle(
      id: json['id'] as String,
      sourceId: json['source'] as String,
      title: json['title'] as String,
      deck: json['deck'] as String,
      image: json['image'] as String,
      minutes: json['minutes'] as int,
      timeLabel: json['time'] as String,
      order: order,
      paragraphs: List.unmodifiable(paragraphs),
      rss: List.unmodifiable(rss.isEmpty ? paragraphs.take(1) : rss),
      english: List.unmodifiable(english),
      summary: List.unmodifiable(strings(json['summary'])),
      isRead: json['read'] as bool,
      isFavorite: json['favorite'] as bool,
      fullAvailable: json['extracted'] as bool,
      progress: (json['progress'] as num).toDouble(),
      archives: (json['archives'] as List).map((value) {
        final map = value as Map<String, dynamic>;
        final kind = map['kind'] == 'rss' ? BodyKind.rss : BodyKind.full;
        return ArchiveSnapshot(
          id: map['id'] as String,
          kind: kind,
          savedLabel: map['date'] as String,
          paragraphs: kind == BodyKind.rss
              ? (rss.isEmpty ? paragraphs.take(1).toList() : rss)
              : paragraphs,
          translations: kind == BodyKind.rss
              ? english.take(1).toList()
              : english,
          resultLabels: strings(map['results']),
        );
      }).toList(),
    );
  }

  final String id;
  final String sourceId;
  final String title;
  final String deck;
  final String image;
  final int minutes;
  final String timeLabel;
  final int order;
  final List<String> paragraphs;
  final List<String> rss;
  final List<String> english;
  final List<String> summary;
  final List<ArchiveSnapshot> archives;
  final Map<String, GeneratedResult> results = {};
  final Map<String, double> positions;
  bool isRead;
  bool isFavorite;
  bool fullAvailable;
  bool cacheAvailable = true;
  bool? manualFavorite;
  double progress;
  BodyKind lastReadKind = BodyKind.full;
  String? lastReadArchive;

  ArchiveSnapshot? archive(String? id) {
    for (final snapshot in archives) {
      if (snapshot.id == id) return snapshot;
    }
    return null;
  }
}

class ArticleHit {
  const ArticleHit({
    required this.article,
    required this.snippet,
    required this.kind,
    this.archiveId,
    this.translation = false,
    this.paragraph,
    this.titleMatch = false,
  });

  final ReaderArticle article;
  final String snippet;
  final BodyKind kind;
  final String? archiveId;
  final bool translation;
  final int? paragraph;
  final bool titleMatch;
}

class PairedDevice {
  PairedDevice({
    required this.id,
    required this.name,
    required this.isOnline,
    this.trusted = true,
  });

  final String id;
  final String name;
  bool isOnline;
  bool trusted;
  bool pendingRevocation = false;
}

class ReadingRule {
  ReadingRule({
    required this.id,
    required this.name,
    required this.keyword,
    required this.actions,
    required this.enabled,
  });

  final String id;
  final String name;
  final String keyword;
  final String actions;
  bool enabled;

  ReadingRule copy() => ReadingRule(
    id: id,
    name: name,
    keyword: keyword,
    actions: actions,
    enabled: enabled,
  );
}

class DemoService {
  String url = 'https://api.example.com/v1';
  String model = 'demo-reader';
  List<String> models = ['demo-reader', 'demo-compact'];
  int calls = 3;
  int limit = 50;
  String directoryLabel = '示例目录 · 已保存';
  String testLabel = '尚未测试';
}

class RestoreSelection {
  bool archives = true;
  bool favorites = false;
  bool subscriptions = false;
  bool rules = false;
}

class GenerationOutcome {
  const GenerationOutcome.success(this.result) : message = null;
  const GenerationOutcome.failure(this.message) : result = null;

  final GeneratedResult? result;
  final String? message;
}
