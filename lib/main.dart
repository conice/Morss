import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap/open_reader_demo.dart'
    if (dart.library.io) 'bootstrap/open_reader_native.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MorssApp.open(loader: openReader));
}
