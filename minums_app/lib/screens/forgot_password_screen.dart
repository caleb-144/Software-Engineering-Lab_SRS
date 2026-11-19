import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// "Forgot password?" - emails a secure one-time reset link (sent by Firebase).
/// The screen never says whether an account exists for the email.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false, _sent = false;
  String? _error;
  int _wait = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = context.read<AppState>().resetWaitSeconds;
      if (!mounted) return;
      setState(() => _wait = left);
      if (left == 0) _ticker?.cancel();
    });
  }

  Future<void> _send() async {
    if (_busy || _wait > 0) return;
    final s = context.read<AppState>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await s.sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
      if (err == null) _sent = true;
      _wait = s.resetWaitSeconds;
    });
    if (_wait > 0) _startTicker();
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Reset your password',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                const SizedBox(height: 6),
                const Text(
                    'Enter your account email. If it matches an account, we will email you a secure link to choose a new password.',
                    style: TextStyle(color: Brand.grey, fontSize: 15)),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                if (_sent)
                  _msg(
                      Icons.mark_email_read_outlined,
                      'If that email has an account, a reset link is on its way. '
                      'Check your inbox and spam folder. The link works once and expires in about an hour.',
                      Brand.success,
                      Brand.successSoft),
                if (_error != null) _msg(Icons.error_outline, _error!, Brand.danger, Brand.dangerSoft),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: (_busy || _wait > 0) ? null : _send,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Brand.white))
                      : Text(_wait > 0
                          ? 'Send again in ${_wait}s'
                          : (_sent ? 'Send again' : 'Send reset link')),
                ),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to log in')),
                const SizedBox(height: 12),
                const Text(
                    'Tip: after resetting, log in with the new password. Never share the link with anyone.',
                    style: TextStyle(color: Brand.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _msg(IconData icon, String text, Color fg, Color bg) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: fg))),
        ]),
      );
}
