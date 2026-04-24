import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/fitai_button.dart';
import '../../widgets/common/fitai_text_field.dart';
import '../../widgets/common/keyboard_dismisser.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    setState(() {
      _emailError = null;
    });

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      return;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      return;
    }

    final success = await ref
        .read(authStateProvider.notifier)
        .sendPasswordResetEmail(email);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSuccess = true;
      });
    } else {
      final error = ref.read(authStateProvider).errorMessage;
      if (error != null) {
        SnackBarHelper.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: KeyboardDismisser(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Header
                const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Color(0xFF6C63FF),
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'FitAI',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(
                        0x336C63FF,
                      ), // 20% opacity of 0xFF6C63FF
                      width: 1,
                    ),
                  ),
                  child: _isSuccess
                      ? _buildSuccessState()
                      : _buildFormState(authState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email and we\'ll send you a reset link',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            color: Color(0xFF9E9EBE),
          ),
        ),
        const SizedBox(height: 32),
        FitAITextField(
          label: 'Email',
          hint: 'Enter your email',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          errorText: _emailError,
        ),
        const SizedBox(height: 32),
        FitAIButton(
          label: 'Send Reset Link →',
          isLoading: authState.isLoading,
          onPressed: _validateAndSubmit,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
          child: const Text(
            '← Back to Login',
            style: TextStyle(
              color: Color(0xFF9E9EBE),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Icon(Icons.check_circle, color: Color(0xFF43E97B), size: 72),
        ),
        const SizedBox(height: 24),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a reset link to ${_emailController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            color: Color(0xFF9E9EBE),
          ),
        ),
        const SizedBox(height: 32),
        FitAIButton(
          label: 'Back to Login',
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
