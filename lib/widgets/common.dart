import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../services/cloudinary_service.dart';
import '../theme.dart';

String money(num v) => 'RM ${v.toStringAsFixed(2)}';
String fmtDateTime(DateTime d) => DateFormat('d MMM, h:mm a').format(d);
String fmtTime(DateTime d) => DateFormat('h:mm a').format(d);
String fmtDay(DateTime d) => DateFormat('EEE, d MMM').format(d);
String fmtDuration(Duration d) => '${d.inHours}h ${d.inMinutes % 60}m';

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Beverages':
      return Icons.local_cafe_outlined;
    case 'Soft Drinks':
      return Icons.local_drink_outlined;
    case 'Frappe':
      return Icons.icecream_outlined;
    case 'Matcha':
      return Icons.eco_outlined;
    case 'Cocoa':
    case 'Red Velvet':
      return Icons.cake_outlined;
    case 'Taro':
    case 'Latte':
    case 'Thai Tea':
      return Icons.emoji_food_beverage_outlined;
    case 'Sprite':
    case 'Air Balang':
    case 'Other Drinks':
      return Icons.water_drop_outlined;
    case 'Seoul Bites':
      return Icons.ramen_dining_outlined;
    default:
      return Icons.fastfood_outlined; // Dip & Drizzle, Additional
  }
}

/// Soft background colour per category, used behind icons when an item has no photo.
Color categoryTint(String category) {
  switch (category) {
    case 'Matcha':
    case 'Taro':
    case 'Cocoa':
    case 'Beverages':
      return const Color(0xFFE6E6E6);
    case 'Red Velvet':
    case 'Frappe':
    case 'Latte':
    case 'Thai Tea':
      return const Color(0xFFEDEDED);
    default:
      return const Color(0xFFF1F1F1);
  }
}

/// "RM4.00", or "from RM3.50" when the item has several options (Hot/Cold, Regular/Large...).
String priceText(MenuItem m) => money(m.lowestPrice);

class Logo extends StatelessWidget {
  final double height;
  const Logo({this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text("THE MINUM'S",
          style: TextStyle(
              fontSize: height * 0.6,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Brand.primary)),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final bool outlined;

  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Brand.white,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: outlined ? const BorderSide(color: Brand.line) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const Pill({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Brand.white : Brand.ink;
    return Material(
      color: selected ? Brand.primary : Brand.white,
      shape: StadiumBorder(
          side: BorderSide(color: selected ? Brand.primary : Brand.line, width: 1.2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeader(this.title, {this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!, style: const TextStyle(color: Brand.grey, fontSize: 12)),
              ),
          ]),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Fallback when an item has no photo: category icon on a soft coloured tile.
class ItemIcon extends StatelessWidget {
  final String category;
  final double size;
  final bool dark;
  const ItemIcon(this.category, {this.size = 64, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? Brand.primary : categoryTint(category),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(categoryIcon(category),
          size: size * 0.46, color: dark ? Brand.white : Brand.primaryDark),
    );
  }
}

/// Photo of a menu item: `assets/menu/<id>.jpg` (or the item's photo link).
/// If the photo is missing it quietly falls back to the category icon.
class MenuImage extends StatelessWidget {
  final MenuItem item;
  final double size;
  const MenuImage(this.item, {this.size = 64});

  // Decoding base64 on every rebuild would be slow, so decoded photos are remembered.
  static final Map<int, Uint8List> _cache = {};

  static Uint8List? _bytes(String photo) {
    if (photo.isEmpty) return null;
    return _cache.putIfAbsent(photo.hashCode, () => base64Decode(photo));
  }

  @override
  Widget build(BuildContext context) {
    final fallback = ItemIcon(item.category, size: size);
    Uint8List? bytes;
    try {
      bytes = _bytes(item.photo);
    } catch (_) {
      bytes = null; // damaged photo text: fall through to the link / asset / icon
    }
    final path = item.imagePath;
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback);
    } else if (path.startsWith('http')) {
      image = Image.network(CloudinaryService.optimized(path, size: (size * 3).clamp(200, 800).round()),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (_, child, p) => p == null ? child : fallback);
    } else {
      image = Image.asset(path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: image);
  }
}

class Tag extends StatelessWidget {
  final String text;
  final bool filled;
  final Color? color;
  const Tag(this.text, {this.filled = false, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Brand.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? c : Brand.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: filled ? c : (color ?? Brand.grey), width: 1),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: filled ? Brand.white : (color ?? Brand.ink))),
    );
  }
}

/// Order status: grey = received, amber = preparing, green = ready/completed, red = cancelled.
class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case OrderStatus.pending:
        bg = Brand.soft;
        fg = Brand.grey;
        break;
      case OrderStatus.preparing:
        bg = Brand.primarySoft;
        fg = Brand.primaryDark;
        break;
      case OrderStatus.ready:
        bg = Brand.success;
        fg = Brand.white;
        break;
      case OrderStatus.completed:
        bg = Brand.successSoft;
        fg = Brand.success;
        break;
      case OrderStatus.cancelled:
        bg = Brand.dangerSoft;
        fg = Brand.danger;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState(this.icon, this.title, {this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Brand.primarySoft),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: Brand.grey)),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool dark; // true = filled with the brand colour
  const StatTile(this.label, this.value, {this.dark = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: dark ? Brand.primary : Brand.white,
      outlined: !dark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: dark ? Colors.white70 : Brand.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: dark ? Brand.white : Brand.ink, fontWeight: FontWeight.w900, fontSize: 24)),
      ]),
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const QtyStepper({required this.value, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback f) => InkResponse(
          onTap: f,
          radius: 22,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                shape: BoxShape.circle, border: Border.all(color: Brand.primary, width: 1.4)),
            child: Icon(i, size: 18, color: Brand.primary),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove, onMinus),
      SizedBox(
        width: 40,
        child: Text('$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      btn(Icons.add, onPlus),
    ]);
  }
}

/// Row of 1-5 stars. Pass [onChanged] to make it tappable.
class StarRow extends StatelessWidget {
  final double value;
  final double size;
  final ValueChanged<int>? onChanged;
  const StarRow(this.value, {this.size = 16, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        GestureDetector(
          onTap: onChanged == null ? null : () => onChanged!(i),
          child: Padding(
            padding: EdgeInsets.only(right: onChanged == null ? 1 : 4),
            child: Icon(
              value >= i
                  ? Icons.star_rounded
                  : (value >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
              size: size,
              color: Brand.star,
            ),
          ),
        ),
    ]);
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String body,
    {String confirm = 'Confirm', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Brand.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: danger ? TextButton.styleFrom(foregroundColor: Brand.danger) : null,
          child: Text(confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}
