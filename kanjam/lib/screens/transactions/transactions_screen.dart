import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../services/account_service.dart';
import '../../services/finance_calculator.dart';
import '../../services/transaction_service.dart';
import '../../widgets/common.dart';
import '../../widgets/transaction_tile.dart';
import '../credit/credit_screen.dart';
import '../debit/debit_screen.dart';
import 'transaction_details.dart';

/// Full history with Credit / Debit tabs, text search and a date range.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();
  int _tab = 0; // 0 = all, 1 = credit, 2 = debit
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasFilters => _from != null || _search.text.trim().isNotEmpty;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      helpText: 'Date Range',
      saveText: 'APPLY',
    );
    if (picked != null && mounted) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _from = null;
      _to = null;
    });
  }

  void _chooseKind() {
    showKSheet<void>(context, (ctx) {
      final p = ctx.pal;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Add transaction',
            style: TextStyle(color: p.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'ADD CREDIT',
            icon: Icons.south_west,
            onPressed: () {
              final navigator = Navigator.of(ctx);
              navigator.pop();
              navigator.push(MaterialPageRoute<void>(builder: (_) => const CreditScreen()));
            },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'ADD EXPENSE',
            icon: Icons.north_east,
            danger: true,
            onPressed: () {
              final navigator = Navigator.of(ctx);
              navigator.pop();
              navigator.push(MaterialPageRoute<void>(builder: (_) => const DebitScreen()));
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final service = context.watch<TransactionService>();
    final accounts = context.watch<AccountService>();

    final base = service.filter(from: _from, to: _to, query: _search.text);
    final credits = base.where((t) => t.isCredit).length;
    final debits = base.length - credits;
    final List<TransactionModel> visible = switch (_tab) {
      1 => base.where((t) => t.isCredit).toList(),
      2 => base.where((t) => !t.isCredit).toList(),
      _ => base,
    };
    final totals = FinanceCalculator.summarize(visible);

    return Scaffold(
      appBar: const KAppBar(title: 'Transactions', showBack: false),
      floatingActionButton: FloatingActionButton(
        // Several tabs stay alive at once, so FABs must not share a hero tag.
        heroTag: null,
        tooltip: 'Add transaction',
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        onPressed: _chooseKind,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: p.textPrimary),
                    textInputAction: TextInputAction.search,
                    decoration: kInputDecoration(
                      context,
                      hint: 'Search transactions',
                      icon: Icons.search,
                      suffix: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                    ).copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter by date range',
                  onPressed: _pickRange,
                  icon: Icon(Icons.date_range, color: _from != null ? p.accent : p.textSecondary),
                ),
              ],
            ),
          ),
          if (_from != null && _to != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text('${Fmt.dateShort(_from!)} - ${Fmt.dateShort(_to!)}'),
                  onDeleted: () => setState(() {
                    _from = null;
                    _to = null;
                  }),
                  deleteButtonTooltipMessage: 'Clear date range',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: <Widget>[
                Expanded(child: FilterPill(label: 'All (${base.length})', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
                const SizedBox(width: 8),
                Expanded(child: FilterPill(label: 'Credit ($credits)', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
                const SizedBox(width: 8),
                Expanded(child: FilterPill(label: 'Debit ($debits)', selected: _tab == 2, onTap: () => setState(() => _tab = 2))),
              ],
            ),
          ),
          if (visible.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${visible.length} shown',
                      style: TextStyle(color: p.textMuted, fontSize: 12.5),
                    ),
                  ),
                  if (_tab != 2)
                    Text(
                      Fmt.money(totals.income, signed: true),
                      style: TextStyle(color: p.credit, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  if (_tab == 0) const SizedBox(width: 12),
                  if (_tab != 1)
                    Text(
                      '-${Fmt.money(totals.expense)}',
                      style: TextStyle(color: p.debit, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? SingleChildScrollView(
                    child: Center(
                      child: service.all.isEmpty
                          ? EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No transactions recorded yet.',
                              message: 'Add your first credit or expense and it will show up here.',
                              actionLabel: 'Add Transaction',
                              onAction: _chooseKind,
                            )
                          : EmptyState(
                              icon: Icons.search_off,
                              title: 'No matching transactions',
                              message: _hasFilters
                                  ? 'Try a different search or date range.'
                                  : 'Nothing in this tab yet.',
                              actionLabel: _hasFilters ? 'Clear filters' : null,
                              onAction: _hasFilters ? _clearFilters : null,
                            ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: p.border),
                    itemBuilder: (context, index) {
                      final tx = visible[index];
                      return TransactionTile(
                        transaction: tx,
                        accountName: accounts.byId(tx.accountId)?.name ?? 'Deleted account',
                        onTap: () => showTransactionDetails(context, tx),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
