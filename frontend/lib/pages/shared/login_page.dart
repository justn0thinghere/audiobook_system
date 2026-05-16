import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/soft_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isRegisterMode = false;
  bool _busy = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pinCtrl.text.length != 4) {
      _toast('PIN must be 4 digits');
      return;
    }
    if (_isRegisterMode && _nameCtrl.text.trim().isEmpty) {
      _toast('Name is required');
      return;
    }
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    final ok = _isRegisterMode
        ? await auth.register(
            name: _nameCtrl.text.trim(),
            pin: _pinCtrl.text,
            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          )
        : await auth.login(
            pin: _pinCtrl.text,
            email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _toast(auth.lastError ?? 'Authentication failed');
  }

  void _toast(String msg) {
    AppSnackbar.warning(msg, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SoftCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68, height: 68,
                    decoration: const BoxDecoration(
                      color: AppColors.iconCircleBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_outlined, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRegisterMode ? 'Create caregiver account' : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegisterMode
                        ? 'Set up a 4-digit PIN to protect Child Mode'
                        : 'Enter your caregiver PIN to continue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  if (_isRegisterMode) ...[
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'Your name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: _isRegisterMode ? 'Email (optional)' : 'Email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: '4-digit PIN',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isRegisterMode ? 'Create account' : 'Sign in',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isRegisterMode = !_isRegisterMode),
                    child: Text(
                      _isRegisterMode
                          ? 'Already have an account? Sign in'
                          : "New here? Create a caregiver account",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
