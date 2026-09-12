import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morss/data/sqlite_reading_library.dart';
import 'package:morss/features/reader/reader_controller.dart';
import 'package:morss/features/reader/reader_models.dart';
import 'package:sqlite3/sqlite3.dart';

const rssFeed = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel><title>晨间阅读</title>
<item><guid isPermaLink="false">article-1</guid><title>留一点时间阅读</title>
<link>https://example.test/one</link>
<description><![CDATA[<p>第一段正文。</p><p>第二段正文。</p>]]></description>
</item></channel></rss>
''';

const atomFeed = '''
<a:feed xmlns:a="http://www.w3.org/2005/Atom" xml:base="https://example.test/journal/">
<a:title>星光笔记</a:title>
<a:entry xml:base="2026/"><a:id>urn:entry:one</a:id><a:title>有编号的文章</a:title>
<a:link rel="self" href="https://feeds.example.test/entry/one"/>
<a:link rel="alternate" href="first.html"/>
<a:summary>这只是摘要。</a:summary>
<a:content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml"><p>实际正文。</p><p>保留第二段。</p></div></a:content>
</a:entry>
<a:entry><a:title>没有编号的文章</a:title><a:link href="second.html"/>
<a:content type="text">&lt;标签&gt; 是文字</a:content></a:entry>
</a:feed>
''';

const rssWithoutIds = '''
<rss version="2.0" xmlns:body="http://purl.org/rss/1.0/modules/content/"><channel><title>无编号笔记</title>
<item><title>新笔记</title><pubDate>Sun, 13 Sep 2026 08:00:00 GMT</pubDate>
<description>摘要。</description><body:encoded><![CDATA[<div><p>实际完整内容。</p><p>第二段。</p><script>不要展示脚本</script></div>]]></body:encoded></item>
<item><title>旧笔记</title><pubDate>Sat, 12 Sep 2026 08:00:00 GMT</pubDate><description>昨日正文。</description></item>
</channel></rss>
''';

http.Client feedClient(String body) => MockClient(
  (_) async => http.Response(
    body,
    200,
    headers: {'content-type': 'application/rss+xml; charset=utf-8'},
  ),
);

void main() {
  late Directory directory;
  late ReaderController reader;

  ReaderController open(http.Client client) => ReaderController.library(
    SqliteReadingLibrary.open(
      '${directory.path}/reader.sqlite',
      client: client,
    ),
  );

  setUp(() {
    directory = Directory.systemTemp.createTempSync('morss-reader-test-');
    reader = open(feedClient(rssFeed));
  });
  tearDown(() {
    reader.dispose();
    directory.deleteSync(recursive: true);
  });

  test('添加 RSS 后关闭再打开，断网仍可阅读订阅正文', () async {
    expect(reader.sources, isEmpty);
    expect(reader.articles, isEmpty);
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    reader.dispose();
    reader = open(MockClient((_) async => throw const SocketException('离线')));

    expect(reader.sources.single.name, '晨间阅读');
    expect(reader.articles.single.title, '留一点时间阅读');
    reader.openArticle(reader.visibleArticles.single);
    expect(reader.currentParagraphs, ['第一段正文。', '第二段正文。']);
    expect(reader.selected.isRead, isFalse);
  });

  test('重启保留中途阅读位置、取消收藏后的归档和外观设置', () async {
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    reader.openArticle(reader.visibleArticles.single);
    reader.updateProgress(46, userScroll: true);
    reader.toggleFavorite();
    final savedId = reader.selected.archives.single.id;
    reader.toggleFavorite();
    reader.setTheme(ThemeMode.dark);
    reader.setFontSize(18);
    reader.dispose();
    reader = open(feedClient(rssFeed));
    reader.resume();

    expect(reader.progress, 46);
    expect(reader.selected.isRead, isFalse);
    expect(reader.selected.isFavorite, isFalse);
    expect(reader.selected.archives.single.id, savedId);
    expect(reader.selected.archives.single.paragraphs, ['第一段正文。', '第二段正文。']);
    expect(reader.themeMode, ThemeMode.dark);
    expect(reader.fontSize, 18);
    reader.saveArchive();
    expect(
      reader.selected.archives.map((archive) => archive.id).toSet(),
      hasLength(2),
    );
  });

  test('同源正文更新保留文章状态、快照和旧版本续读位置', () async {
    var feed = rssFeed;
    reader.dispose();
    reader = open(
      MockClient(
        (_) async => http.Response(
          feed,
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        ),
      ),
    );
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    reader.openArticle(reader.visibleArticles.single);
    final articleId = reader.selected.id;
    reader.updateProgress(37, userScroll: true);
    reader.toggleFavorite();
    reader.toggleRead();
    feed = rssFeed.replaceFirst('第一段正文。', '更新后的正文。');
    await reader.refreshSubscriptions();

    expect(reader.articles, hasLength(1));
    expect(reader.selected.id, articleId);
    expect(reader.selected.isRead, isTrue);
    expect(reader.selected.isFavorite, isTrue);
    expect(reader.selected.archives.single.paragraphs.first, '第一段正文。');
    reader.switchBody(BodyKind.rss);
    expect(reader.currentParagraphs.first, '更新后的正文。');
    expect(reader.progress, 0);
    reader.dispose();
    reader = open(feedClient(feed));
    reader.resume();
    expect(reader.currentParagraphs.first, '第一段正文。');
    expect(reader.progress, 37);
  });

  test('Atom 重复添加合并同源，缺少编号用链接识别，跨源保持独立', () async {
    reader.dispose();
    reader = open(feedClient(atomFeed));
    await reader.subscribe(
      '星光笔记',
      'https://FEEDS.example.test:443/atom#list',
      '技术',
    );
    await reader.subscribe('另一个名称', 'https://feeds.example.test/atom', '生活');
    expect(reader.sources, hasLength(1));
    expect(reader.sources.single.name, '星光笔记');
    expect(reader.articles, hasLength(2));
    final first = reader.articles.singleWhere(
      (article) => article.title == '有编号的文章',
    );
    expect(first.rss, ['实际正文。', '保留第二段。']);
    expect(first.link, 'https://example.test/journal/2026/first.html');
    expect(
      reader.articles.singleWhere((article) => article.title == '没有编号的文章').rss,
      ['<标签> 是文字'],
    );

    await reader.subscribe('星光笔记', 'https://another.example.test/atom', '技术');
    expect(reader.sources, hasLength(2));
    expect(reader.articles.map((article) => article.id).toSet(), hasLength(4));
  });

  test('无编号和链接的 RSS 按发布时间排序，正文更新仍识别为原文章', () async {
    var feed = rssWithoutIds;
    reader.dispose();
    reader = open(
      MockClient(
        (_) async => http.Response(
          feed,
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        ),
      ),
    );
    await reader.subscribe('无编号笔记', 'https://feeds.example.test/no-ids', '生活');
    expect(reader.visibleArticles.map((hit) => hit.article.title), [
      '新笔记',
      '旧笔记',
    ]);
    reader.openArticle(reader.visibleArticles.first);
    expect(reader.currentParagraphs, ['实际完整内容。', '第二段。']);
    final id = reader.selected.id;
    reader.toggleRead();
    feed = rssWithoutIds.replaceFirst('实际完整内容。', '更新后的完整内容。');
    await reader.refreshSubscriptions();
    expect(reader.articles, hasLength(2));
    expect(
      reader.articles.singleWhere((article) => article.id == id).isRead,
      isTrue,
    );
    reader.switchBody(BodyKind.rss);
    expect(reader.currentParagraphs.first, '更新后的完整内容。');
  });

  test('一个订阅返回 HTTP 错误时保留旧正文，并继续刷新其他订阅', () async {
    var fail = false;
    reader.dispose();
    reader = open(
      MockClient(
        (request) async => http.Response(
          fail ? rssFeed.replaceFirst('第一段正文。', '本次更新正文。') : rssFeed,
          fail && request.url.path == '/broken' ? 503 : 200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        ),
      ),
    );
    await reader.subscribe('暂时失效', 'https://feeds.example.test/broken', '生活');
    await reader.subscribe('正常订阅', 'https://feeds.example.test/healthy', '技术');
    final broken = reader.sources
        .singleWhere((source) => source.name == '暂时失效')
        .id;
    fail = true;
    final message = await reader.refreshSubscriptions();

    expect(message, contains('503'));
    expect(reader.feedError, contains('暂时失效'));
    expect(
      reader.articles
          .singleWhere((article) => article.sourceId == broken)
          .rss
          .first,
      '第一段正文。',
    );
    expect(
      reader.articles
          .singleWhere((article) => article.sourceId != broken)
          .rss
          .first,
      '本次更新正文。',
    );
    expect(reader.isFetchingFeeds, isFalse);
  });

  test('阅读多篇文章后重启，继续阅读回到最后打开的文章', () async {
    reader.dispose();
    reader = open(feedClient(rssWithoutIds));
    await reader.subscribe('笔记', 'https://feeds.example.test/notes', '生活');
    reader.openArticle(reader.visibleArticles.first);
    reader.updateProgress(50, userScroll: true);
    reader.openArticle(reader.visibleArticles.last);
    reader.updateProgress(25, userScroll: true);
    reader.dispose();
    reader = open(feedClient(rssWithoutIds));
    reader.resume();

    expect(reader.selected.title, '旧笔记');
    expect(reader.progress, 25);
    expect(reader.selected.isRead, isFalse);
  });

  test('本机写入失败不报告收藏成功，重试后快照完整保存', () async {
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    final otherConnection = sqlite3.open('${directory.path}/reader.sqlite');
    try {
      otherConnection.execute('BEGIN IMMEDIATE');
      final message = reader.toggleFavorite();
      expect(message, contains('未保存'));
      expect(reader.storageError, isNotNull);
      expect(reader.selected.isFavorite, isFalse);
      expect(reader.selected.archives, isEmpty);
      expect(reader.currentParagraphs, ['第一段正文。', '第二段正文。']);
      otherConnection.execute('ROLLBACK');
    } finally {
      otherConnection.close();
    }

    expect(reader.toggleFavorite(), contains('已收藏'));
    expect(reader.storageError, isNull);
    reader.dispose();
    reader = open(feedClient(rssFeed));
    expect(reader.selected.isFavorite, isTrue);
    expect(reader.selected.archives.single.paragraphs, ['第一段正文。', '第二段正文。']);
  });

  test('订阅更新为空正文时仍能续读此前保存的版本', () async {
    var feed = rssFeed;
    reader.dispose();
    reader = open(
      MockClient(
        (_) async => http.Response(
          feed,
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        ),
      ),
    );
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    reader.openArticle(reader.visibleArticles.single);
    reader.updateProgress(35, userScroll: true);
    feed = rssFeed.replaceFirst(
      RegExp(r'<description>[\s\S]*?</description>'),
      '',
    );
    await reader.refreshSubscriptions();
    expect(reader.bodyAvailable, isTrue);
    expect(reader.currentParagraphs.first, '第一段正文。');
    reader.switchBody(BodyKind.rss);
    expect(reader.bodyAvailable, isFalse);
    reader.dispose();
    reader = open(feedClient(feed));
    reader.resume();
    expect(reader.bodyAvailable, isTrue);
    expect(reader.progress, 35);
    expect(reader.currentParagraphs.first, '第一段正文。');
  });

  test('RSS 的数字时区用于按真实发布时间排序', () async {
    reader.dispose();
    reader = open(
      feedClient('''
