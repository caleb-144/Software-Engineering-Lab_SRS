import 'models.dart';

const List<String> kCategories = [
  'Beverages',
  'Soft Drinks',
  'Frappe',
  'Matcha',
  'Cocoa',
  'Taro',
  'Latte',
  'Red Velvet',
  'Sprite',
  'Thai Tea',
  'Air Balang',
  'Other Drinks',
  'Dip & Drizzle',
  'Seoul Bites',
  'Additional',
];

/// Default stock for a new menu item and the amount the restock dialog starts from (was 5).
const int kDefaultStock = 10;

/// Shown at the bottom of the Account page.
const String kAppVersion = '1.9.0';

const String kServicesInfo =
    'Services: pickup and dine-in. Payment is made at the counter (cash or QR). '
    'No food delivery, no online payment and no debit/credit card payment.';

/// Preset FAQ chips in the Assistant tab. [toManager] = the app has no answer,
/// so tapping the chip sends the question straight to the manager's inbox.
class FaqItem {
  final String question;
  final bool toManager;
  const FaqItem(this.question, {this.toManager = false});
}

const List<FaqItem> kFaqs = [
  FaqItem("What's hot right now?"),
  FaqItem("What's sold out?"),
  FaqItem('How do I pay?'),
  FaqItem('Do you offer delivery?'),
  FaqItem('Pickup or dine-in?'),
  FaqItem('What sizes are there?'),
  FaqItem('What are your opening hours?', toManager: true),
  FaqItem('Do you have allergen information?', toManager: true),
  FaqItem('Can I place a bulk or event order?', toManager: true),
];

/// Example prompts that show off the AI assistant.
const List<String> kAiPrompts = ['Recommend something sweet', "What's good under RM8?"];

/// The manager account is created by hand in the Firebase console
/// (see FIREBASE_SETUP_GUIDE.md). Nobody can register as manager in the app.
const String kManagerEmail = 'petrus@minums.com';

