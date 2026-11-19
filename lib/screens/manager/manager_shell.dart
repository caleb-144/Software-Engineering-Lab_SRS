import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../account_page.dart';
import '../staff/inventory_tab.dart';
import 'dashboard_tab.dart';
import 'messages_tab.dart';
import 'staff_overview_tab.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final waiting = state.threadsAwaitingReply;
    final pending = state.pendingStaff.length;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardTab(),
          InventoryTab(canEdit: true),
          StaffOverviewTab(),
          MessagesTab(),
          AccountPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview'),
          const NavigationDestination(
              icon: Icon(Icons.local_cafe_outlined),
              selectedIcon: Icon(Icons.local_cafe),
              label: 'Menu'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending'),
                  child: const Icon(Icons.groups_outlined)),
              selectedIcon: const Icon(Icons.groups),
              label: 'Staff'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: waiting > 0,
                  label: Text('$waiting'),
                  child: const Icon(Icons.chat_bubble_outline)),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: 'Messages'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }
}
