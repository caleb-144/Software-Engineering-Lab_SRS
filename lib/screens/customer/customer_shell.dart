import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';

import '../../state/app_state.dart';
import '../account_page.dart';
import 'chat_tab.dart';
import 'home_tab.dart';
import 'menu_tab.dart';
import 'orders_tab.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final active = context.watch<AppState>().myOrders.where((o) => o.status.isActive).length;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onGoMenu: () => _go(1)),
          const MenuTab(),
          const OrdersTab(),
          const ChatTab(),
          const AccountPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.local_cafe_outlined),
              selectedIcon: Icon(Icons.local_cafe),
              label: 'Menu'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: active > 0,
                  label: Text('$active'),
                  child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'Orders'),
          const NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Assistant'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }
}
