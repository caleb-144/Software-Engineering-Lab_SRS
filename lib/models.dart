enum Role { customer, staff, manager }

/// Staff accounts start as [pending] until the manager approves them.
enum AccountStatus { approved, pending, rejected }

enum OrderStatus { pending, preparing, ready, completed, cancelled }

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Received';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  OrderStatus? get next {
    switch (this) {
      case OrderStatus.pending:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.completed;
      default:
        return null;
    }
  }

  String get actionLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'Start preparing';
      case OrderStatus.preparing:
        return 'Mark ready';
      case OrderStatus.ready:
        return 'Complete order';
      default:
        return '';
    }
  }

  bool get isActive =>
      this == OrderStatus.pending ||
      this == OrderStatus.preparing ||
      this == OrderStatus.ready;
}

class AppUser {
  final String id; // Firebase Auth uid
  String name;
  final String email;
  final Role role;
  String phone;
  String birthday; // yyyy-MM-dd, optional
  bool birthdayPublic;
  int avatar; // index of the picked avatar, -1 = initial letter
  AccountStatus status;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.birthday = '',
    this.birthdayPublic = true,
    this.avatar = -1,
    this.status = AccountStatus.approved,
  });

  /// Stored in Firestore at users/{uid}. The password is NEVER stored here.
  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role.name,
        'phone': phone,
        'birthday': birthday,
        'birthdayPublic': birthdayPublic,
        'avatar': avatar,
        'status': status.name,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> j) => AppUser(
        id: id,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        role: _enumByName(Role.values, j['role'] as String?, Role.customer),
        phone: (j['phone'] ?? '') as String,
        birthday: (j['birthday'] ?? '') as String,
        birthdayPublic: (j['birthdayPublic'] ?? true) as bool,
        avatar: (j['avatar'] ?? -1) as int,
        status: _enumByName(AccountStatus.values, j['status'] as String?, AccountStatus.pending),
      );
}

/// One choice inside an [OptionGroup], e.g. "Large" (+RM2.00) or "Milk Foam" (+RM2.00).
class OptionChoice {
  final String label;
  final double price; // extra charge, or the full price when the group is [OptionGroup.fixedPrice]
  const OptionChoice(this.label, this.price);

  Map<String, dynamic> toJson() => {'label': label, 'price': price};

  factory OptionChoice.fromJson(Map<String, dynamic> j) =>
      OptionChoice((j['label'] ?? '') as String, (j['price'] as num).toDouble());
}

/// A set of choices on the item page, like the ZUS app:
///  * [required] (pick exactly one): Size, Temperature ...
///  * [multi] (optional, pick any): Add-ons such as Milk Foam, Telur Mata ...
///  * [fixedPrice]: each choice is the full price of the item (Air Balang Small / Medium / Big).
class OptionGroup {
  final String title;
  final bool required;
  final bool multi;
  final bool fixedPrice;
  final List<OptionChoice> choices;

  const OptionGroup({
    required this.title,
    this.required = false,
    this.multi = false,
    this.fixedPrice = false,
    required this.choices,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'required': required,
        'multi': multi,
        'fixedPrice': fixedPrice,
        'choices': choices.map((c) => c.toJson()).toList(),
      };

  factory OptionGroup.fromJson(Map<String, dynamic> j) => OptionGroup(
        title: (j['title'] ?? '') as String,
        required: j['required'] == true,
        multi: j['multi'] == true,
        fixedPrice: j['fixedPrice'] == true,
        choices: [
          for (final c in (j['choices'] as List? ?? const []))
            OptionChoice.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
      );

  /// Text used by the item editor, one line per group:
  ///   Size*: Regular=0, Large=2.00          (* = customer must pick one)
  ///   Size*@: Small=2.50, Big=5.00          (@ = the numbers are full prices)
  ///   Add-ons: Milk Foam=2.00               (no * = optional, any number)
  String toLine() =>
      '$title${required ? '*' : ''}${fixedPrice ? '@' : ''}: '
      '${choices.map((c) => '${c.label}=${_trim(c.price)}').join(', ')}';

  static String _trim(double v) {
    final t = v.toStringAsFixed(2);
    return t.endsWith('.00') ? v.toStringAsFixed(0) : t;
  }

  static String format(List<OptionGroup> groups) => groups.map((g) => g.toLine()).join('\n');

  /// Reads the editor text. Returns null if a line is not valid. Empty text = no groups.
  static List<OptionGroup>? parse(String text) {
    final out = <OptionGroup>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final colon = line.indexOf(':');
      if (colon < 1) return null;
      var head = line.substring(0, colon).trim();
      final fixed = head.endsWith('@');
      if (fixed) head = head.substring(0, head.length - 1).trim();
      final req = head.endsWith('*');
      if (req) head = head.substring(0, head.length - 1).trim();
      if (head.isEmpty) return null;
      final choices = <OptionChoice>[];
      for (final part in line.substring(colon + 1).split(',')) {
        final t = part.trim();
        if (t.isEmpty) continue;
        final bits = t.split('=');
        if (bits.length != 2) return null;
        final label = bits[0].trim();
        final price = double.tryParse(bits[1].trim());
        if (label.isEmpty || price == null || price < 0) return null;
        choices.add(OptionChoice(label, price));
      }
      if (choices.isEmpty) return null;
      out.add(OptionGroup(
          title: head, required: req || fixed, multi: !(req || fixed), fixedPrice: fixed, choices: choices));
    }
    return out;
  }
}

class MenuItem {
  final String id;
  String name;
  String category;
  double price;
  String description;
  int stock;
  bool available;
  String tag;
  String image; // '' = assets/menu/<id>.jpg, or an https:// photo link
  List<OptionGroup> groups; // customisation shown on the item page (size, temperature, add-ons)
  String photo; // photo picked from the phone, stored as base64 text in Firestore ('' = none)
  int sold; // units ordered so far (updated by the order transaction)

