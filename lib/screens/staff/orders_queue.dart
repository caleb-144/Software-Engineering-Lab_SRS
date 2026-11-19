import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../customer/order_detail_screen.dart';

/// Order fulfilment for staff and manager: advance status, confirm payment, cancel.
class OrdersQueue extends StatefulWidget {
  final bool showAppBar;
  const OrdersQueue({this.showAppBar = true});

  @override
  State<OrdersQueue> createState() => _OrdersQueueState();
}

class _OrdersQueueState extends State<OrdersQueue> {
  String _filter = 'Active';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.orders.where((o) {
      switch (_filter) {
        case 'Active':
          return o.status.isActive;
        case 'Unpaid':
          return !o.paid && o.status != OrderStatus.cancelled;
        case 'Done':
          return o.status == OrderStatus.completed || o.status == OrderStatus.cancelled;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                for (final f in ['Active', 'Unpaid', 'Done', 'All']) ...[
                  Pill(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(Icons.inbox_outlined, 'No orders here')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _OrderCard(order: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final o = order;
    final next = o.status.next;
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${o.number}  -  ${o.customerName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              StatusBadge(o.status),
            ],
          ),
          const SizedBox(height: 8),
          for (final l in o.lines)
            Text('${l.qty} x ${l.name}${l.size == 'Regular' || l.size.isEmpty ? '' : ' (${l.size})'}',
                style: const TextStyle(fontSize: 14)),
          if (o.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: ${o.note}',
                style: const TextStyle(color: Brand.grey, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Tag(o.type),
              const SizedBox(width: 6),
              Tag(o.paid ? 'Paid' : 'Unpaid - ${o.payment}', filled: !o.paid),
              const Spacer(),
              Text(money(o.total), style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          Text(fmtDateTime(o.createdAt),
              style: const TextStyle(fontSize: 12, color: Brand.grey)),
          if (o.status != OrderStatus.cancelled &&
              (next != null || !o.paid || o.status.isActive)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (next != null)
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: () => s.advanceOrder(o.id),
                      child: Text(o.status.actionLabel),
                    ),
                  ),
                if (!o.paid) ...[
                  if (next != null) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: () => s.markPaid(o.id),
                      child: Text('Paid ${money(o.total)}'),
                    ),
                  ),
                ],
                if (o.status.isActive) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Cancel order',
                    onPressed: () async {
                      final ok = await confirmDialog(context, 'Cancel order #${o.number}?',
                          'Items will be returned to stock.',
                          confirm: 'Cancel order');
                      if (ok) s.cancelOrder(o.id);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
