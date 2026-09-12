import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/reader_theme.dart';
import '../../design/reader_widgets.dart';
import 'reader_controller.dart';
import 'reader_models.dart';
import 'subscription_panel.dart';

enum ReaderSheet {
  settings,
  appearance,
  devices,
  pair,
  revoke,
  archives,
  deleteArchive,
  translation,
  summary,
  ask,
  service,
  modelTest,
  rules,
  backup,
  exportBackup,
  storage,
  cleanup,
  subscribe,
  subscriptions,
  articleMenu,
  original;

  bool get availableInLibrary => switch (this) {
    settings ||
    appearance ||
    archives ||
    deleteArchive ||
    subscribe ||
    subscriptions ||
    articleMenu ||
    original => true,
    _ => false,
  };
}

abstract final class ReaderSheets {
  static Future<void> show(
    BuildContext context, {
    required ReaderController controller,
    required ReaderSheet initial,
  }) async {
    GeneratedResult? summary;
    if (!controller.hasSelection &&
        const {
          ReaderSheet.archives,
          ReaderSheet.deleteArchive,
          ReaderSheet.articleMenu,
          ReaderSheet.original,
        }.contains(initial)) {
      showReaderNotice(context, '先选择一篇文章。');
      return;
    }
    if (initial == ReaderSheet.summary && controller.isDemo) {
      final outcome = controller.generate(GenerationTask.summary);
      if (outcome.result == null) {
        showReaderNotice(context, outcome.message!);
        return;
      }
      summary = outcome.result;
    }
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭面板',
      barrierColor: const Color(0x3b1f2d21),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _ReaderSheetDialog(
            controller: controller,
            initial: initial,
            summary: summary,
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

class _ReaderSheetDialog extends StatefulWidget {
  const _ReaderSheetDialog({
    required this.controller,
    required this.initial,
    this.summary,
  });
  final ReaderController controller;
  final ReaderSheet initial;
  final GeneratedResult? summary;

  @override
  State<_ReaderSheetDialog> createState() => _ReaderSheetDialogState();
}

class _ReaderSheetDialogState extends State<_ReaderSheetDialog> {
  late ReaderSheet _kind;
  late final TextEditingController _url;
  late final TextEditingController _limit;
  final _key = TextEditingController();
  final _manualModel = TextEditingController();
  final _pairCode = TextEditingController();
  final _question = TextEditingController();
  final _feedName = TextEditingController();
  final _feedUrl = TextEditingController();
  final _feedCategory = TextEditingController(text: '生活');
  final _password = TextEditingController();
  final _scroll = ScrollController();
  String _category = '生活';
  String? _archiveToDelete;
  PairedDevice? _deviceToRevoke;
  GeneratedResult? _answer;
  String? _feedback;

  ReaderController get c => widget.controller;
  ReaderColors get colors => ReaderColors.of(context);

  @override
  void initState() {
    super.initState();
    _kind = widget.initial;
    _url = TextEditingController(text: c.service.url);
    _limit = TextEditingController(text: '${c.service.limit}');
  }

  @override
  void dispose() {
    for (final controller in [
      _url,
      _limit,
      _key,
      _manualModel,
      _pairCode,
      _question,
      _feedName,
      _feedUrl,
      _feedCategory,
      _password,
    ]) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _go(ReaderSheet kind) {
    FocusScope.of(context).unfocus();
    setState(() {
      _kind = kind;
      _feedback = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _notice(String message, {bool close = false}) {
    if (close) {
      showReaderNotice(context, message);
      _close();
    } else {
      setState(() => _feedback = message);
    }
  }

  String get _title => switch (_kind) {
    ReaderSheet.settings => '你的阅读，随你喜欢',
    ReaderSheet.appearance => '读得舒服一点',
    ReaderSheet.devices => '在另一台设备，接着读',
    ReaderSheet.pair => '让设备认出彼此',
    ReaderSheet.revoke => '撤销这台设备的授权？',
    ReaderSheet.archives => '值得留下的版本',
    ReaderSheet.deleteArchive => '删除这份归档？',
    ReaderSheet.translation => '换一种语言，继续阅读',
    ReaderSheet.summary => '先读一个小摘要',
    ReaderSheet.ask => '和这篇文章，聊一聊',
    ReaderSheet.service => '把喜欢的模型接进来',
    ReaderSheet.modelTest => '测试当前模型',
    ReaderSheet.rules => '让小事，自动发生',
    ReaderSheet.backup => '把阅读，好好留下',
    ReaderSheet.exportBackup => '为导出的备份设个密码',
    ReaderSheet.storage => '留住喜欢的，清理临时的',
    ReaderSheet.cleanup => '清理本机普通缓存？',
    ReaderSheet.subscribe => '把喜欢的声音，加进来',
    ReaderSheet.subscriptions => '你的订阅',
    ReaderSheet.articleMenu => '这篇文章',
    ReaderSheet.original => '原网页入口',
  };

  String get _articleIntro =>
      '${c.selected.title} · '
      '${c.currentKind == BodyKind.rss ? 'RSS 摘要' : '当前全文'}';

  String get _intro => !c.isDemo && !_kind.availableInLibrary
      ? '此功能尚未开放。当前版本支持本机订阅与离线阅读。'
      : switch (_kind) {
          ReaderSheet.settings => '把工具调成舒服的样子，然后回到内容。',
          ReaderSheet.appearance => '外观随系统切换，字号只影响你的阅读体验。',
          ReaderSheet.devices => '设备处于同一局域网、两端应用同时打开时，就能交换阅读状态和归档。',
          ReaderSheet.pair => '在另一台设备选择“输入配对码”，确认后开始连接。此处使用固定演示码。',
          ReaderSheet.revoke => _deviceToRevoke?.name ?? '',
          ReaderSheet.archives => '${c.selected.title}。收藏标记与实际保存的归档分别管理。',
          ReaderSheet.deleteArchive ||
          ReaderSheet.articleMenu ||
          ReaderSheet.original => c.selected.title,
          ReaderSheet.translation ||
          ReaderSheet.summary ||
          ReaderSheet.ask => _articleIntro,
          ReaderSheet.service => '填写你自己的服务地址与模型。此页面只演示配置状态，不发送网络请求。',
          ReaderSheet.modelTest =>
            c.service.model.isEmpty ? '尚未选择模型' : c.service.model,
          ReaderSheet.rules => '先预览，再放心交给规则。默认只执行第一条命中的规则，新建或修改后只影响之后的新文章。',
          ReaderSheet.backup => '每天首次启动备份，保留最近 7 份。归档即使已取消收藏，也在备份范围内。',
          ReaderSheet.exportBackup => '这是加密导出流程的界面预览，不会创建实际备份文件。',
          ReaderSheet.storage => '普通缓存默认保留 30 天。归档长期保留，删除需要单独操作。',
          ReaderSheet.cleanup => '将清理示例文章的普通正文及其关联普通生成结果，也会移除对应正文搜索命中。',
          ReaderSheet.subscribe =>
            c.isDemo
                ? '支持 RSS、Atom 和 OPML。同一订阅源重复添加会合并。'
                : '填写 RSS / Atom 订阅地址。同一订阅源重复添加会合并。',
          ReaderSheet.subscriptions => '整理订阅与分类，也可以导入或导出 OPML。',
        };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final media = MediaQuery.of(context);
      final mobile = media.size.width <= ReaderMetrics.mobileBreakpoint;
      final available = media.size.height - media.viewInsets.bottom;
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: mobile ? EdgeInsets.zero : const EdgeInsets.all(28),
          alignment: mobile ? Alignment.bottomCenter : Alignment.center,
          constraints: BoxConstraints(
            maxWidth: mobile ? media.size.width : 540,
            maxHeight: math.min(
              available * (mobile ? .88 : .82),
              mobile ? available : 850,
            ),
          ),
          child: Container(
            key: ValueKey('sheet-${_kind.name}'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.solid,
              borderRadius: mobile
                  ? const BorderRadius.vertical(top: Radius.circular(26))
                  : BorderRadius.circular(25),
              border: Border.all(color: colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x321a3023),
                  blurRadius: 90,
                  offset: Offset(0, 35),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                mobile ? 23 : 28,
                mobile ? 12 : 28,
                mobile ? 23 : 28,
                mobile ? 28 + media.padding.bottom : 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mobile) ...[
                    Center(
                      child: Container(
                        width: 33,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 21),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title,
                          style: TextStyle(
                            fontSize: mobile ? 23 : 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ReaderIconButton(
                        icon: 'close',
                        label: '关闭面板',
                        onPressed: _close,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _intro,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(height: 23),
                  ..._content(),
                  if (c.storageError != null && c.storageError != _feedback)
                    _message(c.storageError!),
                  if (_feedback != null)
                    _message(_feedback!, key: const ValueKey('sheet-feedback')),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _content() => !c.isDemo && !_kind.availableInLibrary
      ? [ReaderButton(text: '返回阅读', onPressed: _close)]
      : switch (_kind) {
          ReaderSheet.settings => _settings(),
          ReaderSheet.appearance => _appearance(),
          ReaderSheet.devices => _devices(),
          ReaderSheet.pair => _pair(),
          ReaderSheet.revoke => _revoke(),
          ReaderSheet.archives => _archives(),
          ReaderSheet.deleteArchive => _deleteArchive(),
          ReaderSheet.translation => _translation(),
          ReaderSheet.summary => _summary(),
          ReaderSheet.ask => _ask(),
          ReaderSheet.service => _service(),
          ReaderSheet.modelTest => _modelTest(),
          ReaderSheet.rules => _rules(),
          ReaderSheet.backup => _backup(),
          ReaderSheet.exportBackup => _export(),
          ReaderSheet.storage => _storage(),
          ReaderSheet.cleanup => _cleanup(),
          ReaderSheet.subscribe => _subscribe(),
          ReaderSheet.subscriptions => [
            SubscriptionPanel(
              controller: c,
              onAdd: () => _go(ReaderSheet.subscribe),
              onClose: _close,
            ),
          ],
          ReaderSheet.articleMenu => _articleMenu(),
          ReaderSheet.original => _original(),
        };

  List<Widget> _original() => c.isDemo
      ? [
          _message(
            '这里的文章由自带的示例文字组成，没有对应的公开原网页。正式阅读流程会保留订阅条目的原始链接，在提取失败或缓存清理后仍可访问。',
          ),
          ReaderButton(
            text: '继续阅读示例',
            primary: true,
            expand: true,
            onPressed: _close,
          ),
        ]
      : [
          if (c.selected.link == null)
            _message('订阅源没有提供可用的原网页链接。')
          else ...[
            SelectableText(
              c.selected.link!,
              style: TextStyle(color: colors.accent, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ReaderButton(
              text: '在浏览器中打开',
              primary: true,
              expand: true,
              onPressed: () async {
                final message = await c.openOriginal();
                if (!mounted) return;
                if (message == null) {
                  _close();
                } else {
                  _notice(message);
                }
              },
            ),
          ],
        ];

  List<Widget> _settings() => [
    _card([
      for (final (icon, title, caption, sheet) in [
        ('text', '阅读与外观', '字号、明暗与跟随系统', ReaderSheet.appearance),
        if (!c.isDemo)
          ('folder', '订阅管理', '订阅、分类与 OPML', ReaderSheet.subscriptions),
        ('sparkles', '翻译与 AI', '服务地址、模型与每日调用额度', ReaderSheet.service),
        ('auto', '自动化', '让重复的小事自动发生', ReaderSheet.rules),
        ('laptop', '我的设备', '局域网配对与同步', ReaderSheet.devices),
        ('archive', '备份与恢复', '每日备份，保留最近 7 份', ReaderSheet.backup),
        ('download', '存储空间', '普通缓存与长期归档分别管理', ReaderSheet.storage),
      ])
        _row(
          icon: icon,
          title: title,
          caption: c.isDemo || sheet.availableInLibrary ? caption : '尚未开放',
          onTap: () => _go(sheet),
        ),
    ]),
  ];

  List<Widget> _appearance() => [
    _heading('外观'),
    Row(
      children: [
        for (final (mode, icon, label) in [
          (ThemeMode.light, 'sun', '浅色'),
          (ThemeMode.dark, 'moon', '深色'),
          (ThemeMode.system, 'laptop', '跟随系统'),
        ])
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: mode == ThemeMode.system ? 0 : 10,
              ),
              child: ReaderTap(
                onTap: () => c.setTheme(mode),
                radius: 12,
                border: c.themeMode == mode
                    ? const Color(0xffa7b99b)
                    : colors.line,
                color: c.themeMode == mode ? colors.accentSoft : null,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 6,
                ),
                child: Column(
                  children: [
                    ReaderIcon(icon),
                    const SizedBox(height: 10),
                    Text(label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
    const SizedBox(height: 22),
    _heading('正文字号  ${c.fontSize.round()}px'),
    Row(
      children: [
        const Text('A'),
        Expanded(
          child: Slider(
            value: c.fontSize,
            min: 13,
            max: 22,
            divisions: 9,
            label: '${c.fontSize.round()}px',
            onChanged: c.setFontSize,
            semanticFormatterCallback: (value) => '正文字号 ${value.round()}',
            activeColor: colors.accent,
          ),
        ),
        const Text('A', style: TextStyle(fontSize: 25)),
      ],
    ),
    _message('不急着读完世界，先找回自己的节奏。', fontSize: c.fontSize),
  ];

  List<Widget> _devices() => [
    const Padding(
      padding: EdgeInsets.only(top: 23, bottom: 30),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReaderIcon('phone', size: 47, color: Color(0xff718b65)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '···',
                style: TextStyle(color: Color(0xff9aae8d), letterSpacing: 5),
              ),
            ),
            ReaderIcon('link', size: 36, color: Color(0xff718b65)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '···',
                style: TextStyle(color: Color(0xff9aae8d), letterSpacing: 5),
              ),
            ),
            ReaderIcon('laptop', size: 47, color: Color(0xff718b65)),
          ],
        ),
      ),
    ),
    _card([
      _row(
        icon: 'phone',
        title: '这台设备',
        caption: '本机示例数据 · ${c.networkAvailable ? '当前可连接局域网' : '离线阅读中'}',
      ),
      for (final device in c.devices)
        _row(
          icon: device.id.contains('windows') ? 'laptop' : 'phone',
          title: device.name,
          caption:
              '${!device.trusted
                  ? '授权已撤销 · 已保存数据保留'
                  : device.isOnline && c.networkAvailable
                  ? '同网且已打开 · 可以同步'
                  : '等待同网并打开应用'}'
              '${device.pendingRevocation ? ' · 待接收撤销信息' : ''}',
          trailing: device.trusted
              ? _textAction('撤销', () {
                  _deviceToRevoke = device;
                  _go(ReaderSheet.revoke);
                })
              : _small('已断开'),
        ),
    ]),
    _buttons([
      ReaderButton(
        text: '立即同步',
        icon: 'refresh',
        primary: true,
        onPressed: () async {
          final message = await c.sync();
          if (mounted) _notice(message);
        },
      ),
      ReaderButton(
        text: '配对新设备',
        icon: 'plus',
        onPressed: () => _go(ReaderSheet.pair),
      ),
    ]),
    _message('${c.syncLabel} · 最后成功：${c.lastSync} · 待同步 ${c.pendingChanges} 项'),
    _row(
      title: '局域网连接 · 演示开关',
      caption: '关闭后仍可阅读、收藏及管理本机内容。',
      trailing: _toggle(c.networkAvailable, '模拟局域网连接', c.toggleNetwork),
    ),
  ];

  List<Widget> _pair() => [
    Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 23),
      decoration: BoxDecoration(
        color: colors.wash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '426 810',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w300,
          letterSpacing: 9,
        ),
      ),
    ),
    _field(
      '输入另一台设备的配对码',
      _pairCode,
      hint: '426 810',
      keyboard: TextInputType.number,
    ),
    ReaderButton(
      text: '确认配对 · 演示',
      primary: true,
      expand: true,
      onPressed: () => _notice(c.pairDevice(_pairCode.text)),
    ),
    _message('新安装拥有独立设备身份。恢复备份后也需要重新配对。'),
  ];

  List<Widget> _revoke() => [
    _message(
      '本机立即停止与它的新同步及未完成传输。其他可信设备收到撤销信息后生效；离线设备要等下次收到信息。已经保存的数据会保留，重新加入需要再次配对。',
    ),
    _buttons([
      ReaderButton(text: '保留授权', onPressed: () => _go(ReaderSheet.devices)),
      ReaderButton(
        text: '撤销授权',
        danger: true,
        onPressed: () {
          final message = c.revokeDevice(_deviceToRevoke!.id);
          _go(ReaderSheet.devices);
          _notice(message);
        },
      ),
    ]),
  ];

  List<Widget> _archives() => [
    _card([
      if (c.selected.archives.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
          child: Column(
            children: [
              const Text('当前没有离线归档', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 9),
              _small('收藏和已读标记仍然保留。\n可以手动保存正在阅读的正文。'),
            ],
          ),
        ),
      for (final archive in c.selected.archives)
        _row(
          icon: 'archive',
          title:
              '${archive.kind == BodyKind.full ? '提取全文' : 'RSS 正文'} · ${archive.savedLabel}',
          caption: c.isDemo
              ? '正文与图片已保存${archive.resultLabels.isEmpty ? '' : ' · 附带${archive.resultLabels.join('、')}'}'
              : '正文文字已保存 · 图片请查看原网页',
          onTap: () {
            c.openArchive(archive.id);
            _close();
          },
          trailing: ReaderIconButton(
            icon: 'trash',
            label: '删除这份归档 ${archive.savedLabel}',
            onPressed: () {
              _archiveToDelete = archive.id;
              _go(ReaderSheet.deleteArchive);
            },
          ),
        ),
    ]),
    _buttons([
      ReaderButton(
        text: c.selected.archives.isEmpty ? '保存当前正文' : '重新归档当前正文',
        icon: 'plus',
        primary: true,
        onPressed: () => _notice(c.saveArchive()),
      ),
      ReaderButton(
        text: c.selected.isFavorite ? '取消收藏' : '添加收藏',
        icon: 'favorite',
        onPressed: () => _notice(c.toggleFavorite()),
      ),
    ]),
    _message(
      c.isDemo
          ? '取消收藏后，这些版本仍可从“保留归档”访问、搜索、同步和恢复。'
          : '取消收藏后，这些版本仍可从“保留归档”访问和搜索。本机归档仅包含正文文字。',
    ),
  ];

  List<Widget> _deleteArchive() {
    final archive = c.selected.archive(_archiveToDelete);
    final labels = {
      ...?archive?.resultLabels,
      for (final result in c.selected.results.values)
        if (result.archiveId == _archiveToDelete) result.label,
    };
    return [
      _message(
        '将删除 ${archive?.savedLabel ?? ''} 的'
        '${archive?.kind == BodyKind.rss ? ' RSS 正文' : '全文'}快照${c.isDemo ? '及图片' : '文字'}。'
        '${labels.isEmpty ? '此版本没有附加生成结果。' : '附加结果也会删除：${labels.join('、')}。'}'
        '\n${c.isDemo ? '删除会参与局域网同步，' : ''}其他归档和收藏、已读标记保留。',
      ),
      _buttons([
        ReaderButton(
          text: '保留这份归档',
          onPressed: () => _go(ReaderSheet.archives),
        ),
        ReaderButton(
          text: '删除这份归档',
          danger: true,
          onPressed: () {
            final message = c.deleteArchive(_archiveToDelete!);
            _go(ReaderSheet.archives);
            _notice(message);
          },
        ),
      ]),
    ];
  }

  List<Widget> _translation() => [
    _select('目标语言', c.targetLanguage, const {
      'zh': '简体中文',
      'en': 'English',
    }, c.setLanguage),
    _message(
      '${c.targetLanguage == 'zh' ? '这篇示例的原文已是简体中文。选择 English 可以体验逐段对照。' : '译文与原文逐段对应，共用这个正文版本的阅读位置。'}'
      '\n生成或切换译文不会自动把文章标为已读。',
    ),
    _buttons([
      ReaderButton(
        text: '打开逐段对照',
        icon: 'translate',
        primary: true,
        onPressed: () {
          final result = c.generate(GenerationTask.translation);
          if (result.result != null) {
            _close();
          } else {
            _notice(result.message!);
          }
        },
      ),
      if (c.bilingual)
        ReaderButton(
          text: '仅看原文',
          onPressed: () {
            c.showOriginalOnly();
            _close();
          },
        ),
    ]),
    const SizedBox(height: 15),
    _small('使用预先写好的示例译文，不调用在线服务。'),
  ];

  List<Widget> _summary() => [
    _small(
      c.currentKind == BodyKind.rss
          ? '依据订阅提供的摘要，不代表完整文章。'
          : '依据当前正文；点击段落标记可以回到原文。',
    ),
    const SizedBox(height: 20),
    for (final (index, point)
        in (widget.summary?.content ?? <String>[]).indexed)
      Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.wash,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '0${index + 1}',
              style: const TextStyle(
                fontFamily: 'MorssSerif',
                color: Color(0xff93a280),
                fontSize: 20,
                height: 1.5,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point,
                    style: const TextStyle(fontSize: 12, height: 1.9),
                  ),
                  const SizedBox(height: 7),
                  _citation(
                    c.summaryReferences[index.clamp(
                      0,
                      c.summaryReferences.length - 1,
                    )],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    _buttons([
      ReaderButton(
        text: '归档当前正文与结果',
        icon: 'archive',
        onPressed: () => _notice(c.saveArchive()),
      ),
    ]),
  ];

  List<Widget> _ask() => [
    _field('问一个与正文有关的问题', _question, hint: '这篇文章有哪些值得实践的建议？', maxLines: 3),
    ReaderButton(
      text: '问问文章 · 演示',
      icon: 'chat',
      primary: true,
      expand: true,
      onPressed: () {
        final question = _question.text.trim();
        if (question.isEmpty) {
          _notice('先写下你想问的问题。');
          return;
        }
        final outcome = c.generate(GenerationTask.question, question: question);
        if (outcome.result == null) {
          _notice(outcome.message!);
          return;
        }
        setState(() {
          _answer = outcome.result;
          _feedback = null;
        });
      },
    ),
    if (_answer != null) ...[
      _message(_answer!.content.join('\n'), fontSize: 13),
      _citation(0),
    ],
    const SizedBox(height: 15),
    _small('此处使用预设示例回答，只依据所选正文演示问答。不会发送在线请求。'),
  ];

  List<Widget> _service() => [
    _field(
      '服务 URL · 完整接口前缀',
      _url,
      hint: 'https://api.example.com/v1',
      keyboard: TextInputType.url,
      help: '保留服务商的完整路径前缀，不重复添加 /v1。',
    ),
    _field(
      'API Key',
      _key,
      obscure: true,
      hint: '仅填示例文本，无需真实密钥',
      help: '不保存输入的密钥。正式版由各设备在系统安全存储中单独配置。',
    ),
    ReaderButton(
      text: '保存配置并获取示例模型列表',
      expand: true,
      onPressed: () {
        final message = c.saveService(_url.text);
        _key.clear();
        _notice(message);
      },
    ),
    const SizedBox(height: 22),
    _select('选择模型 · ${c.service.directoryLabel}', c.service.model, {
      '': '请选择模型',
      for (final model in c.service.models) model: model,
    }, c.chooseModel),
    _field(
      '也可以手动填写模型 ID',
      _manualModel,
      hint: '目录不可用时填写模型 ID',
      suffix: ReaderIconButton(
        icon: 'check',
        label: '使用填写的模型',
        onPressed: () {
          c.chooseModel(_manualModel.text);
          _notice('已选择填写的模型。');
        },
      ),
      onSubmitted: c.chooseModel,
    ),
    _field(
      '每设备每日调用上限',
      _limit,
      keyboard: TextInputType.number,
      onChanged: (value) {
        final number = int.tryParse(value);
        if (number != null) c.setCallLimit(number);
      },
    ),
    _message(
      '今日演示调用 ${c.service.calls} / ${c.service.limit} 次。目录读取不占额度；文章生成与模型测试共用额度。',
    ),
    _buttons([
      ReaderButton(text: '刷新目录', onPressed: c.refreshModels),
      ReaderButton(
        text: '测试当前模型',
        primary: true,
        onPressed: () => _go(ReaderSheet.modelTest),
      ),
    ]),
    const SizedBox(height: 12),
    _small(c.service.testLabel),
  ];

  List<Widget> _modelTest() => [
    _message(
      '正式服务会收到一段固定短文本，可能产生费用，计入本设备每日额度。成功仅代表这一次文本调用可用。\n此处只演示调用计数与结果，不发出请求。',
    ),
    _buttons([
      ReaderButton(text: '返回配置', onPressed: () => _go(ReaderSheet.service)),
      ReaderButton(
        text: '发送演示测试',
        primary: true,
        onPressed: () => _notice(c.testModel()),
      ),
    ]),
  ];

  List<Widget> _rules() => [
    if (c.automationPaused) _message('恢复后，本机自动化已暂停。预览规则后再启用。'),
    _card([
      for (final (index, rule) in c.rules.indexed)
        _row(
          title: rule.name,
          leading: _small('0${index + 1}'),
          caption: '新文章 › 标题含 ${rule.keyword} › ${rule.actions}',
          trailing: _toggle(
            rule.enabled,
            '启用${rule.name}',
            () => c.toggleRule(rule),
          ),
        ),
    ]),
    _buttons([
      ReaderButton(text: '预览已有文章', onPressed: c.previewRules),
      if (c.automationPaused)
        ReaderButton(
          text: '启用本机自动化',
          primary: true,
          onPressed: () => _notice(c.enableAutomation()),
        ),
    ]),
    if (c.previewedRules) ...[
      const SizedBox(height: 22),
      _heading('本次预览 · ${c.ruleMatches.length} 篇命中'),
      _card([
        if (c.ruleMatches.isEmpty) _message('当前启用规则没有命中示例文章。'),
        for (final article in c.ruleMatches)
          _row(
            icon: 'book',
            title: article.title,
            caption: article.manualFavorite != null
                ? '已有手动收藏决定，此字段将受到保护'
                : article.isFavorite
                ? '已经收藏，不追加自动归档'
                : '将提取正文并首次收藏',
          ),
      ]),
      const SizedBox(height: 15),
      ReaderButton(
        text: '手动执行这批文章',
        primary: true,
        expand: true,
        onPressed: () => _notice(c.runPreviewedRules()),
      ),
    ],
    _message('手动收藏与取消收藏优先于规则。重复执行同一批示例不会再创建相同归档。'),
  ];

  List<Widget> _backup() => [
    _card([
      _row(
        icon: 'shield',
        title: '今天 09:12 · 本地备份',
        caption: '订阅、阅读状态、保留归档及规则 · 示例',
        trailing: _small('最近一份'),
      ),
    ]),
    const SizedBox(height: 22),
    _heading('选择恢复到已有数据的设备'),
    _card([
      _restoreOption(
        'archives',
        '保留归档',
        '包括取消收藏后的正文、图片和附加结果',
        c.restoreSelection.archives,
        (value) =>
            c.updateRestoreSelection((selection) => selection.archives = value),
      ),
      _restoreOption(
        'favorites',
        '收藏标记',
        '单独恢复归档不会自动变成收藏',
        c.restoreSelection.favorites,
        (value) => c.updateRestoreSelection(
          (selection) => selection.favorites = value,
        ),
      ),
      _restoreOption(
        'subscriptions',
        '订阅与分类',
        '按新的修改参与合并',
        c.restoreSelection.subscriptions,
        (value) => c.updateRestoreSelection(
          (selection) => selection.subscriptions = value,
        ),
      ),
      _restoreOption(
        'rules',
        '自动化规则',
        '恢复后，本机先暂停自动执行',
        c.restoreSelection.rules,
        (value) =>
            c.updateRestoreSelection((selection) => selection.rules = value),
      ),
    ]),
    _buttons([
      ReaderButton(
        text: '加密导出预览',
        onPressed: () => _go(ReaderSheet.exportBackup),
      ),
      ReaderButton(
        text: '恢复所选 · 演示',
        primary: true,
        onPressed: () => _notice(c.restoreBackup()),
      ),
    ]),
    _message(
      '新安装用独立身份重新配对。已有安装沿用当前身份与授权，备份不含配对凭据和 API Key。\n此处从初始示例数据恢复，不读写备份文件。',
    ),
  ];

  List<Widget> _export() => [
    _field('备份密码', _password, hint: '填写演示密码', obscure: true),
    _message('包含保留归档及业务数据，排除普通缓存、API Key 和配对凭据。'),
    ReaderButton(
      text: '预览导出结果',
      primary: true,
      expand: true,
      onPressed: () {
        if (_password.text.trim().isEmpty) {
          _notice('填写一个演示密码后继续。');
          return;
        }
        _password.clear();
        _notice('导出流程预览完成。未创建文件，也未保存输入的密码。');
      },
    ),
  ];

  List<Widget> _storage() => [
    _card([
      _row(
        icon: 'clock',
        title: '普通正文和生成结果',
        caption: c.cacheCleared ? '本机缓存已清理 · 演示状态' : '近期阅读内容；清理只影响本机',
        trailing: _textAction('清理', () => _go(ReaderSheet.cleanup)),
      ),
      _row(
        icon: 'archive',
        title:
            '保留归档 · ${c.articles.fold(0, (count, article) => count + article.archives.length)} 份',
        caption: '包含已取消收藏的内容，不随缓存清理',
        trailing: _textAction('查看', () {
          c.navigate(ReaderView.archives);
          _close();
        }),
      ),
    ]),
    _message('普通生成结果仍被保留时，其准确原文也一并保留。主动清理原文，会列出并清理失去依据的本机普通结果。'),
  ];

  List<Widget> _cleanup() {
    final results = [
      for (final article in c.articles)
        for (final result in article.results.values)
          if (result.archiveId == null) '${article.title} · ${result.label}',
    ];
    return [
      _message(
        '所有保留归档及其中的附加结果仍在；已读、收藏标记和其他设备副本不受影响。'
        '${results.isEmpty ? '\n当前没有关联的普通生成结果。' : '\n将一并清理：\n${results.join('\n')}'}',
      ),
      _buttons([
        ReaderButton(text: '暂时保留', onPressed: () => _go(ReaderSheet.storage)),
        ReaderButton(
          text: '清理这些缓存',
          danger: true,
          onPressed: () {
            final message = c.clearOrdinaryCache();
            _go(ReaderSheet.storage);
            _notice(message);
          },
        ),
      ]),
    ];
  }

  List<Widget> _subscribe() => [
    _field(
      '订阅源名称',
      _feedName,
      key: const ValueKey('feed-name'),
      hint: '例如：慢读 Slow Reading',
    ),
    _field(
      'RSS / Atom 地址',
      _feedUrl,
      key: const ValueKey('feed-url'),
      hint: 'https://example.com/feed.xml',
      keyboard: TextInputType.url,
    ),
    if (c.isDemo)
      _select('分类', _category, const {
        '生活': '生活',
        '设计': '设计',
        '技术': '技术',
      }, (value) => setState(() => _category = value))
    else
      _field(
        '分类',
        _feedCategory,
        key: const ValueKey('feed-category'),
        hint: '输入新的分类，或留空归入未分类',
      ),
    ReaderButton(
      text: c.isDemo
          ? '添加示例订阅'
          : c.isFetchingFeeds
          ? '正在获取订阅…'
          : '添加订阅并获取文章',
      primary: true,
      expand: true,
      onPressed: () async {
        if (c.isFetchingFeeds) return;
        final message = await c.subscribe(
          _feedName.text,
          _feedUrl.text,
          c.isDemo ? _category : _feedCategory.text,
        );
        if (!mounted) return;
        _notice(message, close: !c.isDemo && c.feedError == null);
      },
    ),
    _message(
      c.isDemo
          ? '只添加内存中的订阅入口，不抓取网页。OPML 的解析、导入和导出留待数据层实现。'
          : '正文文字会保存在本机，断网也能继续阅读。图片与原始排版可从原网页查看。',
    ),
    if (!c.isDemo)
      ReaderButton(
        text: '订阅管理',
        icon: 'folder',
        onPressed: () => _go(ReaderSheet.subscriptions),
      ),
  ];

  List<Widget> _articleMenu() => [
    _card([
      _row(
        icon: 'check',
        title: c.selected.isRead ? '标为未读' : '标为已读',
        caption: '手动调整阅读状态',
        onTap: () => _notice(c.toggleRead(), close: true),
      ),
      _row(
        icon: 'archive',
        title: '归档版本',
        caption: '${c.selected.archives.length} 份保留快照',
        onTap: () => _go(ReaderSheet.archives),
      ),
      _row(
        icon: 'text',
        title: '阅读外观',
        caption: '字号与明暗',
        onTap: () => _go(ReaderSheet.appearance),
      ),
      _row(
        icon: 'external',
        title: '原网页入口',
        caption: c.isDemo ? '离开应用继续阅读的入口预览' : '在浏览器中阅读源站内容',
        onTap: () => _go(ReaderSheet.original),
      ),
    ]),
  ];

  Widget _card(List<Widget> rows) => GlassPanel(
    radius: 15,
    color: colors.surface,
    border: colors.line,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) Divider(height: 1, thickness: 1, color: colors.line),
          row,
        ],
      ],
    ),
  );

  Widget _row({
    required String title,
    String? caption,
    String? icon,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) => ReaderTap(
    onTap: onTap,
    radius: 0,
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        if (icon != null || leading != null) ...[
          leading ?? ReaderIcon(icon!, color: const Color(0xff7e9672)),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 5),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.muted,
                    height: 1.7,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null || onTap != null) ...[
          const SizedBox(width: 12),
          trailing ?? const ReaderIcon('chevron', size: 16),
        ],
      ],
    ),
  );

  Widget _toggle(bool value, String label, VoidCallback onTap) => Semantics(
    label: label,
    toggled: value,
    child: ReaderTap(
      onTap: onTap,
      radius: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 39,
        height: 23,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? const Color(0xff759660) : const Color(0xffd2d9ce),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 17,
            height: 17,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _restoreOption(
    String id,
    String title,
    String caption,
    bool value,
    ValueChanged<bool> onChanged,
  ) => _row(
    title: title,
    caption: caption,
    onTap: () => onChanged(!value),
    leading: SizedBox(
      width: 19,
      height: 24,
      child: Checkbox(
        key: ValueKey('restore-$id'),
        value: value,
        activeColor: colors.accent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (value) => onChanged(value!),
      ),
    ),
    trailing: const SizedBox.shrink(),
  );

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Text(
      title,
      style: TextStyle(fontSize: 11, color: colors.muted, letterSpacing: .5),
    ),
  );

  Widget _small(String text) => Text(
    text,
    style: TextStyle(fontSize: 10, color: colors.muted, height: 1.7),
  );

  Widget _message(String text, {Key? key, double fontSize = 11}) => Container(
    key: key,
    margin: const EdgeInsets.symmetric(vertical: 14),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: colors.wash,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: TextStyle(color: colors.accent, fontSize: fontSize, height: 1.9),
    ),
  );

  Widget _buttons(List<Widget> buttons) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, button) in buttons.indexed) ...[
          if (index > 0) const SizedBox(width: 9),
          Expanded(child: button),
        ],
      ],
    ),
  );

  Widget _textAction(String label, VoidCallback onTap) => ReaderTap(
    onTap: onTap,
    padding: const EdgeInsets.all(4),
    child: Text(label, style: TextStyle(fontSize: 10, color: colors.accent)),
  );

  Widget _citation(int paragraph) => Align(
    alignment: Alignment.centerLeft,
    child: ReaderTap(
      onTap: () {
        c.goToParagraph(paragraph);
        _close();
      },
      color: colors.accentSoft,
      radius: 5,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: Text(
        '原文 ${paragraph + 1} 段 ↗',
        style: TextStyle(fontSize: 9, color: colors.accent),
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    Key? key,
    String? hint,
    String? help,
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(label),
        TextField(
          key: key,
          controller: controller,
          obscureText: obscure,
          maxLines: maxLines,
          keyboardType: keyboard,
          autocorrect: !obscure,
          enableSuggestions: !obscure,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          inputFormatters: keyboard == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            hintStyle: TextStyle(fontSize: 12, color: colors.faint),
          ),
        ),
        if (help != null) ...[const SizedBox(height: 7), _small(help)],
      ],
    ),
  );

  Widget _select(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(label),
        DropdownButtonFormField<String>(
          key: ValueKey('$label/$value'),
          initialValue: value,
          isExpanded: true,
          style: TextStyle(
            fontFamily: 'MorssSans',
            fontSize: 12,
            color: colors.ink,
          ),
          dropdownColor: colors.solid,
          items: [
            for (final entry in options.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    ),
  );
}
