import 'package:flutter/material.dart';

import 'app.dart';
import 'features/reader/reader_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await ReaderController.loadDemo();
  runApp(MorssApp(controller: controller));
}
