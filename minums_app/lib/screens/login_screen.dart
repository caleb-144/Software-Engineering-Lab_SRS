import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import 'forgot_password_screen.dart';

/// Opens the login page and returns true if the visitor is logged in afterwards.
/// Used where a guest hits something that needs an account (ordering, messaging the manager).
Future<bool> requireLogin(BuildContext context, {String reason = 'Log in to continue'}) async {
  final s = context.read<AppState>();
  if (s.user != null) return true;
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => LoginScreen(reason: reason)));
  return s.user != null;
}

/// ONE login page for everybody. There is no "pick your role" step: the role
/// (customer / staff / manager) is stored with the account in the database, and the app
/// opens the matching screen right after the password is accepted.
///  - Sign up creates a customer account (the staff switch sends a request Petrus must approve).
///  - The manager account is created by hand in Firebase (no sign-up in the app).
class LoginScreen extends StatefulWidget {
  final String? reason;
  const LoginScreen({super.key, this.reason});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signUp = false, _staff = false, _hide = true, _busy = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error, _info;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final s = context.read<AppState>();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    String? err, info;
    if (_signUp) {
      final r = await s.signUp(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
          asStaff: _staff);
      err = r.error;
      if (err == null && r.pendingApproval) {
        info = 'Request sent! You can log in once Petrus approves your account.';
      }
    } else {
      err = await s.login(_email.text, _password.text);
    }
    if (!mounted) return;
    if (err == null && info == null) {
      Navigator.of(context).popUntil((r) => r.isFirst); // role screen shows automatically
      return;
    }
    setState(() {
      _busy = false;
      _error = err;
      _info = info;
      if (info != null) {
        _signUp = false;
        _staff = false;
        _password.clear();
      }
    });
  }

  Widget _message(IconData icon, String text, Color fg, Color bg) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: fg))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final checks = Validators.passwordChecks(_password.text);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                const Logo(height: 44),
                const SizedBox(height: 24),
                Text(_signUp ? 'Create your account' : 'Welcome back',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                const SizedBox(height: 6),
                Text(
                  widget.reason ??
                      (_signUp
                          ? 'Order ahead and skip the queue.'
                          : 'Log in with your email. We will take you to the right place.'),
                  style: const TextStyle(color: Brand.grey, fontSize: 15),
                ),
                const SizedBox(height: 24),
                if (_signUp) ...[
                  TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Full name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone (optional)')),
                  const SizedBox(height: 12),
                ],
                TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: _hide,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                if (!_signUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ForgotPasswordScreen(initialEmail: _email.text.trim())),
                              ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                if (_signUp) ...[
                  const SizedBox(height: 10),
                  for (final c in checks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Icon(c.ok ? Icons.check_circle : Icons.circle_outlined,
                            size: 16, color: c.ok ? Brand.success : Brand.grey),
                        const SizedBox(width: 8),
                        Text(c.label,
                            style: TextStyle(
                                fontSize: 13, color: c.ok ? Brand.success : Brand.grey)),
                      ]),
                    ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("I work at THE MINUM'S (staff)",
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Petrus must approve your request before you can log in.'),
                    value: _staff,
                    onChanged: (v) => setState(() => _staff = v),
                  ),
                ],
                if (_info != null)
                  _message(Icons.check_circle_outline, _info!, Brand.success, Brand.successSoft),
                if (_error != null)
                  _message(Icons.error_outline, _error!, Brand.danger, Brand.dangerSoft),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Brand.white))
                      : Text(_signUp ? (_staff ? 'Send request' : 'Sign up') : 'Log in'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _signUp = !_signUp;
                            _error = null;
                            _info = null;
                          }),
                  child: Text(_signUp ? 'Already have an account? Log in' : 'New here? Create an account'),
                ),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue as guest')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
