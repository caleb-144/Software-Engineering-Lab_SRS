import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../seed.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'cart_screen.dart';
import 'item_sheet.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String _cat = kCategories.first;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final searching = _q.trim().isNotEmpty;
    final items = s.menu.where((m) {
      if (searching) return m.name.toLowerCase().contains(_q.trim().toLowerCase());
      return m.category == _cat;
    }).toList();

    return Scaffold(
      backgroundColor: Brand.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v),
                    decoration: const InputDecoration(
                      hintText: 'Search drinks and snacks',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // category rail
                  Container(
                    width: 84,
                    color: Brand.white,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final c in kCategories)
                          _RailItem(
                            label: c,
                            selected: !searching && c == _cat,
                            onTap: () => setState(() {
                              _cat = c;
                              _q = '';
                            }),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                          child: Text(searching ? 'Search results' : _cat,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                        Expanded(
                          child: items.isEmpty
                              ? const EmptyState(Icons.search_off, 'No items found')
                              : GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                      12, 4, 12, s.cartCount > 0 ? 90 : 24),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.72,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (_, i) => _MenuCard(item: items[i]),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: s.cartCount == 0
          ? null
          : Container(
              color: Brand.cream,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.shopping_bag_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('View cart (${s.cartCount})'),
                      ]),
                      Text(money(s.cartTotal)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Brand.primarySoft : Brand.white,
          border: Border(
              left: BorderSide(
                  color: selected ? Brand.primary : Colors.transparent, width: 4)),
        ),
        child: Column(children: [
          Icon(categoryIcon(label),
              size: 24, color: selected ? Brand.primary : Brand.grey),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Brand.primaryDark : Brand.ink)),
        ]),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final soldOut = !item.isAvailable;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => showItemSheet(context, item),
      child: Opacity(
        opacity: soldOut ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Brand.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Brand.line),
          ),
          child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              ClipOval(child: MenuImage(item, size: 92)),
              if (soldOut)
                const Positioned(bottom: 0, child: Tag('Sold out', color: Brand.grey))
              else if (item.isLow)
                Positioned(
                    bottom: 0,
                    child: Tag('Only ${item.stock} left', filled: true, color: Brand.danger)),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: Text(item.name,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, height: 1.15, fontWeight: FontWeight.w800)),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(priceText(item),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: Brand.primary, fontSize: 14)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: soldOut ? Brand.line : Brand.primary, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Brand.white, size: 18),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
