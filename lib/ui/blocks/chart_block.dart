import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../content/models.dart';
import '../../theme/theme.dart';
import '../widgets/common.dart';

Color _toneColor(SeriesTone t, AppColors c) => switch (t) {
  SeriesTone.primary => c.text,
  SeriesTone.accent => c.accent,
  SeriesTone.muted => c.textMuted,
};

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class ChartView extends StatelessWidget {
  const ChartView(this.block, {super.key});

  final ChartBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(block.title, style: AppText.label.copyWith(color: c.text, fontSize: 14)),
              const SizedBox(height: 12),
              switch (block.kind) {
                ChartKind.line => _LineChart(block),
                ChartKind.bar => _BarChart(block),
              },
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

// ---------------------------------------------------------------------------

class _LineChart extends StatefulWidget {
  const _LineChart(this.block);
  final ChartBlock block;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  double? _hoverDx;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final b = widget.block;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (b.series.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final s in b.series)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(16, 8),
                        painter: _SwatchPainter(_toneColor(s.tone, c), s.dashed),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(s.name, style: AppText.small.copyWith(color: c.textSecondary, fontSize: 12)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        if (b.yLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(b.yLabel!, style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5)),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => setState(() => _hoverDx = d.localPosition.dx),
          onHorizontalDragStart: (d) => setState(() => _hoverDx = d.localPosition.dx),
          onHorizontalDragUpdate: (d) => setState(() => _hoverDx = d.localPosition.dx),
          onDoubleTap: () => setState(() => _hoverDx = null),
          child: SizedBox(
            height: 190,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LinePainter(b, c, _hoverDx),
            ),
          ),
        ),
        if (b.xLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              b.xLabel!,
              textAlign: TextAlign.right,
              style: AppText.eyebrow.copyWith(color: c.textMuted, fontSize: 10.5),
            ),
          ),
      ],
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.color, this.dashed);
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (dashed) {
      canvas.drawLine(Offset(1, y), Offset(5, y), p);
      canvas.drawLine(Offset(10, y), Offset(size.width - 1, y), p);
    } else {
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), p);
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.color != color || old.dashed != dashed;
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.b, this.c, this.hoverDx);

  final ChartBlock b;
  final AppColors c;
  final double? hoverDx;

  static const _left = 34.0;
  static const _bottom = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = [for (final s in b.series) ...s.points];
    final minX = pts.map((p) => p.$1).reduce(math.min);
    final maxX = pts.map((p) => p.$1).reduce(math.max);
    final dataMaxY = pts.map((p) => p.$2).reduce(math.max);
    final maxY = b.yMax ?? _niceCeil(dataMaxY);

    final plot = Rect.fromLTRB(_left, 6, size.width - 6, size.height - _bottom);
    Offset at(double x, double y) => Offset(
      plot.left + (x - minX) / (maxX - minX) * plot.width,
      plot.bottom - y / maxY * plot.height,
    );

    final tickStyle = TextStyle(fontFamily: AppText.mono, fontSize: 10, color: c.textMuted);
    final grid = Paint()
      ..color = c.border
      ..strokeWidth = 1;

    // Grade horizontal recessiva + rótulos do eixo y.
    const ticks = 4;
    for (var i = 0; i <= ticks; i++) {
      final v = maxY * i / ticks;
      final y = plot.bottom - plot.height * i / ticks;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final tp = _tp('${_fmt(v)}${b.unit}', tickStyle);
      tp.paint(canvas, Offset(plot.left - tp.width - 6, y - tp.height / 2));
    }
    // Rótulos do eixo x.
    const xTicks = 5;
    for (var i = 0; i <= xTicks; i++) {
      final v = minX + (maxX - minX) * i / xTicks;
      final tp = _tp(_fmt(v), tickStyle);
      final x = plot.left + plot.width * i / xTicks;
      final dx = (x - tp.width / 2).clamp(plot.left - 4, plot.right - tp.width);
      tp.paint(canvas, Offset(dx, plot.bottom + 6));
    }

    // Séries: 2px, cantos arredondados. Referências tracejadas vão por cima
    // para não sumirem atrás de séries que coincidem com elas.
    for (final s in [...b.series.where((s) => !s.dashed), ...b.series.where((s) => s.dashed)]) {
      final paint = Paint()
        ..color = _toneColor(s.tone, c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (final (i, p) in s.points.indexed) {
        final o = at(p.$1, p.$2);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      if (s.dashed) {
        for (final m in path.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += 9) {
            canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
    }

    // Crosshair + tooltip.
    final hx = hoverDx;
    if (hx == null) return;
    final px = hx.clamp(plot.left, plot.right);
    final x = minX + (px - plot.left) / plot.width * (maxX - minX);
    canvas.drawLine(
      Offset(px, plot.top),
      Offset(px, plot.bottom),
      Paint()
        ..color = c.borderStrong
        ..strokeWidth = 1,
    );
    final rows = <(Color, String, String)>[];
    for (final s in b.series) {
      final y = _interpolate(s.points, x);
      if (y == null) continue;
      final color = _toneColor(s.tone, c);
      final o = at(x, y);
      canvas.drawCircle(o, 5, Paint()..color = c.background);
      canvas.drawCircle(o, 3.5, Paint()..color = color);
      rows.add((color, s.name, '${_fmt(y)}${b.unit}'));
    }

    final title = _tp('${b.xLabel?.split(' ').first ?? 'x'} = ${_fmt(x)}', tickStyle.copyWith(color: c.textSecondary));
    final lines = [
      for (final r in rows)
        (
          r.$1,
          _tp(r.$2, TextStyle(fontFamily: AppText.sans, fontSize: 11.5, color: c.textSecondary)),
          _tp(r.$3, TextStyle(fontFamily: AppText.mono, fontSize: 11.5, fontWeight: FontWeight.w500, color: c.text)),
        ),
    ];
    const pad = 9.0;
    final rowH = 18.0;
    final w = math.max(
      title.width,
      lines.fold<double>(0, (m, l) => math.max(m, 14 + l.$2.width + 14 + l.$3.width)),
    ) + pad * 2;
    final h = pad * 2 + title.height + 4 + rows.length * rowH;
    var left = px + 10;
    if (left + w > size.width) left = px - 10 - w;
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(left, plot.top, w, h), const Radius.circular(8));
    canvas.drawRRect(box.shift(const Offset(0, 2)), Paint()..color = const Color(0x14000000));
    canvas.drawRRect(box, Paint()..color = c.background);
    canvas.drawRRect(box, Paint()
      ..color = c.border
      ..style = PaintingStyle.stroke);
    title.paint(canvas, Offset(left + pad, plot.top + pad));
    var y = plot.top + pad + title.height + 4;
    for (final (color, name, value) in lines) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left + pad, y + rowH / 2 - 1, 8, 2), const Radius.circular(1)),
        Paint()..color = color,
      );
      name.paint(canvas, Offset(left + pad + 14, y + (rowH - name.height) / 2));
      value.paint(canvas, Offset(left + w - pad - value.width, y + (rowH - value.height) / 2));
      y += rowH;
    }
  }

  static double? _interpolate(List<(double, double)> pts, double x) {
    for (var i = 0; i < pts.length - 1; i++) {
      final (x0, y0) = pts[i];
      final (x1, y1) = pts[i + 1];
      if (x >= x0 && x <= x1) {
        return x1 == x0 ? y1 : y0 + (y1 - y0) * (x - x0) / (x1 - x0);
      }
    }
    return null;
  }

  static double _niceCeil(double v) {
    if (v <= 0) return 1;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 2.5, 5, 10]) {
      if (m * mag >= v) return m * mag;
    }
    return 10 * mag;
  }

  static TextPainter _tp(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  bool shouldRepaint(_LinePainter old) => old.b != b || old.c != c || old.hoverDx != hoverDx;
}

// ---------------------------------------------------------------------------

class _BarChart extends StatelessWidget {
  const _BarChart(this.block);
  final ChartBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final max = block.bars.map((b) => b.value).reduce(math.max);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Column(
        children: [
          for (final bar in block.bars)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(bar.label, style: AppText.small.copyWith(color: c.textSecondary, fontSize: 12.5)),
                      ),
                      Text(
                        bar.display ?? '${_fmt(bar.value)}${block.unit}',
                        style: AppText.code.copyWith(color: c.text, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, box) => Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(color: c.surfacePressed, borderRadius: BorderRadius.circular(4)),
                        ),
                        Container(
                          height: 8,
                          width: math.max(4, box.maxWidth * bar.value / max * t),
                          decoration: BoxDecoration(color: c.text, borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
