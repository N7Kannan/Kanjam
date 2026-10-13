import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/goal.dart';
import '../../services/auth_service.dart';
import '../../services/finance_coordinator.dart';
import '../../services/goal_service.dart';
import '../../widgets/common.dart';
import '../../widgets/goal_card.dart';

/// Savings goals: create, edit, add money, delete.
class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  void _openForm(BuildContext context, {GoalModel? existing}) {
    showKSheet<void>(context, (ctx) => _GoalSheet(existing: existing));
  }

  void _addMoney(BuildContext context, GoalModel goal) {
    showKSheet<void>(context, (ctx) => _AddMoneySheet(goalId: goal.id));
  }

  Future<void> _delete(BuildContext context, GoalModel goal) async {
    final goals = context.read<GoalService>();
    final ok = await showConfirmDialog(
      context,
      title: 'Delete goal?',
      message: '"${goal.name}" and its saved progress will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await goals.remove(goal.id);
    if (context.mounted) showAppSnack(context, 'Goal removed');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final goals = context.watch<GoalService>().goals;
    final saved = round2(goals.fold<double>(0, (a, g) => a + g.currentAmount));
    final target = round2(goals.fold<double>(0, (a, g) => a + g.targetAmount));

    return Scaffold(
      appBar: const KAppBar(title: 'Goals & Savings', showBack: false),
      floatingActionButton: goals.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _openForm(context),
              backgroundColor: p.accent,
              foregroundColor: p.onAccent,
              icon: const Icon(Icons.add),
              label: const Text('CREATE GOAL'),
            ),
      body: goals.isEmpty
          ? SingleChildScrollView(
              child: Center(
                child: EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No financial goals yet',
                  message: 'Save towards a laptop, a trip or an emergency fund and watch it grow.',
                  actionLabel: 'Set Your First Goal',
                  onAction: () => _openForm(context),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              children: <Widget>[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Saved across ${goals.length} goal${goals.length == 1 ? '' : 's'}',
                        style: TextStyle(color: p.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${Fmt.money(saved)} / ${Fmt.money(target)}',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...goals.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalCard(
                      goal: g,
                      onAddMoney: () => _addMoney(context, g),
                      onMenu: (action) {
                        if (action == GoalMenuAction.edit) {
                          _openForm(context, existing: g);
                        } else {
                          _delete(context, g);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({this.existing});

  final GoalModel? existing;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _saved;
  DateTime? _date;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  static String _plain(double v) => v == 0 ? '' : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _target = TextEditingController(text: e == null ? '' : _plain(e.targetAmount));
    _saved = TextEditingController(text: e == null ? '' : _plain(e.currentAmount));
    _date = e?.targetDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _date ?? today.add(const Duration(days: 90));
    final first = initial.isBefore(today) ? initial : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(now.year + 30),
      helpText: 'Target Date',
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final target = AmountParser.tryParse(_target.text);
    final saved = AmountParser.tryParse(_saved.text) ?? 0;
    final userId = context.read<AuthService>().user?.id;
    if (target == null || userId == null) return;
    final coordinator = context.read<FinanceCoordinator>();
    final navigator = Navigator.of(context);
    final existing = widget.existing;

    setState(() {
      _busy = true;
      _error = null;
    });
    final GoalModel goal;
    if (existing == null) {
      goal = GoalModel(
        id: IdGen.next('goal'),
        userId: userId,
        name: _name.text.trim(),
        targetAmount: target,
        currentAmount: saved,
        createdAt: DateTime.now(),
        targetDate: _date,
      );
    } else {
      goal = existing.copyWith(
        name: _name.text.trim(),
        targetAmount: target,
        currentAmount: saved,
        targetDate: _date,
        clearTargetDate: _date == null,
      );
    }
    final error = await coordinator.saveGoal(goal, isNew: existing == null);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    showAppSnack(context, _isEdit ? 'Goal updated' : 'Goal created');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _isEdit ? 'Edit Goal' : 'Set Your First Goal',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          KTextField(
            controller: _name,
            label: 'Goal Name',
            hint: 'e.g. New Laptop',
            icon: Icons.flag_outlined,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.requiredText(v, 'Enter goal name', maxLength: 40),
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _target,
            label: 'Target amount',
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.amount(v, emptyMessage: 'Enter target amount'),
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _saved,
            label: 'Saved so far (optional)',
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.amount(v, allowZero: true, optional: true),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.event_outlined, size: 20, color: p.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _date == null ? 'Target date (optional)' : Fmt.date(_date!),
                      style: TextStyle(color: _date == null ? p.textMuted : p.textPrimary),
                    ),
                  ),
                  if (_date != null)
                    IconButton(
                      tooltip: 'Clear date',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _date = null),
                    ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: p.debit)),
            ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _isEdit ? 'SAVE CHANGES' : 'CREATE GOAL',
            loading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _AddMoneySheet extends StatefulWidget {
  const _AddMoneySheet({required this.goalId});

  final String goalId;

  @override
  State<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<_AddMoneySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final amount = AmountParser.tryParse(_amount.text);
    final goals = context.read<GoalService>();
    final coordinator = context.read<FinanceCoordinator>();
    final navigator = Navigator.of(context);
    // Always use the latest saved amount, not the one captured when the sheet opened.
    final goal = goals.byId(widget.goalId);
    if (amount == null || goal == null) {
      navigator.pop();
      return;
    }
    setState(() => _busy = true);
    await coordinator.addMoneyToGoal(goal, amount);
    if (!mounted) return;
    showAppSnack(context, 'Added ${Fmt.money(amount)} to ${goal.name}');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final goal = context.watch<GoalService>().byId(widget.goalId);
    if (goal == null) return const SizedBox.shrink();
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Add money to ${goal.name}',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${Fmt.money(goal.currentAmount)} saved of ${Fmt.money(goal.targetAmount)}. '
            '${Fmt.money(goal.remaining)} to go.',
            style: TextStyle(color: p.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          AmountField(
            controller: _amount,
            label: 'Amount to add',
            autofocus: true,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.amount(v),
          ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'ADD MONEY', loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}
