import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import 'core/network/network_info.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/transactions/data/datasources/transaction_local_datasource.dart';
import 'features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/data/seed/seed_data.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';
import 'features/transactions/domain/usecases/add_transaction.dart';
import 'features/transactions/domain/usecases/delete_transaction.dart';
import 'features/transactions/domain/usecases/get_transactions.dart';
import 'features/transactions/domain/usecases/sync_transactions.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<TransactionLocalDataSource>(
    TransactionLocalDataSourceImpl.new,
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    TransactionRemoteDataSourceImpl.new,
  );

  // Repositories
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => SyncTransactions(sl()));
  sl.registerLazySingleton(() => GetDashboardSummary(sl()));

  // Inter-bloc coordinator (singleton stream bus)
  sl.registerLazySingleton(TransactionListCoordinator.new);

  // BLoCs — factory so each scope gets fresh instance; app uses one global.
  sl.registerFactory(
    () => TransactionBloc(
      getTransactions: sl(),
      addTransaction: sl(),
      deleteTransaction: sl(),
      syncTransactions: sl(),
      coordinator: sl(),
    ),
  );
  sl.registerFactory(
    () => DashboardBloc(
      getSummary: sl(),
      coordinator: sl(),
    ),
  );

  await _seedIfNeeded();
}

Future<void> _seedIfNeeded() async {
  final local = sl<TransactionLocalDataSource>();
  final existing = await local.getAll();
  if (existing.isEmpty) {
    final seed = buildSeedTransactions();
    await local.saveAll(seed);
    (sl<TransactionRemoteDataSource>() as TransactionRemoteDataSourceImpl)
        .seedIfEmpty(seed);
  }
}
