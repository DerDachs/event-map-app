import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authentication_provider.dart';
import '../../../providers/user_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../../providers/state_provider.dart';
import '../../../utils/custom_widgets.dart'; // Utility for reusable components
import '../../../utils/apple_sign_in_button.dart'; // Apple sign-in button
import '../services/auth_errors.dart';
import 'package:market_mates/l10n/l10n.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For input validation

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = ref.watch(authRepositoryProvider);
    final isLoading = ref.watch(loginLoadingProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/brand/market-mate-logo.png',
                  height: 64,
                  semanticLabel: 'Market Mate',
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  context.l10n.loginWelcome,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Input
                    CustomTextFormField(
                      controller: _emailController,
                      label: context.l10n.emailLabel,
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.loginEmailRequired;
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) {
                          return context.l10n.loginEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password Input
                    CustomTextFormField(
                      controller: _passwordController,
                      label: context.l10n.passwordLabel,
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.loginPasswordRequired;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Login Button
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : CustomElevatedButton(
                      label: context.l10n.loginButton,
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          try {
                            ref
                                .read(loginLoadingProvider.notifier)
                                .state = true;

                            // Perform login
                            final user = await authRepository.signInWithEmail(
                              _emailController.text.trim(),
                              _passwordController.text,
                            );

                            // Load user profile
                            await ref
                                .read(userProfileProvider.notifier)
                                .loadUserProfile(user.uid);

                            // Navigate to home screen
                            Navigator.pushReplacementNamed(
                                context, '/home');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(authErrorMessage(e, context.l10n))),
                            );
                          } finally {
                            ref
                                .read(loginLoadingProvider.notifier)
                                .state = false;
                          }
                        }
                      },
                    ),
                    SizedBox(height: 20),

                    // Apple Sign-In Button
                    AppleSignInButton(
                      onPressed: () => authRepository.handleAppleSignIn(context, ref),
                    ),
                    SizedBox(height: 20),

                    // Register and Forgot Password Links
                    CustomTextButton(
                      label: context.l10n.loginNoAccount,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterScreen()),
                        );
                      },
                    ),
                    CustomTextButton(
                      label: context.l10n.loginForgotPassword,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}