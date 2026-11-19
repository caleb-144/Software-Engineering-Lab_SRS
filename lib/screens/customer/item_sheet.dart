import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'cart_screen.dart';

/// Opens the full-page customisation screen (ZUS style) for an item.
void showItemSheet(BuildContext context, MenuItem item) {
  Navigator.push(
      context, MaterialPageRoute(builder: (_) => ItemPage(itemId: item.id)));
}

class ItemPage extends StatefulWidget {
  final String itemId;
  const ItemPage({required this.itemId, super.key});

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  List<String>? _picks;
  int _qty = 1;

  void _toggle(MenuItem m, OptionGroup g, String label) {
    final cur = List<String>.of(_picks ?? m.defaultPicks);
    if (g.required || !g.multi) {
      for (final c in g.choices) {
        cur.remove(c.label);
      }
      // an optional single-choice group can be un-picked by tapping again
      final had = (_picks ?? m.defaultPicks).contains(label);
      if (!(had && !g.required)) cur.add(label);
    } else {
      cur.contains(label) ? cur.remove(label) : cur.add(label);
    }
    setState(() => _picks = m.normalizePicks(cur));
  }

  String _extra(OptionGroup g, OptionChoice c) {
    if (g.fixedPrice) return money(c.price);
    return c.price == 0 ? 'Free' : '+${money(c.price)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final m = s.itemById(widget.itemId);
    if (m == null) return const Scaffold(body: SizedBox.shrink());
    final picks = m.normalizePicks(_picks ?? m.defaultPicks);
    final unit = m.priceFor(picks);
    final summary = m.describePicks(picks);
    final more = s
        .hotSelling(8)
        .map((h) => h.item)
        .where((x) => x.id != m.id && x.isAvailable)
        .take(6)
        .toList();

    return Scaffold(
      backgroundColor: Brand.cream,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Brand.cream,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircleAvatar(
                      backgroundColor: Brand.white,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Brand.ink, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircleAvatar(
                        backgroundColor: Brand.white,
                        child: IconButton(
                          icon: Badge(
                            isLabelVisible: s.cartCount > 0,
                            label: Text('${s.cartCount}'),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: Brand.ink, size: 20),
                          ),
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const CartScreen())),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Brand.white, shape: BoxShape.circle),
                        child: ClipOval(child: MenuImage(m, size: 200)),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(children: [
                          Text(m.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)),
                          const SizedBox(height: 6),
                          Text(money(m.lowestPrice),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Brand.primary)),
                          if (m.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(m.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Brand.grey, fontSize: 14)),
                          ],
                          if (m.isLow) ...[
                            const SizedBox(height: 10),
                            Tag('Only ${m.stock} left', filled: true, color: Brand.danger),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (final g in m.groups)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Brand.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Brand.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(g.title,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w900)),
                              ),
                              Tag(g.required
                                  ? 'Pick 1'
                                  : g.multi
                                      ? 'Optional'
                                      : 'Optional - pick 1'),
                            ]),
                            const SizedBox(height: 12),
                            Wrap(spacing: 10, runSpacing: 10, children: [
                              for (final c in g.choices)
                                _ChoiceChip(
                                  label: c.label,
                                  sub: _extra(g, c),
                                  selected: picks.contains(c.label),
                                  check: !g.required,
                                  onTap: () => _toggle(m, g, c.label),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    if (more.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
                        child: Text('Frequently enjoyed with',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: more.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final x = more[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ItemPage(itemId: x.id))),
                              child: Container(
                                width: 112,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Brand.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Brand.line),
                                ),
                                child: Column(children: [
                                  ClipOval(child: MenuImage(x, size: 64)),
                                  const SizedBox(height: 8),
                                  Text(x.name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Text(money(x.lowestPrice),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Brand.primary)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (m.category == 'Air Balang')
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Brand.successSoft,
                            borderRadius: BorderRadius.circular(16)),
                        child: const Row(children: [
                          Icon(Icons.local_offer_outlined, color: Brand.success),
                          SizedBox(width: 10),
                          Expanded(
                              child: Text(
                                  'Special deal: order 2 BIG Air Balang and get 20% off both cups!',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700, color: Brand.success))),
                        ]),
                      ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ],
            ),
          ),
          // sticky bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Brand.white,
              border: Border(top: BorderSide(color: Brand.line)),
            ),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      const Icon(Icons.tune, size: 16, color: Brand.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Brand.grey, fontSize: 13))),
                    ]),
                  ),
                Row(children: [
                  QtyStepper(
                    value: _qty,
                    onMinus: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                    onPlus: () => setState(() => _qty = _qty < m.stock ? _qty + 1 : _qty),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton(
                      onPressed: !m.isAvailable
                          ? null
                          : () {
                              final err = s.addToCart(m.id, picks, _qty);
                              if (err != null) {
                                toast(context, err);
                                return;
                              }
                              Navigator.pop(context);
                              toast(context, '${m.name} added to cart');
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.isAvailable ? 'Add to Cart' : 'Sold out'),
                          if (m.isAvailable) Text(money(unit * _qty)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final bool check;
  final VoidCallback onTap;
  const _ChoiceChip(
      {required this.label,
      required this.sub,
      required this.selected,
      required this.check,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Brand.primarySoft : Brand.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? Brand.primary : Brand.line, width: selected ? 1.6 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (check) ...[
            Icon(selected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18, color: selected ? Brand.primary : Brand.grey),
            const SizedBox(width: 8),
          ],
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Brand.primaryDark : Brand.ink)),
            Text(sub, style: const TextStyle(fontSize: 12, color: Brand.grey)),
          ]),
        ]),
      ),
    );
  }
}
