import 'package:get_it/get_it.dart';

import '../storage/hive_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/expenses/data/datasources/expense_local_data_source.dart';

final GetIt getIt = GetIt.instance;

/// Call once from main() after Hive has been initialized.
Future<void> initDependencies() async {
  if (getIt.isRegistered<AuthBloc>()) return;

  // Core services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  // Auth
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt<SecureStorageService>()),
  );
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => const AuthRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(local: getIt(), remote: getIt()),
  );
  getIt.registerFactory<AuthBloc>(() => AuthBloc(authRepository: getIt()));

  // Expenses (local-first data source)
  getIt.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(HiveService.expensesBox),
  );
}
