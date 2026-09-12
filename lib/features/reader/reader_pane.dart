import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../design/reader_theme.dart';
import '../../design/reader_widgets.dart';
import 'reader_controller.dart';
import 'reader_models.dart';
import 'reader_sheets.dart';

class ReaderPane extends StatefulWidget {
  const ReaderPane({
    super.key,
    required this.controller,
    required this.mobile,
    required this.onSheet,
  });

  final ReaderController controller;
  final bool mobile;
  final ValueChanged<ReaderSheet> onSheet;

  @override
  State<ReaderPane> createState() => _ReaderPaneState();
}

class _ReaderPaneState extends State<ReaderPane> {
  final _scroll = ScrollController();
  List<GlobalKey> _paragraphs = [];
  String _document = '';
  int _request = -1;
  bool _programmatic = false;
  bool _userScroll = false;
  bool _bilingual = false;
  double _fontSize = 15;

  ReaderController get c => widget.controller;
  ReaderColors get colors => ReaderColors.of(context);
  bool get mobile => widget.mobile;

  @override
  void initState() {
    super.initState();
    _updateDocument(initial: true);
  }

  @override
  void didUpdateWidget(covariant ReaderPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateDocument();
  }

  double? _offsetFor(int index) {
    if (index < 0 || index >= _paragraphs.length) return null;
    final object = _paragraphs[index].currentContext?.findRenderObject();
    if (object == null || !object.attached) return null;
    return RenderAbstractViewport.of(
      object,
    ).getOffsetToReveal(object, 0).offset;
  }

