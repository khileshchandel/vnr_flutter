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
import '../../features/tasks/data/datasources/task_local_data_source.dart';
import '../../features/search/data/datasources/search_remote_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';

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

  // Expenses (local-first data source)
  getIt.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(HiveService.expensesBox),
  );

  // Tasks (local-first data source)
  getIt.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(HiveService.tasksBox),
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
}
