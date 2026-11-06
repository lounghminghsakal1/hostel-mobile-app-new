import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_providers.dart';
import '../widgets/result_illustration.dart';

enum SetPasswordMode { welcome, reset }

/// Opened from the emailed link, for first-time activation or a reset.
///
/// Deep link format: `/set-password?token=<raw token>&mode=welcome|reset`.
/// The email currently links to the web app; to open the mobile app the
/// link must use a verified App Link / Universal Link (see docs/API_GAPS.md).
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key, required this.token, this.mode = SetPasswordMode.welcome});

  final String? token;
  final SetPasswordMode mode;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  late bool _expired = widget.token == null || widget.token!.isEmpty;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(setNewPasswordProvider)(token: widget.token!, newPassword: _password.text);
      if (!mounted) return;
      context.showMessage('Password saved. Sign in with your new password.');
      context.go(Routes.login);
    } on AppException catch (e) {
      if (!mounted) return;
      final status = e.statusCode ?? 0;
      if (status >= 400 && status < 500) {
        setState(() => _expired = true);
      } else {
        context.showError(e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(child: _expired ? _buildExpired(context) : _buildForm(context)),
    );
  }

  Widget _buildForm(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final welcome = widget.mode == SetPasswordMode.welcome;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(label: welcome ? 'Account setup' : 'Password reset', tone: Tone.primary, showDot: false),
          ),
          const SizedBox(height: 18),
          Text(welcome ? 'Welcome! Set your password' : 'Reset your password', style: t.display),
          const SizedBox(height: 10),
          Text(
            welcome
                ? "Your hostel created your account. Pick a password to activate it, and you're in."
                : "Choose a new password. You'll use it the next time you sign in.",
            style: t.body,
          ),
          const SizedBox(height: 28),
          ValueListenableBuilder(
            valueListenable: _password,
            builder: (context, value, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'New password',
                  controller: _password,
                  obscure: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.newPassword,
                ),
                const SizedBox(height: 10),
                PasswordStrengthBar(password: value.text),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Confirm password',
            controller: _confirm,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: Validators.matches(() => _password.text),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(16)),
            child: Text(
              'Use at least 8 characters, including a number.',
              style: t.small.copyWith(color: p.inkSoft),
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: welcome ? 'Activate my account' : 'Save new password',
            expand: true,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildExpired(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
      child: Column(
        children: [
          const ResultIllustration(icon: Icons.schedule_rounded, tone: Tone.accent),
          const SizedBox(height: 26),
          Text('This link has expired', style: t.display, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'To keep your account safe, links only work for 5 minutes. Request a fresh one and open it right away.',
            style: t.body,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          AppButton(label: 'Send me a new link', expand: true, onPressed: () => context.go(Routes.forgotPassword)),
          const SizedBox(height: 12),
          AppButton(
            label: 'Back to sign in',
            variant: ButtonVariant.outline,
            expand: true,
            onPressed: () => context.go(Routes.login),
          ),
        ],
      ),
    );
  }
}
