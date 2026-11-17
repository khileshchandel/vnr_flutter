import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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

/// Small donut chart for the expense category breakdown. The ring sweeps in
/// once when first shown.
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
    final scheme = theme.colorScheme;

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: AppTheme.emphasized,
            builder: (context, progress, _) => CustomPaint(
              painter: _DonutPainter(
                slices: slices,
                progress: progress,
                trackColor: scheme.surfaceContainerHighest,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Text(
            centerLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.progress,
    required this.trackColor,
  });

  static const double _stroke = 14;

  final List<CategorySlice> slices;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by half the stroke so the ring stays fully inside the box and
    // the track and arcs share exactly the same circle.
    final rect = (Offset.zero & size).deflate(_stroke / 2);

    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = trackColor,
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;

    final gap = slices.length > 1 ? 1.6 : 0.0;
    var cursor = -90.0;
    for (final slice in slices) {
      if (slice.share <= 0) continue;
      final sweep = slice.share * 360 * progress;
      final drawn = sweep - gap;
      if (drawn > 0) {
        arcPaint.color = slice.color;
        canvas.drawArc(
          rect,
          (cursor + gap / 2) * math.pi / 180,
          drawn * math.pi / 180,
          false,
          arcPaint,
        );
      }
      cursor += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices ||
      old.progress != progress ||
      old.trackColor != trackColor;
}
