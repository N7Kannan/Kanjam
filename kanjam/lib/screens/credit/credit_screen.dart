import 'package:flutter/widgets.dart';

import '../transactions/transaction_form_screen.dart';

/// "Add Credit (Income)" - the transaction form opened on the Credit side.
class CreditScreen extends StatelessWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context) => const TransactionFormScreen(initialCredit: true);
}