  /// Stock at or below this number is labelled "Low stock" (new items start at 10).
  static const int lowStockAt = 5;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.stock = 0,
    this.available = true,
    this.tag = '',
    this.image = '',
    this.photo = '',
    this.groups = const [],
    this.sold = 0,
  });

  String get imagePath => image.isNotEmpty ? image : 'assets/menu/$id.jpg';

  bool get isAvailable => available && stock > 0;
  bool get isLow => stock > 0 && stock <= lowStockAt;
  /// Food and extras are not drinks.
  static const _notDrinks = {'Dip & Drizzle', 'Seoul Bites', 'Additional'};
  bool get isDrink => !_notDrinks.contains(category);

  bool get hasChoices => groups.isNotEmpty;

  /// Picks that are used when the customer changes nothing: the first choice of every required group.
  List<String> get defaultPicks => [
        for (final g in groups)
          if (g.required && g.choices.isNotEmpty) g.choices.first.label,
      ];

  /// Cleans up a list of picked labels: one choice per required group (the first if missing),
  /// only labels that exist, in the order of the groups.
  List<String> normalizePicks(List<String> picks) {
    final out = <String>[];
    for (final g in groups) {
      final chosen = [for (final c in g.choices) if (picks.contains(c.label)) c.label];
      if (g.required) {
        out.add(chosen.isEmpty ? g.choices.first.label : chosen.first);
      } else if (g.multi) {
        out.addAll(chosen);
      } else if (chosen.isNotEmpty) {
        out.add(chosen.first);
      }
    }
    return out;
  }

  /// Price of one cup / plate with these picks.
  double priceFor(List<String> picks) {
    final sel = normalizePicks(picks);
    var total = price;
    for (final g in groups) {
      if (!g.fixedPrice) continue;
      for (final c in g.choices) {
        if (sel.contains(c.label)) total = c.price;
      }
    }
    for (final g in groups) {
      if (g.fixedPrice) continue;
      for (final c in g.choices) {
        if (sel.contains(c.label)) total += c.price;
      }
    }
    return total;
  }

  /// "Large, Cold, +Milk Foam" - shown in the cart and on the order for the kitchen.
  String describePicks(List<String> picks) {
    final sel = normalizePicks(picks);
    final parts = <String>[];
    for (final g in groups) {
      for (final c in g.choices) {
        if (!sel.contains(c.label)) continue;
        parts.add(g.required ? c.label : '+${c.label}');
      }
    }
    return parts.join(', ');
  }

  /// The lowest price of the item (cheapest choice in every required group).
  double get lowestPrice {
    final cheapest = <String>[];
    for (final g in groups) {
      if (g.required && g.choices.isNotEmpty) {
        cheapest.add((g.choices.toList()..sort((a, b) => a.price.compareTo(b.price))).first.label);
      }
    }
    return priceFor(cheapest);
  }

  /// Every price this item can be sold at (used to check the AI never quotes a wrong price).
  Set<double> get possiblePrices {
    var combos = <List<String>>[[]];
    for (final g in groups) {
      final opts = <List<String>>[];
      if (g.required) {
        for (final c in g.choices) {
          opts.add([c.label]);
        }
      } else {
        opts.add([]);
        for (var i = 0; i < g.choices.length; i++) {
          opts.add([g.choices[i].label]);
          for (var j = i + 1; j < g.choices.length; j++) {
            opts.add([g.choices[i].label, g.choices[j].label]);
          }
        }
      }
      combos = [
        for (final base in combos)
          for (final o in opts) [...base, ...o],
      ];
    }
    return {for (final c in combos) double.parse(priceFor(c).toStringAsFixed(2))};
  }

  /// Short text for the AI: "Size: Regular / Large +RM2.00; Temperature: Hot / Cold +RM0.50".
  String get optionSummary => groups
      .map((g) =>
          '${g.title}${g.required ? '' : ' (optional)'}: ' +
          g.choices
              .map((c) => g.fixedPrice
                  ? '${c.label} RM${c.price.toStringAsFixed(2)}'
                  : (c.price > 0 ? '${c.label} +RM${c.price.toStringAsFixed(2)}' : c.label))
              .join(' / '))
      .join('; ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'stock': stock,
        'available': available,
        'tag': tag,
        'image': image,
        'photo': photo,
        'groups': groups.map((g) => g.toJson()).toList(),
        'sold': sold,
      };

  /// Fields the manager edits. Stock and sold are NOT included: they change only through
  /// atomic increments (orders, restocking) so edits can never overwrite them.
  Map<String, dynamic> toDoc() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'available': available,
        'tag': tag,
        'image': image,
        'photo': photo,
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'],
        name: j['name'],
        category: j['category'],
        price: (j['price'] as num).toDouble(),
        description: j['description'] ?? '',
        stock: (j['stock'] as num?)?.toInt() ?? 0,
        available: j['available'] ?? true,
        tag: j['tag'] ?? '',
        image: j['image'] ?? '',
        photo: (j['photo'] ?? '') as String,
        groups: _readGroups(j),
        sold: (j['sold'] as num?)?.toInt() ?? 0,
      );

  /// Reads `groups`; menus saved by v1.7 only have `sizes` (full prices), converted here.
  static List<OptionGroup> _readGroups(Map<String, dynamic> j) {
    final g = j['groups'];
    if (g is List) {
      return [for (final e in g) OptionGroup.fromJson(Map<String, dynamic>.from(e as Map))];
    }
    final old = j['sizes'];
    if (old is List && old.isNotEmpty) {
      return [
        OptionGroup(title: 'Size', required: true, fixedPrice: true, choices: [
          for (final e in old)
            OptionChoice((e['label'] ?? '') as String, (e['price'] as num).toDouble()),
        ]),
      ];
    }
    return const [];
  }
}


