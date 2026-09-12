import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reader_models.dart';

/// Presentation state for the selected A interface.
/// Demo content is injected here; no networking or persistence is implied.
class ReaderController extends ChangeNotifier {
  ReaderController.fromJson(Map<String, dynamic> json)
    : sources = (json['sources'] as List)
          .map((value) => FeedSource.fromJson(value as Map<String, dynamic>))
          .toList(),
      articles = [
        for (final (index, value) in (json['articles'] as List).indexed)
          ReaderArticle.fromJson(value as Map<String, dynamic>, index),
      ] {
    _originalSources = List.of(sources);
    _originalArchives = {
      for (final article in articles) article.id: List.of(article.archives),
    };
    _originalFavorites = {
      for (final article in articles) article.id: article.isFavorite,
    };
    _originalRules = rules.map((rule) => rule.copy()).toList();
    selectedId = articles.first.id;
  }

  static Future<ReaderController> loadDemo() async {
    final source = await rootBundle.loadString('assets/data/reader_demo.json');
    return ReaderController.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  final List<FeedSource> sources;
  final List<ReaderArticle> articles;
  late final List<FeedSource> _originalSources;
  late final Map<String, List<ArchiveSnapshot>> _originalArchives;
  late final Map<String, bool> _originalFavorites;
  late final List<ReadingRule> _originalRules;
  late String selectedId;
  ReaderView view = ReaderView.today;
  ArticleFilter filter = ArticleFilter.all;
  String? category;
  String? sourceId;
  String query = '';
  bool readerOpen = false;
  BodyKind body = BodyKind.full;
  String? archiveId;
  bool bilingual = false;
  ThemeMode themeMode = ThemeMode.system;
  double fontSize = 15;
  String targetLanguage = 'zh';
  bool networkAvailable = true;
  String syncLabel = '已同步';
  String lastSync = '刚刚';
  int pendingChanges = 0;
  int readingRequest = 0;
  int? requestedParagraph;
  double? requestedProgress;
  bool automationPaused = false;
  bool previewedRules = false;
  bool cacheCleared = false;
  int _archiveSequence = 0;
  bool _disposed = false;
  final service = DemoService();
  final restoreSelection = RestoreSelection();
  final Set<String> completedRuleArticles = {};
  final List<PairedDevice> devices = [
    PairedDevice(id: 'windows', name: '书房的 Windows', isOnline: true),
    PairedDevice(id: 'android', name: '随身 Android', isOnline: false),
  ];
  final List<ReadingRule> rules = [
    ReadingRule(
      id: 'flutter',
      name: '把技术好文留下',
      keyword: 'Flutter',
      actions: '提取全文 → 收藏',
      enabled: true,
    ),
    ReadingRule(
      id: 'design',
      name: '留一点设计灵感',
      keyword: '界面',
      actions: '收藏',
      enabled: false,
    ),
  ];

  ReaderArticle get selected =>
      articles.firstWhere((article) => article.id == selectedId);
  FeedSource sourceOf(ReaderArticle article) =>
      sources.firstWhere((source) => source.id == article.sourceId);
  ArchiveSnapshot? get currentArchive => selected.archive(archiveId);
  BodyKind get currentKind => currentArchive?.kind ?? body;
  String get bodyKey => archiveId ?? body.name;
  List<String> get currentParagraphs =>
      currentArchive?.paragraphs ??
      (body == BodyKind.rss ? selected.rss : selected.paragraphs);
  List<String> get currentEnglish =>
      currentArchive?.translations ??
      selected.english.take(currentParagraphs.length).toList();
  bool get bodyAvailable => currentArchive != null || selected.cacheAvailable;
  double get progress => selected.positions[bodyKey] ?? 0;
  bool get canSync =>
      networkAvailable &&
      devices.any((device) => device.trusted && device.isOnline);

  String get title {
    if (sourceId != null) {
      return sources.firstWhere((source) => source.id == sourceId).name;
    }
    if (category != null) return category!;
    return switch (view) {
      ReaderView.today => '今日阅读',
      ReaderView.unread => '未读文章',
      ReaderView.favorites => '我的收藏',
      ReaderView.archives => '保留归档',
    };
  }

  int count(ReaderView view) => switch (view) {
    ReaderView.today => articles.length,
    ReaderView.unread => articles.where((article) => !article.isRead).length,
    ReaderView.favorites =>
      articles.where((article) => article.isFavorite).length,
    ReaderView.archives =>
      articles.where((article) => article.archives.isNotEmpty).length,
  };

  ReaderArticle get resumeArticle {
    for (final article in articles) {
      if (article.progress > 0 && article.progress < 100) return article;
    }
    return selected;
  }

  List<ArticleHit> get visibleArticles {
    final words = query.trim().toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    final hits = <ArticleHit>[];
    for (final article in articles) {
      if ((view == ReaderView.unread || filter == ArticleFilter.unread) &&
          article.isRead) {
        continue;
      }
      if ((view == ReaderView.favorites || filter == ArticleFilter.favorites) &&
          !article.isFavorite) {
        continue;
      }
      if (view == ReaderView.archives && article.archives.isEmpty) continue;
      if (category != null && sourceOf(article).category != category) continue;
      if (sourceId != null && article.sourceId != sourceId) continue;
      if (words.isEmpty) {
        final archive = view == ReaderView.archives
            ? article.archives.first
            : null;
        hits.add(
          ArticleHit(
            article: article,
            snippet: article.deck,
            kind:
                archive?.kind ??
                (article.fullAvailable ? BodyKind.full : BodyKind.rss),
            archiveId: archive?.id,
          ),
        );
        continue;
      }
      final titleMatch = words.every(article.title.toLowerCase().contains);
      final versions =
          <
            ({
              List<String> text,
              BodyKind kind,
              String? archive,
              bool translation,
            })
          >[
            (
              text: article.cacheAvailable
                  ? (article.fullAvailable ? article.paragraphs : article.rss)
                  : const [],
              kind: article.fullAvailable ? BodyKind.full : BodyKind.rss,
              archive: null,
              translation: false,
            ),
            for (final snapshot in article.archives)
              (
                text: snapshot.paragraphs,
                kind: snapshot.kind,
                archive: snapshot.id,
                translation: false,
              ),
            for (final result in article.results.values)
              if (result.task == GenerationTask.translation)
                (
                  text: result.content,
                  kind: result.kind,
                  archive: result.archiveId,
                  translation: true,
                ),
          ];
      for (final version in versions) {
        final text = version.text.join(' ');
        final searchable = '${article.title} $text'.toLowerCase();
        if (!words.every(searchable.contains)) continue;
        final start = text.toLowerCase().indexOf(words.first);
        final from = (start - 15).clamp(0, text.length);
        final to = (from + 68).clamp(from, text.length);
        final paragraph = version.text.indexWhere(
          (text) => words.any(text.toLowerCase().contains),
        );
        hits.add(
          ArticleHit(
            article: article,
            snippet: text.isEmpty
                ? '仅标题命中 · 普通正文已清理'
                : '${from > 0 ? '…' : ''}${text.substring(from, to)}'
                      '${to < text.length ? '…' : ''}',
            kind: version.kind,
            archiveId: version.archive,
            translation: version.translation,
            paragraph: paragraph < 0 ? null : paragraph,
            titleMatch: titleMatch,
          ),
        );
        break;
      }
    }
    hits.sort((a, b) {
      if (a.titleMatch != b.titleMatch) return a.titleMatch ? -1 : 1;
      return a.article.order.compareTo(b.article.order);
    });
    return hits;
  }

  void navigate(ReaderView next) {
    view = next;
    category = null;
    sourceId = null;
    filter = ArticleFilter.all;
    query = '';
    readerOpen = false;
    notifyListeners();
  }

  void selectCategory(String value) {
    navigate(ReaderView.today);
    category = value;
    notifyListeners();
  }

  void selectSource(String id) {
    navigate(ReaderView.today);
    sourceId = id;
    notifyListeners();
  }

  void setFilter(ArticleFilter value) {
    filter = value;
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  void openArticle(ArticleHit hit) {
    selectedId = hit.article.id;
    archiveId = hit.archiveId;
    body = hit.kind;
    bilingual = hit.translation;
    readerOpen = true;
    requestedParagraph = hit.paragraph;
    requestedProgress = hit.paragraph == null ? 0 : null;
    readingRequest++;
    notifyListeners();
  }

  void resume() {
    final article = resumeArticle;
    selectedId = article.id;
    archiveId = article.archive(article.lastReadArchive)?.id;
    body = article.lastReadKind;
    bilingual = false;
    readerOpen = true;
    requestedParagraph = null;
    requestedProgress = article.progress;
    readingRequest++;
    notifyListeners();
  }

  void backToList() {
    readerOpen = false;
    notifyListeners();
  }

  void switchBody(BodyKind kind) {
    body = kind;
    archiveId = null;
    bilingual = false;
    requestedParagraph = null;
    requestedProgress = selected.positions[kind.name] ?? 0;
    readingRequest++;
    notifyListeners();
  }

  void openArchive(String id) {
    final snapshot = selected.archive(id);
    if (snapshot == null) return;
    archiveId = id;
    body = snapshot.kind;
    readerOpen = true;
    bilingual = false;
    requestedParagraph = null;
    requestedProgress = selected.positions[id] ?? 0;
    readingRequest++;
    notifyListeners();
  }

  void goToParagraph(int paragraph) {
    readerOpen = true;
    requestedParagraph = paragraph;
    requestedProgress = null;
    readingRequest++;
    notifyListeners();
  }

  void updateProgress(double value, {required bool userScroll}) {
    if (!userScroll) return;
    value = value.clamp(0, 100);
    if ((progress - value).abs() < .5) return;
    selected.positions[bodyKey] = value;
    selected.progress = value;
    selected.lastReadKind = currentKind;
    selected.lastReadArchive = archiveId;
    if (value >= 99 && !selected.isRead && bodyAvailable) {
      selected.isRead = true;
      pendingChanges++;
    }
    notifyListeners();
  }

  String toggleRead() {
    selected.isRead = !selected.isRead;
    pendingChanges++;
    notifyListeners();
    return selected.isRead ? '已标为已读。' : '已标为未读，阅读位置保留。';
  }

  String markVisibleRead() {
    final matches = visibleArticles;
    for (final hit in matches) {
      if (!hit.article.isRead) pendingChanges++;
      hit.article.isRead = true;
    }
    notifyListeners();
    return '已将当前列表的 ${matches.length} 篇文章标为已读。';
  }

  String toggleFavorite() {
    final article = selected;
    article.isFavorite = !article.isFavorite;
    article.manualFavorite = article.isFavorite;
    if (article.isFavorite && article.archives.isEmpty && bodyAvailable) {
      _saveArchive(article);
    }
    pendingChanges++;
    notifyListeners();
    return article.isFavorite ? '已收藏，喜欢的内容留在这里。' : '已取消收藏，保存的归档仍在。';
  }

  void _saveArchive(ReaderArticle article, {bool automatic = false}) {
    final kind = automatic ? BodyKind.full : currentKind;
    final key = automatic ? BodyKind.full.name : bodyKey;
    article.archives.insert(
      0,
      ArchiveSnapshot(
        id: '${article.id}-saved-${++_archiveSequence}',
        kind: kind,
        savedLabel: '今天 · 刚刚',
        paragraphs: automatic ? article.paragraphs : List.of(currentParagraphs),
        translations: automatic ? article.english : List.of(currentEnglish),
        resultLabels: article.results.values
            .where((result) => result.bodyKey == key)
            .map((result) => result.label)
            .toSet()
            .toList(),
      ),
    );
    pendingChanges++;
  }

  String saveArchive() {
    if (!bodyAvailable) return '本机没有当前正文，请先补取。';
    _saveArchive(selected);
    notifyListeners();
    return '已保存新的归档版本，原有快照保留。';
  }

  String deleteArchive(String id) {
    selected.archives.removeWhere((snapshot) => snapshot.id == id);
    selected.results.removeWhere((_, result) => result.archiveId == id);
    if (archiveId == id) archiveId = null;
    pendingChanges++;
    notifyListeners();
    return '这份归档已删除，收藏和已读标记保持原样。';
  }

  String extractFullText() {
    selected.fullAvailable = true;
    selected.cacheAvailable = true;
    switchBody(BodyKind.full);
    return '示例全文已展开，已有归档不会被替换。';
  }

  void setFontSize(double value) {
    fontSize = value.clamp(13, 22);
    notifyListeners();
  }

  void setTheme(ThemeMode value) {
    themeMode = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    targetLanguage = value;
    notifyListeners();
  }

  void showOriginalOnly() {
    bilingual = false;
    notifyListeners();
  }

  GenerationOutcome generate(GenerationTask task, {String question = ''}) {
    if (!bodyAvailable) {
      return const GenerationOutcome.failure('先补取原文，或打开一份保留归档。');
    }
    if (task == GenerationTask.translation && targetLanguage == 'zh') {
      return const GenerationOutcome.failure('原文已经是简体中文，选择 English 体验对照。');
    }
    final key = [
      task.name,
      bodyKey,
      service.url,
      service.model,
      targetLanguage,
      question,
    ].join('|');
    final cached = selected.results[key];
    if (cached != null) {
      if (task == GenerationTask.translation) bilingual = true;
      notifyListeners();
      return GenerationOutcome.success(cached);
    }
    if (service.model.isEmpty) {
      return const GenerationOutcome.failure('先选择模型，再开始生成。');
    }
    if (service.calls >= service.limit) {
      return const GenerationOutcome.failure('已达到今天的演示额度，已有结果仍可阅读。');
    }
    final content = switch (task) {
      GenerationTask.translation => currentEnglish,
      GenerationTask.summary =>
        currentKind == BodyKind.rss ? currentParagraphs : selected.summary,
      GenerationTask.question => [
        RegExp('建议|核心|重点|总结|讲|怎么|如何').hasMatch(question)
            ? currentKind == BodyKind.rss
                  ? '当前只有 RSS 摘要。它谈到：${currentParagraphs.first}'
                  : '根据当前文章，可以带走的是：${selected.summary.join(' ')}'
            : '仅凭当前正文，无法确定这个问题的答案。'
                  '你可以查看文章已经提供的信息，或者换一个与正文直接相关的问题。',
      ],
    };
    service.calls++;
    final result = GeneratedResult(
      task: task,
      articleId: selected.id,
      bodyKey: bodyKey,
      kind: currentKind,
      language: targetLanguage,
      service: service.url,
      model: service.model,
      original: currentParagraphs,
      content: content,
      archiveId: archiveId,
      question: question,
    );
    selected.results[key] = result;
    if (task == GenerationTask.translation) bilingual = true;
    notifyListeners();
    return GenerationOutcome.success(result);
  }

  List<int> get summaryReferences => currentKind == BodyKind.rss
      ? [0]
      : selected.id == 'quiet'
      ? [1, 2, 4]
      : [0, 1, 2];

  String saveService(String value) {
    final url = Uri.tryParse(value.trim());
    if (url == null ||
        !['http', 'https'].contains(url.scheme) ||
        url.host.isEmpty ||
        RegExp(r'/(chat/completions|models)/?$').hasMatch(url.path)) {
      return '填写完整接口前缀，不要填完整生成端点。';
    }
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized != service.url) service.model = '';
    service.url = normalized;
    refreshModels();
    return '示例目录已获取，请选择要使用的模型。';
  }

  void refreshModels() {
    service.directoryLabel = '示例目录 · 刚刚获取';
    notifyListeners();
  }

  void chooseModel(String value) {
    service.model = value.trim();
    if (service.model.isNotEmpty && !service.models.contains(service.model)) {
      service.models.add(service.model);
    }
    notifyListeners();
  }

  void setCallLimit(int value) {
    service.limit = value.clamp(1, 1000);
    notifyListeners();
  }

  String testModel() {
    if (service.model.isEmpty) return '请先选择或填写模型。';
    if (service.calls >= service.limit) return '今天的演示调用额度已用尽。';
    service.calls++;
    service.testLabel = '此次示例文本调用可用 · 没有发送实际请求';
    notifyListeners();
    return service.testLabel;
  }

  void toggleNetwork() {
    networkAvailable = !networkAvailable;
    syncLabel = networkAvailable ? '等待同步' : '等待连接';
    notifyListeners();
  }

  Future<String> sync() async {
    if (!canSync) return '等待同一局域网内的配对设备打开应用。';
    if (syncLabel == '正在同步') return '正在同步示例内容。';
    syncLabel = '正在同步';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_disposed) return '';
    if (!canSync) {
      syncLabel = '等待连接';
      notifyListeners();
      return '连接已中断，已保存的内容仍在。';
    }
    pendingChanges = 0;
    lastSync = '刚刚';
    syncLabel = '已同步';
    for (final device in devices) {
      if (device.trusted && device.isOnline) device.pendingRevocation = false;
    }
    notifyListeners();
    return '演示同步完成，阅读进度与归档已对齐。';
  }

