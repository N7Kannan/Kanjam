import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'onboarding_flow.dart';
import 'onboarding_scaffold.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cash;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthService>().user?.onboardingDraft['cash'];
    final value = saved is num ? saved.toDouble() : 0.0;
    _cash = TextEditingController(text: value > 0 ? value.toStringAsFixed(value % 1 == 0 ? 0 : 2) : '');
  }

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  Future<void> _save(double amount) async {
    if (_busy) return;
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    try {
      await auth.saveOnboardingProgress(nextStep: 3, draft: <String, dynamic>{'cash': amount});
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
    await _save(AmountParser.tryParse(_cash.text) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      totalSteps: OnboardingFlow.totalSteps,
      title: 'Add cash',
      subtitle: 'How much cash do you have on hand right now? It goes into your Cash Wallet.',
      busy: _busy,
      onContinue: _continue,
      onSkip: () => _save(0),
      child: Form(
        key: _formKey,
        child: AmountField(
          controller: _cash,
          label: 'Cash in hand',
          hint: '5,000',
          autofocus: true,
          textInputAction: TextInputAction.done,
          validator: (v) => Validators.amount(v, allowZero: true, optional: true),
        ),
      ),
    );
  }
}
