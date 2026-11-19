/// Password / email rules for sign-up. Change the constants to tighten or relax them.
///  - at least [minPasswordLength] characters
///  - at least one letter and one number
///  - at least one special character
class Validators {
  static const int minPasswordLength = 8;
  static const String _specials = r'''!@#$%^&*()_+-=[]{};:'"\|,.<>/?~`''';

  static bool _hasLetter(String p) => RegExp(r'[A-Za-z]').hasMatch(p);
  static bool _hasDigit(String p) => RegExp(r'\d').hasMatch(p);
  static bool _hasSpecial(String p) => p.split('').any(_specials.contains);

  /// Live checklist shown under the password field while signing up.
  static List<({String label, bool ok})> passwordChecks(String p) => [
        (label: 'At least $minPasswordLength characters', ok: p.length >= minPasswordLength),
        (label: 'A letter and a number', ok: _hasLetter(p) && _hasDigit(p)),
        (label: r'A special character (! @ # $ % ...)', ok: _hasSpecial(p)),
      ];

  static String? password(String p) {
    if (p.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    if (!_hasLetter(p) || !_hasDigit(p)) {
      return 'Password needs at least one letter and one number';
    }
    if (!_hasSpecial(p)) {
      return r'Password needs at least one special character, for example ! @ # $ %';
    }
    return null;
  }

  static String? email(String raw) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw.trim());
    return ok ? null : 'Enter a valid email';
  }
}
