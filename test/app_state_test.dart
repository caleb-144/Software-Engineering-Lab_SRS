import 'package:flutter_test/flutter_test.dart';
import 'package:minums_app/models.dart';
import 'package:minums_app/seed.dart';
import 'package:minums_app/state/app_state.dart';
import 'package:minums_app/utils/validators.dart';

/// Tests run without Firebase (useFirebase: false) and cover the in-memory logic.
Future<AppState> _make() async {
  final s = AppState();
  await s.init(useFirebase: false);
  s.menu = seedMenu();
  return s;
}

void main() {
  test('password rules: length, letter+number, special character', () {
    expect(Validators.password('abc1!'), isNotNull); // too short
    expect(Validators.password('abcdefgh!'), isNotNull); // no number
    expect(Validators.password('abcd1234'), isNotNull); // no special
    expect(Validators.password('abcd123!'), isNull);
  });

  test('guest can fill a cart but cannot order or message', () async {
    final s = await _make();
    expect(s.isGuest, true);
    expect(s.addToCart('fr01', ['Regular'], 1), isNull);
    expect((await s.placeOrder(type: 'Pickup', payment: 'Cash at counter')).error, isNotNull);
    expect(s.sendCustomerMessage('hi'), isNotNull);
  });

  test('every menu item starts at the default stock of 10', () async {
    final s = await _make();
    expect(kStartingStock, 10);
    expect(s.menu.length, 126);
    expect(s.menu.every((m) => m.stock == 10), true);
  });

  test('menu categories match the printed menu', () async {
    final s = await _make();
    expect(kCategories.length, 15);
    for (final m in s.menu) {
      expect(kCategories.contains(m.category), true, reason: m.name);
    }
  });

  test('size, temperature and add-on prices', () async {
    final s = await _make();
    final milo = s.menu.firstWhere((m) => m.name == 'Milo');
    expect(milo.priceFor(['Regular', 'Hot']), 3.5);
    expect(milo.priceFor(['Regular', 'Cold']), 4.0);
    expect(milo.priceFor(['Large', 'Hot']), 5.5);
    final frappe = s.menu.firstWhere((m) => m.id == 'fr01');
    expect(frappe.priceFor(['Regular']), 4.0);
    expect(frappe.priceFor(['Large']), 5.0);
    expect(frappe.priceFor(['Large', 'Milk Foam']), 7.0);
    final balang = s.menu.firstWhere((m) => m.id == 'ab01');
    expect(balang.priceFor(['Small']), 2.5);
    expect(balang.priceFor(['Medium']), 3.0);
    expect(balang.priceFor(['Big']), 5.0);
    final bite = s.menu.firstWhere((m) => m.id == 'sb01');
    expect(bite.priceFor(['Telur Mata']), bite.price + 1.5);
    expect(s.menu.firstWhere((m) => m.name == 'Popia Carbonara').isDrink, false);
  });

  test('2 big Air Balang get 20% off', () async {
    final s = await _make();
    expect(s.addToCart('ab01', ['Big'], 1), isNull);
    expect(s.cartDiscount, 0);
    expect(s.addToCart('ab01', ['Big'], 1), isNull);
    expect(s.cartSubtotal, 10.0);
    expect(s.cartDiscount, closeTo(2.0, 0.001));
    expect(s.cartTotal, closeTo(8.0, 0.001));
  });

  test('customisation text can be typed and read back', () {
    final list = OptionGroup.parse('Size*: Regular=0, Large=2\nAdd-ons: Milk Foam=2')!;
    expect(list.length, 2);
    expect(list[0].required, true);
    expect(list[1].multi, true);
    final again = OptionGroup.parse(OptionGroup.format(list))!;
    expect(again.length, 2);
    expect(again[0].choices[1].price, 2.0);
    expect(OptionGroup.parse('Size Regular 0'), isNull);
  });

  test('cart refuses more than the stock', () async {
    final s = await _make();
    expect(s.addToCart('fr01', ['Regular'], 11), isNotNull);
    expect(s.addToCart('fr01', ['Regular'], 10), isNull);
  });

  test('hot selling ranks by units ordered plus reviews', () async {
    final s = await _make();
    s.itemById('ma01')!.sold = 3;
    expect(s.hotSelling().first.item.id, 'ma01');
    expect(s.orderCountFor('ma01'), 3);
  });

  test('menu item edits never carry stock or sold', () {
    final doc = seedMenu().first.toDoc();
    expect(doc.containsKey('stock'), false);
    expect(doc.containsKey('sold'), false);
  });

  test('events survive a JSON round trip', () {
    final e = CampusEvent('e1', 'Open Day', DateTime(2027, 1, 5, 9), 'Main Hall', 'Hello');
    final back = CampusEvent.fromJson(e.toJson());
    expect(back.title, 'Open Day');
    expect(back.date, e.date);
  });

  test('reorder puts the same drink back in the cart with the same options', () async {
    final s = await _make();
    final o = Order(
      id: 'o1',
      number: 1001,
      customerId: 'u1',
      customerName: 'Test',
      type: 'Pickup',
      payment: 'Cash at counter',
      lines: [
        OrderLine(
            itemId: 'fr01', name: 'Frappe', size: 'Large, +Milk Foam', qty: 2, unitPrice: 7.0),
        OrderLine(itemId: 'gone', name: 'Old item', size: '', qty: 1, unitPrice: 1.0),
      ],
    );
    final r = s.reorder(o);
    expect(r.added, 1);
    expect(r.skipped, 1);
    expect(s.cart.single.qty, 2);
    expect(s.cart.single.size, 'Large, +Milk Foam');
    expect(s.cartSubtotal, 14.0);
  });

  test('event banner media survives a JSON round trip', () {
    final e = CampusEvent('e2', 'Movie', DateTime(2027, 2, 1, 20), 'Hall', '',
        media: 'https://res.cloudinary.com/x/video/upload/v1/a.mp4', isVideo: true);
    final back = CampusEvent.fromJson(e.toJson());
    expect(back.isVideo, true);
    expect(back.media, e.media);
  });
}
