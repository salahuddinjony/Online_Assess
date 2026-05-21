import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/budget_arc_meter.dart';
import '../../../../core/widgets/transaction_celebration_overlay.dart';
import '../../../../core/widgets/spending_line_chart.dart';
import '../../../../core/widgets/spring_swipe_tile.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';

class SpendArcHomePage extends StatefulWidget {
  const SpendArcHomePage({super.key});

  @override
  State<SpendArcHomePage> createState() => _SpendArcHomePageState();
}

class _SpendArcHomePageState extends State<SpendArcHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const TransactionsStarted());
    context.read<DashboardBloc>().add(const DashboardStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('SpendArc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => context
                .read<TransactionBloc>()
                .add(const TransactionSyncRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, txState) {
          return TransactionCelebrationOverlay(
            effect: txState.celebration,
            onComplete: () => context
                .read<TransactionBloc>()
                .add(const TransactionParticleDismissed()),
            child: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TransactionBloc>()
                    .add(const TransactionSyncRequested());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _DashboardHeader()),
                  if (txState.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: MaterialBanner(
                          content: Text(txState.errorMessage!),
                          leading: const Icon(Icons.warning_amber),
                          actions: [
                            TextButton(
                              onPressed: () {},
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = txState.transactions[index];
                          return Padding(
                            key: ValueKey(tx.id),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SpringSwipeTile(
                              key: ValueKey('swipe_${tx.id}'),
                              onDismissed: () => context
                                  .read<TransactionBloc>()
                                  .add(TransactionDeleted(tx.id)),
                              child: _TransactionCard(transaction: tx),
                            ),
                          );
                        },
                        childCount: txState.transactions.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddTransactionSheet(),
    );
    if (result != null && context.mounted) {
      context.read<TransactionBloc>().add(TransactionAdded(result));
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final summary = state.summary;
        if (summary == null) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final currency = NumberFormat.currency(symbol: '\$');

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                currency.format(summary.balance),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      BudgetArcMeter(
                        ratio: summary.budgetUsedRatio,
                        spent: summary.totalExpense,
                        limit: summary.budgetLimit,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget usage',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Income ${currency.format(summary.totalIncome)}',
                            ),
                            Text(
                              'Spent ${currency.format(summary.totalExpense)}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7-day spending',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SpendingLineChart(values: summary.dailySpending),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final color = isExpense ? Colors.red.shade400 : Colors.teal.shade600;
    final icon = isExpense ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(transaction.title),
        subtitle: Text(
          '${transaction.category} · ${DateFormat.MMMd().format(transaction.date)}'
          '${transaction.synced ? '' : ' · pending'}',
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Food';
  TransactionType _type = TransactionType.expense;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New transaction',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Food', 'Transport', 'Health', 'Entertainment', 'Income']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final title = _titleController.text.trim();
              final amount = double.tryParse(_amountController.text);
              if (title.isEmpty || amount == null || amount <= 0) return;
              Navigator.pop(
                context,
                Transaction(
                  id: const Uuid().v4(),
                  title: title,
                  amount: amount,
                  category: _category,
                  date: DateTime.now(),
                  type: _type,
                  synced: false,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
