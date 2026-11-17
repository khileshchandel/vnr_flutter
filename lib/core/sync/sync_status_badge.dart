import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sync_coordinator.dart';
import 'sync_feedback.dart';
import 'sync_status.dart';

/// Compact, tappable status indicator for the home app bar.
///
/// The icon colour and the queued-count badge reflect the latest sync state;
/// tapping it starts a sync on demand.
final class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.read<SyncStatusStore>();
    final sync = context.read<SyncService>();

    return ValueListenableBuilder<SyncSnapshot>(
      valueListenable: status.value,
      builder: (context, snapshot, _) {
        return IconButton(
          tooltip: syncBadgeLabel(snapshot),
          onPressed: () => unawaited(sync.run()),
          icon: Badge(
            isLabelVisible: snapshot.pendingCount > 0,
            label: Text('${snapshot.pendingCount}'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: _StatusIcon(snapshot: snapshot),
          ),
        );
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.snapshot});

  final SyncSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!snapshot.online || snapshot.phase == SyncPhase.offline) {
      return Icon(Icons.cloud_off_outlined, color: theme.colorScheme.error);
    }

    return switch (snapshot.phase) {
      SyncPhase.syncing => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      SyncPhase.synced => Icon(
        Icons.cloud_done_outlined,
        color: theme.colorScheme.primary,
      ),
      SyncPhase.pending => Icon(
        Icons.cloud_upload_outlined,
        color: theme.colorScheme.tertiary,
      ),
      SyncPhase.error => Icon(
        Icons.sync_problem_outlined,
        color: theme.colorScheme.error,
      ),
      // Offline is handled above; idle uses the neutral cloud.
      SyncPhase.idle || SyncPhase.offline => Icon(
        Icons.cloud_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    };
  }
}
