import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../seed.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../manager/item_editor_screen.dart';
import 'stock_history_screen.dart';

/// FR-07. Staff: record stock in/out (3 steps: tap item -> set quantity -> confirm)
/// and toggle availability. Manager (canEdit): also add / edit / delete items and prices.
class InventoryTab extends StatefulWidget {
  final bool canEdit;
  const InventoryTab({this.canEdit = false});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  String _cat = 'All';
  String _level = 'All'; // All / Low stock / Out of stock
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.menu.where((m) {
      final okCat = _cat == 'All' || m.category == _cat;
      final okQ = _q.isEmpty || m.name.toLowerCase().contains(_q.toLowerCase());
      final okLevel = _level == 'All' ||
          (_level == 'Low stock' && m.isLow) ||
          (_level == 'Out of stock' && m.stock == 0);
      return okCat && okQ && okLevel;
    }).toList();
    final low = s.lowStockItems.length;
    final lowCount = s.menu.where((m) => m.isLow).length;
    final outCount = s.menu.where((m) => m.stock == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.canEdit ? 'Menu & stock' : 'Inventory'),
        actions: [
          if (widget.canEdit)
            IconButton(
              tooltip: "Load THE MINUM'S menu",
              icon: const Icon(Icons.playlist_add_outlined),
              onPressed: () async {
                final st = context.read<AppState>();
                final ok = await confirmDialog(
                  context,
                  "Load THE MINUM'S menu?",
                  'Adds the items that are missing (stock starts at $kStartingStock) and updates the '
                  'names, prices and options (size, hot/cold, add-ons) of the others. Stock, photos '
                  'and your own items are kept. Old starter items that are not on the menu are removed.',
                  confirm: 'Load menu',
                );
                if (!ok) return;
                final r = st.loadOfficialMenu();
                if (context.mounted) {
                  toast(context,
                      '${r.added} added, ${r.updated} updated, ${r.removed} old items removed');
                }
              },
            ),
          IconButton(
            tooltip: 'Stock history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const StockHistoryScreen())),
          ),
        ],
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ItemEditorScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                  hintText: 'Search items', prefixIcon: Icon(Icons.search)),
            ),
          ),
          if (low > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Brand.danger, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Brand.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('$low item${low == 1 ? '' : 's'} low or out of stock',
                        style: const TextStyle(
                            color: Brand.white, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                for (final l in [
                  ('All', 'All items'),
                  ('Low stock', 'Low stock ($lowCount)'),
                  ('Out of stock', 'Out of stock ($outCount)'),
                ]) ...[
                  Pill(
                      label: l.$2,
                      selected: _level == l.$1,
                      onTap: () => setState(() => _level = l.$1)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                for (final c in ['All', ...kCategories]) ...[
                  Pill(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20, 8, 20, widget.canEdit ? 96 : 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (_, i) => _InventoryRow(item: items[i], canEdit: widget.canEdit),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final MenuItem item;
  final bool canEdit;
  const _InventoryRow({required this.item, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showStockSheet(context, item),
      child: Row(
        children: [
          MenuImage(item, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${item.category}  -  ${priceText(item)}',
                    style: const TextStyle(color: Brand.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('${item.stock} in stock',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: item.stock == 0
                              ? Brand.danger
                              : (item.isLow ? Brand.warn : Brand.success))),
                  const SizedBox(width: 8),
                  if (item.stock == 0)
                    const Tag('Out of stock', filled: true, color: Brand.danger)
                  else if (item.isLow)
                    const Tag('Low stock', filled: true, color: Brand.warn),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: item.available,
                onChanged: (v) => s.setAvailable(item.id, v),
              ),
              Text(item.available ? 'Listed' : 'Hidden',
                  style: const TextStyle(fontSize: 10, color: Brand.grey)),
            ],
          ),
          if (canEdit)
            IconButton(
              tooltip: 'Edit item',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ItemEditorScreen(item: item)),
              ),
            ),
        ],
      ),
    );
  }
}

void showStockSheet(BuildContext context, MenuItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider<AppState>.value(
      value: context.read<AppState>(),
      child: _StockSheet(itemId: item.id),
    ),
  );
}

class _StockSheet extends StatefulWidget {
  final String itemId;
  const _StockSheet({required this.itemId});

  @override
  State<_StockSheet> createState() => _StockSheetState();
}

class _StockSheetState extends State<_StockSheet> {
  bool _isIn = true;
  int _qty = 5; // restock quantity starts at 5; change it before confirming
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final m = s.itemById(widget.itemId);
    if (m == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Brand.line, borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 16),
          Text(m.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Current stock: ${m.stock}', style: const TextStyle(color: Brand.grey)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: Pill(
                  label: 'Stock in',
                  icon: Icons.add_circle_outline,
                  selected: _isIn,
                  onTap: () => setState(() => _isIn = true)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Pill(
                  label: 'Stock out',
                  icon: Icons.remove_circle_outline,
                  selected: !_isIn,
                  onTap: () => setState(() => _isIn = false)),
            ),
          ]),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w800)),
              QtyStepper(
                value: _qty,
                onMinus: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                onPlus: () => setState(() => _qty++),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final n in [10, 20, 50])
              ActionChip(
                label: Text('+$n'),
                backgroundColor: Brand.white,
                side: const BorderSide(color: Brand.line),
                shape: const StadiumBorder(),
                onPressed: () => setState(() => _qty += n),
              ),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            decoration: InputDecoration(
              labelText: _isIn ? 'Note (e.g. supplier delivery)' : 'Reason (e.g. wastage)',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final err = s.recordStock(m.id, _isIn, _qty, _reason.text);
                if (err != null) {
                  toast(context, err);
                  return;
                }
                Navigator.pop(context);
                toast(context, '${_isIn ? 'Added' : 'Removed'} $_qty - ${m.name}');
              },
              child: Text(_isIn ? 'Confirm stock in' : 'Confirm stock out'),
            ),
          ),
        ],
      ),
    );
  }
}
