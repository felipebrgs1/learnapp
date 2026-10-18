import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';
import 'icons.dart';

/// Área tocável com feedback sutil de fundo (sem ripple).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _pressed ? context.colors.surfacePressed : const Color(0x00000000),
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Botão quadrado com ícone e borda fina.
class IconButtonBox extends StatelessWidget {
  const IconButtonBox({
    super.key,
    required this.icon,
    required this.onTap,
    required this.label,
    this.bordered = true,
  });

  final AppIconKind icon;
  final VoidCallback onTap;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: bordered ? Border.all(color: c.border) : null,
        ),
        child: AppIcon(icon, color: c.text, size: 17),
      ),
    );
  }
}

/// Pequeno rótulo em mono, estilo badge.
class Badge extends StatelessWidget {
  const Badge(this.text, {super.key, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? c.accentSoft : c.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent ? c.accent.withValues(alpha: .25) : c.border),
      ),
      child: Text(
        text,
        style: AppText.eyebrow.copyWith(color: accent ? c.accent : c.textSecondary, fontSize: 11),
      ),
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.colors.border);
}

/// Converte `**negrito**` e `` `código` `` em spans.
TextSpan richText(String source, TextStyle base, AppColors c) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`');
  var last = 0;
  for (final m in pattern.allMatches(source)) {
    if (m.start > last) spans.add(TextSpan(text: source.substring(last, m.start)));
    if (m.group(1) != null) {
      spans.add(TextSpan(
        text: m.group(1),
        style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
      ));
    } else {
      spans.add(TextSpan(
        text: ' ${m.group(2)} ',
        style: TextStyle(
          fontFamily: AppText.mono,
          fontSize: (base.fontSize ?? 15) * .86,
          color: c.text,
          backgroundColor: c.surfacePressed,
        ),
      ));
    }
    last = m.end;
  }
  if (last < source.length) spans.add(TextSpan(text: source.substring(last)));
  return TextSpan(style: base, children: spans);
}

class RichParagraph extends StatelessWidget {
  const RichParagraph(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text.rich(richText(text, style ?? AppText.body.copyWith(color: c.textSecondary), c));
  }
}

/// Rota com fade + leve deslocamento, no espírito de transições discretas.
class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute({required WidgetBuilder builder, super.fullscreenDialog})
    : super(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, .02), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      );
}
