import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../staff/orders_queue.dart';
import '../staff/stock_history_screen.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final top = s.topSellers();
    final low = s.lowStockItems;
    final onShift = s.onShiftNow;
    return Scaffold(
      appBar: AppBar(title: const Logo(height: 26)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Text('Today',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: StatTile("Today's sales", money(s.todaySales), dark: true)),
            const SizedBox(width: 12),
            Expanded(child: StatTile('Orders today', '${s.todayOrderCount}')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StatTile('Active orders', '${s.activeOrders.length}')),
            const SizedBox(width: 12),
            Expanded(child: StatTile('All-time sales', money(s.allTimeSales))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const OrdersQueue())),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('All orders'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const StockHistoryScreen())),
                icon: const Icon(Icons.history),
                label: const Text('Stock log'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const _Title('Top sellers'),
          if (top.isEmpty)
            const Text('No sales yet.', style: TextStyle(color: Brand.grey))
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        SizedBox(
                            width: 28,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, color: Brand.grey))),
                        Expanded(
                            child: Text(top[i].key,
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                        Text('${top[i].value} sold',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                    ),
                ],
              ),
            ),
          const _Title('Low stock'),
          if (low.isEmpty)
            const Text('All items are well stocked.', style: TextStyle(color: Brand.grey))
          else
            AppCard(
              child: Column(
                children: [
                  for (final m in low)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(
                            child: Text(m.name,
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                        Tag(m.stock == 0 ? 'Out of stock' : '${m.stock} left', filled: true, color: Brand.danger),
                      ]),
                    ),
                ],
              ),
            ),
          const _Title('On shift now'),
          if (onShift.isEmpty)
            const Text('Nobody is checked in.', style: TextStyle(color: Brand.grey))
          else
            AppCard(
              child: Column(
                children: [
                  for (final r in onShift)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        const Icon(Icons.circle, size: 10),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(r.staffName,
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                        Text('since ${fmtTime(r.checkIn)}',
                            style: const TextStyle(color: Brand.grey)),
                      ]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );
}
