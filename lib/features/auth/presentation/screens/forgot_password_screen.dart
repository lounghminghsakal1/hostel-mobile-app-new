import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_providers.dart';
import '../widgets/result_illustration.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(requestPasswordResetProvider)(_email.text);
      if (mounted) setState(() => _sent = true);
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _backToLogin() => context.canPop() ? context.pop() : context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppTopBar(showBack: true, onBack: _backToLogin, backgroundColor: context.colors.surface),
      body: SafeArea(
        top: false,
        child: _sent ? _buildSent(context) : _buildForm(context, t),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AppTextStyles t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(alignment: Alignment.centerLeft, child: IconTile(icon: Icons.lock_reset_rounded, size: 72)),
            const SizedBox(height: 28),
            Text('Forgot your password?', style: t.display),
            const SizedBox(height: 10),
            Text("No worries. Enter your email and we'll send you a link to set a new one.", style: t.body),
            const SizedBox(height: 28),
            AppTextField(
              label: 'Email',
              controller: _email,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Send reset link', expand: true, loading: _loading, onPressed: _submit),
            const SizedBox(height: 16),
            Center(
              child: TextButton(onPressed: _backToLogin, child: const Text('Back to sign in')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSent(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          const ResultIllustration(icon: Icons.mark_email_read_outlined),
          const SizedBox(height: 26),
          Text('Check your inbox', style: t.display, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'If an account exists for '),
              TextSpan(text: _email.text.trim(), style: t.body.copyWith(color: context.colors.ink, fontWeight: FontWeight.w700)),
              const TextSpan(text: ', a reset link is on its way.'),
            ]),
            style: t.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const InfoCallout(
            title: 'The link works for 5 minutes.',
            message: 'Open it on this phone to jump straight into the app.',
            tone: Tone.warning,
            icon: Icons.schedule_rounded,
          ),
          const Spacer(),
          AppButton(label: 'Back to sign in', expand: true, onPressed: () => context.go(Routes.login)),
          const SizedBox(height: 8),
          TextButton(onPressed: () => setState(() => _sent = false), child: const Text("Didn't get it? Send again")),
        ],
      ),
    );
  }
}
