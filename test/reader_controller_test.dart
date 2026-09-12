import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:morss/features/reader/reader_controller.dart';
import 'package:morss/features/reader/reader_models.dart';

ReaderController loadReader() => ReaderController.fromJson(
  jsonDecode(File('assets/data/reader_demo.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  late ReaderController reader;
  setUp(() => reader = loadReader());
  tearDown(() => reader.dispose());

  test('取消收藏后，归档仍能访问和搜索；删除最后一份不改变阅读标记', () {
    final article = reader.selected;
    expect(article.archives, hasLength(2));
    reader.toggleFavorite();
    expect(article.isFavorite, isFalse);
    reader.navigate(ReaderView.archives);
    expect(
      reader.visibleArticles.any((hit) => hit.article.id == article.id),
      isTrue,
    );
    reader.search(article.title);
    expect(reader.visibleArticles.single.article, article);
    reader.toggleRead();
    for (final archive in List.of(article.archives)) {
      reader.deleteArchive(archive.id);
    }
    expect(article.archives, isEmpty);
    expect(article.isFavorite, isFalse);
    expect(article.isRead, isTrue);
  });

  test('归档删除只移除该快照的生成结果', () {
    final archives = List.of(reader.selected.archives);
    for (final archive in archives) {
      reader.openArchive(archive.id);
      expect(reader.generate(GenerationTask.summary).result, isNotNull);
    }
    reader.deleteArchive(archives.first.id);
    expect(reader.selected.results.values.single.archiveId, archives.last.id);
    expect(reader.selected.isFavorite, isTrue);
  });

  test('清理普通缓存后仍可检索并阅读归档及其译文', () {
    reader.setLanguage('en');
    reader.generate(GenerationTask.translation);
    final archive = reader.selected.archives.first;
    reader.openArchive(archive.id);
    final translation = reader.generate(GenerationTask.translation).result!;
    reader.clearOrdinaryCache();
    expect(reader.bodyAvailable, isTrue);
    expect(
      reader.selected.results.values.every(
        (result) => result.archiveId != null,
      ),
      isTrue,
    );
    reader.search(translation.content.first);
    final hit = reader.visibleArticles.single;
    expect(hit.archiveId, archive.id);
    expect(hit.translation, isTrue);
    reader.openArticle(hit);
    expect(reader.bilingual, isTrue);
    expect(reader.currentParagraphs, archive.paragraphs);
  });

  test('仅恢复归档不会恢复收藏、覆盖阅读位置或重新授权设备', () {
    final originalCount = reader.selected.archives.length;
    reader.toggleFavorite();
    for (final archive in List.of(reader.selected.archives)) {
      reader.deleteArchive(archive.id);
    }
    reader.updateProgress(73, userScroll: true);
    reader.toggleRead();
    reader.revokeDevice('windows');
    reader.restoreBackup();
    expect(reader.selected.archives, hasLength(originalCount));
    expect(reader.selected.isFavorite, isFalse);
    expect(reader.selected.isRead, isTrue);
    expect(reader.progress, 73);
    expect(reader.devices.first.trusted, isFalse);
    expect(reader.devices.last.pendingRevocation, isTrue);
    reader.restoreBackup();
    expect(reader.selected.archives, hasLength(originalCount));
  });

  test('已生成结果在额度用尽后可复用，正文版本之间不误复用', () {
    final before = reader.service.calls;
    final first = reader.generate(GenerationTask.summary).result;
    expect(first, isNotNull);
    reader.setCallLimit(reader.service.calls);
    expect(reader.generate(GenerationTask.summary).result, same(first));
    expect(reader.service.calls, before + 1);
    reader.switchBody(BodyKind.rss);
    expect(reader.generate(GenerationTask.summary).result, isNull);
    reader.switchBody(BodyKind.full);
    expect(reader.generate(GenerationTask.summary).result, same(first));
  });

  test('目录刷新不消耗调用额度，服务变化后等待明确选择模型', () {
    final before = reader.service.calls;
    reader.saveService('https://example.com/custom/api/v2/');
    expect(reader.service.url, 'https://example.com/custom/api/v2');
    expect(reader.service.model, isEmpty);
    reader.refreshModels();
    expect(reader.service.calls, before);
    expect(reader.generate(GenerationTask.summary).result, isNull);
    reader.chooseModel('manually-entered-model');
    reader.testModel();
    expect(reader.service.calls, before + 1);
    reader.saveService('https://example.com/v1/chat/completions');
    expect(reader.service.url, 'https://example.com/custom/api/v2');
  });

  test('译文、摘要、定位与切换正文不会自动标为已读', () {
    reader.setLanguage('en');
    reader.generate(GenerationTask.translation);
    reader.generate(GenerationTask.summary);
    reader.goToParagraph(4);
    reader.updateProgress(100, userScroll: false);
    expect(reader.selected.isRead, isFalse);
    expect(reader.progress, 42);
    reader.switchBody(BodyKind.rss);
    reader.updateProgress(25, userScroll: true);
    reader.switchBody(BodyKind.full);
    expect(reader.progress, 42);
    reader.updateProgress(100, userScroll: true);
    expect(reader.selected.isRead, isTrue);
    reader.switchBody(BodyKind.rss);
    expect(reader.progress, 25);
  });

  test('规则预览后执行，重复批次不追加归档', () {
    final matches = reader.ruleMatches;
    final before = matches.fold(
      0,
      (total, article) => total + article.archives.length,
    );
    reader.runPreviewedRules();
    expect(
      matches.fold(0, (total, article) => total + article.archives.length),
      before,
    );
    reader.previewRules();
    reader.runPreviewedRules();
    final saved = matches.fold(
      0,
      (total, article) => total + article.archives.length,
    );
    expect(saved, greaterThan(before));
    reader.runPreviewedRules();
    expect(
      matches.fold(0, (total, article) => total + article.archives.length),
      saved,
    );
  });

  test('规则尊重手动取消收藏，恢复规则后须预览才能重新启用', () {
    final match = reader.ruleMatches.first;
    reader.openArticle(
      reader.visibleArticles.firstWhere((hit) => hit.article == match),
    );
    if (!match.isFavorite) reader.toggleFavorite();
    reader.toggleFavorite();
    final archives = match.archives.length;
    reader.previewRules();
    reader.runPreviewedRules();
    expect(match.isFavorite, isFalse);
    expect(match.archives, hasLength(archives));
    reader.updateRestoreSelection((selection) => selection.rules = true);
    reader.restoreBackup();
    expect(reader.automationPaused, isTrue);
    reader.enableAutomation();
    expect(reader.automationPaused, isTrue);
    reader.previewRules();
    reader.enableAutomation();
    expect(reader.automationPaused, isFalse);
  });

  test('撤销唯一在线设备后停止同步，离线仍能保存阅读操作', () async {
    final syncing = reader.sync();
    reader.revokeDevice('windows');
    expect(await syncing, contains('连接已中断'));
    expect(reader.pendingChanges, greaterThan(0));
    final archives = reader.selected.archives.length;
    reader.saveArchive();
    expect(reader.selected.archives, hasLength(archives + 1));
    expect(reader.canSync, isFalse);
  });
}
