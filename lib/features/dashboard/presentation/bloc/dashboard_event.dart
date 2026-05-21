part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}
