import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  bool _isRegistering = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      return;
    }

    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    final bloc = context.read<AuthBloc>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isRegistering) {
      bloc.add(
        AuthSignUpRequested(
          email: email,
          password: password,
          displayName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        ),
      );
    } else {
      bloc.add(AuthSignInRequested(email: email, password: password));
    }
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() => _isRegistering = !_isRegistering);
  }

  void _toggleObscure() {
    HapticFeedback.selectionClick();
    setState(() => _obscure = !_obscure);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final isSubmitting =
        context.watch<AuthBloc>().state.status == AuthStatus.authenticating;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final message = state.errorMessage;
        if (message == null) return;
        HapticFeedback.mediumImpact();
        _shake.forward(from: 0);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AmbientBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──────────────────────────────────────────
                      const Reveal(child: Align(child: BrandMark(size: 68))),
                      const SizedBox(height: 24),
                      Reveal(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Reveal(
                        delay: const Duration(milliseconds: 160),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: AppTheme.emphasized,
                          child: Text(
                            _isRegistering
                                ? 'Create your account in seconds.'
                                : 'Track every expense, offline first.',
                            key: ValueKey(_isRegistering),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Form card ───────────────────────────────────────
                      Reveal(
                        delay: const Duration(milliseconds: 260),
                        child: AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) {
                            final dx =
                                math.sin(_shake.value * math.pi * 5) *
                                10 *
                                (1 - _shake.value);
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow.withValues(
                                alpha: dark ? 0.78 : 0.88,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: dark ? 0.35 : 0.06,
                                  ),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 450),
                                    curve: AppTheme.emphasized,
                                    alignment: Alignment.topCenter,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: _isRegistering
                                          ? Padding(
                                              key: const ValueKey('name'),
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: TextFormField(
                                                controller: _nameController,
                                                textInputAction:
                                                    TextInputAction.next,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                autofillHints: const [
                                                  AutofillHints.name,
                                                ],
                                                onFieldSubmitted: (_) =>
                                                    _emailFocus.requestFocus(),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Name (optional)',
                                                      prefixIcon: Icon(
                                                        Icons.person_outline,
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : const SizedBox(
                                              key: ValueKey('no-name'),
                                              width: double.infinity,
                                            ),
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    onFieldSubmitted: (_) =>
                                        _passwordFocus.requestFocus(),
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.mail_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter your email.';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Enter a valid email.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: _toggleObscure,
                                        icon: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          transitionBuilder: (child, anim) =>
                                              ScaleTransition(
                                                scale: anim,
                                                child: child,
                                              ),
                                          child: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            key: ValueKey(_obscure),
                                          ),
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.length < 6) {
                                        return 'Password must be at least 6 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  PressableScale(
                                    enabled: !isSubmitting,
                                    child: FilledButton(
                                      onPressed: isSubmitting ? null : _submit,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        child: isSubmitting
                                            ? const SizedBox(
                                                key: ValueKey('busy'),
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                _isRegistering
                                                    ? 'Create account'
                                                    : 'Sign in',
                                                key: ValueKey(_isRegistering),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Mode toggle ─────────────────────────────────────
                      Reveal(
                        delay: const Duration(milliseconds: 380),
                        dy: 14,
                        child: PressableScale(
                          enabled: !isSubmitting,
                          pressedScale: 0.98,
                          child: TextButton(
                            onPressed: isSubmitting ? null : _toggleMode,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isRegistering
                                    ? 'Already have an account? Sign in'
                                    : 'New here? Create an account',
                                key: ValueKey(_isRegistering),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
