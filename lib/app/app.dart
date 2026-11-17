import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/auth/user_id_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/di/injection.dart';
import '../core/sync/sync_coordinator.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/home/presentation/bloc/dashboard_bloc.dart';
import '../features/home/presentation/bloc/dashboard_event.dart';
import '../features/search/presentation/bloc/search_bloc.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import 'router/app_router.dart';

/// Root widget for E Track.
///
/// Light and dark themes come from [AppTheme]; navigation is owned by
/// go_router so the widget tree stays free of imperative route pushes.
class ETrackApp extends StatefulWidget {
  const ETrackApp({super.key});

  @override
  State<ETrackApp> createState() => _ETrackAppState();
}

class _ETrackAppState extends State<ETrackApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_sync());
  }

  Future<void> _sync() => getIt<SyncService>().run();

  void _onAuthStateChanged(AuthState state) {
    authStatusNotifier.value = state.status;
    getIt<MutableUserIdProvider>().set(state.user?.id);
    if (state.status == AuthStatus.authenticated) unawaited(_sync());
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseRepository>(
          create: (_) => getIt<ExpenseRepository>(),
        ),
        RepositoryProvider<TaskRepository>(
          create: (_) => getIt<TaskRepository>(),
        ),
        RepositoryProvider<SyncService>(create: (_) => getIt<SyncService>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
          ),
          BlocProvider<DashboardBloc>(
            create: (_) =>
                getIt<DashboardBloc>()..add(const DashboardStarted()),
          ),
          BlocProvider<SearchBloc>(create: (_) => getIt<SearchBloc>()),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (_, state) => _onAuthStateChanged(state),
          child: MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: appRouter,
          ),
        ),
      ),
    );
  }
}
