import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morss/app.dart';
import 'package:morss/data/sqlite_reading_library.dart';
import 'package:morss/features/reader/reader_controller.dart';
import 'package:xml/xml.dart';

import 'reader_library_controller_test.dart' show feedClient, rssFeed;
import 'reader_library_screen_test.dart' show settleFeeds;
import 'reader_subscriptions_controller_test.dart' show subscriptionOpml;

void main() {
  late Directory directory;
  late ReaderController reader;
  late FilePickerPlatform originalPicker;
  late TestFilePicker picker;
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
    directory = Directory.systemTemp.createTempSync(
      'morss-subscription-screen-',
    );
    originalPicker = FilePickerPlatform.instance;
    picker = TestFilePicker(directory);
    FilePickerPlatform.instance = picker;
    reader = ReaderController.library(
      SqliteReadingLibrary.open(
        '${directory.path}/reader.sqlite',
        client: feedClient(rssFeed),
      ),
    );
  });
  tearDown(() {
    reader.dispose();
    FilePickerPlatform.instance = originalPicker;
    directory.deleteSync(recursive: true);
  });

  testWidgets('手机可编辑订阅和自定义分类，退订确认可取消且保留归档', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => reader.subscribe('晨间阅读', 'https://feeds.example.test/rss', '生活'),
    );
    reader.toggleFavorite();
    await tester.pumpWidget(MorssApp(controller: reader));
    await settleFeeds(tester, reader);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('订阅管理'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('sheet-subscriptions')),
        matching: find.text('晨间阅读'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('managed-feed-name')),
      '自然笔记',
    );
    await tester.enterText(
      find.byKey(const ValueKey('managed-feed-category')),
      '自然科学',
    );
    await tester.ensureVisible(find.text('保存订阅'));
    await tester.tap(find.text('保存订阅'));
    await tester.pumpAndSettle();
    expect(reader.sources.single.name, '自然笔记');
    expect(reader.categories, ['自然科学']);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('sheet-subscriptions')),
        matching: find.text('自然笔记'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('退订'));
    await tester.tap(find.text('退订'));
    await tester.pumpAndSettle();
    expect(find.text('停止刷新此订阅。已保存文章、阅读位置、已读状态、收藏和归档都会保留。'), findsOneWidget);
    await tester.tap(find.text('保留订阅'));
    await tester.pumpAndSettle();
    expect(reader.sources, hasLength(1));
    await tester.ensureVisible(find.text('退订'));
    await tester.tap(find.text('退订'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认退订'));
    await tester.pumpAndSettle();
    expect(reader.sources, isEmpty);
    expect(reader.selected.isFavorite, isTrue);
    expect(reader.selected.archives, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('桌面通过文件选择器导入 OPML 并导出可恢复的文件', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final input = File('${directory.path}/subscriptions.opml')
      ..writeAsStringSync(subscriptionOpml);
    picker.selected = TestPickedFile(input);
    await tester.pumpWidget(MorssApp(controller: reader));
    await settleFeeds(tester, reader);
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('订阅管理'));
    await tester.pumpAndSettle();
    await fileAction(tester, '导入 OPML');
    expect(reader.sources, hasLength(2));
    expect(find.textContaining('新增 2'), findsOneWidget);
    expect(reader.articles, isEmpty);
    await fileAction(tester, '导出 OPML');
    expect(find.text('OPML 已导出。'), findsOneWidget);
    final exported = XmlDocument.parse(picker.output.readAsStringSync());
    expect(
      exported
          .findAllElements('outline')
          .where((node) => node.getAttribute('xmlUrl') != null),
      hasLength(2),
    );
    expect(picker.output.path, endsWith('morss-subscriptions.opml'));
    expect(reader.sources.first.name, '开发 & 阅读');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('取消导入和无效文件保留原数据，可重新导入 UTF-16 文件', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MorssApp(controller: reader));
    await settleFeeds(tester, reader);
    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('订阅管理'));
    await tester.pumpAndSettle();
    await fileAction(tester, '导入 OPML');
    expect(find.text('已取消导入。'), findsOneWidget);
    expect(reader.sources, isEmpty);
    final input = File('${directory.path}/subscriptions.opml')
      ..writeAsStringSync('<opml><body><outline></body>');
    picker.selected = TestPickedFile(input);
    await fileAction(tester, '导入 OPML');
    expect(find.textContaining('无法导入 OPML'), findsOneWidget);
    expect(reader.sources, isEmpty);
    final utf16 = subscriptionOpml.replaceFirst('UTF-8', 'UTF-16');
    input.writeAsBytesSync([
      0xff,
      0xfe,
      for (final unit in utf16.codeUnits) ...[unit & 0xff, unit >> 8],
    ]);
    await fileAction(tester, '导入 OPML');
    expect(reader.sources.map((source) => source.name), ['开发 & 阅读', '晨间阅读']);
    expect(find.textContaining('新增 2'), findsOneWidget);
    expect(find.textContaining('无法导入 OPML'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('导出失败或取消不会显示成功，重新导出后保留全部订阅', (tester) async {
    await tester.pumpWidget(MorssApp(controller: reader));
    await settleFeeds(tester, reader);
    reader.importOpml(subscriptionOpml);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('订阅管理'));
    await tester.pumpAndSettle();
    picker.failSave = true;
    await fileAction(tester, '导出 OPML');
    expect(find.textContaining('无法导出 OPML'), findsOneWidget);
    expect(find.text('OPML 已导出。'), findsNothing);
    picker.failSave = false;
    picker.cancelSave = true;
    await fileAction(tester, '导出 OPML');
    expect(find.text('已取消导出。'), findsOneWidget);
    expect(find.text('OPML 已导出。'), findsNothing);
    picker.cancelSave = false;
    await fileAction(tester, '导出 OPML');
    expect(find.text('OPML 已导出。'), findsOneWidget);
    expect(reader.sources, hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> fileAction(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.runAsync(() async {
    await tester.tap(find.text(label));
    await tester.pump();
    for (var attempt = 0; attempt < 100; attempt++) {
      if (find.text('正在处理文件…').evaluate().isEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
  expect(find.text('正在处理文件…'), findsNothing);
}

class TestFilePicker extends FilePickerPlatform {
  TestFilePicker(this.directory);
  final Directory directory;
  PlatformFile? selected;
  bool cancelSave = false;
  bool failSave = false;
  late File output;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => selected;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (failSave) throw const FileSystemException('只读目录');
    if (cancelSave) return null;
    output = File('${directory.path}/$fileName');
    await output.writeAsBytes(bytes);
    return output.uri;
  }
}

final class TestPickedFile extends PlatformFile {
  TestPickedFile(this.file);
  final File file;
  @override
  String get name => file.uri.pathSegments.last;
  @override
  Uri get uri => file.uri;
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int lengthSync() => file.lengthSync();
  @override
  Future<int> length() => file.length();
  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() =>
      file.openRead().map(Uint8List.fromList);
}