<rss version="2.0"><channel><title>时区笔记</title>
<item><guid>early</guid><title>UTC 八点</title><pubDate>Fri, 11 Sep 2026 02:00:00 -0600</pubDate><description>较早。</description></item>
<item><guid>late</guid><title>UTC 九点</title><pubDate>Fri, 11 Sep 2026 18:00:00 +0900</pubDate><description>较晚。</description></item>
</channel></rss>
'''),
    );
    await reader.subscribe('', 'https://feeds.example.test/timezones', '生活');
    expect(reader.visibleArticles.map((hit) => hit.article.title), [
      'UTC 九点',
      'UTC 八点',
    ]);
    expect(
      reader.articles.every((article) => article.timeLabel != '日期未知'),
      isTrue,
    );
  });

  test('多源刷新期间切换阅读，最新正文、当前版本和归档都保留', () async {
    var refreshing = false;
    final waiting = Completer<void>();
    final release = Completer<http.Response>();
    final original = http.Response(
      rssFeed,
      200,
      headers: {'content-type': 'application/rss+xml; charset=utf-8'},
    );
    final updated = http.Response(
      rssFeed.replaceFirst('第一段正文。', '刷新得到的新正文。'),
      200,
      headers: {'content-type': 'application/rss+xml; charset=utf-8'},
    );
    reader.dispose();
    reader = open(
      MockClient((request) async {
        if (refreshing && request.url.path == '/slow') {
          waiting.complete();
          return release.future;
        }
        return refreshing ? updated : original;
      }),
    );
    await reader.subscribe('先更新的源', 'https://feeds.example.test/fast', '生活');
    await reader.subscribe('稍后更新的源', 'https://feeds.example.test/slow', '生活');
    final fast = reader.sources
        .singleWhere((source) => source.name == '先更新的源')
        .id;
    final slow = reader.sources
        .singleWhere((source) => source.name == '稍后更新的源')
        .id;
    reader.selectSource(slow);
    reader.openArticle(reader.visibleArticles.single);
    refreshing = true;
    final refresh = reader.refreshSubscriptions();
    try {
      await waiting.future.timeout(const Duration(seconds: 5));
      reader.selectSource(fast);
      reader.openArticle(reader.visibleArticles.single);
      reader.updateProgress(45, userScroll: true);
      reader.toggleFavorite();
      reader.toggleRead();
    } finally {
      release.complete(updated);
      await refresh;
    }
    expect(reader.selected.rss.first, '刷新得到的新正文。');
    expect(reader.currentParagraphs.first, '第一段正文。');
    expect(reader.progress, 45);
    expect(reader.selected.isFavorite, isTrue);
    expect(reader.selected.isRead, isTrue);
    expect(reader.selected.archives.single.paragraphs.first, '第一段正文。');
    reader.switchBody(BodyKind.rss);
    expect(reader.currentParagraphs.first, '刷新得到的新正文。');
    reader.dispose();
    reader = open(feedClient(rssFeed));
    reader.resume();
    expect(reader.currentParagraphs.first, '第一段正文。');
    expect(reader.progress, 45);
    expect(reader.selected.rss.first, '刷新得到的新正文。');
  });

  test('Atom 引用外部正文时保存源中已有的摘要', () async {
    reader.dispose();
    reader = open(
      feedClient(
        atomFeed.replaceFirst(
          RegExp(r'<a:content type="xhtml">[\s\S]*?</a:content>'),
          '<a:content type="text/html" src="https://example.test/external-content"/>',
        ),
      ),
    );
    await reader.subscribe('星光笔记', 'https://feeds.example.test/atom', '技术');
    final article = reader.visibleArticles.singleWhere(
      (hit) => hit.article.title == '有编号的文章',
    );
    reader.openArticle(article);
    expect(reader.currentParagraphs, ['这只是摘要。']);
    expect(reader.bodyAvailable, isTrue);
    expect(
      reader.selected.link,
      'https://example.test/journal/2026/first.html',
    );
  });

  test('再次添加当前订阅也保留正在阅读的正文版本', () async {
    var feed = rssFeed;
    reader.dispose();
    reader = open(
      MockClient(
        (_) async => http.Response(
          feed,
          200,
          headers: {'content-type': 'application/rss+xml; charset=utf-8'},
        ),
      ),
    );
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    reader.updateProgress(25, userScroll: true);
    feed = rssFeed.replaceFirst('第一段正文。', '再次获取的新正文。');
    await reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活');
    expect(reader.articles, hasLength(1));
    expect(reader.sources, hasLength(1));
    expect(reader.selected.rss.first, '再次获取的新正文。');
    expect(reader.currentParagraphs.first, '第一段正文。');
    expect(reader.progress, 25);
  });
}
