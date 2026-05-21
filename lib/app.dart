import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/spendarc/presentation/pages/spendarc_home_page.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'injection_container.dart';

class SpendArcApp extends StatelessWidget {
  const SpendArcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<TransactionBloc>()),
        BlocProvider(create: (_) => sl<DashboardBloc>()),
      ],
      child: MaterialApp(
        title: 'SpendArc',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SpendArcHomePage(),
      ),
    );
  }
}
