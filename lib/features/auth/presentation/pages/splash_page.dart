import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_widgets.dart';

/// Shown while the stored token is being checked. Auth redirects are owned by
/// the router, so this page only renders the loading state.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  curve: AppTheme.emphasized,
                  builder: (context, v, child) => Opacity(
                    opacity: v.clamp(0.0, 1.0).toDouble(),
                    child: Transform.scale(
                      scale: 0.72 + 0.28 * v,
                      child: child,
                    ),
                  ),
                  child: const BrandMark(size: 88),
                ),
                const SizedBox(height: 28),
                Reveal(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Reveal(
                  delay: const Duration(milliseconds: 480),
                  child: Text(
                    'Track every expense, offline first.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                Reveal(
                  delay: const Duration(milliseconds: 700),
                  dy: 12,
                  child: SizedBox(
                    height: 40,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: AppTheme.emphasized,
                      child: message != null
                          ? Padding(
                              key: ValueKey(message),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : SizedBox(
                              key: const ValueKey('loader'),
                              width: 56,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    color: scheme.primary,
                                    backgroundColor: scheme.outlineVariant,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
