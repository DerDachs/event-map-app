import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AppleSignInButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SignInWithAppleButton(
      onPressed: onPressed,
      style: SignInWithAppleButtonStyle.black,
    );
  }
}