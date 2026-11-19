import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../theme.dart';

enum _Kind { one, any, full }

class _Choice {
  final TextEditingController label;
  final TextEditingController price;
  _Choice(String l, double p)
      : label = TextEditingController(text: l),
        price = TextEditingController(text: p == 0 ? '' : _fmt(p));
  void dispose() {
    label.dispose();
    price.dispose();
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class _Group {
  final TextEditingController title;
  _Kind kind;
  final List<_Choice> choices;
  _Group(String t, this.kind, this.choices) : title = TextEditingController(text: t);
  void dispose() {
    title.dispose();
    for (final c in choices) {
      c.dispose();
    }
  }
}

/// Simple point-and-tap editor for an item's customisation (sizes, hot/cold, add-ons).
/// The manager never has to type any special symbols.
/// Call `key.currentState!.read()` to get the groups (or an error message).
class GroupsEditor extends StatefulWidget {
  final List<OptionGroup> initial;
  const GroupsEditor({required this.initial, super.key});

  @override
  State<GroupsEditor> createState() => GroupsEditorState();
}

class GroupsEditorState extends State<GroupsEditor> {
  late final List<_Group> _groups = [
    for (final g in widget.initial)
      _Group(
        g.title,
        g.fixedPrice ? _Kind.full : (g.multi ? _Kind.any : _Kind.one),
        [for (final c in g.choices) _Choice(c.label, c.price)],
      ),
  ];

  @override
  void dispose() {
    for (final g in _groups) {
      g.dispose();
    }
    super.dispose();
  }

  /// The lowest price a "full price" group sets, or null if there is none.
  double? get fullPriceStart {
    final r = read();
    if (r.groups == null) return null;
    for (final g in r.groups!.where((g) => g.fixedPrice)) {
      return g.choices.map((c) => c.price).reduce((a, b) => a < b ? a : b);
    }
    return null;
  }

  ({List<OptionGroup>? groups, String? error}) read() {
    final out = <OptionGroup>[];
    for (final g in _groups) {
      final title = g.title.text.trim();
      final choices = <OptionChoice>[];
      for (final c in g.choices) {
        final label = c.label.text.trim();
        final raw = c.price.text.trim();
        if (label.isEmpty && raw.isEmpty) continue; // blank row, ignore
        if (label.isEmpty) return (groups: null, error: 'Give every choice a name');
        final price = raw.isEmpty ? 0.0 : double.tryParse(raw);
        if (price == null || price < 0) {
          return (groups: null, error: 'Check the price of "$label"');
        }
        if (g.kind == _Kind.full && price <= 0) {
          return (groups: null, error: '"$label" needs a price');
        }
        choices.add(OptionChoice(label, price));
      }
      if (title.isEmpty && choices.isEmpty) continue;
      if (title.isEmpty) return (groups: null, error: 'Give every option group a title');
      if (choices.isEmpty) return (groups: null, error: '"$title" needs at least one choice');
      out.add(OptionGroup(
        title: title,
        required: g.kind != _Kind.any,
        multi: g.kind == _Kind.any,
        fixedPrice: g.kind == _Kind.full,
        choices: choices,
      ));
    }
    return (groups: out, error: null);
  }

  void _add(String title, _Kind kind, List<(String, double)> choices) =>
      setState(() => _groups.add(_Group(title, kind, [for (final c in choices) _Choice(c.$1, c.$2)])));

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Customisation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      const Text('Optional. Choices the customer picks before adding to cart.',
          style: TextStyle(color: Brand.grey, fontSize: 12)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Size'),
            onPressed: () =>
                _add('Size', _Kind.one, [('Regular', 0), ('Large', 2)])),
        ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Hot / Cold'),
            onPressed: () =>
                _add('Temperature', _Kind.one, [('Hot', 0), ('Cold', 0.5)])),
        ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Add-ons'),
            onPressed: () => _add('Add-ons', _Kind.any, [('', 0)])),
        ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Own prices'),
            onPressed: () => _add('Size', _Kind.full, [('Small', 2.5), ('Big', 5)])),
      ]),
      const SizedBox(height: 10),
      for (var i = 0; i < _groups.length; i++) _groupCard(i),
    ]);
  }

  Widget _groupCard(int i) {
    final g = _groups[i];
    final isFull = g.kind == _Kind.full;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Brand.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: g.title,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Group title', isDense: true),
            ),
          ),
          IconButton(
            tooltip: 'Remove this group',
            icon: const Icon(Icons.delete_outline, color: Brand.danger),
            onPressed: () => setState(() => _groups.removeAt(i).dispose()),
          ),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<_Kind>(
          initialValue: g.kind,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'How it works', isDense: true),
          items: const [
            DropdownMenuItem(value: _Kind.one, child: Text('Customer must pick one')),
            DropdownMenuItem(value: _Kind.any, child: Text('Optional add-ons (tick any)')),
            DropdownMenuItem(
                value: _Kind.full, child: Text('Pick one, each has its own full price')),
          ],
          onChanged: (v) => setState(() => g.kind = v ?? g.kind),
        ),
        const SizedBox(height: 10),
        for (var j = 0; j < g.choices.length; j++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: g.choices[j].label,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Choice', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: g.choices[j].price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: isFull ? 'Price' : 'Extra',
                      prefixText: 'RM ',
                      isDense: true),
                ),
              ),
              IconButton(
                tooltip: 'Remove choice',
                icon: const Icon(Icons.close, size: 20),
                onPressed: g.choices.length <= 1
                    ? null
                    : () => setState(() => g.choices.removeAt(j).dispose()),
              ),
            ]),
          ),
        TextButton.icon(
          onPressed: () => setState(() => g.choices.add(_Choice('', 0))),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add choice'),
        ),
        Text(
          isFull
              ? 'Leave out nothing: the price replaces the item price.'
              : 'Extra = added to the item price. Leave empty for no extra charge.',
          style: const TextStyle(color: Brand.grey, fontSize: 11),
        ),
      ]),
    );
  }
}
