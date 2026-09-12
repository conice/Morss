import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'design/reader_theme.dart';
import 'features/reader/reader_controller.dart';
import 'features/reader/reader_screen.dart';

class MorssApp extends StatelessWidget {
  const MorssApp({super.key, required this.controller});

  final ReaderController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      title: 'Morss · 阅读，回到自己',
      debugShowCheckedModeBanner: false,
      theme: readerTheme(Brightness.light),
      darkTheme: readerTheme(Brightness.dark),
      themeMode: controller.themeMode,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ReaderScreen(controller: controller),
    ),
  );
}
