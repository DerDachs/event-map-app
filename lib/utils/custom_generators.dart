import 'dart:math';

String generateTeamCode() {
  const length = 6; // Length of the team code
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(Iterable.generate(
    length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
  ));
}