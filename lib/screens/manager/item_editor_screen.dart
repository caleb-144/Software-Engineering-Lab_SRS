import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../seed.dart';
import '../../services/cloudinary_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/groups_editor.dart';

/// Manager: add or edit menu items and prices.
class ItemEditorScreen extends StatefulWidget {
  final MenuItem? item;
  const ItemEditorScreen({this.item});

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _price = TextEditingController(
      text: widget.item == null ? '' : widget.item!.price.toStringAsFixed(2));
  final _groupsKey = GlobalKey<GroupsEditorState>();
  late final TextEditingController _desc =
      TextEditingController(text: widget.item?.description ?? '');
  late final TextEditingController _stock =
      TextEditingController(text: '${widget.item?.stock ?? kDefaultStock}');
  late final TextEditingController _image =
      TextEditingController(text: widget.item?.image ?? '');
  late String _category = widget.item?.category ?? kCategories.first;
  late bool _available = widget.item?.available ?? true;
  late String _photo = widget.item?.photo ?? '';
  bool _picking = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    _stock.dispose();
    _image.dispose();
    super.dispose();
  }

  /// Opens the gallery or camera.
  ///  - Cloudinary set up (lib/config/cloudinary_config.dart): the photo is uploaded and its link
  ///    is saved with the item.
  ///  - Otherwise the photo is shrunk and saved as text inside the Firestore menu item.
  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    final cloud = CloudinaryService.isConfigured;
    setState(() => _picking = true);
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: cloud ? 1000 : 560,
        maxHeight: cloud ? 1000 : 560,
        imageQuality: cloud ? 80 : 65,
      );
      if (x == null) return;
      final Uint8List bytes = await x.readAsBytes();
      if (cloud) {
        final url = await CloudinaryService.uploadImage(bytes);
        if (mounted) {
          setState(() {
            _image.text = url;
            _photo = '';
          });
          toast(context, 'Photo uploaded. Tap Save to keep it.');
        }
        return;
      }
      final text = base64Encode(bytes);
      if (text.length > 280000) {
        if (mounted) toast(context, 'That photo is too big. Try another one.');
        return;
      }
      if (mounted) setState(() => _photo = text);
    } on String catch (message) {
      if (mounted) toast(context, message);
    } catch (_) {
      if (mounted) toast(context, 'Could not open the photo. Please allow photo/camera access.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    final s = context.read<AppState>();
    var price = double.tryParse(_price.text.trim());
    final read = _groupsKey.currentState!.read();
    if (read.error != null) return toast(context, read.error!);
    final groups = read.groups ?? <OptionGroup>[];
    // a group with its own full prices sets the item's starting price
    for (final g in groups.where((g) => g.fixedPrice)) {
      price = g.choices.map((c) => c.price).reduce((a, b) => a < b ? a : b);
    }
    final stock = int.tryParse(_stock.text.trim());
    if (_name.text.trim().isEmpty) return toast(context, 'Enter an item name');
    if (price == null || price <= 0) return toast(context, 'Enter a valid price');
    if (stock == null || stock < 0) return toast(context, 'Enter a valid stock quantity');

    final existing = widget.item;
    if (existing != null) {
      existing
        ..name = _name.text.trim()
        ..category = _category
        ..price = price
        ..groups = groups
        ..description = _desc.text.trim()
        ..image = _image.text.trim()
        ..photo = _photo
        ..available = _available;
      if (stock != existing.stock) {
        // keep the audit trail: stock edits are logged as transactions
        final diff = stock - existing.stock;
        s.recordStock(existing.id, diff > 0, diff.abs(), 'Manual adjustment');
      }
      s.saveItem(existing);
    } else {
      s.createItem(MenuItem(
        id: s.newItemId(),
        name: _name.text.trim(),
        category: _category,
        price: price,
        groups: groups,
        description: _desc.text.trim(),
        image: _image.text.trim(),
        photo: _photo,
        stock: stock,
        available: _available,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit item' : 'Add item'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Delete item',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final s = context.read<AppState>();
                final ok = await confirmDialog(context, 'Delete ${widget.item!.name}?',
                    'It will be removed from the menu. Past orders keep their records.',
                    confirm: 'Delete');
                if (ok) {
                  s.deleteItem(widget.item!.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: MenuImage(
              MenuItem(
                id: widget.item?.id ?? 'new',
                name: _name.text,
                category: _category,
                price: 0,
                image: _image.text.trim(),
                photo: _photo,
              ),
              size: 140,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _picking ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
            if (_photo.isNotEmpty || _image.text.trim().isNotEmpty) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: () => setState(() {
                  _photo = '';
                  _image.clear();
                }),
                icon: const Icon(Icons.delete_outline, color: Brand.danger),
              ),
            ],
          ]),
          if (_picking)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              CloudinaryService.isConfigured
                  ? 'Photos are uploaded to Cloudinary.'
                  : 'Photos are saved in the database (set up Cloudinary for bigger photos).',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Brand.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Item name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Price (RM)', helperText: 'Starting price. Extra charges are added by Customisation below.')),
          const SizedBox(height: 12),
          GroupsEditor(key: _groupsKey, initial: widget.item?.groups ?? const []),
          const SizedBox(height: 16),
          TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: editing ? 'Stock quantity' : 'Opening stock')),
          const SizedBox(height: 12),
          TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          TextField(
              controller: _image,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Or a photo link (optional)',
                  helperText: 'A picked photo is used first, then this link, then assets/menu/<id>.jpg')),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Listed on customer menu',
                style: TextStyle(fontWeight: FontWeight.w700)),
            value: _available,
            onChanged: (v) => setState(() => _available = v),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: Text(editing ? 'Save changes' : 'Add to menu')),
        ],
      ),
    );
  }
}
