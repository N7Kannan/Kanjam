import 'package:flutter/widgets.dart';

import '../transactions/transaction_form_screen.dart';

/// "Add Debit (Expense)" - the transaction form opened on the Debit side.
class DebitScreen extends StatelessWidget {
  const DebitScreen({super.key});

  @override
  Widget build(BuildContext context) => const TransactionFormScreen(initialCredit: false);
}
