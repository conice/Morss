import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';

import '../features/reader/reader_models.dart';
import 'feed_document.dart';
import 'opml_document.dart';
import 'reading_library.dart';
import 'xml_text.dart';

class SqliteReadingLibrary implements ReadingLibrary {
  SqliteReadingLibrary._(this._database, this._client);

  factory SqliteReadingLibrary.open(
    String path, {
    required http.Client client,
  }) {
    Database? database;
    try {
      database = sqlite3.open(path);
      final version =
          database.select('PRAGMA user_version').single.values.single as int;
      if (version > 1) {
        throw const ReadingLibraryException('阅读库由更新版本创建，请使用更新的 Morss 打开。');
      }
      database.execute('PRAGMA foreign_keys = ON');
      database.execute('PRAGMA busy_timeout = 5000');
      database.execute('PRAGMA journal_mode = WAL');
      database.execute('''
        CREATE TABLE IF NOT EXISTS subscriptions (
          id TEXT PRIMARY KEY,
          url TEXT NOT NULL UNIQUE,
          payload TEXT NOT NULL
        )
      ''');
      database.execute('''
        CREATE TABLE IF NOT EXISTS articles (
          id TEXT PRIMARY KEY,
          source_id TEXT NOT NULL REFERENCES subscriptions(id),
          item_key TEXT NOT NULL,
          payload TEXT NOT NULL,
          published_at INTEGER,
          discovered_at INTEGER NOT NULL,
          feed_position INTEGER NOT NULL,
          UNIQUE(source_id, item_key)
        )
      ''');
      database.execute(
        'CREATE TABLE IF NOT EXISTS preferences (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)',
      );
      database.execute('PRAGMA user_version = 1');
      return SqliteReadingLibrary._(database, client);
    } catch (_) {
      database?.close();
      client.close();
      rethrow;
    }
  }

  final Database _database;
  final http.Client _client;
  bool _closed = false;

  @override
  ReadingLibraryData load() => ReadingLibraryData(
    sources: [
      for (final row in _database.select('SELECT payload FROM subscriptions'))
        FeedSource.fromJson(
          jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        ),
    ],
    articles: [
      for (final (index, row)
          in _database
              .select(
                'SELECT payload FROM articles ORDER BY COALESCE(published_at, discovered_at) DESC, feed_position, id',
              )
              .indexed)
        ReaderArticle.fromJson(
          jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          index,
        ),
    ],
    preferences: _loadPreferences(),
  );

  Map<String, dynamic> _loadPreferences() {
    final row = _database.select('SELECT payload FROM preferences').firstOrNull;
    return row == null
        ? {}
        : jsonDecode(row['payload'] as String) as Map<String, dynamic>;
  }

  @override
  String exportOpml() => OpmlDocument.export([
    for (final row in _database.select('SELECT payload FROM subscriptions'))
      FeedSource.fromJson(
        jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      ),
  ]);

  @override
  void updateSubscription(String id, String name, String category) {
    name = name.trim();
    category = category.trim();
    if (name.isEmpty) {
      throw const ReadingLibraryException('请填写订阅源名称。');
    }
    final row = _database.select(
      'SELECT payload FROM subscriptions WHERE id = ?',
      [id],
    ).firstOrNull;
    if (row == null) throw const ReadingLibraryException('此订阅已不存在。');
    final payload =
        jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    payload['name'] = name;
    payload['short'] = String.fromCharCodes(name.runes.take(1));
    final nextCategory = category.isEmpty ? '未分类' : category;
    if (payload['category'] != nextCategory) {
      payload['category'] = nextCategory;
      payload.remove('categoryPath');
    }
    _database.execute('UPDATE subscriptions SET payload = ? WHERE id = ?', [
      jsonEncode(payload),
      id,
    ]);
  }

