import 'dart:math' as math;

import 'package:flutter/material.dart';

class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.share,
    required this.color,
  });

  final String category;
  final double share;
  final Color color;
}

/// Small donut chart for the expense category breakdown.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
  });

  final List<CategorySlice> slices;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _DonutPainter(
              slices: slices,
              trackColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.4,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Text(
            centerLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.trackColor});

  final List<CategorySlice> slices;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = trackColor;
    canvas.drawCircle(rect.center, size.width / 2 - 9, track);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    var start = -90.0;
    for (final slice in slices) {
      if (slice.share <= 0) continue;
      final sweep = slice.share * 360;
      arcPaint.color = slice.color;
      canvas.drawArc(
        rect,
        start * math.pi / 180,
        sweep * math.pi / 180,
        false,
        arcPaint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.trackColor != trackColor;
}