  String revokeDevice(String id) {
    final device = devices.firstWhere((device) => device.id == id);
    device.trusted = false;
    device.isOnline = false;
    for (final other in devices) {
      if (other.trusted && !other.isOnline) other.pendingRevocation = true;
    }
    syncLabel = '等待同步';
    pendingChanges++;
    notifyListeners();
    return '授权已撤销，已提交的业务数据保留。';
  }

  String pairDevice(String code) {
    if (code.replaceAll(RegExp(r'\s'), '') != '426810') {
      return '演示配对码是 426 810。';
    }
    if (!networkAvailable) return '请先打开局域网演示开关。';
    PairedDevice? previous;
    for (final device in devices) {
      if (device.id == 'paired-demo') previous = device;
    }
    if (previous == null) {
      devices.add(
        PairedDevice(id: 'paired-demo', name: '新配对的设备', isOnline: true),
      );
    } else {
      previous.trusted = true;
      previous.isOnline = true;
    }
    notifyListeners();
    return '演示配对完成，可以继续同步。';
  }

  List<ReaderArticle> get ruleMatches => articles
      .where(
        (article) => rules.any(
          (rule) => rule.enabled && article.title.contains(rule.keyword),
        ),
      )
      .toList();

  void toggleRule(ReadingRule rule) {
    rule.enabled = !rule.enabled;
    previewedRules = false;
    notifyListeners();
  }

