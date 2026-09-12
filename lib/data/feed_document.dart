import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';

class FeedEntry {
  const FeedEntry({
    required this.key,
    required this.title,
    required this.link,
    required this.paragraphs,
    required this.versionId,
    required this.published,
  });

  final String key;
  final String title;
  final String? link;
  final List<String> paragraphs;
  final String versionId;
  final String published;
}

class FeedDocument {
  const FeedDocument(this.title, this.entries);

  final String title;
  final List<FeedEntry> entries;

  factory FeedDocument.parse(String source, Uri feedUri) {
    final root = XmlDocument.parse(source).rootElement;
    final atom = root.name.local == 'feed';
    final rss = root.name.local == 'rss' || root.name.local == 'RDF';
    final channel = _child(root, 'channel');
    if (!atom && (!rss || channel == null)) {
      throw const FormatException('地址没有返回 RSS / Atom 订阅内容。');
    }
    final container = atom || root.name.local == 'RDF' ? root : channel!;
    final entries = <FeedEntry>[];
    for (final item in container.childElements.where(
      (node) => node.name.local == (atom ? 'entry' : 'item'),
    )) {
      final title = _text(item, 'title');
      final published = atom
          ? _text(item, 'published')
          : _text(item, 'pubDate');
      final date = published.isNotEmpty
          ? published
          : atom
          ? _text(item, 'updated')
          : _text(item, 'date');
      final id = _text(item, atom ? 'id' : 'guid');
      final linkNode = atom
          ? item.childElements
                .where(
                  (node) =>
                      node.name.local == 'link' &&
                      (node.getAttribute('rel') ?? 'alternate') == 'alternate',
                )
                .firstOrNull
          : _child(item, 'link');
      final link = _resolveLink(
        linkNode ?? item,
        atom ? linkNode?.getAttribute('href') : linkNode?.innerText,
        feedUri,
      );
      final content = _child(item, 'content');
      final body = atom
          ? content?.getAttribute('src') != null
                ? _child(item, 'summary')
                : content ?? _child(item, 'summary')
          : _child(item, 'encoded') ?? _child(item, 'description');
      final markup = !atom || (body?.getAttribute('type') ?? 'text') != 'text';
      final rawBody = body == null
          ? ''
          : body.childElements.isNotEmpty
          ? body.children.map((node) => node.toXmlString()).join()
          : body.innerText;
      final key = id.isNotEmpty
          ? 'id:$id'
          : link != null
          ? 'link:$link'
          : 'fallback:${_hash(jsonEncode([title, date, if (title.isEmpty && date.isEmpty) rawBody]))}';
      entries.add(
        FeedEntry(
          key: key,
          title: title.isEmpty ? '无标题' : title,
          link: link,
          paragraphs: _paragraphs(rawBody, markup: markup),
          versionId: _hash(jsonEncode([rawBody, markup, link])),
          published: date,
        ),
      );
    }
    return FeedDocument(_text(atom ? root : channel!, 'title'), entries);
  }

  static XmlElement? _child(XmlElement element, String name) => element
      .childElements
      .where((node) => node.name.local == name)
      .firstOrNull;
  static String _text(XmlElement element, String name) =>
      _child(element, name)?.innerText.trim() ?? '';
  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static String? _resolveLink(XmlElement element, String? value, Uri feedUri) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      var base = feedUri;
      final parents = <XmlElement>[];
      for (XmlNode? node = element; node != null; node = node.parent) {
        if (node is XmlElement) parents.add(node);
      }
      for (final parent in parents.reversed) {
        final value = parent.attributes
            .where((attribute) => attribute.name.qualified == 'xml:base')
            .firstOrNull
            ?.value;
        if (value != null) base = base.resolve(value);
      }
      final uri = base.resolve(value.trim());
      return ['http', 'https'].contains(uri.scheme) && uri.host.isNotEmpty
          ? uri.toString()
          : null;
    } on FormatException {
      return null;
    }
  }

  static List<String> _paragraphs(String source, {required bool markup}) {
    if (!markup) {
      return source
          .split(RegExp(r'\n\s*\n'))
          .map((text) => text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
    }
    final document = html.parseFragment(source);
    final paragraphs = <String>[];
    var buffer = StringBuffer();
    void flush() {
      final text = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) paragraphs.add(text);
      buffer = StringBuffer();
    }

    void visit(dom.Node node) {
      if (node is dom.Text) {
        buffer.write(node.data);
        return;
      }
      final tag = node is dom.Element ? node.localName?.split(':').last : null;
      if (const {'script', 'style', 'noscript', 'template'}.contains(tag)) {
        return;
      }
      final block = const {
        'p',
        'div',
        'section',
        'article',
        'blockquote',
        'li',
        'pre',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
        'tr',
        'br',
      }.contains(tag);
      if (block) flush();
      for (final child in node.nodes) {
        visit(child);
      }
      if (block) flush();
    }

    visit(document);
    flush();
    return paragraphs;
  }
}
