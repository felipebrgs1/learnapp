import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../content/models.dart';
import '../../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';

class DiagramView extends StatelessWidget {
  const DiagramView(this.block, {super.key});

  final DiagramBlock block;

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      FadeRoute<void>(fullscreenDialog: true, builder: (_) => _DiagramFullscreen(block)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 38,
                padding: const EdgeInsets.only(left: 14, right: 4),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(bottom: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        block.title ?? 'Diagrama',
                        overflow: TextOverflow.ellipsis,
                        style: AppText.eyebrow.copyWith(color: c.textSecondary),
                      ),
                    ),
                    Pressable(
                      onTap: () => _openFullscreen(context),
                      semanticLabel: 'Ampliar diagrama',
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: AppIcon(AppIconKind.expand, size: 15, color: c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openFullscreen(context),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DiagramCanvas(block),
                ),
              ),
            ],
          ),
        ),
        if (block.caption != null) ...[
          const SizedBox(height: 8),
          RichParagraph(block.caption!, style: AppText.small.copyWith(color: c.textMuted, fontSize: 12.5)),
        ],
      ],
    );
  }
}

/// Desenha o diagrama ocupando a largura disponível, mantendo a proporção.
class DiagramCanvas extends StatelessWidget {
  const DiagramCanvas(this.block, {super.key});

  final DiagramBlock block;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _describe(block),
      child: AspectRatio(
        aspectRatio: block.cols / block.rows,
        child: CustomPaint(painter: DiagramPainter(block, context.colors)),
      ),
    );
  }

  static String _describe(DiagramBlock b) {
    final names = {for (final n in b.nodes) n.id: n.label};
    return [
      if (b.title != null) b.title!,
      for (final e in b.edges)
        '${names[e.from]} ${e.label ?? 'para'} ${names[e.to]}',
    ].join('. ');
  }
}

class _DiagramFullscreen extends StatelessWidget {
  const _DiagramFullscreen(this.block);