/// THE MINUM'S 2026 menu (from "THE MINUM'S - 2026 LATEST MENU" PDF), with the customisation
/// rules the owner asked for. Every item starts with [kDefaultStock] units.
/// Photos are added in the app (Menu & stock -> item).
List<MenuItem> seedMenu() {
  MenuItem m(String id, String name, String cat, double price, String desc,
          List<OptionGroup> groups) =>
      MenuItem(
          id: id,
          name: name,
          category: cat,
          price: price,
          description: desc,
          groups: groups,
          stock: kDefaultStock);
  return [
    m('bv01', 'Milo', 'Beverages', 3.5, '', _beverage(hot: true)),
    m('bv02', 'Milo Dinasour', 'Beverages', 5.0, '', _beverage(hot: false)),
    m('bv03', 'Kopi O', 'Beverages', 3.0, '', _beverage(hot: true)),
    m('bv04', 'Kopi Susu', 'Beverages', 3.5, '', _beverage(hot: true)),
    m('bv05', 'Kopi C', 'Beverages', 3.0, '', _beverage(hot: true)),
    m('bv06', 'Horlicks', 'Beverages', 3.5, '', _beverage(hot: true)),
    m('bv07', 'Teh O/C', 'Beverages', 2.5, '', _beverage(hot: true)),
    m('bv08', 'Teh Tarik', 'Beverages', 3.5, '', _beverage(hot: true)),
    m('bv09', 'Green Tea Syrup', 'Beverages', 3.0, '', _beverage(hot: false)),
    m('bv10', 'Milk Green Tea', 'Beverages', 4.0, '', _beverage(hot: false)),
    m('bv11', 'Green Tea Lemon', 'Beverages', 3.5, '', _beverage(hot: true)),
    m('bv12', 'Soya', 'Beverages', 3.0, '', _beverage(hot: false)),
    m('bv13', 'Soya Gula Apong', 'Beverages', 4.5, '', _beverage(hot: false)),
    m('bv14', 'Soya Laici', 'Beverages', 5.0, '', _beverage(hot: false)),
    m('bv15', 'Sirap Ros', 'Beverages', 2.0, '', _beverage(hot: true)),
    m('bv16', 'Sirap Limau', 'Beverages', 2.5, '', _beverage(hot: true)),
    m('bv17', 'Sirap Bandung', 'Beverages', 4.0, '', _beverage(hot: false)),
    m('bv18', 'Sirap Laici', 'Beverages', 3.0, '', _beverage(hot: true)),
    m('bv19', 'Bandung Laici', 'Beverages', 5.0, '', _beverage(hot: false)),
    m('bv20', 'Sirap Ros Oren Sunquick', 'Beverages', 4.0, '', _beverage(hot: false)),
    m('bv21', 'Oren Sunquick', 'Beverages', 3.5, '', _beverage(hot: false)),
    m('bv22', 'Ribena', 'Beverages', 3.0, '', _beverage(hot: false)),
    m('bv23', 'Ribena Sprite', 'Beverages', 4.0, '', _beverage(hot: false)),
    m('bv24', 'Ribena Laici', 'Beverages', 4.5, '', _beverage(hot: false)),
    m('bv25', 'Ribena Sprite Laici', 'Beverages', 5.0, '', _beverage(hot: false)),
    m('bv26', 'Ribena Nata De Coco', 'Beverages', 4.0, '', _beverage(hot: false)),
    m('bv27', 'Ribena Sprite Nata De Coco', 'Beverages', 4.5, '', _beverage(hot: false)),
    m('bv28', 'Limau Kosong', 'Beverages', 2.5, '', _beverage(hot: true)),
    m('bv29', '2-Sour Drinks', 'Beverages', 3.5, '', _beverage(hot: true)),
    m('bv30', 'Lemon', 'Beverages', 2.5, '', _beverage(hot: true)),
    m('bv31', 'Iced Lemon Tea', 'Beverages', 4.0, '', _beverage(hot: false)),
    m('bv32', 'Lemon Lime', 'Beverages', 4.5, '', _beverage(hot: false)),
    m('bv33', 'Lemon Sirap Ros', 'Beverages', 3.0, '', _beverage(hot: true)),
    m('bv34', 'Ribena Sprite Lemon', 'Beverages', 5.0, '', _beverage(hot: false)),
    m('bv35', 'Lemon Laici', 'Beverages', 4.0, '', _beverage(hot: true)),
    m('bv36', 'Nescafe', 'Beverages', 3.5, '', _beverage(hot: true)),
    m('bv37', 'Neslo', 'Beverages', 4.0, '', _beverage(hot: true)),
    m('sd01', 'Coca Cola', 'Soft Drinks', 3.0, '', []),
    m('sd02', '100 Plus', 'Soft Drinks', 3.0, '', []),
    m('sd03', 'Mountain Dew', 'Soft Drinks', 3.0, '', []),
    m('sd04', 'Zappel', 'Soft Drinks', 3.0, '', []),
    m('sd05', 'Strawberry', 'Soft Drinks', 3.0, '', []),
    m('sd06', 'Sarsi', 'Soft Drinks', 3.0, '', []),
    m('sd07', 'Orange', 'Soft Drinks', 3.0, '', []),
    m('sd08', 'Sundrop Orange', 'Soft Drinks', 3.0, '', []),
    m('sd09', 'Pepsi', 'Soft Drinks', 3.0, '', []),
    m('sd10', 'Ice Cream Soda', 'Soft Drinks', 3.0, '', []),
    m('fr01', 'Chocolate', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr02', 'Cappucino', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr03', 'Strawberry', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr04', 'Melon', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr05', 'Lychee', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr06', 'Grape', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr07', 'Mango', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr08', 'Vanilla Blue', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr09', 'Blueberry', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr10', 'Vanilla Latte', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr11', 'Taro', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('fr12', 'Mochacino', 'Frappe', 4.0, 'Chilled, slushy drink made by blending ice with fruits, coffee or syrups. 60kcal.', _frappe()),
    m('ma01', 'Matcha Latte', 'Matcha', 9, '', _sizes()),
    m('ma02', 'Butterfly Pea Matcha', 'Matcha', 9.5, '', _sizes()),
    m('ma03', 'Strawberry Matcha', 'Matcha', 11, '', _sizes()),
    m('ma04', 'Dark Cocoa Matcha', 'Matcha', 10.5, '', _sizes()),
    m('ma05', 'Golden Mango Matcha', 'Matcha', 11, '', _sizes()),
    m('ma06', 'Matcha Taro', 'Matcha', 11, '', _sizes()),
    m('ma07', 'Matcha Oreo Latte', 'Matcha', 11, '', _sizes()),
    m('ma08', 'Bandung Matcha', 'Matcha', 9.5, '', _sizes()),
    m('ma09', 'Blueberry Matcha', 'Matcha', 11, '', _sizes()),
    m('ma10', 'Strawberry Puree Matcha', 'Matcha', 13, '', _sizes()),
    m('ma11', 'Caramel Matcha Latte', 'Matcha', 9, '', _sizes()),
    m('ma12', 'Taro Caramel Matcha', 'Matcha', 12, '', _sizes()),
    m('ma13', 'Cocoa Caramel Matcha', 'Matcha', 12, '', _sizes()),
    m('ma14', 'Cloud Matcha Latte', 'Matcha', 11, '', _sizes()),
    m('ma15', 'Biscoff Matcha Latte', 'Matcha', 12, '', _sizes()),
    m('co01', 'Signature Cocoa', 'Cocoa', 7, '', _sizes()),
    m('co02', 'Cocoa Latte', 'Cocoa', 8, '', _sizes()),
    m('co03', 'Cocoa Oreo Latte', 'Cocoa', 10, '', _sizes()),
    m('co04', 'Cocoa Strawberry', 'Cocoa', 10, '', _sizes()),
    m('co05', 'Cocoa Brown Sugar', 'Cocoa', 8, '', _sizes()),
    m('co06', 'Cocoa Indulgence', 'Cocoa', 10, '', _sizes()),
    m('co07', 'Cocoa Thai Tea Latte', 'Cocoa', 12, '', _sizes()),
    m('ta01', 'Signature Taro', 'Taro', 7, '', _sizes()),
    m('ta02', 'Cocoa Taro', 'Taro', 10, '', _sizes()),
    m('ta03', 'Taro Latte', 'Taro', 8, '', _sizes()),
    m('ta04', 'Gula Apong Taro', 'Taro', 9, '', _sizes()),
    m('ta05', 'Butterfly Pea Taro', 'Taro', 9.5, '', _sizes()),
    m('ta06', 'Taro Indulgence', 'Taro', 10, '', _sizes()),
    m('ta07', 'Taro Oreo Latte', 'Taro', 10, '', _sizes()),
    m('ta08', 'Taro Pink Latte', 'Taro', 10, '', _sizes()),
    m('la01', 'Strawberry Latte', 'Latte', 8, '', _sizes()),
    m('la02', 'Blueberry Latte', 'Latte', 8, '', _sizes()),
    m('la03', 'Oreo Latte', 'Latte', 9, '', _sizes()),
    m('la04', 'Butterfly Pea Latte', 'Latte', 9, '', _sizes()),
    m('la05', 'Strawberry Pink Latte', 'Latte', 10, '', _sizes()),
    m('rv01', 'Red Velvet Latte', 'Red Velvet', 8, '', _sizes()),
    m('rv02', 'Signature Red Velvet', 'Red Velvet', 7, '', _sizes()),
    m('rv03', 'Cocoa Red Velvet', 'Red Velvet', 10, '', _sizes()),
    m('rv04', 'Oreo Crumbs Red Velvet', 'Red Velvet', 9.5, '', _sizes()),
    m('rv05', 'Strawberry Red Velvet', 'Red Velvet', 10, '', _sizes()),
    m('rv06', 'Caramel Red Velvet', 'Red Velvet', 9.5, '', _sizes()),
    m('sp01', 'Lemon Sprite', 'Sprite', 4.5, '', _sizes()),
    m('sp02', 'Orange Sprite', 'Sprite', 4, '', _sizes()),
    m('sp03', 'Green Tea Sprite', 'Sprite', 4, '', _sizes()),
    m('sp04', 'Lime Sprite', 'Sprite', 4, '', _sizes()),
    m('sp05', 'Strawberry Sprite', 'Sprite', 4, '', _sizes()),
    m('sp06', 'Calamansi Sprite', 'Sprite', 4, '', _sizes()),
    m('sp07', 'Blueberry Sprite', 'Sprite', 4, '', _sizes()),
    m('sp08', 'Mango Sprite', 'Sprite', 4, '', _sizes()),
    m('tt01', 'Thai Green Tea', 'Thai Tea', 6, '', _sizes()),
    m('tt02', 'Thai Red Tea', 'Thai Tea', 6, '', _sizes()),
    m('tt03', 'Thai Red Tea With Cocoa', 'Thai Tea', 9, '', _sizes()),
    m('tt04', 'Thai Tea Latte', 'Thai Tea', 7.5, '', _sizes()),
    m('tt05', 'Thai Tea Indulgence', 'Thai Tea', 9, '', _sizes()),
    m('ab01', 'Air Balang', 'Air Balang', 2.5, 'Small RM2.50, Medium RM3.00, Big RM5.00. Order 2 Big cups and get 20% off them.', _airBalang()),
    m('od01', 'Mineral Water (Bottle)', 'Other Drinks', 1.0, '', []),
    m('od02', 'Sky Juice', 'Other Drinks', 1.0, '', []),
    m('dd01', 'Popia Carbonara', 'Dip & Drizzle', 1.0, 'RM1.00 per piece. Menu allergen icons: chicken, cheese, wheat.', []),
    m('dd02', 'Potato Curry Puff', 'Dip & Drizzle', 3.0, 'RM3.00 for 4 pieces. Menu allergen icons: potato, coconut, wheat.', []),
    m('sb01', 'Maggi Goreng Basah', 'Seoul Bites', 6.0, '', _seoulAddOns()),
    m('sb02', 'Maggi Kari', 'Seoul Bites', 3.5, '', _seoulAddOns()),
    m('sb03', 'Maggi Ayam', 'Seoul Bites', 3.5, '', _seoulAddOns()),
    m('sb04', 'Maggi Tomyam', 'Seoul Bites', 3.5, '', _seoulAddOns()),
    m('sb05', 'Maggi Asam Laksa', 'Seoul Bites', 3.5, '', _seoulAddOns()),
    m('sb06', 'Mi Sedaap', 'Seoul Bites', 4.0, '', _seoulAddOns()),
    m('sb07', 'Ramyeon Hot Chicken', 'Seoul Bites', 8.5, '', _seoulAddOns()),
    m('ad01', 'Ice Cup', 'Additional', 0.5, 'Regular RM0.50, Large RM0.70.', _iceCup()),
  ];
}

// ---- Prices that apply to whole categories (change here, then use Menu & stock -> Load menu) ----
const double kLargeExtra = 2.00; // Large costs this much more (Matcha, Cocoa, Taro, Latte, Red Velvet, Sprite, Thai Tea, Beverages)
const double kFrappeLargeExtra = 1.00; // Frappe: Regular RM4.00, Large RM5.00 (printed menu)
const double kColdExtra = 0.50; // Cold beverages cost this much more than Hot
const double kMilkFoamPrice = 2.00; // add-on for Frappe (printed menu)
const double kMeePrice = 1.50; // extra mee for Seoul Bites. NOT printed on the menu: check it!

List<OptionGroup> _sizes([double large = kLargeExtra]) => [
      OptionGroup(
          title: 'Size',
          required: true,
          choices: [const OptionChoice('Regular', 0), OptionChoice('Large', large)]),
    ];

/// Beverages: Size + Temperature (Hot = no extra, Cold = +RM0.50). Cold-only drinks keep Cold only.
List<OptionGroup> _beverage({required bool hot}) => [
      ..._sizes(),
      OptionGroup(title: 'Temperature', required: true, choices: [
        if (hot) const OptionChoice('Hot', 0),
        OptionChoice('Cold', hot ? kColdExtra : 0),
      ]),
    ];

List<OptionGroup> _frappe() => [
      ..._sizes(kFrappeLargeExtra),
      const OptionGroup(
          title: 'Add-ons', choices: [OptionChoice('Milk Foam', kMilkFoamPrice)], multi: true),
    ];

List<OptionGroup> _airBalang() => [
      const OptionGroup(title: 'Size', required: true, fixedPrice: true, choices: [
        OptionChoice('Small', 2.50),
        OptionChoice('Medium', 3.00),
        OptionChoice('Big', 5.00),
      ]),
    ];

List<OptionGroup> _seoulAddOns() => [
      const OptionGroup(title: 'Add-ons', multi: true, choices: [
        OptionChoice('Mee', kMeePrice),
        OptionChoice('Telur Mata', 1.50),
        OptionChoice('Sosej', 1.50),
        OptionChoice('Fishball', 1.50),
        OptionChoice('Fishcake', 1.50),
        OptionChoice('Cili Api', 0.50),
      ]),
    ];

List<OptionGroup> _iceCup() => [
      const OptionGroup(title: 'Size', required: true, fixedPrice: true, choices: [
        OptionChoice('Regular', 0.50),
        OptionChoice('Large', 0.70),
      ]),
    ];
