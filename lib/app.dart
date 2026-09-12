import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/reading_library.dart';
import 'design/reader_theme.dart';
import 'features/reader/reader_controller.dart';
import 'features/reader/reader_screen.dart';

class MorssApp extends StatefulWidget {
  const MorssApp({super.key, required this.controller}) : loader = null;

  const MorssApp.open({super.key, required this.loader}) : controller = null;

  final ReaderController? controller;
  final Future<ReaderController> Function()? loader;

  @override
  State<MorssApp> createState() => _MorssAppState();
}

class _MorssAppState extends State<MorssApp> with WidgetsBindingObserver {
  ReaderController? _controller;
  Object? _openError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller;
    if (_controller == null) {
      _openLibrary();
    } else {
      _startRefreshing();
    }
  }

  Future<void> _openLibrary() async {
    setState(() => _openError = null);
    try {
      final controller = await widget.loader!();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      _startRefreshing();
    } catch (error) {
      if (mounted) setState(() => _openError = error);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    if (widget.loader != null) _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _refreshTimer?.cancel();
    if (state == AppLifecycleState.resumed) _startRefreshing();
  }

  void _startRefreshing() {
    _refreshTimer?.cancel();
    final reader = _controller;
    final state = WidgetsBinding.instance.lifecycleState;
    if (reader == null ||
        reader.isDemo ||
        (state != null && state != AppLifecycleState.resumed)) {
      return;
    }
    unawaited(reader.refreshSubscriptions());
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      unawaited(reader.refreshSubscriptions());
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return controller == null
        ? _app(null)
        : ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _app(controller),
          );
  }

  Widget _app(ReaderController? controller) => MaterialApp(
    title: 'Morss · 阅读，回到自己',
    debugShowCheckedModeBanner: false,
    theme: readerTheme(Brightness.light),
    darkTheme: readerTheme(Brightness.dark),
    themeMode: controller?.themeMode ?? ThemeMode.system,
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: controller != null
        ? ReaderScreen(controller: controller)
        : Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _openError == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '无法打开本地阅读库',
                            style: TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _openError is ReadingLibraryException
                                ? (_openError! as ReadingLibraryException)
                                      .message
                                : '请检查可用空间和文件访问权限后重试。已有数据不会被重置。',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _openLibrary,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
  );
}
