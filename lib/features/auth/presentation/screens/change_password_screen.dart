import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_providers.dart';

/// Used by both students (from Profile) and admins (from the account sheet).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _currentError = null;
    });
    try {
      await ref.read(changePasswordProvider)(currentPassword: _current.text, newPassword: _next.text);
      if (!mounted) return;
      context.showMessage('Password updated.');
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.code == 'Invalid current password') {
        setState(() => _currentError = "That isn't your current password.");
      } else {
        context.showError(e);
      }
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.colors.surface;
    return Scaffold(
      backgroundColor: surface,
      appBar: AppTopBar(title: 'Change password', showBack: true, backgroundColor: surface),
      bottomNavigationBar: BottomActionBar(
        children: [AppButton(label: 'Update password', loading: _loading, onPressed: _submit)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text("Use at least 8 characters with a number. You'll stay signed in on this phone.", style: context.text.body),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Current password',
              controller: _current,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
              autofillHints: const [AutofillHints.password],
              errorText: _currentError,
              onChanged: (_) {
                if (_currentError != null) setState(() => _currentError = null);
              },
              validator: (v) => Validators.required(v, 'Current password'),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 18),
            ValueListenableBuilder(
              valueListenable: _next,
              builder: (context, value, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'New password',
                    controller: _next,
                    obscure: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) =>
                        Validators.newPassword(v) ?? (v == _current.text ? 'Pick a password different from your current one' : null),
                  ),
                  const SizedBox(height: 10),
                  PasswordStrengthBar(password: value.text),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Confirm new password',
              controller: _confirm,
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.matches(() => _next.text),
            ),
          ],
        ),
      ),
    );
  }
}
