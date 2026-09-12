import 'package:flutter/material.dart';

/// Values taken from the user-selected A reference, in logical pixels.
abstract final class ReaderMetrics {
  static const mobileBreakpoint = 760.0;
  static const compactBreakpoint = 1150.0;
  static const largeBreakpoint = 1600.0;
  static const maxWidth = 1496.0;
  static const shellRadius = 28.0;
  static const mobileShellRadius = 23.0;
  static const shellBlur = 40.0;

  static double sidebar(double width) => width >= largeBreakpoint
      ? 228
      : width <= compactBreakpoint
      ? 178
      : 214;
  static double inbox(double width) => width >= largeBreakpoint
      ? 392
      : width <= compactBreakpoint
      ? 292
      : 354;
}

@immutable
class ReaderColors {
  const ReaderColors({
    required this.dark,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.line,
    required this.surface,
    required this.solid,
    required this.wash,
    required this.glass,
    required this.background,
    required this.reader,
    required this.sidebar,
  });

  static const light = ReaderColors(
    dark: false,
    ink: Color(0xff263a31),
    muted: Color(0xff738078),
    faint: Color(0xff9aa49b),
    accent: Color(0xff3d6952),
    accentSoft: Color(0xffe6efe1),
    line: Color(0x1a394b3c),
    surface: Color(0xbdfffffc),
    solid: Color(0xfffbfcf8),
    wash: Color(0x99e7eee4),
    glass: Color(0x99fdfff9),
    background: Color(0xffe5eae2),
    reader: Color(0xa8fffffc),
    sidebar: Color(0x52edf2e7),
  );
  static const night = ReaderColors(
    dark: true,
    ink: Color(0xffdde6d6),
    muted: Color(0xff95a38e),
    faint: Color(0xff75826e),
    accent: Color(0xffafc995),
    accentSoft: Color(0xff354332),
    line: Color(0x15bdcda9),
    surface: Color(0xba2d362b),
    solid: Color(0xff242d25),
    wash: Color(0x1c80956d),
    glass: Color(0xc22b382b),
    background: Color(0xff1b261f),
    reader: Color(0xbf242d25),
    sidebar: Color(0x2e3b4933),
  );

  static ReaderColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? night : light;

  final bool dark;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color accentSoft;
  final Color line;
  final Color surface;
  final Color solid;
  final Color wash;
  final Color glass;
  final Color background;
  final Color reader;
  final Color sidebar;

  Color get border => dark ? const Color(0x27a9bea1) : const Color(0xd9ffffff);
  Color get bodyText =>
      dark ? const Color(0xffb1bca9) : const Color(0xff526052);
}

ThemeData readerTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? ReaderColors.night
      : ReaderColors.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'MorssSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      surface: colors.solid,
    ),
    scaffoldBackgroundColor: colors.background,
    dividerColor: colors.line,
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'MorssSans',
      bodyColor: colors.ink,
      displayColor: colors.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 500),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff9ab58c), width: 2),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      radius: const Radius.circular(8),
      thickness: const WidgetStatePropertyAll(5),
      thumbColor: WidgetStatePropertyAll(colors.faint.withValues(alpha: .18)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xf0293d2b),
      contentTextStyle: TextStyle(
        fontFamily: 'MorssSans',
        color: Color(0xffedf3e5),
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(13)),
      ),
    ),
  );
}
