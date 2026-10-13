import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../services/account_service.dart';
import '../../services/finance_coordinator.dart';
import '../../widgets/category_badge.dart';
import '../../widgets/common.dart';
import 'transaction_form_screen.dart';

/// Bottom sheet with every field of a transaction plus Edit and Delete.
Future<void> showTransactionDetails(BuildContext context, TransactionModel tx) {
  return showKSheet<void>(context, (ctx) => _TransactionDetails(tx: tx));
}

class _TransactionDetails extends StatefulWidget {
  const _TransactionDetails({required this.tx});

  final TransactionModel tx;

  @override
  State<_TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<_TransactionDetails> {
  bool _busy = false;

  Widget _row(BuildContext context, String label, String value) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(label, style: TextStyle(color: p.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    if (_busy) return;
    final coordinator = context.read<FinanceCoordinator>();
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete transaction?',
      message: 'This will remove it from your balance, budgets and reports.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await coordinator.deleteTransaction(widget.tx.id);
      if (!mounted) return;
      showAppSnack(context, 'Transaction deleted');
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(context, 'Could not delete. Please try again.', error: true);
    }
  }

  void _edit() {
    final navigator = Navigator.of(context);
    final tx = widget.tx;
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => TransactionFormScreen(existing: tx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tx = widget.tx;
    final account = context.read<AccountService>().byId(tx.accountId);
    final color = tx.isCredit ? p.credit : p.debit;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            CategoryBadge(category: tx.category, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tx.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${tx.isCredit ? '+' : '-'}${Fmt.money(tx.amount)}',
            style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: p.border),
        _row(context, 'Type', tx.isCredit ? 'Credit (income)' : 'Debit (expense)'),
        _row(context, 'Category', tx.category),
        _row(context, 'Account', account?.name ?? 'Deleted account'),
        _row(context, 'Mode', tx.mode),
        _row(context, 'Date', '${Fmt.longDate(tx.date)}, ${tx.date.year}'),
        if (tx.note.trim().isNotEmpty) _row(context, 'Notes', tx.note.trim()),
        Divider(color: p.border),
        const SizedBox(height: 12),
        PrimaryButton(label: 'EDIT', icon: Icons.edit_outlined, outlined: true, onPressed: _busy ? null : _edit),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'DELETE TRANSACTION',
          icon: Icons.delete_outline,
          danger: true,
          loading: _busy,
          onPressed: _delete,
        ),
      ],
    );
  }
}
