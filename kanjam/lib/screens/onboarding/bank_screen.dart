import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'onboarding_flow.dart';
import 'onboarding_scaffold.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balance;
  String? _provider;
  String? _providerError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AuthService>().user?.onboardingDraft ?? const <String, dynamic>{};
    final saved = draft['bankBalance'];
    final value = saved is num ? saved.toDouble() : 0.0;
    _balance = TextEditingController(text: value > 0 ? value.toStringAsFixed(value % 1 == 0 ? 0 : 2) : '');
    final provider = draft['bankProvider'];
    _provider = provider is String && provider.isNotEmpty ? provider : null;
  }

  @override
  void dispose() {
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save(Map<String, dynamic> draft) async {
    if (_busy) return;
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    try {
      await auth.saveOnboardingProgress(nextStep: 4, draft: draft);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, 'Could not save. Please try again.', error: true);
      }
    }
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final balance = AmountParser.tryParse(_balance.text) ?? 0;
    if (_provider == null) {
      // A balance without a bank is ambiguous; ask which bank it belongs to.
      setState(() => _providerError = 'Choose your bank to continue, or tap Skip');
      return;
    }
    setState(() => _providerError = null);
    await _save(<String, dynamic>{
      'bankAdded': true,
      'bankProvider': _provider,
      'bankBalance': balance,
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return OnboardingScaffold(
      step: 3,
      totalSteps: OnboardingFlow.totalSteps,
      title: 'Add your bank account',
      subtitle:
          'Pick your bank and enter the current balance. KANJAM tracks it from the transactions you record. It does not log in to your bank.',
      busy: _busy,
      onContinue: _continue,
      continueLabel: 'CONNECT ACCOUNT',
      onSkip: () => _save(<String, dynamic>{'bankAdded': false}),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChipSelector(
              options: AppConstants.bankProviders,
              selected: _provider,
              iconFor: (_) => Icons.account_balance,
              onSelected: (v) => setState(() {
                _provider = v;
                _providerError = null;
              }),
            ),
            if (_providerError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_providerError!, style: TextStyle(color: p.debit, fontSize: 12.5)),
              ),
            const SizedBox(height: 20),
            AmountField(
              controller: _balance,
              label: 'Current balance',
              hint: '25,000',
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.amount(v, allowZero: true, optional: true),
            ),
          ],
        ),
      ),
    );
  }
}
