import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morss/app.dart';
import 'package:morss/features/reader/reader_controller.dart';
import 'package:morss/features/reader/reader_sheets.dart';

import 'reader_controller_test.dart' show loadReader;

Future<ReaderController> pumpReader(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = loadReader();
  addTearDown(controller.dispose);
  await tester.pumpWidget(MorssApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, filename) in [
      ('MorssSans', 'NotoSansSC.ttf'),
      ('MorssSerif', 'NotoSerifSC.ttf'),
    ]) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$filename'))).load();
    }
  });
  for (final width in [320.0, 390.0, 760.0, 761.0, 1024.0, 1440.0, 1920.0]) {
    testWidgets('A 布局在 ${width.round()}px 下没有溢出', (tester) async {
      final controller = await pumpReader(tester, Size(width, 960));
      expect(find.byKey(const ValueKey('reader-shell')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('reader-sidebar')),
        width <= 760 ? findsNothing : findsOneWidget,
      );
      if (width <= 760) {
        expect(find.byKey(const ValueKey('mobile-navigation')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('article-quiet')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('reader-pane')), findsOneWidget);
      expect(controller.selected.isRead, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('手机可进入正文、收藏、返回列表和继续阅读', (tester) async {
    final controller = await pumpReader(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('article-quiet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-favorite')));
    await tester.pumpAndSettle();
    expect(controller.selected.isFavorite, isFalse);
    expect(controller.selected.archives, hasLength(2));
    await tester.tap(find.byTooltip('返回文章列表'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-navigation')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resume-reading')));
    await tester.pumpAndSettle();
    expect(controller.readerOpen, isTrue);
    expect(controller.selected.isRead, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('引用定位不标已读，实际滚动到正文末尾后才标已读', (tester) async {
    final controller = await pumpReader(tester, const Size(390, 844));
    await tester.tap(find.byKey(const ValueKey('article-quiet')));
    await tester.pumpAndSettle();
    controller.goToParagraph(controller.currentParagraphs.length - 1);
    await tester.pumpAndSettle();
    expect(controller.selected.isRead, isFalse);
    await tester.drag(
      find.byKey(const ValueKey('article-scroll')),
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    expect(controller.selected.isRead, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('手机设置、归档和恢复面板可滚动且没有溢出', (tester) async {
    final controller = await pumpReader(tester, const Size(320, 640));
    for (final sheet in [
      ReaderSheet.settings,
      ReaderSheet.archives,
      ReaderSheet.backup,
      ReaderSheet.appearance,
      ReaderSheet.devices,
      ReaderSheet.service,
      ReaderSheet.rules,
    ]) {
      final context = tester.element(
        find.byKey(const ValueKey('reader-shell')),
      );
      ReaderSheets.show(context, controller: controller, initial: sheet);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('sheet-${sheet.name}')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: sheet.name);
      await tester.tap(find.byTooltip('关闭面板'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('深色与字号变化保留同一正文，并且不改变已读状态', (tester) async {
    final controller = await pumpReader(tester, const Size(1440, 960));
    controller.goToParagraph(2);
    await tester.pumpAndSettle();
    controller.setTheme(ThemeMode.dark);
    controller.setFontSize(22);
    await tester.pumpAndSettle();
    expect(
      Theme.of(
        tester.element(find.byKey(const ValueKey('reader-pane'))),
      ).brightness,
      Brightness.dark,
    );
    expect(controller.selected.isRead, isFalse);
    expect(find.byKey(const ValueKey('paragraph-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
