import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/reader_theme.dart';
import '../../design/reader_widgets.dart';
import 'reader_controller.dart';
import 'reader_models.dart';
import 'reader_pane.dart';
import 'reader_sheets.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.controller});
  final ReaderController controller;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final TextEditingController _search;
  final _searchFocus = FocusNode(debugLabel: 'Article search');
  ReaderController get c => widget.controller;
  ReaderColors get colors => ReaderColors.of(context);

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: c.query);
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_search.text != c.query) {
      _search.value = TextEditingValue(
        text: c.query,
        selection: TextSelection.collapsed(offset: c.query.length),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _open(ReaderSheet kind) =>
      ReaderSheets.show(context, controller: c, initial: kind);
  void _notice(String message) => showReaderNotice(context, message);
  Future<void> _refresh() async {
    final message = await c.refreshSubscriptions();
    if (mounted) {
      _notice(message.length <= 180 ? message : '部分订阅未更新，请点击列表中的提示查看原因。');
    }
  }

  void _showFeedErrors() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('订阅刷新未全部完成'),
      content: SingleChildScrollView(child: Text(c.feedError ?? '没有刷新错误。')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    ),
  );

  String get _dateLabel {
    if (c.isDemo) return '9 月 12 日 · 星期六';
    final now = DateTime.now();
    return '${now.month} 月 ${now.day} 日 · 星期${'一二三四五六日'[now.weekday - 1]}';
  }

  void _focusSearch() {
    c.backToList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width <= ReaderMetrics.mobileBreakpoint;
    return PopScope<void>(
      canPop: !mobile || !c.readerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && c.readerOpen) c.backToList();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true):
              _focusSearch,
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
              _focusSearch,
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              (colors.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: colors.background,
                  ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            bottomNavigationBar: c.storageError == null
                ? null
                : SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        c.storageError!,
                        key: const ValueKey('storage-error'),
                        style: TextStyle(color: colors.accent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
            body: Stack(
              children: [
                Positioned.fill(child: _AmbientBackground(dark: colors.dark)),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ReaderMetrics.maxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          mobile ? 10 : 24,
                          mobile ? 39 : 52,
                          mobile ? 10 : 24,
                          mobile ? 73 : 80,
                        ),
                        child: GlassPanel(
                          key: const ValueKey('reader-shell'),
                          radius: mobile
                              ? ReaderMetrics.mobileShellRadius
                              : ReaderMetrics.shellRadius,
                          blur: ReaderMetrics.shellBlur,
                          shadow: true,
                          child: mobile
                              ? _mobile()
                              : Row(
                                  children: [
                                    SizedBox(
                                      width: ReaderMetrics.sidebar(size.width),
                                      child: _sidebar(),
                                    ),
                                    SizedBox(
                                      width: ReaderMetrics.inbox(size.width),
                                      child: _inbox(false),
                                    ),
                                    Expanded(
                                      child: c.hasSelection
                                          ? ReaderPane(
                                              controller: c,
                                              mobile: false,
                                              onSheet: _open,
                                            )
                                          : const Center(
                                              key: ValueKey('empty-reader'),
                                              child: Padding(
                                                padding: EdgeInsets.all(24),
                                                child: Text(
                                                  '选择一篇文章，开始阅读',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobile() => c.readerOpen && c.hasSelection
      ? ReaderPane(controller: c, mobile: true, onSheet: _open)
      : Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 65),
                child: _inbox(true),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 84,
              child: _mobileNavigation(),
            ),
          ],
        );

  Widget _sidebar() {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width <= ReaderMetrics.compactBreakpoint;
    final edge = compact ? 10.0 : 16.0;
    return Container(
      key: const ValueKey('reader-sidebar'),
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      padding: EdgeInsets.fromLTRB(edge, 30, edge, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MorssBrand(onTap: () => c.navigate(ReaderView.today)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 15, 12, 26),
            child: Text(
              '阅读，回到自己。',
              style: TextStyle(
                color: colors.muted,
                fontSize: 10,
                height: 1.5,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 5),
                child: Column(
                  children: [
                    for (final (view, icon, label) in [
                      (ReaderView.today, 'sun', '今日阅读'),
                      (ReaderView.unread, 'inbox', '全部未读'),
                      (ReaderView.favorites, 'favorite', '我的收藏'),
                      (ReaderView.archives, 'archive', '保留归档'),
                    ]) ...[
                      _nav(
                        label: label,
                        leading: ReaderIcon(
                          icon,
                          size: 18,
                          color:
                              c.view == view &&
                                  c.category == null &&
                                  c.sourceId == null
                              ? colors.accent
                              : colors.muted,
                        ),
                        count: c.count(view).toString(),
                        active:
                            c.view == view &&
                            c.category == null &&
                            c.sourceId == null,
                        onTap: () => c.navigate(view),
                      ),
                      const SizedBox(height: 4),
                    ],
                    _navLabel('我的分类'),
                    for (final category in ['技术', '设计', '生活']) ...[
                      _nav(
                        label: category,
                        leading: const ReaderIcon('folder', size: 18),
                        count: c.articles
                            .where(
                              (article) =>
                                  c.sourceOf(article).category == category,
                            )
                            .length
                            .toString(),
                        active: c.category == category,
                        onTap: () => c.selectCategory(category),
                      ),
                      const SizedBox(height: 4),
                    ],
                    _navLabel('订阅源', add: true),
                    for (final source in c.sources) ...[
                      _nav(
                        label: source.name,
                        leading: SourceBadge(source),
                        count: c.articles
                            .where(
                              (article) =>
                                  article.sourceId == source.id &&
                                  !article.isRead,
                            )
                            .length
                            .toString(),
                        active: c.sourceId == source.id,
                        onTap: () => c.selectSource(source.id),
                        hideZero: true,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _nav(
            label: '自动化',
            leading: const ReaderIcon('auto', size: 18),
            count: !c.isDemo
                ? '尚未开放'
                : c.automationPaused
                ? '已暂停'
                : c.rules.where((rule) => rule.enabled).length.toString(),
            onTap: () => _open(ReaderSheet.rules),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 13),
            child: ReaderTap(
              onTap: () => _open(ReaderSheet.devices),
              color: colors.dark
                  ? const Color(0x24405039)
                  : const Color(0x75ffffff),
              border: colors.dark
                  ? const Color(0x1ba9bea1)
                  : const Color(0x99ffffff),
              radius: 15,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ReaderIcon('link', size: 16, color: colors.accent),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          !c.isDemo
                              ? '本机保存，随时阅读'
                              : c.networkAvailable
                              ? '设备间，继续阅读'
                              : '离线，也能安心阅读',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 5),
                    child: Text(
                      !c.isDemo
                          ? '跨设备同步尚未开放'
                          : c.networkAvailable
                          ? '${c.syncLabel} · ${c.lastSync}'
                          : '本机内容仍然可用',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: colors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 29,
                  height: 29,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.dark
                        ? const Color(0xff425239)
                        : const Color(0xffe0e6d9),
                  ),
                  child: Text(
                    'M',
                    style: TextStyle(
                      fontFamily: 'MorssSerif',
                      fontSize: 15,
                      color: colors.dark
                          ? const Color(0xffc4d0ba)
                          : const Color(0xff7c8975),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '我的阅读空间',
                    style: TextStyle(color: colors.muted, fontSize: 11),
                  ),
                ),
                ReaderIconButton(
                  icon: 'settings',
                  label: '打开设置',
                  onPressed: () => _open(ReaderSheet.settings),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLabel(String label, {bool add = false}) => Padding(
    padding: EdgeInsets.fromLTRB(12, add ? 19 : 21, 12, 10),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.faint,
            fontSize: 10,
            letterSpacing: 1.3,
          ),
        ),
        const Spacer(),
        if (add)
          ReaderIconButton(
            icon: 'plus',
            label: '添加订阅源',
            size: 22,
            iconSize: 13,
            onPressed: () => _open(ReaderSheet.subscribe),
          ),
      ],
    ),
  );

  Widget _nav({
    required String label,
    required Widget leading,
    required String count,
    required VoidCallback onTap,
    bool active = false,
    bool hideZero = false,
  }) => ReaderTap(
    onTap: onTap,
    radius: 12,
    color: active ? colors.surface : null,
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width <= ReaderMetrics.compactBreakpoint
          ? 9
          : 12,
      10,
      12,
      10,
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 23),
      child: Row(
        children: [
          leading,
          SizedBox(
            width:
                MediaQuery.sizeOf(context).width <=
                    ReaderMetrics.compactBreakpoint
                ? 8
                : 11,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize:
                    MediaQuery.sizeOf(context).width <=
                        ReaderMetrics.compactBreakpoint
                    ? 12
                    : 13,
                color: active
                    ? colors.accent
                    : colors.dark
                    ? const Color(0xff99a591)
                    : const Color(0xff68766c),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (!hideZero || count != '0') ...[
            const SizedBox(width: 5),
            Container(
              decoration: active
                  ? BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              padding: active
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1)
                  : EdgeInsets.zero,
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? colors.accent : colors.faint,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _inbox(bool mobile) {
    final matches = c.visibleArticles;
    final compact =
        !mobile &&
        MediaQuery.sizeOf(context).width <= ReaderMetrics.compactBreakpoint;
    return Container(
      key: const ValueKey('article-list'),
      decoration: BoxDecoration(
        border: mobile ? null : Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              mobile || compact ? 21 : 24,
              mobile
                  ? 19
                  : compact
                  ? 26
                  : 30,
              mobile || compact ? 21 : 24,
              mobile ? 9 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mobile) ...[
                  Row(
                    children: [
                      MorssBrand(
                        mobile: true,
                        onTap: () => c.navigate(ReaderView.today),
                      ),
                      const Spacer(),
                      ReaderIconButton(
                        icon: 'plus',
                        label: '添加订阅',
                        onPressed: () => _open(ReaderSheet.subscribe),
                      ),
                      const SizedBox(width: 4),
                      ReaderIconButton(
                        icon: 'settings',
                        label: '设置',
                        onPressed: () => _open(ReaderSheet.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 21),
                ],
                Text(
                  _dateLabel,
                  style: TextStyle(
                    fontSize: mobile ? 9 : 10,
                    height: mobile ? 13 / 9 : 1.5,
                    letterSpacing: 1.5,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: mobile ? 30 : 27,
                          letterSpacing: -1.1,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                    ReaderIconButton(
                      icon: 'refresh',
                      label: '刷新订阅',
                      onPressed: _refresh,
                    ),
                  ],
                ),
                SizedBox(height: mobile ? 14 : 17),
                _searchBox(mobile),
                SizedBox(height: mobile ? 12 : 14),
                Row(
                  children: [
                    for (final (filter, label) in [
                      (ArticleFilter.all, '全部'),
                      (ArticleFilter.unread, '未读'),
                      (ArticleFilter.favorites, '收藏'),
                    ]) ...[
                      ReaderTap(
                        onTap: () => c.setFilter(filter),
                        color: c.filter == filter ? colors.surface : null,
                        radius: 7,
                        padding: EdgeInsets.symmetric(
                          horizontal: mobile ? 13 : 11,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                height: 16 / 11,
                                color: c.filter == filter
                                    ? colors.accent
                                    : colors.muted,
                                fontWeight: c.filter == filter
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (filter == ArticleFilter.all) ...[
                              const SizedBox(width: 4),
                              Text(
                                matches.length.toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: const PageStorageKey('article-list-scroll'),
              padding: EdgeInsets.fromLTRB(
                mobile ? 11 : 13,
                0,
                (mobile ? 11 : 13) + 5,
                mobile ? 20 : 15,
              ),
              children: [
                if (!c.isDemo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: ReaderTap(
                      onTap: c.feedError == null ? null : _showFeedErrors,
                      child: Text(
                        c.feedError == null ? c.refreshLabel : '部分订阅未更新 · 查看原因',
                        style: TextStyle(
                          fontSize: 11,
                          color: c.feedError == null
                              ? colors.muted
                              : colors.accent,
                        ),
                      ),
                    ),
                  ),
                if (c.hasSelection &&
                    c.view == ReaderView.today &&
                    c.query.isEmpty &&
                    c.sourceId == null)
                  _resumeCard(mobile),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.query.isNotEmpty
                              ? '本机搜索结果'
                              : c.view == ReaderView.archives
                              ? '保留的内容 · 不随取消收藏删除'
                              : '为你留着的好内容',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.5,
                            color: colors.faint,
                          ),
                        ),
                      ),
                      ReaderTap(
                        onTap: () => _notice(c.markVisibleRead()),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '全部已读',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.5,
                            color: colors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (matches.isEmpty) _emptyList(),
                for (final hit in matches)
                  Padding(
                    padding: EdgeInsets.only(bottom: mobile ? 3 : 5),
                    child: _articleCard(hit, mobile),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox(bool mobile) => Container(
    height: mobile ? 39 : 37,
    decoration: BoxDecoration(
      color: colors.dark ? const Color(0x39162219) : const Color(0x61d6e1d0),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: colors.line.withValues(alpha: .04)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 11),
    child: Row(
      children: [
        const ReaderIcon('search', size: 15, color: Color(0xff85927e)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            key: const ValueKey('article-search'),
            controller: _search,
            focusNode: _searchFocus,
            onChanged: c.search,
            textInputAction: TextInputAction.search,
            style: TextStyle(fontSize: mobile ? 12 : 11, height: 1.4),
            decoration: InputDecoration(
              hintText: '搜索文章、正文与归档',
              hintStyle: TextStyle(
                color: colors.faint,
                fontSize: mobile ? 12 : 11,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
            ),
          ),
        ),
        if (_search.text.isNotEmpty)
          ReaderIconButton(
            icon: 'close',
            label: '清空搜索',
            size: 23,
            iconSize: 12,
            onPressed: () {
              _search.clear();
              c.search('');
            },
          )
        else if (!mobile)
          Text('⌘ K', style: TextStyle(fontSize: 9, color: colors.faint)),
      ],
    ),
  );

  Widget _resumeCard(bool mobile) {
    final article = c.resumeArticle;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, mobile ? 7 : 5, 10, mobile ? 19 : 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colors.dark ? const Color(0xff3c4c34) : null,
          gradient: colors.dark
              ? null
              : const LinearGradient(
                  begin: Alignment(-.866, -.5),
                  end: Alignment(.866, .5),
                  colors: [Color(0xa3dae7cd), Color(0x94e7edd7)],
                ),
        ),
        child: ReaderTap(
          key: const ValueKey('resume-reading'),
          onTap: c.resume,
          radius: 12,
          border: colors.dark
              ? const Color(0x1ba9bea1)
              : const Color(0x94ffffff),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                height: 29,
                width: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x7affffff),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const ReaderIcon(
                  'book',
                  size: 15,
                  color: Color(0xff62815b),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '接着上次 · 已读 ${article.progress.round()}%',
                            style: TextStyle(
                              fontSize: mobile ? 10 : 9,
                              height: mobile ? 1.5 : 13 / 9,
                              color: colors.dark
                                  ? const Color(0xff91a67f)
                                  : const Color(0xff7a9070),
                              letterSpacing: .3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: mobile ? 11 : 10,
                        height: 1.6,
                        color: colors.dark
                            ? const Color(0xffb9c9ac)
                            : colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              const ReaderIcon('chevron', size: 13, color: Color(0xff8aa077)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _articleCard(ArticleHit hit, bool mobile) {
    final article = hit.article;
    final source = c.sourceOf(article);
    final selected = article.id == c.selectedId;
    final width = MediaQuery.sizeOf(context).width;
    final compact = !mobile && width <= ReaderMetrics.compactBreakpoint;
    final large = width >= ReaderMetrics.largeBreakpoint;
    final thumb = mobile
        ? (width <= 370 ? 62.0 : 73.0)
        : compact
        ? 55.0
        : large
        ? 78.0
        : 68.0;
    return ReaderTap(
      key: ValueKey('article-${article.id}'),
      onTap: () {
        _searchFocus.unfocus();
        c.openArticle(hit);
      },
      radius: 14,
      color: selected ? colors.surface : null,
      border: selected
          ? colors.dark
                ? const Color(0x15a9bea1)
                : const Color(0xe6ffffff)
          : Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 13 : 14,
        vertical: mobile
            ? 15
            : large
            ? 20
            : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SourceBadge(source, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  source.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: mobile ? 10 : 9,
                    color: colors.muted,
                  ),
                ),
              ),
              Text(
                article.timeLabel,
                style: TextStyle(fontSize: 9, color: colors.faint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: mobile || large ? 15 : 14,
                        fontWeight: FontWeight.w600,
                        height: 1.65,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hit.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: mobile ? 11 : 10,
                        color: colors.muted,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: mobile ? 12 : 11),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: article.image.isEmpty
                      ? Container(
                          height: thumb,
                          width: thumb,
                          color: colors.wash,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.article_outlined,
                            size: 28,
                            color: colors.faint,
                          ),
                        )
                      : Image.asset(
                          'assets/images/${article.image}.jpg',
                          height: mobile && width <= 370
                              ? 68
                              : compact
                              ? 62
                              : thumb,
                          width: thumb,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusDot(active: !article.isRead),
              const SizedBox(width: 6),
              Text(
                '${article.minutes} 分钟阅读',
                style: TextStyle(fontSize: 9, color: colors.faint),
              ),
              const Spacer(),
              if (article.archives.isNotEmpty) ...[
                const ReaderIcon('archive', size: 10, color: Color(0xff829672)),
                const SizedBox(width: 4),
                Text(
                  article.archives.length > 1
                      ? '${article.archives.length} 份归档'
                      : '已离线保存',
                  style: const TextStyle(fontSize: 9, color: Color(0xff829672)),
                ),
              ] else if (article.isFavorite)
                const Text(
                  '暂无离线归档',
                  style: TextStyle(fontSize: 9, color: Color(0xff829672)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyList() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
    child: Column(
      children: [
        ReaderIcon(
          c.view == ReaderView.archives ? 'archive' : 'book',
          size: 34,
          color: colors.faint,
        ),
        const SizedBox(height: 13),
        Text(
          !c.isDemo && c.sources.isEmpty
              ? '从第一个订阅开始'
              : c.query.isNotEmpty
              ? '还没有找到这篇文章'
              : '这里，留给下一篇好文章',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 9),
        Text(
          !c.isDemo && c.sources.isEmpty
              ? '添加 RSS 或 Atom，让喜欢的内容来到这里。'
              : !c.isDemo && c.articles.isEmpty
              ? '订阅源暂时没有文章，可以稍后刷新。'
              : c.view == ReaderView.archives
              ? '归档会保留正文，取消收藏也能在这里找到。'
              : '换个关键词，或查看全部文章。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.muted, height: 1.8),
        ),
        const SizedBox(height: 17),
        ReaderButton(
          text: !c.isDemo && c.sources.isEmpty
              ? '添加第一个订阅'
              : !c.isDemo && c.articles.isEmpty
              ? '刷新订阅'
              : '查看全部文章',
          onPressed: () => !c.isDemo && c.sources.isEmpty
              ? _open(ReaderSheet.subscribe)
              : !c.isDemo && c.articles.isEmpty
              ? _refresh()
              : c.navigate(ReaderView.today),
        ),
      ],
    ),
  );

  Widget _mobileNavigation() => SizedBox(
    height: 56,
    child: GlassPanel(
      key: const ValueKey('mobile-navigation'),
      radius: 20,
      blur: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (view, icon, label) in [
            (ReaderView.today, 'sun', '阅读'),
            (ReaderView.favorites, 'favorite', '收藏'),
            (ReaderView.archives, 'archive', '归档'),
            (null, 'laptop', '设备'),
          ])
            SizedBox(
              width: 57,
              height: 43,
              child: ReaderTap(
                onTap: () => view == null
                    ? _open(ReaderSheet.devices)
                    : c.navigate(view),
                color: view == c.view ? const Color(0x25a6c193) : null,
                radius: 13,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ReaderIcon(
                      icon,
                      size: 18,
                      color: view == c.view ? colors.accent : colors.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: view == c.view ? colors.accent : colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      Widget blob(double w, double h, Color color) => ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 72, sigmaY: 72),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
            color: color.withValues(alpha: dark ? .1 : 1),
          ),
        ),
      );
      return ClipRect(
        child: Stack(
          children: [
            Positioned(
              right: -.12 * width,
              top: -.27 * height,
              child: blob(.62 * width, .60 * height, const Color(0xfff6efd3)),
            ),
            Positioned(
              left: -.19 * width,
              bottom: -.28 * height,
              child: blob(.44 * width, .76 * height, const Color(0xffb6cab9)),
            ),
            Positioned(
              right: 0,
              bottom: -.22 * height,
              child: blob(.54 * width, .45 * height, const Color(0xffccd5e1)),
            ),
          ],
        ),
      );
    },
  );
}
