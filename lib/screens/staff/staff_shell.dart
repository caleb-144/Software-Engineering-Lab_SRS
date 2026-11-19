import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../account_page.dart';
import 'attendance_tab.dart';
import 'inventory_tab.dart';
import 'orders_queue.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final active = context.watch<AppState>().activeOrders.length;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          OrdersQueue(),
          InventoryTab(),
          AttendanceTab(),
          AccountPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: active > 0,
                  label: Text('$active'),
                  child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'Orders'),
          const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory'),
          const NavigationDestination(
              icon: Icon(Icons.access_time),
              selectedIcon: Icon(Icons.access_time_filled),
              label: 'Attendance'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }
}
