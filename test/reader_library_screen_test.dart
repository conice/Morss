import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morss/app.dart';
import 'package:morss/data/sqlite_reading_library.dart';
import 'package:morss/features/reader/reader_controller.dart';

import 'reader_library_controller_test.dart' show feedClient, rssFeed;

void main() {
  late Directory directory;
  late ReaderController reader;
  late String responseBody;
  late int responseStatus;
  late bool browserAvailable;
  late List<Uri> openedUrls;
  setUpAll(() async {
    for (final (family, file) in [
      ('MorssSans', 'NotoSansSC.ttf'),
      ('MorssSerif', 'NotoSerifSC.ttf'),
    ]) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$file'))).load();
    }
  });
  setUp(() {
    responseBody = rssFeed;
    responseStatus = 200;
    browserAvailable = true;
    openedUrls = [];
    directory = Directory.systemTemp.createTempSync('morss-screen-test-');
    reader = ReaderController.library(
      SqliteReadingLibrary.open(
        '${directory.path}/reader.sqlite',
        client: MockClient(
          (_) async => http.Response(
            responseBody,
            responseStatus,
            headers: {'content-type': 'application/rss+xml; charset=utf-8'},
          ),
        ),
      ),
      launchOriginal: (url) async {
        openedUrls.add(url);
        return browserAvailable;
      },
    );
  });
  tearDown(() {
    reader.dispose();
    directory.deleteSync(recursive: true);
  });

  testWidgets('手机空库可添加真实订阅并进入 RSS 正文', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MorssApp(controller: reader));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('添加第一个订阅'));
    await tester.tap(find.text('添加第一个订阅'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('feed-name')), '晨间阅读');
    await tester.enterText(
      find.byKey(const ValueKey('feed-url')),
      'https://feeds.example.test/rss',
    );
    await tester.ensureVisible(find.text('添加订阅并获取文章'));
    await fetchFromUi(tester, reader, find.text('添加订阅并获取文章'));
    await tester.pumpAndSettle();
    expect(reader.articles, hasLength(1));
    expect(find.byKey(const ValueKey('sheet-subscribe')), findsNothing);
    final article = find.byKey(
      ValueKey('article-${reader.articles.single.id}'),
    );
    await tester.ensureVisible(article);
    await tester.tap(article);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-pane')), findsOneWidget);
    expect(find.text('留一点时间阅读'), findsOneWidget);
    expect(reader.currentParagraphs, ['第一段正文。', '第二段正文。']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('桌面空库可进入设置，未开放的功能不执行演示操作', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MorssApp(controller: reader));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('empty-reader')), findsOneWidget);
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('备份与恢复'));
    await tester.pumpAndSettle();
    expect(find.text('此功能尚未开放。当前版本支持本机订阅与离线阅读。'), findsOneWidget);
    expect(find.text('恢复所选数据'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('阅读库打开失败可重试，已有订阅和正文保留', (tester) async {
    await tester.runAsync(
      () => reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活'),
    );
    reader.dispose();
    var databasePath = directory.path;
    await tester.pumpWidget(
      MorssApp.open(
        loader: () async {
          return ReaderController.library(
            SqliteReadingLibrary.open(
              databasePath,
              client: feedClient(rssFeed),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('无法打开本地阅读库'), findsOneWidget);
    databasePath = '${directory.path}/reader.sqlite';
    await tester.runAsync(() => tester.tap(find.text('重试')));
    await tester.pumpAndSettle();
    expect(find.text('无法打开本地阅读库'), findsNothing);
    expect(find.text('留一点时间阅读'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('启动和使用期间每 30 分钟刷新，后台暂停并在返回时更新', (tester) async {
    await tester.runAsync(
      () => reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活'),
    );
    responseBody = rssFeed.replaceFirst('留一点时间阅读', '启动时更新');
    await tester.pumpWidget(MorssApp(controller: reader));
    await settleFeeds(tester, reader);
    expect(reader.selected.title, '启动时更新');

    responseBody = rssFeed.replaceFirst('留一点时间阅读', '定时更新');
    await tester.pump(const Duration(minutes: 29));
    expect(reader.selected.title, '启动时更新');
    await tester.pump(const Duration(minutes: 1));
    await settleFeeds(tester, reader);
    expect(reader.selected.title, '定时更新');

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    responseBody = rssFeed.replaceFirst('留一点时间阅读', '返回时更新');
    await tester.pump(const Duration(minutes: 31));
    expect(reader.selected.title, '定时更新');
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await settleFeeds(tester, reader);
    expect(reader.selected.title, '返回时更新');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('原网页打开保存的文章链接，浏览器不可用时可重试', (tester) async {
    await tester.runAsync(
      () => reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活'),
    );
    await tester.pumpWidget(MorssApp(controller: reader));
    await settleFeeds(tester, reader);
    final article = find.byKey(ValueKey('article-${reader.selected.id}'));
    await tester.ensureVisible(article);
    await tester.tap(article);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('原网页'));
    await tester.pumpAndSettle();
    expect(find.text('https://example.test/one'), findsOneWidget);
    browserAvailable = false;
    await tester.runAsync(() => tester.tap(find.text('在浏览器中打开')));
    await tester.pumpAndSettle();
    expect(openedUrls.single.toString(), 'https://example.test/one');
    expect(find.text('无法打开浏览器。可复制上方链接后手动打开。'), findsOneWidget);
    browserAvailable = true;
    await tester.runAsync(() => tester.tap(find.text('在浏览器中打开')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sheet-original')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('短 RSS 正文在主动向下阅读后标为已读，打开时保留未读', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活'),
    );
    await tester.pumpWidget(MorssApp(controller: reader));
    await settleFeeds(tester, reader);
    expect(reader.selected.isRead, isFalse);
    await tester.drag(
      find.byKey(const ValueKey('article-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(reader.selected.isRead, isTrue);
    expect(reader.progress, 100);
    reader.toggleRead();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('article-scroll')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(reader.selected.isRead, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('订阅获取失败保留表单，重试和手动刷新后可恢复', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MorssApp(controller: reader));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('添加第一个订阅'));
    await tester.tap(find.text('添加第一个订阅'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('feed-url')),
      'https://feeds.example.test/rss',
    );
    responseStatus = 503;
    await tester.ensureVisible(find.text('添加订阅并获取文章'));
    await fetchFromUi(tester, reader, find.text('添加订阅并获取文章'));
    await tester.pumpAndSettle();
    expect(find.text('服务器返回 HTTP 503。'), findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-subscribe')), findsOneWidget);
    expect(reader.sources, isEmpty);

    responseStatus = 200;
    await fetchFromUi(tester, reader, find.text('添加订阅并获取文章'));
    await tester.pumpAndSettle();
    expect(reader.sources.single.name, '晨间阅读');
    expect(find.byKey(const ValueKey('sheet-subscribe')), findsNothing);
    responseStatus = 503;
    await fetchFromUi(tester, reader, find.byTooltip('刷新订阅'));
    await tester.pumpAndSettle();
    expect(reader.articles.single.title, '留一点时间阅读');
    final error = find.text('部分订阅未更新 · 查看原因');
    await tester.ensureVisible(error);
    await tester.tap(error);
    await tester.pumpAndSettle();
    expect(find.text('晨间阅读：服务器返回 HTTP 503。'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    responseStatus = 200;
    responseBody = rssFeed.replaceFirst('留一点时间阅读', '刷新后继续阅读');
    await fetchFromUi(tester, reader, find.byTooltip('刷新订阅'));
    await tester.pumpAndSettle();
    expect(reader.articles.single.title, '刷新后继续阅读');
    expect(reader.feedError, isNull);
    await tester.runAsync(() => tester.pumpAndSettle());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> settleFeeds(WidgetTester tester, ReaderController reader) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => waitForFeeds(reader));
  await tester.pumpAndSettle();
}

Future<void> waitForFeeds(ReaderController reader) async {
  if (!reader.isFetchingFeeds) return;
  final completed = Completer<void>();
  void onChange() {
    if (!reader.isFetchingFeeds && !completed.isCompleted) completed.complete();
  }

  reader.addListener(onChange);
  try {
    await completed.future.timeout(const Duration(seconds: 5));
  } finally {
    reader.removeListener(onChange);
  }
}

Future<void> fetchFromUi(
  WidgetTester tester,
  ReaderController reader,
  Finder button,
) async {
  await tester.runAsync(() async {
    final completed = Completer<void>();
    void onChange() {
      if (!reader.isFetchingFeeds && !completed.isCompleted) {
        completed.complete();
      }
    }

    reader.addListener(onChange);
    try {
      await tester.tap(button);
      await completed.future.timeout(const Duration(seconds: 5));
    } finally {
      reader.removeListener(onChange);
    }
  });
}