  @override
  void unsubscribe(String id) {
    final row = _database.select(
      'SELECT payload FROM subscriptions WHERE id = ?',
      [id],
    ).firstOrNull;
    if (row == null) throw const ReadingLibraryException('此订阅已不存在。');
    final payload =
        jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    payload['subscribed'] = false;
    payload['unsubscribeRevision'] =
        (payload['unsubscribeRevision'] as int? ?? 0) + 1;
    _database.execute('UPDATE subscriptions SET payload = ? WHERE id = ?', [
      jsonEncode(payload),
      id,
    ]);
  }

  @override
  OpmlImportResult importOpml(String text) {
    final document = OpmlDocument.parse(text);
    var added = 0;
    var merged = 0;
    _database.execute('BEGIN IMMEDIATE');
    try {
      for (final entry in document.subscriptions) {
        final existing = _database.select(
          'SELECT payload FROM subscriptions WHERE url = ?',
          [entry.url],
        );
        if (existing.isNotEmpty) {
          final payload =
              jsonDecode(existing.single['payload'] as String)
                  as Map<String, dynamic>;
          if (payload['subscribed'] == false) {
            payload['subscribed'] = true;
            _database.execute(
              'UPDATE subscriptions SET payload = ? WHERE url = ?',
              [jsonEncode(payload), entry.url],
            );
          }
          merged++;
          continue;
        }
        final sourceId = _id(entry.url);
        _database.execute(
          'INSERT INTO subscriptions (id, url, payload) VALUES (?, ?, ?)',
          [
            sourceId,
            entry.url,
            jsonEncode(
              _newSubscriptionPayload(
                id: sourceId,
                name: entry.name,
                url: entry.url,
                category: entry.category,
                categoryPath: entry.folders,
              ),
            ),
          ],
        );
        added++;
      }
      _database.execute('COMMIT');
      return OpmlImportResult(added, merged, document.skipped);
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  Map<String, dynamic> _newSubscriptionPayload({
    required String id,
    required String name,
    required String url,
    required String category,
    List<String>? categoryPath,
  }) => {
    'id': id,
    'name': name,
    'short': String.fromCharCodes(name.runes.take(1)),
    'category': category.trim().isEmpty ? '未分类' : category.trim(),
    'categoryPath': ?categoryPath,
    'color': '#657951',
    'bg': '#e6ebdc',
    'url': url,
  };

  @override
  Future<void> subscribe(String name, String url, String category) async {
    final saved = await _fetchSubscription(
      name,
      url,
      category,
      reactivate: true,
    );
    if (!saved) {
      throw const ReadingLibraryException('订阅状态已改变，本次获取的内容未保存。需要时请重新刷新。');
    }
  }

  Future<bool> _fetchSubscription(
    String name,
    String url,
    String category, {
    required bool reactivate,
  }) async {
    final uri = normalizeFeedUrl(url);
    url = uri.toString();
    final before = _database.select(
      'SELECT payload FROM subscriptions WHERE url = ?',
      [url],
    ).firstOrNull;
    final beforePayload = before == null
        ? null
        : jsonDecode(before['payload'] as String) as Map<String, dynamic>;
    final wasInactive = beforePayload?['subscribed'] == false;
    final unsubscribeRevision =
        beforePayload?['unsubscribeRevision'] as int? ?? 0;
    if (wasInactive && !reactivate) return false;
    final text = await _fetch(uri);
    final FeedDocument document;
    try {
      document = FeedDocument.parse(text, uri);
    } on FormatException {
      throw const ReadingLibraryException('无法解析 RSS / Atom，请确认填写的是订阅地址。');
    }
    if (_closed) throw const ReadingLibraryException('阅读库已关闭。');
    final current = _database.select(
      'SELECT payload FROM subscriptions WHERE url = ?',
      [url],
    ).firstOrNull;
    final currentPayload = current == null
        ? null
        : jsonDecode(current['payload'] as String) as Map<String, dynamic>;
    // OPML can reactivate a source and the user can unsubscribe again while
    // this request is pending. The final flag alone cannot detect that change.
    if ((currentPayload?['unsubscribeRevision'] as int? ?? 0) !=
        unsubscribeRevision) {
      return false;
    }
    if (currentPayload?['subscribed'] == false &&
        (!reactivate || !wasInactive)) {
      return false;
    }
    name = name.trim().isEmpty ? document.title : name.trim();
    if (name.isEmpty) name = uri.host;
    final sourceId = _id(url);
    final source = _newSubscriptionPayload(
      id: sourceId,
      name: name,
      url: url,
      category: category,
    );
    _database.execute('BEGIN IMMEDIATE');
    try {
      _database.execute(
        'INSERT OR IGNORE INTO subscriptions (id, url, payload) VALUES (?, ?, ?)',
        [sourceId, url, jsonEncode(source)],
      );
      if (currentPayload?['subscribed'] == false) {
        currentPayload!['subscribed'] = true;
        _database.execute('UPDATE subscriptions SET payload = ? WHERE id = ?', [
          jsonEncode(currentPayload),
          sourceId,
        ]);
      }
      final discoveredAt = DateTime.now().millisecondsSinceEpoch;
      for (final (index, item) in document.entries.indexed) {
        final title = item.title;
        final link = item.link;
        final key = item.key;
        final articleId = _id('$sourceId\n$key');
        final paragraphs = item.paragraphs;
        final versionId = item.versionId;
        final published = _publishedTime(item.published);
        final existing = _database.select(
          'SELECT payload FROM articles WHERE id = ?',
          [articleId],
        ).firstOrNull;
        final previous = existing == null
            ? <String, dynamic>{}
            : jsonDecode(existing['payload'] as String) as Map<String, dynamic>;
        final article = <String, dynamic>{
          'read': false,
          'favorite': false,
          'extracted': false,
          'progress': 0,
          'archives': <Object>[],
          'lastKind': 'rss',
          ...previous,
          'id': articleId,
          'source': sourceId,
          'title': title,
          'deck': paragraphs.firstOrNull ?? '',
          'image': '',
          'minutes': (paragraphs.join().length / 450).ceil().clamp(1, 999),
          'time': published?.toLocal().toString().substring(0, 16) ?? '日期未知',
          'paragraphs': paragraphs,
          'rss': paragraphs,
          'english': <String>[],
          'summary': <String>[],
          'link': link,
          'cacheAvailable': paragraphs.isNotEmpty,
          'rssVersionId': versionId,
          'rssVersions': {
            ...?previous['rssVersions'] as Map?,
            versionId: paragraphs,
          },
        };
        _database.execute(
          'INSERT INTO articles (id, source_id, item_key, payload, published_at, discovered_at, feed_position) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, published_at = excluded.published_at, feed_position = excluded.feed_position',
          [
            articleId,
            sourceId,
            key,
            jsonEncode(article),
            published?.millisecondsSinceEpoch,
            discoveredAt,
            index,
          ],
        );
      }
      _database.execute('COMMIT');
      return true;
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<FeedRefreshResult> refresh({
    void Function(int completed, int total)? onProgress,
  }) async {
    final sources = load().sources
        .where((source) => source.isSubscribed)
        .toList();
    final errors = <String>[];
    var succeeded = 0;
    for (final (index, source) in sources.indexed) {
      if (_closed) break;
      try {
        if (await _fetchSubscription(
          source.name,
          source.url!,
          source.category,
          reactivate: false,
        )) {
          succeeded++;
        }
      } on ReadingLibraryException catch (error) {
        errors.add('${source.name}：${error.message}');
      } on FormatException {
        errors.add('${source.name}：订阅地址或内容无效。');
      } on SqliteException {
        errors.add('${source.name}：无法保存到本机，请检查可用空间。');
      }
      onProgress?.call(index + 1, sources.length);
    }
    return FeedRefreshResult(succeeded, errors);
  }

  Future<String> _fetch(Uri uri) async {
    const timeout = Duration(seconds: 20);
    const maxBytes = 8 * 1024 * 1024;
    final abort = Completer<void>();
    void cancel() {
      if (!abort.isCompleted) abort.complete();
    }

    final timer = Timer(timeout, cancel);
    try {
      final request =
          http.AbortableRequest('GET', uri, abortTrigger: abort.future)
            ..headers['Accept'] =
                'application/atom+xml, application/rss+xml, application/xml, text/xml;q=0.9, */*;q=0.1';
      final response = await _client.send(request).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ReadingLibraryException('服务器返回 HTTP ${response.statusCode}。');
      }
      if ((response.contentLength ?? 0) > maxBytes) {
        throw const ReadingLibraryException('订阅超过 8 MB，本次未保存。');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(timeout)) {
        if (bytes.length + chunk.length > maxBytes) {
          throw const ReadingLibraryException('订阅超过 8 MB，本次未保存。');
        }
        bytes.add(chunk);
      }
      return decodeXml(
        bytes.takeBytes(),
        response.headers['content-type'] ?? '',
      );
    } on TimeoutException {
      throw const ReadingLibraryException('获取订阅超时，请稍后重试。');
    } on http.RequestAbortedException {
      throw const ReadingLibraryException('获取订阅超时或已取消，请重试。');
    } on http.ClientException {
      throw const ReadingLibraryException('无法连接订阅源，请检查网络和地址。');
    } on SocketException {
      throw const ReadingLibraryException('无法连接订阅源，请检查网络和地址。');
    } on FormatException {
      throw const ReadingLibraryException('订阅文字编码无效或暂不支持。');
    } finally {
      timer.cancel();
      cancel();
    }
  }

  static String _id(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static DateTime? _publishedTime(String value) {
    if (value.trim().isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    try {
      return HttpDate.parse(value);
    } on HttpException {
      // RSS commonly uses an RFC 822 numeric offset, which HttpDate rejects.
    }
    final match = RegExp(
      r'^(?:[a-z]{3},\s*)?(\d{1,2})\s+([a-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s+([+-])(\d{2})(\d{2})$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    final month =
        const [
          'jan',
          'feb',
          'mar',
          'apr',
          'may',
          'jun',
          'jul',
          'aug',
          'sep',
          'oct',
          'nov',
          'dec',
        ].indexOf(match[2]!.toLowerCase()) +
        1;
    final day = int.parse(match[1]!);
    final hour = int.parse(match[4]!);
    final minute = int.parse(match[5]!);
    final second = int.parse(match[6] ?? '0');
    final zoneHours = int.parse(match[8]!);
    final zoneMinutes = int.parse(match[9]!);
    if (month == 0 ||
        hour > 23 ||
        minute > 59 ||
        second > 59 ||
        zoneHours > 23 ||
        zoneMinutes > 59) {
      return null;
    }
    final date = DateTime.utc(
      int.parse(match[3]!),
      month,
      day,
      hour,
      minute,
      second,
    );
    if (date.day != day || date.month != month) return null;
    final offset = (zoneHours * 60 + zoneMinutes) * (match[7] == '-' ? -1 : 1);
    return date.subtract(Duration(minutes: offset));
  }

  @override
  void saveState({
    required Iterable<ReaderArticle> articles,
    required Map<String, dynamic> preferences,
  }) {
    _database.execute('BEGIN IMMEDIATE');
    try {
      for (final article in articles) {
        // A source may already have committed fresh content while the controller
        // is still displaying its previous version during a multi-source refresh.
        final row = _database.select(
          'SELECT payload FROM articles WHERE id = ?',
          [article.id],
        ).single;
        final payload =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        final state = article.toJson();
        for (final key in const [
          'read',
          'favorite',
          'manualFavorite',
          'progress',
          'positions',
          'lastKind',
          'lastArchive',
          'lastVersion',
          'archives',
        ]) {
          payload[key] = state[key];
        }
        _database.execute('UPDATE articles SET payload = ? WHERE id = ?', [
          jsonEncode(payload),
          article.id,
        ]);
      }
      _database.execute(
        'INSERT INTO preferences (id, payload) VALUES (1, ?) ON CONFLICT (id) DO UPDATE SET payload = excluded.payload',
        [jsonEncode(preferences)],
      );
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
    _database.close();
  }
}
