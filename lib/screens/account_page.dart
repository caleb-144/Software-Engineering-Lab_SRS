import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../seed.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'account_screens.dart';
import 'customer/orders_tab.dart';
import 'login_screen.dart';
import 'manager/events_screen.dart';
import 'thread_screen.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  String _roleLabel(Role r) =>
      r == Role.customer ? 'Customer' : (r == Role.staff ? 'Staff' : 'Manager');

  void _go(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  List<Widget> _helpAndGeneral(BuildContext context, {required bool signedIn}) => [
        const _Section('Need Help?'),
        _Row(
            icon: Icons.forum_outlined,
            label: 'Help Centre',
            onTap: () => _go(context, const HelpCentreScreen())),
        if (signedIn)
          _Row(
              icon: Icons.star_outline_rounded,
              label: 'Feedback',
              onTap: () => _go(context, const FeedbackScreen())),
        _Row(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => _go(context, const SettingsScreen())),
        const SizedBox(height: 20),
        const _Section('General'),
        _Row(
            icon: Icons.handshake_outlined,
            label: 'Terms & Conditions',
            onTap: () => _go(context, LegalScreen.terms)),
        _Row(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Notice',
            onTap: () => _go(context, LegalScreen.privacy)),
      ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;

    if (u == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              color: Brand.primarySoft,
              outlined: false,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('You are browsing as a guest',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                    'Log in or sign up to place orders, rate your drinks and message the manager.',
                    style: TextStyle(color: Brand.grey)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _go(context, const LoginScreen()),
                  child: const Text('Log in / Sign up'),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            ..._helpAndGeneral(context, signedIn: false),
            const SizedBox(height: 24),
            const Center(
                child: Text('V $kAppVersion', style: TextStyle(color: Brand.grey))),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _go(context, const EditProfileScreen()),
            child: Row(children: [
              UserAvatar(u),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(u.email, style: const TextStyle(color: Brand.grey)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Tag(_roleLabel(u.role), filled: true),
                    const SizedBox(width: 10),
                    const Text('Edit profile',
                        style: TextStyle(
                            color: Brand.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Brand.grey),
            ]),
          ),
          const SizedBox(height: 24),
          if (u.role == Role.customer) ...[
            const _Section('My Purchase'),
            _Row(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                onTap: () => _go(context, const OrdersTab())),
            _Row(
              icon: Icons.support_agent_outlined,
              label: 'Message the manager',
              onTap: () => _go(context, ThreadScreen(customerId: u.id)),
            ),
            const SizedBox(height: 20),
          ],
          if (u.role == Role.manager) ...[
            const _Section('Manage'),
            _Row(
              icon: Icons.event_outlined,
              label: 'Campus events',
              onTap: () => _go(context, const EventsScreen()),
            ),
            const SizedBox(height: 20),
          ],
          ..._helpAndGeneral(context, signedIn: u.role == Role.customer),
          const SizedBox(height: 28),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: Brand.danger,
                side: const BorderSide(color: Brand.danger),
                minimumSize: const Size.fromHeight(50)),
            onPressed: () => s.logout(),
            child: const Text('Log Out'),
          ),
          const SizedBox(height: 10),
          const Center(
              child: Text('V $kAppVersion', style: TextStyle(color: Brand.grey))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Row({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(height: 1),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Brand.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right, color: Brand.primary),
        onTap: onTap,
      ),
    ]);
  }
}
