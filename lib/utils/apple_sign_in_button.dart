import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:market_mates/l10n/l10n.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AppleSignInButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SignInWithAppleButton(
      onPressed: onPressed,
      text: context.l10n.signInWithApple,
      style: SignInWithAppleButtonStyle.black,
    );
  }
}