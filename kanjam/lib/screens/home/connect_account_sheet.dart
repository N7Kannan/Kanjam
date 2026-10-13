import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/account.dart';
import '../../services/account_service.dart';
import '../../services/auth_service.dart';
import '../../services/finance_calculator.dart';
import '../../services/finance_coordinator.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common.dart';

/// Add a new account ("Connect Account") or edit/delete an existing one.
///
/// KANJAM does not talk to banks. An account here is a place you track money;
/// its balance follows the credits and debits you record against it.
Future<void> showAccountSheet(BuildContext context, {AccountModel? existing}) {
  return showKSheet<void>(context, (ctx) => _AccountSheet(existing: existing));
}

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({this.existing});

  final AccountModel? existing;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _last4;
  late AccountType _type;
  String? _provider;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _type = a?.type ?? AccountType.bank;
    _provider = a?.provider;
    _name = TextEditingController(text: a?.name ?? '');
    final opening = a?.openingBalance ?? 0;
    _balance = TextEditingController(
      text: opening == 0 ? '' : opening.toStringAsFixed(opening % 1 == 0 ? 0 : 2),
    );
    _last4 = TextEditingController(text: a?.last4 ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _last4.dispose();
    super.dispose();
  }

  List<String> get _providers {
    switch (_type) {
      case AccountType.bank:
        return AppConstants.bankProviders;
      case AccountType.investment:
        return AppConstants.investmentTypes;
      case AccountType.cash:
        return const <String>[];
    }
  }

  String get _defaultName {
    if (_provider != null && _provider!.isNotEmpty) return _provider!;
    switch (_type) {
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.investment:
        return 'Investments';
      case AccountType.cash:
        return 'Cash Wallet';
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final accounts = context.read<AccountService>();
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    final userId = auth.user?.id;
    if (userId == null) return;

    final name = _name.text.trim().isEmpty ? _defaultName : _name.text.trim();
    final balance = AmountParser.tryParse(_balance.text) ?? 0;
    final last4 = _last4.text.trim().isEmpty ? null : _last4.text.trim();

    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      final existing = widget.existing;
      if (existing == null) {
        error = await accounts.add(AccountModel(
          id: IdGen.next('acc'),
          userId: userId,
          name: name,
          type: _type,
          openingBalance: balance,
          createdAt: DateTime.now(),
          provider: _provider,
          last4: last4,
        ));
      } else {
        error = await accounts.update(existing.copyWith(
          name: name,
          openingBalance: balance,
          provider: _provider,
          last4: last4,
        ));
      }
    } catch (_) {
      error = 'Could not save the account. Please try again.';
    }
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    showAppSnack(context, _isEdit ? 'Account updated' : 'Account added');
    navigator.pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null || _busy) return;
    final coordinator = context.read<FinanceCoordinator>();
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Delete account?',
      message: 'Remove "${existing.name}" from KANJAM? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final error = await coordinator.deleteAccount(existing.id);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    showAppSnack(context, 'Account deleted');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final providers = _providers;
    final existing = widget.existing;

    String? currentBalanceLine;
    if (existing != null) {
      final txs = context.watch<TransactionService>().all;
      final current = FinanceCalculator.balances(<AccountModel>[existing], txs)[existing.id] ?? 0;
      currentBalanceLine = 'Current balance: ${Fmt.money(current)} (opening balance plus recorded credits and debits)';
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _isEdit ? 'Edit Account' : 'Connect Account',
            style: TextStyle(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _isEdit
                ? (currentBalanceLine ?? '')
                : 'Add a bank, cash or investment account to track. KANJAM does not log in to '
                    'your bank; the balance follows the transactions you record.',
            style: TextStyle(color: p.textSecondary, height: 1.4, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          if (!_isEdit) ...<Widget>[
            ChipSelector(
              options: AccountType.values.map((t) => t.label).toList(),
              selected: _type.label,
              onSelected: (label) => setState(() {
                _type = AccountType.values.firstWhere((t) => t.label == label);
                _provider = null;
              }),
            ),
            const SizedBox(height: 14),
          ],
          if (providers.isNotEmpty) ...<Widget>[
            ChipSelector(
              options: providers,
              selected: _provider,
              onSelected: (v) => setState(() => _provider = v),
            ),
            const SizedBox(height: 14),
          ],
          KTextField(
            controller: _name,
            label: 'Account name',
            hint: _defaultName,
            icon: Icons.label_outline,
            maxLength: 40,
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').trim().length > 40 ? 'Name is too long' : null,
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _balance,
            label: _isEdit ? 'Opening balance' : 'Current balance',
            textInputAction: TextInputAction.next,
            validator: (v) => Validators.amount(v, allowZero: true, optional: true),
          ),
          if (_type == AccountType.bank) ...<Widget>[
            const SizedBox(height: 14),
            KTextField(
              controller: _last4,
              label: 'Last 4 digits (optional)',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textInputAction: TextInputAction.done,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                return RegExp(r'^\d{4}$').hasMatch(t) ? null : 'Enter exactly 4 digits';
              },
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: p.debit)),
            ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _isEdit ? 'SAVE CHANGES' : 'CONNECT ACCOUNT',
            loading: _busy,
            onPressed: _save,
          ),
          if (_isEdit) ...<Widget>[
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'DELETE ACCOUNT',
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
