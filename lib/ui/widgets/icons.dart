import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum AppIconKind { arrowLeft, arrowRight, search, copy, check, sun, moon, monitor, expand, close, clock }

/// Ícones de traço fino desenhados à mão, para não depender de fontes de
/// ícones nem de Material.
class AppIcon extends StatelessWidget {
  const AppIcon(this.kind, {super.key, this.size = 16, required this.color});

  final AppIconKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _IconPainter(kind, color)),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.kind, this.color);

  final AppIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Desenha numa caixa 24x24 e escala.
    canvas.scale(size.width / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (kind) {
      case AppIconKind.arrowLeft:
        path
          ..moveTo(19, 12)
          ..lineTo(5, 12)
          ..moveTo(11, 6)
          ..lineTo(5, 12)
          ..lineTo(11, 18);
      case AppIconKind.arrowRight:
        path
          ..moveTo(5, 12)
          ..lineTo(19, 12)
          ..moveTo(13, 6)
          ..lineTo(19, 12)
          ..lineTo(13, 18);
      case AppIconKind.search:
        path
          ..addOval(Rect.fromCircle(center: const Offset(11, 11), radius: 6.5))
          ..moveTo(16, 16)
          ..lineTo(20.5, 20.5);
      case AppIconKind.copy:
        path
          ..addRRect(RRect.fromLTRBR(9, 9, 20, 20, const Radius.circular(2)))
          ..moveTo(15, 5.5)
          ..lineTo(15, 5)
          ..arcToPoint(const Offset(13, 4), radius: const Radius.circular(1.5), clockwise: false)
          ..lineTo(6, 4)
          ..arcToPoint(const Offset(4, 6), radius: const Radius.circular(2), clockwise: false)
          ..lineTo(4, 13)
          ..arcToPoint(const Offset(5.5, 15), radius: const Radius.circular(1.5), clockwise: false);
      case AppIconKind.check:
        path
          ..moveTo(5, 12.5)
          ..lineTo(10, 17.5)
          ..lineTo(19.5, 7);
      case AppIconKind.sun:
        path.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 4));
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          path
            ..moveTo(12 + 7 * math.cos(a), 12 + 7 * math.sin(a))
            ..lineTo(12 + 9.5 * math.cos(a), 12 + 9.5 * math.sin(a));
        }
      case AppIconKind.moon:
        path
          ..moveTo(20, 14.5)
          ..arcToPoint(const Offset(9.5, 4), radius: const Radius.circular(8.5), largeArc: true)
          ..arcToPoint(const Offset(20, 14.5), radius: const Radius.circular(7), clockwise: false);
      case AppIconKind.monitor:
        path
          ..addRRect(RRect.fromLTRBR(3, 4, 21, 16, const Radius.circular(2)))
          ..moveTo(8, 20)
          ..lineTo(16, 20)
          ..moveTo(12, 16)
          ..lineTo(12, 20);
      case AppIconKind.expand:
        path
          ..moveTo(14, 4)
          ..lineTo(20, 4)
          ..lineTo(20, 10)
          ..moveTo(20, 4)
          ..lineTo(13.5, 10.5)
          ..moveTo(10, 20)
          ..lineTo(4, 20)
          ..lineTo(4, 14)
          ..moveTo(4, 20)
          ..lineTo(10.5, 13.5);
      case AppIconKind.close:
        path
          ..moveTo(6, 6)
          ..lineTo(18, 18)
          ..moveTo(18, 6)
          ..lineTo(6, 18);
      case AppIconKind.clock:
        path
          ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8.5))
          ..moveTo(12, 7.5)
          ..lineTo(12, 12)
          ..lineTo(15, 14);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.kind != kind || old.color != color;
}
