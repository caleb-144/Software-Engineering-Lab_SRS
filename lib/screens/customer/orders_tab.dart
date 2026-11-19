import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../login_screen.dart';
import 'order_detail_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final orders = state.myOrders;
    if (state.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: EmptyState(
          Icons.receipt_long_outlined,
          'Log in to see your orders',
          subtitle: 'Guests can browse the menu. Log in to order and track your drinks.',
          action: FilledButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Log in / Sign up'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: orders.isEmpty
          ? const EmptyState(Icons.receipt_long_outlined, 'No orders yet',
              subtitle: 'Your orders and receipts will show up here.')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final o = orders[i];
                return AppCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: o.id)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${o.number}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                          StatusBadge(o.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        o.lines.map((l) => '${l.qty} x ${l.name}').join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Brand.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fmtDateTime(o.createdAt),
                              style: const TextStyle(fontSize: 12, color: Brand.grey)),
                          Text(money(o.total),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
