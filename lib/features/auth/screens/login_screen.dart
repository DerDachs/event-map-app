import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/authentication_provider.dart';
import '../../../providers/user_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../../providers/state_provider.dart';
import '../../../utils/custom_widgets.dart'; // Utility for reusable components
import '../../../utils/apple_sign_in_button.dart'; // Apple sign-in button

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
                child: Text(
                  'Welcome Back!',
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
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password Input
                    CustomTextFormField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Login Button
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : CustomElevatedButton(
                      label: 'Login',
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          try {
                            ref
                                .read(loginLoadingProvider.notifier)
                                .state = true;

                            // Perform login
                            final user = await authRepository.signInWithEmail(
                              _emailController.text,
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
                              SnackBar(content: Text('Error: $e')),
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
                      label: 'Don’t have an account? Register here',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterScreen()),
                        );
                      },
                    ),
                    CustomTextButton(
                      label: 'Forgot Password?',
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