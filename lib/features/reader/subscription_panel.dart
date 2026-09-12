import 'package:flutter/material.dart';

import '../../data/subscription_files.dart';
import '../../design/reader_theme.dart';
import '../../design/reader_widgets.dart';
import 'reader_controller.dart';
import 'reader_models.dart';

class SubscriptionPanel extends StatefulWidget {
  const SubscriptionPanel({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onClose,
  });

  final ReaderController controller;
  final VoidCallback onAdd;
  final VoidCallback onClose;

  @override
  State<SubscriptionPanel> createState() => _SubscriptionPanelState();
}

class _SubscriptionPanelState extends State<SubscriptionPanel> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  String? _editingId;
  String? _message;
  bool _confirmUnsubscribe = false;
  bool _fileBusy = false;

  ReaderController get c => widget.controller;
  ReaderColors get colors => ReaderColors.of(context);

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    super.dispose();
  }

  void _edit(FeedSource source) {
    setState(() {
      _editingId = source.id;
      _name.text = source.name;
      _category.text = source.category;
      _message = null;
      _confirmUnsubscribe = false;
    });
  }

  Future<void> _import() async {
    if (_fileBusy) return;
    setState(() {
      _fileBusy = true;
      _message = null;
    });
    try {
      final text = await SubscriptionFiles.pickOpml();
      if (!mounted) return;
      _message = text == null ? '已取消导入。' : c.importOpml(text);
    } on FormatException {
      if (mounted) _message = '无法读取 OPML，请检查文件编码和大小（最多 8 MB）。已有订阅保留。';
    } catch (_) {
      if (mounted) _message = '无法读取文件，请重新选择 OPML 文件。已有订阅保留。';
    } finally {
      if (mounted) setState(() => _fileBusy = false);
    }
  }

  Future<void> _export() async {
    if (_fileBusy) return;
    setState(() {
      _fileBusy = true;
      _message = null;
    });
    try {
      final saved = await SubscriptionFiles.saveOpml(c.exportOpml());
      if (mounted) _message = saved ? 'OPML 已导出。' : '已取消导出。';
    } catch (_) {
      if (mounted) _message = '无法导出 OPML，请检查目标位置和可用空间后重试。';
    } finally {
      if (mounted) setState(() => _fileBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = c.sources
        .where((source) => source.id == _editingId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_message != null && _message != c.storageError) ...[
          Text(
            _message!,
            key: const ValueKey('subscription-feedback'),
            style: TextStyle(fontSize: 12, height: 1.8, color: colors.muted),
          ),
          const SizedBox(height: 16),
        ],
        if (_fileBusy) ...[
          const Text('正在处理文件…', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
        ],
        if (source == null)
          ..._overview()
        else if (_confirmUnsubscribe)
          ..._confirmation(source)
        else
          ..._editor(source),
      ],
    );
  }

  List<Widget> _overview() => [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ReaderButton(
          text: '添加 RSS / Atom',
          icon: 'plus',
          onPressed: _fileBusy ? null : widget.onAdd,
        ),
        ReaderButton(
          text: '导入 OPML',
          icon: 'folder',
          onPressed: _fileBusy ? null : _import,
        ),
        ReaderButton(
          text: '导出 OPML',
          icon: 'download',
          onPressed: _fileBusy ? null : _export,
        ),
        ReaderButton(
          text: c.isFetchingFeeds ? '正在刷新…' : '刷新订阅',
          icon: 'refresh',
          onPressed: _fileBusy || c.isFetchingFeeds
              ? null
              : () async {
                  final message = await c.refreshSubscriptions();
                  if (mounted) setState(() => _message = message);
                },
        ),
      ],
    ),
    const SizedBox(height: 12),
    Text(
      'OPML 只包含订阅清单。导入后刷新以获取文章；正文、阅读位置和归档不包含在此文件中。',
      style: TextStyle(fontSize: 11, height: 1.8, color: colors.muted),
    ),
    if (c.categories.isNotEmpty) ...[
      const SizedBox(height: 20),
      const Text('按分类阅读', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in c.categories)
            ReaderButton(
              text: category,
              icon: 'folder',
              onPressed: () {
                c.selectCategory(category);
                widget.onClose();
              },
            ),
        ],
      ),
    ],
    const SizedBox(height: 20),
    if (c.sources.isEmpty)
      Text('尚未添加订阅。', style: TextStyle(fontSize: 12, color: colors.muted))
    else
      GlassPanel(
        radius: 15,
        child: Column(
          children: [
            for (final source in c.sources)
              ReaderTap(
                onTap: _fileBusy ? null : () => _edit(source),
                radius: 10,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    SourceBadge(source),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            source.category,
                            style: TextStyle(fontSize: 11, color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ReaderIcon('chevron', size: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
  ];

  List<Widget> _editor(FeedSource source) => [
    TextField(
      key: const ValueKey('managed-feed-name'),
      controller: _name,
      style: const TextStyle(fontSize: 12),
      decoration: const InputDecoration(labelText: '订阅源名称'),
    ),
    const SizedBox(height: 16),
    TextField(
      key: const ValueKey('managed-feed-category'),
      controller: _category,
      style: const TextStyle(fontSize: 12),
      decoration: const InputDecoration(
        labelText: '分类',
        helperText: '可输入新的分类，留空归入未分类',
      ),
    ),
    const SizedBox(height: 18),
    SelectableText(
      source.url ?? '',
      style: TextStyle(fontSize: 12, color: colors.muted),
    ),
    const SizedBox(height: 8),
    Text('更换地址时请添加新的订阅源。', style: TextStyle(fontSize: 11, color: colors.muted)),
    const SizedBox(height: 18),
    ReaderButton(
      text: '保存订阅',
      primary: true,
      onPressed: () {
        final error = c.updateSubscription(
          source.id,
          _name.text,
          _category.text,
        );
        setState(() {
          if (error == null) _editingId = null;
          _message = error ?? '订阅已保存。';
        });
      },
    ),
    const SizedBox(height: 10),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ReaderButton(
          text: '阅读此订阅',
          icon: 'book',
          onPressed: () {
            c.selectSource(source.id);
            widget.onClose();
          },
        ),
        ReaderButton(
          text: '退订',
          danger: true,
          onPressed: () => setState(() {
            _confirmUnsubscribe = true;
            _message = null;
          }),
        ),
        ReaderButton(
          text: '返回列表',
          onPressed: () => setState(() {
            _editingId = null;
            _message = null;
          }),
        ),
      ],
    ),
  ];

  List<Widget> _confirmation(FeedSource source) => [
    Text(
      source.name,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 12),
    const Text(
      '停止刷新此订阅。已保存文章、阅读位置、已读状态、收藏和归档都会保留。',
      style: TextStyle(fontSize: 12, height: 1.8),
    ),
    const SizedBox(height: 20),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ReaderButton(
          text: '保留订阅',
          onPressed: () => setState(() => _confirmUnsubscribe = false),
        ),
        ReaderButton(
          text: '确认退订',
          danger: true,
          onPressed: () {
            final error = c.unsubscribe(source.id);
            setState(() {
              if (error == null) {
                _editingId = null;
                _confirmUnsubscribe = false;
              }
              _message = error ?? '已退订，保存的阅读内容仍可访问。';
            });
          },
        ),
      ],
    ),
  ];
}
