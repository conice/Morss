import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morss/data/sqlite_reading_library.dart';
import 'package:morss/features/reader/reader_controller.dart';
import 'package:morss/features/reader/reader_models.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:xml/xml.dart';

import 'reader_library_controller_test.dart' show feedClient, rssFeed;

const subscriptionOpml = '''
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0"><head><title>我的订阅</title></head><body>
  <outline text="技术"><outline text="客户端">
    <outline type="rss" text="开发 &amp; 阅读" xmlUrl="https://feeds.example.test/dev?a=1&amp;b=2"/>
  </outline></outline>
  <outline type="rss" text="晨间阅读" xmlUrl="https://feeds.example.test/rss"/>
</body></opml>
''';

void main() {
  late Directory directory;
  late ReaderController reader;

  ReaderController open([http.Client? client]) => ReaderController.library(
    SqliteReadingLibrary.open(
      '${directory.path}/reader.sqlite',
      client: client ?? feedClient(rssFeed),
    ),
  );

  setUp(() {
    directory = Directory.systemTemp.createTempSync('morss-subscriptions-');
    reader = open();
  });
  tearDown(() {
    reader.dispose();
    directory.deleteSync(recursive: true);
  });

  test('离线导入 OPML 保存名称、地址和嵌套分类，重启后可刷新文章', () async {
    reader.dispose();
    reader = open(MockClient((_) async => throw const SocketException('离线')));
    final message = reader.importOpml(subscriptionOpml);
    expect(message, contains('新增 2'));
    expect(reader.sources.map((source) => source.name), ['开发 & 阅读', '晨间阅读']);
    expect(reader.sources.map((source) => source.category), [
      '技术 / 客户端',
      '未分类',
    ]);
    expect(reader.sources.first.url, 'https://feeds.example.test/dev?a=1&b=2');
    expect(reader.articles, isEmpty);
    reader.dispose();
    reader = open();
    expect(reader.sources, hasLength(2));
    await reader.refreshSubscriptions();
    expect(reader.articles, hasLength(2));
    expect(reader.feedError, isNull);
  });

  test('编辑名称与自定义分类后重复导入不覆盖设置、阅读位置和归档', () async {
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    reader.openArticle(reader.visibleArticles.single);
    reader.updateProgress(42, userScroll: true);
    reader.toggleFavorite();
    final sourceId = reader.sources.single.id;
    final articleId = reader.selected.id;
    final archiveId = reader.selected.archives.single.id;
    expect(reader.updateSubscription(sourceId, ' 我的阅读 ', ' 科学 '), isNull);
    expect(reader.sources.single.name, '我的阅读');
    expect(reader.categories, ['科学']);
    final message = reader.importOpml('''
<opml version="2.0"><body><outline text="生活">
  <outline text="旧名称" xmlUrl="https://FEEDS.example.test:443/rss#top"/>
  <outline text="另一个名称" xmlUrl="https://feeds.example.test/rss"/>
  <outline type="rss" text="不支持" xmlUrl="file:///tmp/feed.xml"/>
</outline></body></opml>''');
    expect(message, contains('新增 0'));
    expect(message, contains('合并 2'));
    expect(message, contains('跳过 1'));
    reader.dispose();
    reader = open();
    reader.resume();
    expect(reader.sources.single.name, '我的阅读');
    expect(reader.sources.single.category, '科学');
    expect(reader.selected.id, articleId);
    expect(reader.progress, 42);
    expect(reader.selected.isFavorite, isTrue);
    expect(reader.selected.archives.single.id, archiveId);
  });

  test('刷新途中退订不会复活订阅，收藏和取消收藏的归档可重启续读', () async {
    final waiting = Completer<void>();
    final release = Completer<http.Response>();
    var refreshing = false;
    reader.dispose();
    reader = open(
      MockClient((_) async {
        if (refreshing) {
          waiting.complete();
          return release.future;
        }
        return http.Response(
          rssFeed,
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        );
      }),
    );
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    final sourceId = reader.sources.single.id;
    reader.selectSource(sourceId);
    reader.openArticle(reader.visibleArticles.single);
    reader.updateProgress(55, userScroll: true);
    reader.toggleRead();
    reader.toggleFavorite();
    final archiveId = reader.selected.archives.single.id;
    refreshing = true;
    final refresh = reader.refreshSubscriptions();
    try {
      await waiting.future.timeout(const Duration(seconds: 5));
      expect(reader.unsubscribe(sourceId), isNull);
      expect(reader.sources, isEmpty);
      expect(reader.sourceId, isNull);
    } finally {
      release.complete(
        http.Response(
          rssFeed.replaceFirst('第一段正文。', '退订后到达的新正文。'),
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        ),
      );
      await refresh;
    }
    reader.navigate(ReaderView.favorites);
    expect(reader.visibleArticles, hasLength(1));
    reader.toggleFavorite();
    reader.dispose();
    reader = open();
    await reader.refreshSubscriptions();
    expect(reader.sources, isEmpty);
    expect(reader.feedError, isNull);
    reader.navigate(ReaderView.archives);
    reader.openArticle(reader.visibleArticles.single);
    expect(reader.selected.archives.single.id, archiveId);
    expect(reader.currentParagraphs.first, '第一段正文。');
    expect(reader.selected.isFavorite, isFalse);
    expect(reader.selected.isRead, isTrue);
    expect(reader.sourceOf(reader.selected).name, '晨间阅读');
    reader.resume();
    expect(reader.progress, 55);
    reader.importOpml(subscriptionOpml);
    expect(reader.sources, hasLength(2));
    expect(reader.selected.archives.single.id, archiveId);
  });

  test('导出有效 OPML 保留嵌套分类和特殊字符，只包含正在订阅的源', () {
    reader.importOpml(subscriptionOpml);
    reader.unsubscribe(reader.sources.last.id);
    final output = reader.exportOpml();
    final xml = XmlDocument.parse(output);
    expect(xml.rootElement.name.local, 'opml');
    expect(xml.rootElement.getAttribute('version'), '2.0');
    final folder = xml.rootElement.getElement('body')!.getElement('outline')!;
    expect(folder.getAttribute('text'), '技术');
    expect(folder.getElement('outline')!.getAttribute('text'), '客户端');
    final entries = xml
        .findAllElements('outline')
        .where((element) => element.getAttribute('xmlUrl') != null)
        .toList();
    expect(entries, hasLength(1));
    expect(entries.single.getAttribute('text'), '开发 & 阅读');
    expect(
      entries.single.getAttribute('xmlUrl'),
      'https://feeds.example.test/dev?a=1&b=2',
    );
    final restored = ReaderController.library(
      SqliteReadingLibrary.open(
        '${directory.path}/restored.sqlite',
        client: feedClient(rssFeed),
      ),
    );
    try {
      restored.importOpml(output);
      expect(restored.sources.single.name, '开发 & 阅读');
      expect(restored.sources.single.category, '技术 / 客户端');
    } finally {
      restored.dispose();
    }
  });

  test('OPML 格式错误不会部分导入，失败后可重新选择有效文件', () {
    reader.importOpml(subscriptionOpml);
    final before = reader.sources.map((source) => source.id).toList();
    final error = reader.importOpml('''
<opml version="2.0"><body>
  <outline text="不能部分导入" xmlUrl="https://another.example.test/feed"/>
  <outline text="尚未结束">
</body></opml>''');
    expect(error, contains('无法导入 OPML'));
    expect(reader.storageError, isNull);
    expect(reader.sources.map((source) => source.id), before);
    expect(reader.importOpml('<rss><channel/></rss>'), contains('无法导入 OPML'));
    expect(reader.importOpml(subscriptionOpml), contains('合并 2'));
    expect(reader.sources.map((source) => source.id), before);
  });

  test('存储被占用时导入不丢失原内容，解除后可重试并清除错误', () async {
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    reader.toggleFavorite();
    final savedArchive = reader.selected.archives.single.id;
    final lock = sqlite3.open('${directory.path}/reader.sqlite');
    lock.execute('BEGIN IMMEDIATE');
    try {
      expect(reader.importOpml(subscriptionOpml), contains('未保存'));
      expect(reader.storageError, isNotNull);
      expect(reader.sources, hasLength(1));
      expect(reader.selected.archives.single.id, savedArchive);
    } finally {
      lock.execute('ROLLBACK');
      lock.close();
    }
    expect(reader.importOpml(subscriptionOpml), contains('新增 1'));
    expect(reader.storageError, isNull);
    expect(reader.sources, hasLength(2));
    expect(reader.selected.archives.single.id, savedArchive);
    final id = reader.sources.first.id;
    expect(reader.updateSubscription(id, ' ', '新分类'), contains('请填写'));
    expect(reader.sources.first.name, '晨间阅读');
  });

  test('文件夹名称中的斜杠在重启和只改名后仍按原层级导出', () {
    reader.importOpml('''
<opml version="2.0"><body><outline text="设计 / 生活">
  <outline text="晨间阅读" xmlUrl="https://feeds.example.test/rss"/>
</outline></body></opml>''');
    reader.dispose();
    reader = open();
    final source = reader.sources.single;
    reader.updateSubscription(source.id, '新名称', source.category);
    final body = XmlDocument.parse(
      reader.exportOpml(),
    ).rootElement.getElement('body')!;
    final folder = body.getElement('outline')!;
    expect(folder.getAttribute('text'), '设计 / 生活');
    expect(
      folder.getElement('outline')!.getAttribute('xmlUrl'),
      'https://feeds.example.test/rss',
    );
    expect(folder.getElement('outline')!.getAttribute('text'), '新名称');
  });

  test('重新添加途中导入又退订，晚到的重新添加请求不能撤销最后一次退订', () async {
    final waiting = Completer<void>();
    final release = Completer<http.Response>();
    var addingAgain = false;
    reader.dispose();
    reader = open(
      MockClient((_) async {
        if (addingAgain) {
          waiting.complete();
          return release.future;
        }
        return http.Response(
          rssFeed,
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        );
      }),
    );
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    final sourceId = reader.sources.single.id;
    reader.toggleFavorite();
    reader.unsubscribe(sourceId);
    addingAgain = true;
    final pending = reader.subscribe(
      '重新添加',
      'https://feeds.example.test/rss',
      '技术',
    );
    try {
      await waiting.future.timeout(const Duration(seconds: 5));
      reader.importOpml('''
<opml version="2.0"><body>
  <outline text="晨间阅读" xmlUrl="https://feeds.example.test/rss"/>
</body></opml>''');
      expect(reader.sources, hasLength(1));
      reader.unsubscribe(sourceId);
    } finally {
      release.complete(
        http.Response(
          rssFeed.replaceFirst('第一段正文。', '旧请求送来的正文。'),
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        ),
      );
      await pending;
    }
    expect(reader.sources, isEmpty);
    reader.dispose();
    reader = open();
    expect(reader.sources, isEmpty);
    reader.navigate(ReaderView.favorites);
    expect(reader.visibleArticles, hasLength(1));
    expect(reader.selected.archives.single.paragraphs.first, '第一段正文。');
  });
}