class CartLine {
  final String itemId;
  final List<String> picks; // chosen labels, already cleaned by MenuItem.normalizePicks
  final String size; // the same picks as text, e.g. "Large, Cold, +Milk Foam"
  int qty;
  CartLine({required this.itemId, required this.picks, required this.size, required this.qty});
}

class OrderLine {
  final String itemId;
  final String name;
  final String size;
  final int qty;
  final double unitPrice;

  OrderLine({
    required this.itemId,
    required this.name,
    required this.size,
    required this.qty,
    required this.unitPrice,
  });

  double get subtotal => qty * unitPrice;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'size': size,
        'qty': qty,
        'unitPrice': unitPrice,
      };

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        itemId: j['itemId'],
        name: j['name'],
        size: j['size'],
        qty: j['qty'],
        unitPrice: (j['unitPrice'] as num).toDouble(),
      );
}

class Order {
  final String id;
  final int number;
  final String customerId;
  final String customerName;
  final List<OrderLine> lines;
  final String type; // Pickup / Dine-in
  final String payment; // Cash at counter / QR at counter
  final String note;
  final double discount; // e.g. Air Balang 2 big cups deal
  OrderStatus status;
  bool paid;
  final DateTime createdAt;
  DateTime? paidAt;

  Order({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.lines,
    required this.type,
    required this.payment,
    this.note = '',
    this.discount = 0,
    this.status = OrderStatus.pending,
    this.paid = false,
    required this.createdAt,
    this.paidAt,
  });

