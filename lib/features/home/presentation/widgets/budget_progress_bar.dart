import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Thin rounded progress bar drawn directly on the canvas. Animates smoothly
/// whenever [fraction] changes (and fills in from zero on first show).
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
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: AppTheme.emphasized,
      builder: (context, value, _) => SizedBox(
        height: 10,
        child: CustomPaint(
          painter: _ProgressBarPainter(
            fraction: value,
            color: color,
            trackColor: track,
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  const _ProgressBarPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

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
      ..color = trackColor;
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
  bool shouldRepaint(_ProgressBarPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor;
}
