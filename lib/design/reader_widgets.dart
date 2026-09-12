import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/reader/reader_models.dart';
import 'reader_theme.dart';

class ReaderIcon extends StatelessWidget {
  const ReaderIcon(this.name, {super.key, this.size = 20, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(
      color ?? ReaderColors.of(context).muted,
      BlendMode.srcIn,
    ),
  );
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 15,
    this.blur = 0,
    this.color,
    this.border,
    this.shadow = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final double blur;
  final Color? color;
  final Color? border;
  final bool shadow;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.glass,
        border: Border.all(color: border ?? colors.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: padding.add(const EdgeInsets.all(1)),
        child: child,
      ),
    );
    if (blur > 0) {
      content = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      );
    }
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
    if (!shadow) return panel;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        panel,
        // CSS outer shadows do not darken a translucent panel's interior.
        // Paint this after the panel so its backdrop blur only samples the room.
        Positioned.fill(
          child: IgnorePointer(
            child: ClipPath(
              clipper: _OuterShadowClipper(radius),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    colors.dark
                        ? const BoxShadow(
                            color: Color(0x4d101c16),
                            blurRadius: 65,
                            offset: Offset(0, 25),
                          )
                        : const BoxShadow(
                            color: Color(0x42304031),
                            blurRadius: 70,
                            spreadRadius: -26,
                            offset: Offset(0, 24),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OuterShadowClipper extends CustomClipper<Path> {
  const _OuterShadowClipper(this.radius);
  final double radius;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTWH(-140, -140, size.width + 280, size.height + 280))
    ..addRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
    );

  @override
  bool shouldReclip(_OuterShadowClipper oldClipper) =>
      oldClipper.radius != radius;
}

class ReaderTap extends StatelessWidget {
  const ReaderTap({
    super.key,
    required this.child,
    required this.onTap,
    this.label,
    this.color,
    this.radius = 10,
    this.padding = EdgeInsets.zero,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? border;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: color ?? Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: border ?? Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: ReaderColors.of(context).wash.withValues(alpha: .4),
        highlightColor: ReaderColors.of(context).wash,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class ReaderIconButton extends StatelessWidget {
  const ReaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.size = 34,
    this.iconSize = 18,
    this.color,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    return Tooltip(
      message: label,
      child: ReaderTap(
        label: label,
        onTap: onPressed,
        radius: size / 2,
        color: selected ? colors.accentSoft : null,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: ReaderIcon(
              selected && icon == 'favorite' ? 'favorite-filled' : icon,
              size: iconSize,
              color: color ?? (selected ? colors.accent : colors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

class ReaderButton extends StatelessWidget {
  const ReaderButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.danger = false,
    this.expand = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final String? icon;
  final bool primary;
  final bool danger;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = ReaderColors.of(context);
    final foreground = danger
        ? const Color(0xffad5946)
        : primary
        ? colors.dark
              ? const Color(0xff172316)
              : const Color(0xfff7faef)
        : colors.accent;
    return ReaderTap(
      onTap: onPressed,
      radius: 11,
      color: danger
          ? const Color(0xfff8e7e2)
          : primary
          ? colors.dark
                ? const Color(0xff809b69)
                : colors.accent
          : colors.wash,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            ReaderIcon(icon!, size: 15, color: foreground),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceBadge extends StatelessWidget {
  const SourceBadge(this.source, {super.key, this.size = 23});
  final FeedSource source;
  final double size;

  static Color parseColor(String text) =>
      Color(int.parse(text.replaceFirst('#', 'ff'), radix: 16));

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: parseColor(source.background),
      borderRadius: BorderRadius.circular(size * .29),
    ),
    child: Text(
      source.shortName,
      style: TextStyle(
        color: parseColor(source.color),
        fontSize: size * .48,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    ),
  );
}

class MorssBrand extends StatelessWidget {
  const MorssBrand({super.key, required this.onTap, this.mobile = false});
  final VoidCallback onTap;
  final bool mobile;

  @override
  Widget build(BuildContext context) => ReaderTap(
    onTap: onTap,
    label: 'Morss 首页',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/morss.svg',
          width: mobile ? 29 : 35,
          height: mobile ? 29 : 35,
          excludeFromSemantics: true,
        ),
        SizedBox(width: mobile ? 8 : 10),
        Text(
          'Morss',
          style: TextStyle(
            fontSize: mobile ? 20 : 25,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
            height: mobile ? 1.45 : 1.44,
          ),
        ),
      ],
    ),
  );
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, this.active = true, this.size = 5});
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? const Color(0xff799662) : Colors.transparent,
    ),
  );
}

void showReaderNotice(BuildContext context, String message) {
  if (message.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        width: MediaQuery.sizeOf(context).width > 600 ? 500 : null,
        duration: const Duration(seconds: 3),
      ),
    );
}
