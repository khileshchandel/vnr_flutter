import '../../domain/entities/dashboard_summary.dart';

enum DashboardStatus { initial, ready }

class DashboardState {
  const DashboardState({this.status = DashboardStatus.initial, this.summary});

  final DashboardStatus status;
  final DashboardSummary? summary;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }
}
