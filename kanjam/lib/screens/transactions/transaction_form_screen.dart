import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/categories.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/account_service.dart';
import '../../services/auth_service.dart';
import '../../services/finance_calculator.dart';
import '../../services/finance_coordinator.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common.dart';
import '../../widgets/credit_debit_toggle.dart';
import '../home/connect_account_sheet.dart';

/// One form for adding and editing both credits and debits.
/// [CreditScreen] and [DebitScreen] open it with the matching kind preselected.
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.existing, this.initialCredit = false});

  final TransactionModel? existing;
  final bool initialCredit;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _note = TextEditingController();

  late bool _isCredit;
  late String _category;
  late String _mode;
  late DateTime _date;
  String? _accountId;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _isCredit = e.isCredit;
      _category = e.category;
      _mode = e.mode;
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      _date = day.isAfter(_today()) ? _today() : day;
      _accountId = e.accountId;
      _amount.text = e.amount.toStringAsFixed(e.amount % 1 == 0 ? 0 : 2);
      _title.text = e.title;
      _note.text = e.note;
    } else {
      _isCredit = widget.initialCredit;
      _category = _categories.first;
      _mode = AppConstants.paymentModes.first;
      _date = _today();
      final accounts = context.read<AccountService>().accounts;
      _accountId = accounts.isEmpty ? null : accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get _categories => _isCredit ? Categories.income : Categories.expense;

  void _setKind(bool credit) {
    if (credit == _isCredit) return;
    setState(() {
      _isCredit = credit;
      if (!_categories.contains(_category)) _category = _categories.first;
    });
  }

  Future<void> _pickDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      setState(() => _error = 'Choose an account for this transaction');
      return;
    }
    final amount = AmountParser.tryParse(_amount.text);
    final userId = context.read<AuthService>().user?.id;
    if (amount == null || userId == null) return;

    final coordinator = context.read<FinanceCoordinator>();
    final navigator = Navigator.of(context);
    final existing = widget.existing;
    final TransactionModel tx;
    if (existing == null) {
      tx = TransactionModel(
        id: IdGen.next('tx'),
        userId: userId,
        isCredit: _isCredit,
        amount: amount,
        category: _category,
        accountId: _accountId!,
        mode: _mode,
        date: _date,
        createdAt: DateTime.now(),
        title: _title.text.trim(),
        note: _note.text.trim(),
      );
    } else {
      tx = existing.copyWith(
        isCredit: _isCredit,
        amount: amount,
        category: _category,
        accountId: _accountId,
        mode: _mode,
        date: _date,
        title: _title.text.trim(),
        note: _note.text.trim(),
      );
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await coordinator.saveTransaction(tx, isEdit: existing != null);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    showAppSnack(
      context,
      _isEdit ? 'Transaction updated' : (_isCredit ? 'Credit Added' : 'Expense Added'),
    );
    navigator.pop();
  }

  /// Warns (without blocking) when a debit is larger than the account holds.
  String? _overdraftWarning(List<AccountModel> accounts, List<TransactionModel> all) {
    if (_isCredit || _accountId == null) return null;
    final amount = AmountParser.tryParse(_amount.text);
    if (amount == null || amount <= 0) return null;
    AccountModel? account;
    for (final a in accounts) {
      if (a.id == _accountId) account = a;
    }
    if (account == null) return null;
    final others = all.where((t) => t.id != widget.existing?.id);
    final balance = FinanceCalculator.balances(<AccountModel>[account], others)[account.id] ?? 0;
    if (amount <= balance) return null;
    return 'This is more than the ${Fmt.money(balance)} in ${account.name}; '
        'the balance will go negative.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final accounts = context.watch<AccountService>().accounts;
    final all = context.watch<TransactionService>().all;
    final balances = FinanceCalculator.balances(
      accounts,
      all.where((t) => t.id != widget.existing?.id),
    );
    final title = _isEdit
        ? 'Edit Transaction'
        : (_isCredit ? 'Add Credit (Income)' : 'Add Debit (Expense)');

    if (accounts.isEmpty) {
      return Scaffold(
        appBar: KAppBar(title: title),
        body: Center(
          child: EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Add an account first',
            message: 'Transactions are recorded against an account such as your cash wallet or bank.',
            actionLabel: 'Connect Account',
            onAction: () => showAccountSheet(context),
          ),
        ),
      );
    }

    // If the chosen account was deleted meanwhile, fall back to the first one.
    if (_accountId == null || !accounts.any((a) => a.id == _accountId)) {
      _accountId = accounts.first.id;
    }
    final warning = _overdraftWarning(accounts, all);

    return Scaffold(
      appBar: KAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CreditDebitToggle(isCredit: _isCredit, onChanged: _setKind),
                const SizedBox(height: 18),
                AmountField(
                  controller: _amount,
                  label: _isCredit ? 'Amount received' : 'Amount spent',
                  autofocus: !_isEdit,
                  validator: (v) => Validators.amount(v),
                  onChanged: (_) => setState(() {}),
                ),
                if (warning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.warning_amber_rounded, size: 18, color: p.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            warning,
                            style: TextStyle(color: p.warning, fontSize: 12.5, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                _Label('Category'),
                ChipSelector(
                  options: _categories,
                  selected: _category,
                  iconFor: Categories.iconFor,
                  onSelected: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 20),
                _Label(_isCredit ? 'Deposit To' : 'Payment Source'),
                ...accounts.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AccountOption(
                      account: a,
                      balance: balances[a.id] ?? 0,
                      selected: a.id == _accountId,
                      onTap: () => setState(() => _accountId = a.id),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Label('Source / Mode'),
                ChipSelector(
                  options: AppConstants.paymentModes,
                  selected: _mode,
                  onSelected: (v) => setState(() => _mode = v),
                ),
                const SizedBox(height: 20),
                _Label('Date'),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.calendar_today_outlined, size: 20, color: p.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Fmt.date(_date),
                            style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: p.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                KTextField(
                  controller: _title,
                  label: 'Description (optional)',
                  hint: _isCredit ? 'e.g. Pocket money' : 'e.g. Lunch with friends',
                  icon: Icons.notes,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                KTextField(
                  controller: _note,
                  label: 'Notes (optional)',
                  icon: Icons.edit_note,
                  maxLength: 200,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: TextStyle(color: p.debit)),
                  ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _isEdit ? 'SAVE CHANGES' : (_isCredit ? 'ADD CREDIT' : 'ADD EXPENSE'),
                  loading: _saving,
                  danger: !_isCredit,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: context.pal.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.account,
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  final AccountModel account;
  final double balance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      label: '${account.name}, balance ${Fmt.money(balance)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? p.accent.withValues(alpha: 0.12) : p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? p.accent : p.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? p.accent : p.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Fmt.money(balance),
                style: TextStyle(
                  color: balance < 0 ? p.debit : p.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
