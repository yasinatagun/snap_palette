import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/logger.dart';
import '../../../../providers/index.dart';
import '../../../app/presentation/screens/main_screen.dart';

// Provider for login form state
final loginFormProvider = NotifierProvider<LoginFormNotifier, LoginFormState>(
  () => LoginFormNotifier(),
);

// Login form state
class LoginFormState {
  final String email;
  final String password;
  final bool isLoading;
  final bool obscurePassword;

  LoginFormState({
    this.email = 'demo@demo.com',
    this.password = '123456',
    this.isLoading = false,
    this.obscurePassword = true,
  });

  // Create a copy with updated fields
  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    bool? obscurePassword,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

// Notifier for login form
class LoginFormNotifier extends Notifier<LoginFormState> {
  @override
  LoginFormState build() {
    return LoginFormState();
  }

  // Update email
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  // Update password
  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  // Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // Handle login
  Future<void> login(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    if (!formKey.currentState!.validate()) return;

    setLoading(true);
    try {
      await ref
          .read(userProvider.notifier)
          .signIn(state.email.trim(), state.password);
      if (context.mounted) {
        // Navigate to main screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      logger.logError('Login error', e);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setLoading(false);
    }
  }
}

/// Login screen for user authentication
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final user = ref.watch(userProvider);
    final formState = ref.watch(loginFormProvider);
    final formNotifier = ref.watch(loginFormProvider.notifier);
    final theme = Theme.of(context);

    // If user is already logged in, navigate to main screen
    if (user != null) {
      return const MainScreen();
    }

    // Handle login function
    Future<void> handleLogin() async {
      if (!formKey.currentState!.validate()) return;

      formNotifier.setLoading(true);
      try {
        await ref
            .read(userProvider.notifier)
            .signIn(formState.email.trim(), formState.password);
        if (context.mounted) {
          // Navigate to main screen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        logger.logError('Login error', e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        formNotifier.setLoading(false);
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo or App Icon
                        Container(
                          height: 80,
                          width: 80,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.color_lens,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),

                        Text(
                          'Snap Palette',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Gap(8),

                        Text(
                          'Welcome Back',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Gap(32),

                        TextFormField(
                          initialValue: formState.email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: formNotifier.updateEmail,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const Gap(16),

                        TextFormField(
                          initialValue: formState.password,
                          obscureText: formState.obscurePassword,
                          onChanged: formNotifier.updatePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: theme.colorScheme.primary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                formState.obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.7,
                                ),
                              ),
                              onPressed: formNotifier.togglePasswordVisibility,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),

                        const Gap(16),

                        FilledButton(
                          onPressed: formState.isLoading ? null : handleLogin,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              formState.isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),

                        const Gap(24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account?',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to register screen
                              },
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
