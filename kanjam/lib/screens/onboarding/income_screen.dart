import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/money.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'onboarding_flow.dart';
import 'onboarding_scaffold.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _income;
  late String _source;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    final saved = user?.monthlyIncome ?? 0;
    _income = TextEditingController(text: saved > 0 ? saved.toStringAsFixed(saved % 1 == 0 ? 0 : 2) : '');
    _source = user?.incomeSource ?? AppConstants.incomeSources.first;
  }

  @override
  void dispose() {
    _income.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    try {
      await auth.saveOnboardingProgress(
        nextStep: 2,
        monthlyIncome: AmountParser.tryParse(_income.text) ?? 0,
        incomeSource: _source,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, 'Could not save. Please try again.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 1,
      totalSteps: OnboardingFlow.totalSteps,
      title: 'What is your monthly income?',
      subtitle: 'Salary, pocket money or anything that comes in each month. Enter 0 if you have none yet.',
      busy: _busy,
      onContinue: _continue,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AmountField(
              controller: _income,
              label: 'Monthly income',
              hint: '50,000',
              autofocus: true,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  Validators.amount(v, allowZero: true, emptyMessage: 'Please enter monthly income'),
            ),
            const SizedBox(height: 20),
            const Text('Main source', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ChipSelector(
              options: AppConstants.incomeSources,
              selected: _source,
              onSelected: (v) => setState(() => _source = v),
            ),
          ],
        ),
      ),
    );
  }
}
