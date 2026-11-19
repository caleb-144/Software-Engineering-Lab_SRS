import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../login_screen.dart';
import 'order_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _type = 'Pickup';
  String _payment = 'Cash at counter';
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (_busy) return; // guards against double submission (NFR-04)
    final s = context.read<AppState>();
    // Guests can fill a cart but must log in to place the order (the cart is kept).
    if (s.user == null) {
      final ok = await requireLogin(context,
          reason: 'Log in to place your order. Your cart will be kept.');
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    final res = await s.placeOrder(type: _type, payment: _payment, note: _note.text);
    if (!mounted) return;
    if (res.error != null) {
      setState(() => _busy = false);
      toast(context, res.error!);
      return;
    }
    if (s.orderDiag != null) toast(context, s.orderDiag!);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: res.order!.id, justPlaced: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          if (s.cart.isNotEmpty)
            TextButton(onPressed: s.clearCart, child: const Text('Clear')),
        ],
      ),
      body: s.cart.isEmpty
          ? const EmptyState(Icons.shopping_bag_outlined, 'Your cart is empty',
              subtitle: 'Add something fresh from the menu.')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final l in s.cart) ...[
                  Builder(builder: (_) {
                    final m = s.itemById(l.itemId);
                    if (m == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        MenuImage(m, size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 15)),
                              if (l.size.isNotEmpty && l.size != 'Regular')
                                Text(l.size,
                                    style: const TextStyle(color: Brand.grey, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(money(s.unitPrice(l) * l.qty),
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        QtyStepper(
                          value: l.qty,
                          onMinus: () => s.changeQty(l, -1),
                          onPlus: () {
                            final err = s.changeQty(l, 1);
                            if (err != null) toast(context, err);
                          },
                        ),
                      ],
                    );
                  }),
                  const Divider(height: 28),
                ],
                const Text('Order type', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(children: [
                  Pill(
                      label: 'Pickup',
                      icon: Icons.shopping_bag_outlined,
                      selected: _type == 'Pickup',
                      onTap: () => setState(() => _type = 'Pickup')),
                  const SizedBox(width: 8),
                  Pill(
                      label: 'Dine-in',
                      icon: Icons.chair_alt_outlined,
                      selected: _type == 'Dine-in',
                      onTap: () => setState(() => _type = 'Dine-in')),
                ]),
                const SizedBox(height: 20),
                const Text('Payment', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Pill(
                      label: 'Cash at counter',
                      icon: Icons.payments_outlined,
                      selected: _payment == 'Cash at counter',
                      onTap: () => setState(() => _payment = 'Cash at counter')),
                  Pill(
                      label: 'QR at counter',
                      icon: Icons.qr_code_2,
                      selected: _payment == 'QR at counter',
                      onTap: () => setState(() => _payment = 'QR at counter')),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'You pay when you collect. Online and debit card payment are not available.',
                  style: TextStyle(color: Brand.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Note for the kiosk (e.g. less ice)'),
                ),
              ],
            ),
      bottomNavigationBar: s.cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s.cartDiscount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Special deal: 20% off 2 big Air Balang',
                                style: TextStyle(
                                    color: Brand.success, fontWeight: FontWeight.w700)),
                            Text('-${money(s.cartDiscount)}',
                                style: const TextStyle(
                                    color: Brand.success, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )
                    else if (s.bigBalangCount == 1)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('Add 1 more BIG Air Balang to get 20% off both cups!',
                            style: TextStyle(color: Brand.primary, fontWeight: FontWeight.w700)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(money(s.cartTotal),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _place,
                        child: Text(s.isGuest ? 'Log in to place order' : 'Place order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
