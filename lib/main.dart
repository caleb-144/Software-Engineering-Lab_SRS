import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/manager/manager_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/staff/staff_shell.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // If Firebase cannot start (not configured / offline) the app still opens as a guest.
  var firebaseOk = true;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    firebaseOk = false;
    debugPrint('Firebase could not start: $e');
  }

  final state = AppState();
  await state.init(useFirebase: firebaseOk);
  runApp(ChangeNotifierProvider<AppState>.value(value: state, child: const MinumsApp()));
}

class MinumsApp extends StatelessWidget {
  const MinumsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "THE MINUM'S",
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashGate(child: _Root()),
    );
  }
}

/// Role-based routing (NFR-02): every role only sees its own shell.
/// Nobody logged in = guest, who gets the customer screens in browse-only mode.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Brand.primary)));
    }
    final user = state.user;
    if (user == null) return const CustomerShell();
    switch (user.role) {
      case Role.customer:
        return const CustomerShell();
      case Role.staff:
        return const StaffShell();
      case Role.manager:
        return const ManagerShell();
    }
  }
}
