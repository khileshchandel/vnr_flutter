import 'package:flutter/material.dart';

/// Thin rounded progress bar drawn directly on the canvas. No chart package
/// needed for a single value.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.fraction,
    required this.color,
  });

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: CustomPaint(
        painter: _ProgressBarPainter(fraction: fraction, color: color),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  const _ProgressBarPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final centerY = radius;
    final start = Offset(radius, centerY);
    final end = Offset(size.width - radius, centerY);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.16);
    canvas.drawLine(start, end, track);

    final filledEnd =
        radius + (size.width - size.height) * fraction.clamp(0.0, 1.0);
    if (filledEnd > radius) {
      final fill = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawLine(start, Offset(filledEnd, centerY), fill);
    }
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
