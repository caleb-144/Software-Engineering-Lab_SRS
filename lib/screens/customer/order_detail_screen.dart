import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Receipt + live order tracking. Updates automatically as staff change status.
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final bool justPlaced;
  const OrderDetailScreen({required this.orderId, this.justPlaced = false});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final o = s.orderById(orderId);
    if (o == null) {
      return Scaffold(
          appBar: AppBar(), body: const EmptyState(Icons.error_outline, 'Order not found'));
    }
    final isCustomer = s.user?.role == Role.customer;
    final cancelled = o.status == OrderStatus.cancelled;
    const steps = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.completed,
    ];
    final current = steps.indexOf(o.status);

    return Scaffold(
      appBar: AppBar(title: Text('Order #${o.number}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (justPlaced)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Brand.success, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, color: Brand.white, size: 44),
                  const SizedBox(height: 8),
                  const Text('Order placed!',
                      style: TextStyle(
                          color: Brand.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    'Show #${o.number} at the counter and pay ${money(o.total)}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(o.status),
              Text(fmtDateTime(o.createdAt), style: const TextStyle(color: Brand.grey)),
            ],
          ),
          const SizedBox(height: 20),
          if (!cancelled)
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i <= current ? Brand.success : Brand.white,
                              border: Border.all(
                                  color: i <= current ? Brand.success : Brand.line, width: 1.5),
                            ),
                            child: i <= current
                                ? const Icon(Icons.check, size: 15, color: Brand.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(steps[i].label,
                              style: TextStyle(
                                fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                                color: i <= current ? Brand.ink : Brand.grey,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          for (final l in o.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        '${l.qty} x ${l.name}${l.size == 'Regular' || l.size.isEmpty ? '' : ' (${l.size})'}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text(money(l.subtotal)),
                ],
              ),
            ),
          if (o.discount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Air Balang special deal (20% off 2 big cups)',
                    style: TextStyle(color: Brand.success, fontWeight: FontWeight.w700)),
                Text('-${money(o.discount)}',
                    style: const TextStyle(color: Brand.success, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              Text(money(o.total),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          _kv('Order type', o.type),
          _kv('Payment method', o.payment),
          _kv('Payment status',
              o.paid ? 'Paid ${o.paidAt == null ? '' : fmtDateTime(o.paidAt!)}' : 'Unpaid'),
          if (!isCustomer) _kv('Customer', o.customerName),
          if (o.note.isNotEmpty) _kv('Note', o.note),
          if (isCustomer && o.status == OrderStatus.completed) ...[
            const SizedBox(height: 24),
            const Text('Rate your order',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Your ratings feed the Hot Selling list.',
                style: TextStyle(color: Brand.grey, fontSize: 12)),
            const SizedBox(height: 10),
            for (final l in _uniqueLines(o.lines)) _RateRow(orderId: o.id, line: l),
          ],
          const SizedBox(height: 24),
          if (isCustomer && o.status == OrderStatus.pending)
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmDialog(context, 'Cancel this order?',
                    'Items will be returned to stock.',
                    confirm: 'Cancel order');
                if (ok) {
                  final err = s.cancelOrder(o.id);
                  if (err != null && context.mounted) toast(context, err);
                }
              },
              child: const Text('Cancel order'),
            ),
        ],
      ),
    );
  }

  /// One rating row per item, even if it was ordered in two sizes.
  List<OrderLine> _uniqueLines(List<OrderLine> lines) {
    final seen = <String>{};
    return lines.where((l) => seen.add(l.itemId)).toList();
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(k, style: const TextStyle(color: Brand.grey))),
            Expanded(
                child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

/// Star rating + optional comment for one item of a completed order.
class _RateRow extends StatefulWidget {
  final String orderId;
  final OrderLine line;
  const _RateRow({required this.orderId, required this.line});

  @override
  State<_RateRow> createState() => _RateRowState();
}

class _RateRowState extends State<_RateRow> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    final err = context.read<AppState>().addReview(
          orderId: widget.orderId,
          itemId: widget.line.itemId,
          rating: _stars,
          comment: _comment.text,
        );
    toast(context, err ?? 'Thanks for your review!');
  }

  @override
  Widget build(BuildContext context) {
    final done = context.watch<AppState>().reviewFor(widget.orderId, widget.line.itemId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.line.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (done != null) ...[
            StarRow(done.rating.toDouble(), size: 22),
            const SizedBox(height: 4),
            const Text('Thanks for your review!',
                style: TextStyle(
                    color: Brand.success, fontWeight: FontWeight.w700, fontSize: 13)),
            if (done.comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(done.comment, style: const TextStyle(color: Brand.grey)),
              ),
          ] else ...[
            StarRow(_stars.toDouble(), size: 32, onChanged: (v) => setState(() => _stars = v)),
            if (_stars > 0) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _comment,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Comment (optional)'),
              ),
              const SizedBox(height: 6),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _submit,
                child: const Text('Submit review'),
              ),
            ],
          ],
        ]),
      ),
    );
  }
}
