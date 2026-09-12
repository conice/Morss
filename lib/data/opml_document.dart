import 'dart:convert';

import 'package:xml/xml.dart';

import '../features/reader/reader_models.dart';
import 'reading_library.dart';

typedef OpmlSubscription = ({
  String name,
  String url,
  String category,
  List<String> folders,
});

class OpmlDocument {
  const OpmlDocument(this.subscriptions, this.skipped);

  final List<OpmlSubscription> subscriptions;
  final int skipped;

  static String export(Iterable<FeedSource> sources) {
    final body = XmlElement(const XmlName.parts('body'));
    for (final source in sources) {
      if (!source.isSubscribed || source.url == null) continue;
      var parent = body;
      final folders =
          source.categoryPath ??
          (source.category != '未分类' && source.category.isNotEmpty
              ? source.category.split(' / ')
              : const <String>[]);
      for (final folder in folders) {
        final existing = parent.childElements
            .where(
              (node) =>
                  node.getAttribute('xmlUrl') == null &&
                  node.getAttribute('text') == folder,
            )
            .firstOrNull;
        if (existing != null) {
          parent = existing;
        } else {
          final node = XmlElement(const XmlName.parts('outline'), [
            XmlAttribute(const XmlName.parts('text'), folder),
          ]);
          parent.children.add(node);
          parent = node;
        }
      }
      parent.children.add(
        XmlElement(const XmlName.parts('outline'), [
          XmlAttribute(const XmlName.parts('type'), 'rss'),
          XmlAttribute(const XmlName.parts('text'), source.name),
          XmlAttribute(const XmlName.parts('title'), source.name),
          XmlAttribute(const XmlName.parts('xmlUrl'), source.url!),
        ]),
      );
    }
    return XmlDocument([
      XmlProcessing('xml', 'version="1.0" encoding="UTF-8"'),
      XmlElement(
        const XmlName.parts('opml'),
        [XmlAttribute(const XmlName.parts('version'), '2.0')],
        [
          XmlElement(const XmlName.parts('head'), [], [
            XmlElement(const XmlName.parts('title'), [], [XmlText('Morss 订阅')]),
          ]),
          body,
        ],
      ),
    ]).toXmlString(pretty: true);
  }

  factory OpmlDocument.parse(String text) {
    if (utf8.encode(text).length > 8 * 1024 * 1024) {
      throw const FormatException('OPML 文件不能超过 8 MB。');
    }
    final root = XmlDocument.parse(text).rootElement;
    final body = root.getElement('body');
    if (root.name.local != 'opml' || body == null) {
      throw const FormatException('请选择包含订阅列表的 OPML 文件。');
    }
    final subscriptions = <OpmlSubscription>[];
    var skipped = 0;
    final pending = [
      for (final node in body.findElements('outline').toList().reversed)
        (node: node, folders: <String>[]),
    ];
    while (pending.isNotEmpty) {
      final (:node, :folders) = pending.removeLast();
      final name =
          (node.getAttribute('text') ?? node.getAttribute('title') ?? '')
              .trim();
      final url = node.getAttribute('xmlUrl') ?? node.getAttribute('xmlurl');
      var childrenFolders = folders;
      if (url != null) {
        try {
          final uri = normalizeFeedUrl(url);
          subscriptions.add((
            name: name.isEmpty ? uri.host : name,
            url: uri.toString(),
            category: folders.isEmpty ? '未分类' : folders.join(' / '),
            folders: List.unmodifiable(folders),
          ));
        } on FormatException {
          skipped++;
        }
      } else if (node.getAttribute('type')?.toLowerCase() == 'rss') {
        skipped++;
      } else if (name.isNotEmpty) {
        childrenFolders = [...folders, name];
      }
      for (final child in node.findElements('outline').toList().reversed) {
        pending.add((node: child, folders: childrenFolders));
      }
    }
    return OpmlDocument(subscriptions, skipped);
  }
}
