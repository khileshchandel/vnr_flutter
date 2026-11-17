import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/premium_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    HapticFeedback.lightImpact();
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to sync your data.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(dialogContext).pop(true);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  void _open(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = context.watch<AuthBloc>().state.user;

    final displayName = user?.displayName?.trim();
    final hasName = displayName != null && displayName.isNotEmpty;
    final name = hasName ? displayName : 'There';
    final email = user?.email ?? 'Not signed in';

    final initialSource = hasName ? displayName : (user?.email ?? '');
    final initial = initialSource.isEmpty
        ? null
        : initialSource.substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Identity ────────────────────────────────────────────────────
          Reveal(
            dy: 20,
            duration: const Duration(milliseconds: 700),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: initial == null
                          ? Icon(
                              Icons.person_outline_rounded,
                              size: 40,
                              color: scheme.onPrimaryContainer,
                            )
                          : Text(
                              initial,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Shortcuts ───────────────────────────────────────────────────
          Reveal(
            delay: const Duration(milliseconds: 80),
            dy: 20,
            duration: const Duration(milliseconds: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Shortcuts'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _NavTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Expenses',
                        onTap: () => _open(context, AppRoutes.expenses),
                      ),
                      const Divider(indent: 68),
                      _NavTile(
                        icon: Icons.checklist_rounded,
                        label: 'Tasks',
                        onTap: () => _open(context, AppRoutes.tasks),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Account ─────────────────────────────────────────────────────
          Reveal(
            delay: const Duration(milliseconds: 160),
            dy: 20,
            duration: const Duration(milliseconds: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Account'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: _NavTile(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    destructive: true,
                    showChevron: false,
                    onTap: () => _confirmSignOut(context),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tileColor = destructive
        ? scheme.errorContainer
        : scheme.primaryContainer;
    final iconColor = destructive
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;

    return PressableScale(
      pressedScale: 0.99,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: destructive ? scheme.error : null,
          ),
        ),
        trailing: showChevron
            ? Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}
