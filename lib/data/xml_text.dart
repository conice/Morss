import 'dart:convert';
import 'dart:typed_data';

String decodeXml(Uint8List bytes, [String contentType = '']) {
  if (bytes.length >= 2 &&
      ((bytes[0] == 0xff && bytes[1] == 0xfe) ||
          (bytes[0] == 0xfe && bytes[1] == 0xff))) {
    if (bytes.length.isOdd) throw const FormatException('Invalid UTF-16');
    final little = bytes[0] == 0xff;
    return String.fromCharCodes([
      for (var i = 2; i < bytes.length; i += 2)
        little ? bytes[i] | bytes[i + 1] << 8 : bytes[i] << 8 | bytes[i + 1],
    ]);
  }
  final declaration = latin1.decode(bytes.take(256).toList());
  final headerEncoding = RegExp(
    r'''charset\s*=\s*["']?([\w-]+)''',
    caseSensitive: false,
  ).firstMatch(contentType)?.group(1);
  final xmlEncoding = RegExp(
    r'''<\?xml[^>]*encoding\s*=\s*["']([\w-]+)''',
    caseSensitive: false,
  ).firstMatch(declaration)?.group(1);
  final encoding = Encoding.getByName(headerEncoding ?? xmlEncoding ?? 'utf-8');
  if (encoding == null) throw const FormatException('Unsupported XML encoding');
  return encoding.decode(bytes);
}
