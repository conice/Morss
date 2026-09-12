import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/sqlite_reading_library.dart';
import '../features/reader/reader_controller.dart';

Future<ReaderController> openReader() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final library = SqliteReadingLibrary.open(
    path.join(directory.path, 'reader.sqlite'),
    client: http.Client(),
  );
  try {
    return ReaderController.library(library);
  } catch (_) {
    library.close();
    rethrow;
  }
}
