import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/event_banner.dart';
import '../login_screen.dart';
import 'cart_screen.dart';
import 'item_sheet.dart';
import 'order_detail_screen.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback onGoMenu;
  const HomeTab({required this.onGoMenu});

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
  }

  void _reorder(BuildContext context, Order o) {
    final s = context.read<AppState>();
    final r = s.reorder(o);
    if (r.added == 0) {
      toast(context, 'Those items are sold out right now.');
      return;
    }
    toast(context,
        '${r.added} item${r.added == 1 ? '' : 's'} added to cart${r.skipped > 0 ? ' (${r.skipped} sold out)' : ''}');
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final first = s.user?.name.split(' ').first;
    final hot = s.hotSelling(8);
    final events = s.upcomingEvents;
    final mine = s.myOrders.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final last = mine.isEmpty ? null : mine.first;

    return Scaffold(
      backgroundColor: Brand.cream,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // greeting row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_greeting()}${first == null ? '!' : ','}',
                        style: const TextStyle(
                            fontSize: 14, color: Brand.grey, fontWeight: FontWeight.w600)),
                    Text(first == null ? 'Welcome to THE MINUM\'S' : '$first!',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  ]),
                ),
                CircleAvatar(
                  backgroundColor: Brand.white,
                  child: IconButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CartScreen())),
                    icon: Badge(
                      isLabelVisible: s.cartCount > 0,
                      label: Text('${s.cartCount}'),
                      child: const Icon(Icons.shopping_bag_outlined, color: Brand.ink),
                    ),
                  ),
                ),
              ]),
            ),

            if (s.isGuest)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: AppCard(
                  color: Brand.primarySoft,
                  outlined: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Row(children: [
                    Icon(Icons.person_outline, color: Brand.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Browsing as a guest. Log in to place orders.',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text('Log in',
                        style: TextStyle(
                            color: Brand.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                  ]),
                ),
              ),

            // events banner (auto-sliding), or the brand banner when there are no events
            if (events.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: EventBanner(events: events),
              )
            else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 12, 22),
                decoration: BoxDecoration(
                    gradient: Brand.gradient, borderRadius: BorderRadius.circular(24)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Fresh. Sweet.\nFlavourful.',
                          style: TextStyle(
                              color: Brand.white,
                              fontSize: 28,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1)),
                      const SizedBox(height: 6),
                      const Text('2 BIG Air Balang = 20% off',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Brand.white,
                            foregroundColor: Brand.primary,
                            minimumSize: const Size(0, 42)),
                        onPressed: onGoMenu,
                        child: const Text('Order now'),
                      ),
                    ]),
                  ),
                  if (hot.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: Brand.white, shape: BoxShape.circle),
                      child: ClipOval(child: MenuImage(hot.first.item, size: 104)),
                    ),
                ]),
              ),
            ),

            // pickup / dine-in tiles
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                Expanded(
                    child: _ModeTile(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Pickup',
                        sub: 'Collect at the counter',
                        onTap: onGoMenu)),
                const SizedBox(width: 12),
                Expanded(
                    child: _ModeTile(
                        icon: Icons.restaurant_outlined,
                        title: 'Dine-in',
                        sub: 'Enjoy at the cafe',
                        onTap: onGoMenu)),
              ]),
            ),

            // last order with Reorder (like ZUS)
            if (last != null) _LastOrder(order: last, onReorder: () => _reorder(context, last)),

            // hot selling
            SectionHeader('Hot Selling',
                subtitle: 'Most ordered and best rated',
                trailing: TextButton(onPressed: onGoMenu, child: const Text('Full menu'))),
            SizedBox(
              height: 214,
              child: hot.isEmpty
                  ? const EmptyState(
                      Icons.local_fire_department_outlined, 'Nothing available right now')
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: hot.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _HotCard(hot: hot[i], rank: i + 1),
                    ),
            ),

          ],
        ),
      ),
    );
  }
}

class _LastOrder extends StatefulWidget {
  final Order order;
  final VoidCallback onReorder;
  const _LastOrder({required this.order, required this.onReorder});

  @override
  State<_LastOrder> createState() => _LastOrderState();
}

class _LastOrderState extends State<_LastOrder> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final first = o.lines.isEmpty ? '' : o.lines.first.name;
    final n = o.lines.fold<int>(0, (a, l) => a + l.qty);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
          child: Row(children: [
            const Text('Your last order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Brand.primarySoft,
              child: Icon(Icons.arrow_forward, size: 16, color: Brand.primary),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Brand.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Brand.line),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: Brand.primarySoft, shape: BoxShape.circle),
                  child: Icon(
                      o.type == 'Dine-in'
                          ? Icons.restaurant_outlined
                          : Icons.shopping_bag_outlined,
                      color: Brand.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${o.type}:',
                        style: const TextStyle(color: Brand.grey, fontSize: 13)),
                    Text('Order #${o.number}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ]),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 18)),
                  onPressed: widget.onReorder,
                  child: const Text('Reorder'),
                ),
              ]),
            ),
            const Divider(height: 1),
            InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(DateFormat('d MMM y, HH:mm').format(o.createdAt),
                      style: const TextStyle(color: Brand.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: Text(first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Brand.soft, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('$n item${n == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18),
                      ]),
                    ),
                  ]),
                  if (_open)
                    for (final l in o.lines)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            '${l.qty} x ${l.name}${l.size.isEmpty || l.size == 'Regular' ? '' : ' (${l.size})'}',
                            style: const TextStyle(fontSize: 13, color: Brand.grey)),
                      ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _ModeTile(
      {required this.icon, required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              const BoxDecoration(color: Brand.primarySoft, shape: BoxShape.circle),
          child: Icon(icon, color: Brand.primary, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Brand.grey)),
          ]),
        ),
      ]),
    );
  }
}

class _HotCard extends StatelessWidget {
  final HotItem hot;
  final int rank;
  const _HotCard({required this.hot, required this.rank});

  @override
  Widget build(BuildContext context) {
    final m = hot.item;
    return SizedBox(
      width: 140,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        onTap: () => showItemSheet(context, m),
        child: Column(children: [
          Stack(children: [
            ClipOval(child: MenuImage(m, size: 96)),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: rank == 1 ? Brand.primary : Brand.grey,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('#$rank',
                    style: const TextStyle(
                        color: Brand.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(m.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(priceText(m),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Brand.primary, fontSize: 13)),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: Brand.star),
              Text(hot.ratingCount == 0 ? 'New' : hot.avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, color: Brand.grey)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
