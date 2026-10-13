import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'onboarding_flow.dart';
import 'onboarding_scaffold.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<AuthService>().user?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    setState(() => _busy = true);
    try {
      await auth.saveOnboardingProgress(nextStep: 1, name: _name.text);
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
      step: 0,
      totalSteps: OnboardingFlow.totalSteps,
      title: 'What should we call you?',
      subtitle: 'We will use this to greet you on your dashboard.',
      busy: _busy,
      onContinue: _continue,
      child: Form(
        key: _formKey,
        child: KTextField(
          controller: _name,
          label: 'Your Name',
          icon: Icons.person_outline,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 40,
          validator: Validators.name,
          onSubmitted: (_) => _continue(),
        ),
      ),
    );
  }
}
