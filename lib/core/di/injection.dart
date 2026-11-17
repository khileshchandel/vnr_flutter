import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../network/token_provider.dart';
import '../storage/hive_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/expenses/data/datasources/expense_local_data_source.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/tasks/data/datasources/task_local_data_source.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/home/data/datasources/budget_local_data_source.dart';
import '../../features/home/data/repositories/budget_repository_impl.dart';
import '../../features/home/domain/repositories/budget_repository.dart';
import '../../features/home/presentation/bloc/dashboard_bloc.dart';
import '../../features/search/data/datasources/search_remote_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';

final GetIt getIt = GetIt.instance;

/// Call once from main() after Hive has been initialized.
Future<void> initDependencies() async {
  if (getIt.isRegistered<AuthBloc>()) return;

  // Core services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<TokenProvider>(
    () => SecureTokenProvider(getIt<SecureStorageService>()),
  );

  // Auth
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt<SecureStorageService>()),
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(local: getIt(), remote: getIt()),
  );
  getIt.registerFactory<AuthBloc>(() => AuthBloc(authRepository: getIt()));

  // Expenses (local-first data source + domain repository)
  getIt.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(HiveService.expensesBox),
  );
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(getIt<ExpenseLocalDataSource>()),
  );

  // Tasks (local-first data source + domain repository)
  getIt.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(HiveService.tasksBox),
  );
  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(getIt<TaskLocalDataSource>()),
  );

  // Dashboard (budget + local expense/task summaries)
  getIt.registerLazySingleton<BudgetLocalDataSource>(
    () => BudgetLocalDataSourceImpl(HiveService.settingsBox),
  );
  getIt.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(getIt<BudgetLocalDataSource>()),
  );
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      expenses: getIt<ExpenseRepository>(),
      tasks: getIt<TaskRepository>(),
      budget: getIt<BudgetRepository>(),
    ),
  );

  // Global search (expenses + tasks)
  getIt.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(
      apiClient: getIt<ApiClient>(),
      tokenProvider: getIt<TokenProvider>(),
    ),
  );
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(getIt<SearchRemoteDataSource>()),
  );
  getIt.registerFactory<SearchBloc>(
    () => SearchBloc(repository: getIt<SearchRepository>()),
  );
}