  void previewRules() {
    previewedRules = true;
    notifyListeners();
  }

  String enableAutomation() {
    if (!previewedRules) return '先预览已有规则，再启用本机自动化。';
    automationPaused = false;
    notifyListeners();
    return '本机自动化已启用，只处理后续新文章。';
  }

  String runPreviewedRules() {
    if (!previewedRules) return '请先预览命中文章。';
    var changed = 0;
    for (final article in ruleMatches) {
      if (completedRuleArticles.contains(article.id) ||
          article.isFavorite ||
          article.manualFavorite != null) {
        continue;
      }
      article.fullAvailable = true;
      article.cacheAvailable = true;
      article.isFavorite = true;
      _saveArchive(article, automatic: true);
      completedRuleArticles.add(article.id);
      changed++;
    }
    notifyListeners();
    return '演示处理了 $changed 篇；手动决定和已有归档受到保护。';
  }

  void updateRestoreSelection(void Function(RestoreSelection) update) {
    update(restoreSelection);
    notifyListeners();
  }

  String restoreBackup() {
    for (final article in articles) {
      if (restoreSelection.archives) {
        for (final snapshot
            in _originalArchives[article.id] ?? <ArchiveSnapshot>[]) {
          if (article.archive(snapshot.id) == null) {
            article.archives.add(snapshot);
          }
        }
      }
      if (restoreSelection.favorites &&
          _originalFavorites.containsKey(article.id)) {
        article.isFavorite = _originalFavorites[article.id]!;
        article.manualFavorite = article.isFavorite;
      }
    }
    if (restoreSelection.subscriptions) {
      for (final source in _originalSources) {
        if (!sources.any((existing) => existing.id == source.id)) {
          sources.add(source);
        }
      }
    }
    if (restoreSelection.rules) {
      rules
        ..clear()
        ..addAll(_originalRules.map((rule) => rule.copy()));
      automationPaused = true;
      previewedRules = false;
    }
    pendingChanges++;
    notifyListeners();
    return '所选示例数据已恢复，配对授权与更新的阅读进度保持不变。';
  }

