import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'xml_text.dart';

abstract final class SubscriptionFiles {
  static Future<String?> pickOpml() async {
    // Some Android document providers do not recognise the .opml MIME type.
    // Validate the selected document after opening it rather than hiding it.
    final file = await FilePicker.pickFile(dialogTitle: '导入 OPML 文件');
    if (file == null) return null;
    const maxBytes = 8 * 1024 * 1024;
    if ((file.lengthSync() ?? 0) > maxBytes) {
      throw const FormatException('OPML 文件不能超过 8 MB。');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream().timeout(
      const Duration(seconds: 30),
    )) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('OPML 文件不能超过 8 MB。');
      }
      bytes.add(chunk);
    }
    return decodeXml(bytes.takeBytes());
  }

  static Future<bool> saveOpml(String text) async =>
      await FilePicker.saveFile(
        fileName: 'morss-subscriptions.opml',
        bytes: Uint8List.fromList(utf8.encode(text)),
        mimeType: 'text/x-opml',
        dialogTitle: '导出 OPML 文件',
      ) !=
      null;
}