  final DiagramBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: c.background,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter(c.border))),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) {
                // Garante tamanho legível mesmo em tela estreita: mínimo de
                // 44px por unidade da grade, com pan/zoom livre.
                final width = math.max(box.maxWidth - 32, block.cols * 44);
                return InteractiveViewer(
                  constrained: false,
                  minScale: .4,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, pad.top + 72, 16, pad.bottom + 48),
                    child: SizedBox(width: width, child: DiagramCanvas(block)),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: pad.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    block.title ?? 'Diagrama',
                    style: AppText.h3.copyWith(color: c.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                DecoratedBox(
                  decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(8)),
                  child: IconButtonBox(
                    icon: AppIconKind.close,
                    label: 'Fechar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: pad.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Pinça para zoom · arraste para mover',
                style: AppText.eyebrow.copyWith(color: c.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const step = 22.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

class DiagramPainter extends CustomPainter {
  DiagramPainter(this.block, this.c);

  final DiagramBlock block;
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / block.cols;
    final nodes = {for (final n in block.nodes) n.id: n};
    Rect rectOf(DiagramNode n) => Rect.fromLTWH(n.x * u, n.y * u, n.w * u, n.h * u);
    final radius = Radius.circular(u * .22);

    // Grupos (fronteiras como "cluster", "CI", etc.)
    for (final g in block.groups) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(g.x * u, g.y * u, g.w * u, g.h * u), radius * 1.4);
      canvas.drawRRect(r, Paint()..color = c.surface);
      _dashed(canvas, Path()..addRRect(r), Paint()
        ..color = c.borderStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1, u * .14);
      final label = _layout(
        g.label.toUpperCase(),
        TextStyle(fontFamily: AppText.mono, fontSize: u * .3, fontWeight: FontWeight.w500, color: c.textMuted, letterSpacing: .4),
        g.w * u - u * .6,
      );
      final labelY = g.labelBottom ? (g.y + g.h) * u - u * .22 - label.height : g.y * u + u * .22;
      label.paint(canvas, Offset(g.x * u + u * .3, labelY));
    }

    // Arestas
    final labels = <(Offset, String, bool)>[];
    for (final e in block.edges) {
      final ra = rectOf(nodes[e.from]!);
      final rb = rectOf(nodes[e.to]!);
      final delta = rb.center - ra.center;
      if (delta.distance == 0) continue;
      final dir = delta / delta.distance;
      final shift = Offset(-dir.dy, dir.dx) * (e.offset * u);
      final gap = u * .12;
      final start = _exit(ra, ra.center + shift, dir) + dir * gap;
      final end = _exit(rb, rb.center + shift, -dir) - dir * gap;

      final color = e.accent ? c.accent : c.textMuted;
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, u * .045)
        ..strokeCap = StrokeCap.round;
      final line = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
      if (e.dashed) {
        _dashed(canvas, line, stroke, u * .14);
      } else {
        canvas.drawPath(line, stroke);
      }
      final head = u * .24;
      _arrow(canvas, end, dir, head, color);
      if (e.both) _arrow(canvas, start, -dir, head, color);
      if (e.label != null) labels.add(((start + end) / 2, e.label!, e.accent));
    }

    // Nós
    for (final n in block.nodes) {
      final r = RRect.fromRectAndRadius(rectOf(n), radius);
      final (fill, border, labelColor) = switch (n.variant) {
        NodeVariant.normal => (c.background, c.borderStrong, c.text),
        NodeVariant.accent => (c.accentSoft, c.accent, c.text),
        NodeVariant.muted => (c.surface, c.border, c.textSecondary),
        NodeVariant.dashed => (c.background, c.borderStrong, c.textSecondary),
      };
      canvas.drawRRect(r, Paint()..color = fill);
      final borderPaint = Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = n.variant == NodeVariant.accent ? 1.4 : 1;
      if (n.variant == NodeVariant.dashed) {
        _dashed(canvas, Path()..addRRect(r), borderPaint, u * .14);
      } else {
        canvas.drawRRect(r, borderPaint);
      }

      final maxW = n.w * u - u * .4;
      final labelPainter = _layout(
        n.label,
        TextStyle(fontFamily: AppText.sans, fontSize: u * .42, fontWeight: FontWeight.w500, color: labelColor, height: 1.2),
        maxW,
        center: true,
      );
      final subPainter = n.sub == null
          ? null
          : _layout(
              n.sub!,
              TextStyle(fontFamily: AppText.mono, fontSize: u * .34, color: c.textMuted, height: 1.25),
              maxW,
              center: true,
            );
      final spacing = subPainter == null ? 0 : u * .08;
      final total = labelPainter.height + (subPainter?.height ?? 0) + spacing;
      var y = r.center.dy - total / 2;
      labelPainter.paint(canvas, Offset(r.center.dx - labelPainter.width / 2, y));
      y += labelPainter.height + spacing;
      subPainter?.paint(canvas, Offset(r.center.dx - subPainter.width / 2, y));
    }

    // Rótulos das arestas por cima de tudo.
    for (final (pos, text, accent) in labels) {
      final tp = _layout(
        text,
        TextStyle(fontFamily: AppText.mono, fontSize: u * .33, fontWeight: FontWeight.w500, color: accent ? c.accent : c.textSecondary),
        u * 6,
        center: true,
      );
      final box = Rect.fromCenter(center: pos, width: tp.width + u * .36, height: tp.height + u * .16);
      canvas.drawRRect(RRect.fromRectAndRadius(box, Radius.circular(u * .12)), Paint()..color = c.background);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(u * .12)),
        Paint()
          ..color = c.border
          ..style = PaintingStyle.stroke,
      );
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  /// Ponto onde o raio `origin + dir * t` sai do retângulo.
  static Offset _exit(Rect r, Offset origin, Offset dir) {
    var t = double.infinity;
    if (dir.dx > 0) t = math.min(t, (r.right - origin.dx) / dir.dx);
    if (dir.dx < 0) t = math.min(t, (r.left - origin.dx) / dir.dx);
    if (dir.dy > 0) t = math.min(t, (r.bottom - origin.dy) / dir.dy);
    if (dir.dy < 0) t = math.min(t, (r.top - origin.dy) / dir.dy);
    return origin + dir * t;
  }

  static void _arrow(Canvas canvas, Offset tip, Offset dir, double size, Color color) {
    final perp = Offset(-dir.dy, dir.dx);
    final base = tip - dir * size;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((base + perp * size * .55).dx, (base + perp * size * .55).dy)
      ..lineTo((base - perp * size * .55).dx, (base - perp * size * .55).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static void _dashed(Canvas canvas, Path path, Paint paint, double dash) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash * 1.8;
      }
    }
  }

  static TextPainter _layout(String text, TextStyle style, double maxWidth, {bool center = false}) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: center ? TextAlign.center : TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, maxWidth));
  }


  @override
  bool shouldRepaint(DiagramPainter old) => old.block != block || old.c != c;
}