  String clearOrdinaryCache() {
    for (final article in articles) {
      article.cacheAvailable = false;
      article.results.removeWhere((_, result) => result.archiveId == null);
    }
    cacheCleared = true;
    notifyListeners();
    return '本机示例缓存已清理，保留归档不受影响。';
  }

  String refillBody() {
    if (!canSync) return '等待可连接的已配对设备提供正文。';
    selected.cacheAvailable = true;
    notifyListeners();
    return '演示正文已补取，可以继续阅读。';
  }

  String addSource(String name, String value, String category) {
    final url = Uri.tryParse(value.trim());
    if (name.trim().isEmpty ||
        url == null ||
        !['http', 'https'].contains(url.scheme) ||
        url.host.isEmpty) {
      return '填写订阅名称和完整的 RSS / Atom 地址。';
    }
    final normalized = url.toString().replaceFirst(RegExp(r'/+$'), '');
    if (sources.any(
      (source) => source.url == normalized || source.name == name.trim(),
    )) {
      return '已合并重复订阅，不会创建重复文章。';
    }
    sources.add(
      FeedSource(
        id: 'source-${sources.length + 1}',
        name: name.trim(),
        shortName: name.trim().characters.first,
        category: category,
        color: '#657951',
        background: '#e6ebdc',
        url: normalized,
      ),
    );
    pendingChanges++;
    notifyListeners();
    return '示例订阅已添加；当前界面不抓取内容。';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