  void _updateDocument({bool initial = false}) {
    final document = '${c.selectedId}/${c.bodyKey}';
    final changed = _document != document;
    final requested = _request != c.readingRequest;
    final reflow =
        !changed && (_bilingual != c.bilingual || _fontSize != c.fontSize);
    int? anchor;
    double anchorDelta = 0;
    if (reflow && _scroll.hasClients) {
      for (var index = 0; index < _paragraphs.length; index++) {
        final offset = _offsetFor(index);
        if (offset != null && offset <= _scroll.offset + 30) {
          anchor = index;
          anchorDelta = _scroll.offset - offset;
        }
      }
    }
    if (changed) {
      _paragraphs = List.generate(
        c.currentParagraphs.length,
        (_) => GlobalKey(),
      );
    }
    _document = document;
    _request = c.readingRequest;
    _bilingual = c.bilingual;
    _fontSize = c.fontSize;
    if (!changed && !requested && !reflow) return;
    if (initial && c.readingRequest == 0) return;
    final paragraph = requested ? c.requestedParagraph : anchor;
    final progress = requested ? c.requestedProgress : c.progress;
    final request = _request;
    _programmatic = true;
    _userScroll = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || request != _request) return;
      final offset = paragraph == null ? null : _offsetFor(paragraph);
      final target = offset == null
          ? _scroll.position.maxScrollExtent * (progress ?? 0) / 100
          : offset + (requested ? -28 : anchorDelta);
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
      _programmatic = false;
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (_programmatic || notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userScroll = true;
    }
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _userScroll = true;
    }
    if ((notification is ScrollUpdateNotification ||
            notification is OverscrollNotification) &&
        _userScroll) {
      final extent = notification.metrics.maxScrollExtent;
      if (extent > 0) {
        c.updateProgress(
          notification.metrics.pixels / extent * 100,
          userScroll: true,
        );
      } else if (notification is OverscrollNotification) {
        _readShortBody(notification.overscroll);
      }
    }
    if (notification is ScrollEndNotification) _userScroll = false;
    return false;
  }

  void _readShortBody(double direction) {
    if (!c.isDemo &&
        !_programmatic &&
        direction > 0 &&
        _scroll.hasClients &&
        _scroll.position.maxScrollExtent <= 0 &&
        c.bodyAvailable) {
      c.updateProgress(100, userScroll: true);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _notice(String message) => showReaderNotice(context, message);
  void _sheet(ReaderSheet kind) => widget.onSheet(kind);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width <= ReaderMetrics.compactBreakpoint;
    final large = size.width >= ReaderMetrics.largeBreakpoint;
    final horizontal = mobile
        ? 23.0
        : compact
        ? 24.0
        : large
        ? 48.0
        : 38.0;
    return Container(
      key: const ValueKey('reader-pane'),
      color: colors.reader,
      child: Column(
        children: [
          _topbar(),
          Expanded(
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _userScroll = true;
                  _readShortBody(event.scrollDelta.dy);
                }
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: Scrollbar(
                  controller: _scroll,
                  child: SingleChildScrollView(
                    key: const ValueKey('article-scroll'),
                    controller: _scroll,
                    physics: c.isDemo
                        ? null
                        : const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      mobile || compact
                          ? 24
                          : large
                          ? 37
                          : 30,
                      horizontal + 5,
                      mobile
                          ? 40
                          : compact
                          ? 24
                          : large
                          ? 60
                          : 50,
                    ),
                    child: SelectionArea(child: _article(size)),
                  ),
                ),
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _topbar() {
    final source = c.sourceOf(c.selected);
    return Container(
      height: mobile ? 54 : 62,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 27),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          if (mobile) ...[
            SizedBox(
              width: 24,
              height: 34,
              child: OverflowBox(
                alignment: Alignment.centerRight,
                minWidth: 34,
                maxWidth: 34,
                child: ReaderIconButton(
                  icon: 'left',
                  label: '返回文章列表',
                  iconSize: 12,
                  onPressed: c.backToList,
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            source.category,
            style: TextStyle(fontSize: 10, color: colors.faint),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: mobile ? 5 : 9),
            child: const ReaderIcon('chevron', size: 12),
          ),
          Expanded(
            child: Text(
              source.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xff657562)),
            ),
          ),
          const SizedBox(width: 5),
          ReaderIconButton(
            key: const ValueKey('toggle-favorite'),
            icon: 'favorite',
            label: c.selected.isFavorite ? '取消收藏，保留归档' : '收藏文章',
            selected: c.selected.isFavorite,
            onPressed: () => _notice(c.toggleFavorite()),
          ),
          const SizedBox(width: 3),
          ReaderIconButton(
            icon: 'archive',
            label: '查看归档版本',
            onPressed: () => _sheet(ReaderSheet.archives),
          ),
          const SizedBox(width: 3),
          ReaderIconButton(
            icon: 'more',
            label: '更多阅读操作',
            onPressed: () => _sheet(ReaderSheet.articleMenu),
          ),
        ],
      ),
    );
  }

  Widget _article(Size size) {
    final article = c.selected;
    final source = c.sourceOf(article);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 20, height: 1, color: const Color(0xffbdcbb2)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${source.category}与灵感 · ${c.currentArchive != null ? '历史归档' : '慢一点，也很好'}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xff839374),
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              article.title,
              key: const ValueKey('article-title'),
              style: TextStyle(
                fontFamily: 'MorssSerif',
                fontSize: mobile ? 29 : (size.width * .0275).clamp(25, 39),
                fontWeight: FontWeight.w700,
                height: mobile ? 1.55 : 1.5,
                letterSpacing: -.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          article.deck,
          style: TextStyle(
            fontSize: mobile ? 11 : 12,
            color: colors.muted,
            height: 1.8,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            top: mobile ? 19 : 20,
            bottom: mobile ? 19 : 23,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final byline = Wrap(
                spacing: mobile ? 6 : 8,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SourceBadge(source, size: mobile ? 22 : 25),
                  Text(source.name),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '·',
                      style: TextStyle(color: Color(0xffbcc5b7)),
                    ),
                  ),
                  Text(
                    c.isDemo
                        ? (article.timeLabel == '昨天' ? '9 月 11 日' : '9 月 12 日')
                        : article.timeLabel,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '·',
                      style: TextStyle(color: Color(0xffbcc5b7)),
                    ),
                  ),
                  Text('${article.minutes} 分钟'),
                ],
              );
              final saved = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReaderIcon(
                    c.bodyAvailable ? 'checkcircle' : 'clock',
                    size: 12,
                    color: const Color(0xff7e936d),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    !c.bodyAvailable
                        ? (c.isDemo ? '正文已清理' : '订阅未提供正文')
                        : c.currentArchive?.savedLabel ??
                              (c.isDemo ? '本机可离线阅读' : '正文文字已离线保存'),
                    style: TextStyle(
                      color: Color(0xff7e936d),
                      fontSize: mobile ? 8 : 9,
                    ),
                  ),
                ],
              );
              return DefaultTextStyle(
                style: TextStyle(
                  fontFamily: 'MorssSans',
                  fontSize: mobile ? 9 : 10,
                  color: colors.muted,
                ),
                child: OverflowBar(
                  alignment:
                      !mobile && size.width <= ReaderMetrics.compactBreakpoint
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.spaceBetween,
                  spacing: mobile ? 6 : 8,
                  overflowSpacing: 8,
                  children: [byline, saved],
                ),
              );
            },
          ),
        ),
        if (article.image.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(mobile ? 12 : 15),
            child: Image.asset(
              'assets/images/${article.image}.jpg',
              width: double.infinity,
              height: mobile ? 181 : (size.height * .2).clamp(168, 245),
              fit: BoxFit.cover,
              semanticLabel: switch (article.image) {
                'mountain' => '阳光下连绵的山峰',
                'forest' => '光线穿过绿色森林',
                'architecture' => '明亮建筑的几何线条',
                'desk' => '桌上的书本与笔记',
                _ => '海岸的浪花',
              },
            ),
          ),
          const SizedBox(height: 9),
          Text(
            article.id == 'quiet' ? '留一点空白，让好内容慢慢发生。' : '每一篇值得停留的文字，都有自己的风景。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: mobile ? 8 : 9,
              color: colors.faint,
              letterSpacing: .4,
            ),
          ),
        ],
        const SizedBox(height: 22),
        _readingTools(),
        if (c.currentArchive != null)
          _message(
            '正在查看 ${c.currentArchive!.savedLabel} 保存的'
            '${c.currentKind == BodyKind.rss ? ' RSS 正文' : '全文'}；源站更新不会替换这份快照。',
          ),
        if (c.isDemo && c.currentKind == BodyKind.rss)
          _message('此订阅仅提供摘要。可以提取公开网页全文，或查看原网页入口。'),
        if (!c.isDemo && c.currentArchive == null)
          _message(
            c.bodyKey == c.selected.rssVersionId
                ? '这里显示订阅源提供的正文文字。原网页可查看图片与排版。'
                : '这是上次阅读的正文版本，点击「RSS 正文」可查看更新内容。',
          ),
        c.bodyAvailable ? _body() : _missingBody(),
      ],
    );
  }

  Widget _readingTools() {
    final sourceTabs = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.wash,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in c.isDemo ? BodyKind.values : [BodyKind.rss]) ...[
            ReaderTap(
              key: ValueKey('body-${kind.name}'),
              onTap: () => kind == BodyKind.full && !c.selected.fullAvailable
                  ? _notice(c.extractFullText())
                  : c.switchBody(kind),
              color: c.currentKind == kind ? colors.solid : null,
              radius: 6,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Text(
                kind == BodyKind.rss
                    ? 'RSS 正文'
                    : c.selected.fullAvailable
                    ? '提取全文'
                    : '提取全文 +',
                style: TextStyle(
                  fontSize: mobile ? 10 : 9,
                  height: mobile ? 1.5 : 13 / 9,
                  color: c.currentKind == kind ? colors.accent : colors.muted,
                ),
              ),
            ),
            if (kind == BodyKind.rss) const SizedBox(width: 2),
          ],
        ],
      ),
    );
    final actions = Wrap(
      spacing: mobile ? 8 : 3,
      runSpacing: 5,
      children: [
        for (final (icon, label, sheet) in [
          ('translate', '译文对照', ReaderSheet.translation),
          ('sparkles', '摘要', ReaderSheet.summary),
          ('chat', '问问文章', ReaderSheet.ask),
        ])
          ReaderTap(
            onTap: () => _sheet(sheet),
            color: sheet == ReaderSheet.translation && c.bilingual
                ? colors.accentSoft
                : null,
            radius: 6,
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 8 : 6,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReaderIcon(icon, size: 12, color: const Color(0xff77876b)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: mobile ? 10 : 9,
                    color: const Color(0xff77876b),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 23),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= 395 && !mobile
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [sourceTabs, actions],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [sourceTabs, const SizedBox(height: 9), actions],
              ),
      ),
    );
  }

  Widget _body() {
    final font = c.fontSize + (mobile ? 1 : 0);
    double trailingSpace(int index) =>
        c.bilingual && index < c.currentEnglish.length ? 25 : font * 1.4;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'MorssSans',
            color: colors.bodyText,
            fontSize: font,
            height: mobile ? 2.1 : 2.15,
            letterSpacing: .2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, paragraph) in c.currentParagraphs.indexed) ...[
                if (index == 2)
                  Padding(
                    // Adjacent paragraph and heading margins collapse in A.
                    padding: EdgeInsets.only(
                      top: math.max(0, 27 - trailingSpace(index - 1)),
                      bottom: 14,
                    ),
                    child: Text(
                      '给日常，留一点空白',
                      style: TextStyle(
                        fontFamily: 'MorssSerif',
                        fontSize: font * 1.2,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                  ),
                Padding(
                  key: _paragraphs[index],
                  padding: EdgeInsets.only(
                    bottom: c.bilingual && index < c.currentEnglish.length
                        ? math.max(0, font * 1.4 - 12)
                        : font * 1.4,
                  ),
                  child: index == 0 && paragraph.isNotEmpty
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: paragraph.characters.first,
                                style: TextStyle(fontSize: font * 1.15),
                              ),
                              TextSpan(
                                text: paragraph.characters.skip(1).toString(),
                              ),
                            ],
                          ),
                          key: ValueKey('paragraph-$index'),
                        )
                      : Text(paragraph, key: ValueKey('paragraph-$index')),
                ),
                if (c.bilingual && index < c.currentEnglish.length)
                  Container(
                    key: ValueKey('translation-$index'),
                    margin: const EdgeInsets.only(bottom: 25),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: colors.wash,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENGLISH · 段落 ${index + 1}',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1,
                            color: colors.accent.withValues(alpha: .65),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          c.currentEnglish[index],
                          style: TextStyle(
                            fontSize: font * .9,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (c.selected.id == 'quiet' && index == 2)
                  Container(
                    margin: EdgeInsets.only(
                      top: math.max(0, 27 - trailingSpace(index)),
                      bottom: 27,
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 3, 0, 3),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xffb8caa7), width: 2),
                      ),
                    ),
                    child: Text(
                      '不必读完所有的文章，只要记得为什么开始。',
                      style: TextStyle(
                        fontFamily: 'MorssSerif',
                        fontSize: font * 1.08,
                        color: const Color(0xff6c805f),
                      ),
                    ),
                  ),
              ],
              Padding(
                padding: EdgeInsets.only(
                  top: math.max(
                    0,
                    35 - trailingSpace(c.currentParagraphs.length - 1),
                  ),
                ),
                child: const Text(
                  '· · ·',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'MorssSerif',
                    fontSize: 17,
                    color: Color(0xff91a285),
                    letterSpacing: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(String text) => Container(
    margin: const EdgeInsets.symmetric(vertical: 14),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: colors.wash,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, height: 1.9, color: colors.accent),
    ),
  );

  Widget _missingBody() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
    child: Column(
      children: [
        Text(
          c.isDemo ? '本机正文缓存已清理' : '订阅未提供可读正文',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 9),
        Text(
          c.isDemo ? '保留的标题仍然可搜，归档版本也仍可阅读。' : '可查看原网页，已保存的历史归档仍可阅读。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.8, color: colors.muted),
        ),
        const SizedBox(height: 17),
        ReaderButton(
          text: c.isDemo ? '从配对设备补取正文' : '查看原网页',
          onPressed: () =>
              c.isDemo ? _notice(c.refillBody()) : _sheet(ReaderSheet.original),
        ),
      ],
    ),
  );

  Widget _footer() => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 350;
      return Container(
        height: mobile ? 44 : 48,
        padding: EdgeInsets.symmetric(horizontal: mobile || narrow ? 12 : 24),
        decoration: BoxDecoration(
          color: colors.glass,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Row(
          children: [
            Text(
              '${c.progress.round()}%',
              style: TextStyle(fontSize: 9, color: colors.muted),
            ),
            if (!narrow) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: mobile ? 40 : 65,
                child: LinearProgressIndicator(
                  value: math.min(c.progress / 100, 1),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: colors.line,
                  color: const Color(0xff94a97d),
                ),
              ),
            ],
            const Spacer(),
            ReaderIconButton(
              icon: 'text',
              label: '阅读字号和外观',
              size: 30,
              iconSize: 13,
              onPressed: () => _sheet(ReaderSheet.appearance),
            ),
            _footerAction(
              c.selected.isRead ? 'checkcircle' : 'check',
              c.selected.isRead ? '已读' : '标为已读',
              () => _notice(c.toggleRead()),
              narrow,
            ),
            _footerAction(
              'external',
              '原网页',
              () => _sheet(ReaderSheet.original),
              narrow,
            ),
          ],
        ),
      );
    },
  );

  Widget _footerAction(
    String icon,
    String label,
    VoidCallback action,
    bool narrow,
  ) => Tooltip(
    message: label,
    child: ReaderTap(
      label: label,
      onTap: action,
      padding: EdgeInsets.all(mobile ? 7 : 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != 'external' || narrow) ReaderIcon(icon, size: 13),
          if (!narrow) ...[
            if (icon != 'external') const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: mobile ? 9 : 10, color: colors.muted),
            ),
            if (icon == 'external') ...[
              const SizedBox(width: 5),
              ReaderIcon(icon, size: 13),
            ],
          ],
        ],
      ),
    ),
  );
}
