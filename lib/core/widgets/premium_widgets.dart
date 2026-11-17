import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fades, lifts and gently scales its child into place using an
/// Apple-style decelerate curve. Use [delay] to stagger siblings.
/// Respects the system "reduce motion" setting.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 900),
    this.dy = 28,
    this.fromScale = 0.97,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dy;
  final double fromScale;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final move = AppTheme.emphasized.transform(_controller.value);
        final fade = const Interval(
          0,
          0.7,
          curve: Curves.easeOut,
        ).transform(_controller.value);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, (1 - move) * widget.dy),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * move,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Wraps a tappable widget (button, card) and gives it a subtle press-down
/// scale. It only listens to raw pointers, so the child's own onPressed /
/// onTap keeps working untouched.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value || !mounted) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && widget.enabled ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// App icon tile: gradient squircle with a soft glow and a glass sheen.
/// Shares a Hero tag so it flies between splash and login.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(size * 0.3);

    return Hero(
      tag: 'brand-mark',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient(scheme),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: size * 0.55,
              offset: Offset(0, size * 0.16),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.48,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}

/// Slowly drifting aurora of two soft color blobs behind [child].
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _AuroraPainter(
                t: _controller.value,
                background: scheme.surface,
                a: scheme.primary.withValues(alpha: dark ? 0.20 : 0.13),
                b: scheme.secondary.withValues(alpha: dark ? 0.11 : 0.10),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.t,
    required this.background,
    required this.a,
    required this.b,
  });

  final double t;
  final Color background;
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final angle = t * 2 * math.pi;

    void blob(Offset center, double radius, Color color) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(rect),
      );
    }

    blob(
      Offset(
        size.width * (0.2 + 0.10 * math.sin(angle)),
        size.height * (0.12 + 0.05 * math.cos(angle)),
      ),
      size.width * 0.85,
      a,
    );
    blob(
      Offset(
        size.width * (0.9 - 0.10 * math.cos(angle)),
        size.height * (0.88 + 0.04 * math.sin(angle)),
      ),
      size.width * 0.95,
      b,
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.t != t || old.background != background || old.a != a || old.b != b;
}
