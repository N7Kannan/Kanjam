import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/money.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../services/finance_coordinator.dart';
import '../../widgets/common.dart';
import 'onboarding_flow.dart';
import 'onboarding_scaffold.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _value;
  late String _type;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AuthService>().user?.onboardingDraft ?? const <String, dynamic>{};
    final saved = draft['investBalance'];
    final value = saved is num ? saved.toDouble() : 0.0;
    _value = TextEditingController(text: value > 0 ? value.toStringAsFixed(value % 1 == 0 ? 0 : 2) : '');
    final type = draft['investType'];
    _type = type is String && AppConstants.investmentTypes.contains(type)
        ? type
        : AppConstants.investmentTypes.first;
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  /// Saves the last answers, then turns everything into real accounts.
  Future<void> _complete(Map<String, dynamic> draft) async {
    if (_busy) return;
    final auth = context.read<AuthService>();
    final coordinator = context.read<FinanceCoordinator>();
    setState(() => _busy = true);
    try {
      await auth.saveOnboardingProgress(nextStep: 4, draft: draft);
      await coordinator.completeOnboarding();
      // The AuthGate now shows the dashboard.
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, 'Could not finish setup. Please try again.', error: true);
      }
    }
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final amount = AmountParser.tryParse(_value.text) ?? 0;
    await _complete(<String, dynamic>{
      'investAdded': amount > 0,
      'investType': _type,
      'investBalance': amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 4,
      totalSteps: OnboardingFlow.totalSteps,
      title: 'Add investments',
      subtitle: 'Mutual funds, stocks, gold - enter the current total value. You can add more accounts later.',
      busy: _busy,
      continueLabel: 'FINISH',
      footer: _busy ? 'Almost done...' : 'Your data is stored only on this device.',
      onContinue: _finish,
      onSkip: () => _complete(<String, dynamic>{'investAdded': false}),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ChipSelector(
              options: AppConstants.investmentTypes,
              selected: _type,
              iconFor: (_) => Icons.trending_up,
              onSelected: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 20),
            AmountField(
              controller: _value,
              label: 'Current value',
              hint: '10,000',
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.amount(v, allowZero: true, optional: true),
            ),
          ],
        ),
      ),
    );
  }
}
