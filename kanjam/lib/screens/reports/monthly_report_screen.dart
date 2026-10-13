import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/categories.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../services/finance_calculator.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common.dart';
import '../../widgets/custom_charts.dart';
import '../../widgets/summary_card.dart';

/// Monthly report. Every number and chart is computed from the stored
/// transactions of the selected month; empty months show empty states.
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  DateTime _month = FinanceCalculator.monthStart(DateTime.now());

  static const List<String> _weekLabels = <String>['Week 1', 'Week 2', 'Week 3', 'Week 4'];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final all = context.watch<TransactionService>().all;
    final monthTx = FinanceCalculator.inMonth(all, _month);
    final summary = FinanceCalculator.summarize(monthTx);
    final categories = FinanceCalculator.expenseByCategory(monthTx);
    final weekly = FinanceCalculator.weeklyExpense(monthTx, _month);
    final rate = summary.savingsRate;
    final hasAnyExpense = summary.expense > 0;

    return Scaffold(
      appBar: const KAppBar(title: 'Reports', showBack: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: <Widget>[
          MonthSwitcher(
            month: _month,
            onChanged: (m) => setState(() => _month = FinanceCalculator.monthStart(m)),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: SummaryCard(
                  label: 'Total Income',
                  amount: summary.income,
                  icon: Icons.south_west,
                  color: p.credit,
                  caption: 'Income: ${monthTx.where((t) => t.isCredit).length} entries',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: 'Total Expense',
                  amount: summary.expense,
                  icon: Icons.north_east,
                  color: p.debit,
                  caption: 'Spent: ${monthTx.where((t) => !t.isCredit).length} entries',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: SummaryCard(
                  label: 'Net Savings',
                  amount: summary.net,
                  icon: Icons.savings_outlined,
                  color: summary.net >= 0 ? p.credit : p.debit,
                  caption: 'Net: income - expense',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: 'Savings Rate',
                  amount: rate ?? 0,
                  asPercent: true,
                  placeholder: rate == null ? '--' : null,
                  icon: Icons.percent,
                  color: (rate ?? 0) >= 0 ? p.accent : p.debit,
                  caption: rate == null ? 'No income recorded' : 'of income saved',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'Income vs Expense',
            child: (summary.income == 0 && summary.expense == 0)
                ? const _EmptyNote('No income or expenses recorded for this period')
                : IncomeExpenseComparisonChart(income: summary.income, expense: summary.expense),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Spending by Category',
            child: categories.isEmpty
                ? const _EmptyNote('No expense data available for this month')
                : Column(
                    children: <Widget>[
                      DonutChart(
                        slices: categories,
                        centerLabel: 'Spent',
                        centerValue: Fmt.money(summary.expense, decimals: false),
                      ),
                      const SizedBox(height: 16),
                      ...categories.map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Categories.colorFor(c.category),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  c.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: p.textPrimary),
                                ),
                              ),
                              Text(
                                Fmt.percent(c.share),
                                style: TextStyle(color: p.textMuted, fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                Fmt.money(c.amount),
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Monthly Spending Trend',
            child: !hasAnyExpense
                ? const _EmptyNote('No expenses recorded for this period')
                : Column(
                    children: <Widget>[
                      SpendingTrendChart(values: weekly, labels: _weekLabels),
                      const SizedBox(height: 6),
                      Text(
                        'Weeks: 1-7, 8-14, 15-21, 22-end of month',
                        style: TextStyle(color: p.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(color: p.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.pal.textMuted, height: 1.4),
      ),
    );
  }
}