  double get subtotal => lines.fold(0.0, (s, l) => s + l.subtotal);
  double get total => subtotal - discount;
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'customerId': customerId,
        'customerName': customerName,
        'lines': lines.map((l) => l.toJson()).toList(),
        'type': type,
        'payment': payment,
        'note': note,
        'discount': discount,
        'status': status.name,
        'paid': paid,
        'createdAt': createdAt.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        number: j['number'],
        customerId: j['customerId'],
        customerName: j['customerName'],
        lines: (j['lines'] as List)
            .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        type: j['type'],
        payment: j['payment'],
        note: j['note'] ?? '',
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        status: _enumByName(OrderStatus.values, j['status'], OrderStatus.pending),
        paid: j['paid'] ?? false,
        createdAt: DateTime.parse(j['createdAt']),
        paidAt: j['paidAt'] == null ? null : DateTime.parse(j['paidAt']),
      );
}

class StockTxn {
  final String id;
  final String itemId;
  final String itemName;
  final bool isIn;
  final int qty;
  final String reason;
  final String byName;
  final DateTime at;

  StockTxn({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.isIn,
    required this.qty,
    required this.reason,
    required this.byName,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemName': itemName,
        'isIn': isIn,
        'qty': qty,
        'reason': reason,
        'byName': byName,
        'at': at.toIso8601String(),
      };

  factory StockTxn.fromJson(Map<String, dynamic> j) => StockTxn(
        id: j['id'],
        itemId: j['itemId'],
        itemName: j['itemName'],
        isIn: j['isIn'],
        qty: j['qty'],
        reason: j['reason'] ?? '',
        byName: j['byName'] ?? '',
        at: DateTime.parse(j['at']),
      );
}

class AttendanceRecord {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime checkIn;
  DateTime? checkOut;

  AttendanceRecord({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.checkIn,
    this.checkOut,
  });

  bool get isOpen => checkOut == null;
  Duration get duration => (checkOut ?? DateTime.now()).difference(checkIn);

  Map<String, dynamic> toJson() => {
        'id': id,
        'staffId': staffId,
        'staffName': staffName,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut?.toIso8601String(),
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'],
        staffId: j['staffId'],
        staffName: j['staffName'],
        checkIn: DateTime.parse(j['checkIn']),
        checkOut: j['checkOut'] == null ? null : DateTime.parse(j['checkOut']),
      );
}

class ChatMessage {
  final String id;
  final String customerId;
  final String customerName;
  final String text;
  final bool fromManager;
  final bool viaBot; // forwarded from the AI assistant
  final DateTime at;

  ChatMessage({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.text,
    required this.fromManager,
    this.viaBot = false,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'text': text,
        'fromManager': fromManager,
        'viaBot': viaBot,
        'at': at.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        customerId: j['customerId'],
        customerName: j['customerName'],
        text: j['text'],
        fromManager: j['fromManager'] ?? false,
        viaBot: j['viaBot'] ?? false,
        at: DateTime.parse(j['at']),
      );
}

class CampusEvent {
  final String id;
  final String title;
  final DateTime date;
  final String where;
  final String blurb;
  final String media; // https link to a banner photo or video (Cloudinary), optional
  final bool isVideo;
  const CampusEvent(this.id, this.title, this.date, this.where, this.blurb,
      {this.media = '', this.isVideo = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'where': where,
        'blurb': blurb,
        'media': media,
        'isVideo': isVideo,
      };

  factory CampusEvent.fromJson(Map<String, dynamic> j) => CampusEvent(
        j['id'] as String,
        (j['title'] ?? '') as String,
        DateTime.parse(j['date'] as String),
        (j['where'] ?? '') as String,
        (j['blurb'] ?? '') as String,
        media: (j['media'] ?? '') as String,
        isVideo: (j['isVideo'] ?? false) as bool,
      );
}

/// A customer's star rating (and optional comment) for one item of a completed order.
class Review {
  final String id, orderId, itemId, itemName, userId, userName, comment;
  final int rating; // 1..5
  final DateTime at;

  Review({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.itemName,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment = '',
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'orderId': orderId, 'itemId': itemId, 'itemName': itemName,
        'userId': userId, 'userName': userName, 'rating': rating,
        'comment': comment, 'at': at.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'], orderId: j['orderId'], itemId: j['itemId'],
        itemName: j['itemName'] ?? '', userId: j['userId'], userName: j['userName'] ?? '',
        rating: j['rating'], comment: j['comment'] ?? '', at: DateTime.parse(j['at']),
      );
}

/// One row of the "Hot Selling" ranking.
class HotItem {
  final MenuItem item;
  final int orders;
  final double avgRating; // 0 when there are no reviews
  final int ratingCount;
  final double score;
  const HotItem(this.item, this.orders, this.avgRating, this.ratingCount, this.score);
}
