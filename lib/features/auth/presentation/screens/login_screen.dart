import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  AppException? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // On success the router sends the user to their home screen.
      await ref.read(authControllerProvider.notifier).login(email: _email.text, password: _password.text);
    } on Object catch (e) {
      if (mounted) setState(() => _error = toAppException(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final auth = ref.watch(authControllerProvider);
    final sessionExpired = auth is Unauthenticated && auth.sessionExpired;

    return Scaffold(
      backgroundColor: p.primary,
      body: Stack(
        children: [
          Positioned(
            top: -110,
            right: -120,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle)),
          ),
          Positioned(
            top: 150,
            left: -70,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.primaryDark, width: 24)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(),
                      const SizedBox(height: 32),
                      Text('Welcome back', style: t.display.copyWith(fontSize: 34, color: p.onPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with the email your hostel registered for you.',
                        style: t.body.copyWith(color: p.onPrimaryMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + MediaQuery.paddingOf(context).bottom),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (sessionExpired) ...[
                                const InfoCallout(
                                  message: 'Your session ended. Please sign in again.',
                                  icon: Icons.lock_clock_outlined,
                                ),
                                const SizedBox(height: 18),
                              ],
                              AppTextField(
                                label: 'Email',
                                controller: _email,
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email, AutofillHints.username],
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Password',
                                controller: _password,
                                obscure: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator: (v) => Validators.required(v, 'Password'),
                                onSubmitted: (_) => _submit(),
                                labelTrailing: GestureDetector(
                                  onTap: () => context.push(Routes.forgotPassword),
                                  child: Text(
                                    'Forgot password?',
                                    style: t.caption.copyWith(color: p.primary, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 18),
                                _LoginErrorCallout(error: _error!),
                              ],
                              const SizedBox(height: 22),
                              AppButton(
                                label: 'Sign in',
                                icon: Icons.arrow_forward_rounded,
                                expand: true,
                                loading: _loading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 28),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    const IconTile(icon: Icons.person_outline_rounded, size: 36),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No sign-up needed. Your hostel admin creates your account and emails you a link to set your password.',
                                        style: t.small.copyWith(color: p.inkSoft),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps the backend's login errors to the three states in the design.
class _LoginErrorCallout extends StatelessWidget {
  const _LoginErrorCallout({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    return switch (error.code) {
      'Password setup required' => const InfoCallout(
          title: "Your account isn't activated yet.",
          message: 'Open the activation link we emailed you, or ask your hostel admin to send a new one.',
          icon: Icons.mark_email_unread_outlined,
        ),
      'Account is not active' => const InfoCallout(
          title: 'This account is on hold.',
          message: 'Your access has been paused by the hostel office. Visit or call them to get it restored.',
          tone: Tone.warning,
          icon: Icons.warning_amber_rounded,
        ),
      'Invalid credentials' => const InfoCallout(
          message: "That email and password don't match. Check for typos, or reset your password.",
          tone: Tone.danger,
          icon: Icons.error_outline_rounded,
        ),
      _ => InfoCallout(message: error.message, tone: Tone.danger, icon: Icons.error_outline_rounded),
    };
  }
}
