import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/categories.dart';
import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/budget.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../services/finance_calculator.dart';
import '../../services/finance_coordinator.dart';
import '../../services/transaction_service.dart';
import '../../widgets/budget_card.dart';
import '../../widgets/common.dart';

/// Monthly budgets with per-month spending, remaining amount and alerts.
class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  DateTime _month = FinanceCalculator.monthStart(DateTime.now());

  void _openSheet({BudgetModel? existing}) {
    showKSheet<void>(context, (ctx) => _BudgetSheet(existing: existing));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final budgets = context.watch<BudgetService>().budgets;
    final txs = context.watch<TransactionService>().all;
    final statuses = FinanceCalculator.budgetStatuses(budgets, txs, _month);

    // Headline numbers: the "Overall" budget when there is one, otherwise the
    // sum of the category budgets (adding both would count spending twice).
    BudgetStatus? overall;
    for (final s in statuses) {
      if (s.budget.category == Categories.overall) overall = s;
    }
    final categoryStatuses =
        statuses.where((s) => s.budget.category != Categories.overall).toList();
    final totalLimit = overall != null
        ? overall.limit
        : round2(categoryStatuses.fold<double>(0, (a, s) => a + s.limit));
    final totalSpent = overall != null
        ? overall.spent
        : round2(categoryStatuses.fold<double>(0, (a, s) => a + s.spent));
    final exceeded = statuses.where((s) => s.exceeded).toList();

    return Scaffold(
      appBar: const KAppBar(title: 'Monthly Budget'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: <Widget>[
            MonthSwitcher(
              month: _month,
              onChanged: (m) => setState(() => _month = FinanceCalculator.monthStart(m)),
            ),
            if (exceeded.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.debit.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.debit.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.warning_amber_rounded, color: p.debit),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Budget Exceeded!',
                            style: TextStyle(color: p.debit, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exceeded
                                .map((s) => s.budget.category == Categories.overall
                                    ? 'Overall'
                                    : s.budget.category)
                                .join(', '),
                            style: TextStyle(color: p.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (statuses.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      overall != null ? 'Overall budget' : 'All budgets',
                      style: TextStyle(color: p.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${Fmt.money(totalSpent)} / ${Fmt.money(totalLimit)}',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0).toDouble() : 0,
                        minHeight: 8,
                        backgroundColor: p.surfaceAlt,
                        color: totalSpent > totalLimit ? p.debit : p.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalLimit - totalSpent >= 0
                          ? '${Fmt.money(totalLimit - totalSpent)} remaining'
                          : 'Over by ${Fmt.money(totalSpent - totalLimit)}',
                      style: TextStyle(
                        color: totalSpent > totalLimit ? p.debit : p.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SectionHeader(
              title: 'MONTHLY BUDGETS',
              actionLabel: '+ ADD BUDGET',
              onAction: () => _openSheet(),
            ),
            const SizedBox(height: 8),
            if (statuses.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.pie_chart_outline,
                  title: 'No budgets configured yet',
                  message:
                      'Set a monthly limit for a category or for everything. You will get an alert at 80% and 100%.',
                  actionLabel: 'Set Monthly Budgets',
                  onAction: () => _openSheet(),
                ),
              )
            else
              ...statuses.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BudgetCard(status: s, onTap: () => _openSheet(existing: s.budget)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({this.existing});

  final BudgetModel? existing;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limit;
  String? _category;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category;
    _limit = TextEditingController(
      text: e == null ? '' : e.monthlyLimit.toStringAsFixed(e.monthlyLimit % 1 == 0 ? 0 : 2),
    );
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (_category == null) {
      setState(() => _error = 'Choose a category');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final limit = AmountParser.tryParse(_limit.text);
    final userId = context.read<AuthService>().user?.id;
    if (limit == null || userId == null) return;
    final coordinator = context.read<FinanceCoordinator>();
    final navigator = Navigator.of(context);
    final existing = widget.existing;

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await coordinator.saveBudget(
      existing == null
          ? BudgetModel(
              id: IdGen.next('bg'),
              userId: userId,
              category: _category!,
              monthlyLimit: limit,
              createdAt: DateTime.now(),
            )
          : existing.copyWith(monthlyLimit: limit),
      isNew: existing == null,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    showAppSnack(context, _isEdit ? 'Budget updated' : 'Budget added');
    navigator.pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null || _busy) return;
    final budgets = context.read<BudgetService>();
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Delete budget?',
      message: 'Your ${existing.category} budget will be removed. Transactions are not affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await budgets.remove(existing.id);
    if (!mounted) return;
    showAppSnack(context, 'Budget deleted');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final budgets = context.watch<BudgetService>();
    final available =
        Categories.budget.where((c) => !budgets.hasCategory(c)).toList();
    final nothingToAdd = !_isEdit && available.isEmpty;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _isEdit ? 'Edit Budget' : 'Set Monthly Budget',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'The limit applies to every month. Progress resets on the 1st.',
            style: TextStyle(color: p.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          if (nothingToAdd)
            Text(
              'Every category already has a budget. Tap one to edit it.',
              style: TextStyle(color: p.textSecondary),
            )
          else ...<Widget>[
            if (_isEdit)
              Text(
                widget.existing!.category == Categories.overall
                    ? 'Overall spending'
                    : widget.existing!.category,
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
              )
            else
              ChipSelector(
                options: available,
                selected: _category,
                iconFor: Categories.iconFor,
                onSelected: (v) => setState(() {
                  _category = v;
                  _error = null;
                }),
              ),
            const SizedBox(height: 16),
            AmountField(
              controller: _limit,
              label: 'Monthly limit',
              hint: 'Enter budget limit',
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.amount(v, emptyMessage: 'Enter budget limit'),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: p.debit)),
            ),
          const SizedBox(height: 18),
          if (!nothingToAdd)
            PrimaryButton(
              label: _isEdit ? 'SAVE CHANGES' : 'SAVE BUDGET',
              loading: _busy,
              onPressed: _save,
            ),
          if (_isEdit) ...<Widget>[
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'DELETE BUDGET',
              danger: true,
              outlined: true,
              onPressed: _busy ? null : _delete,
            ),
          ],
        ],
      ),
    );
  }
}
