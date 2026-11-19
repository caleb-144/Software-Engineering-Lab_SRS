import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../seed.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'thread_screen.dart';

/// Preset avatars (icon on a colour) that the customer can choose from.
const List<(IconData, Color)> kAvatars = [
  (Icons.local_cafe, Color(0xFF151515)),
  (Icons.icecream, Color(0xFF3A3A3A)),
  (Icons.bubble_chart, Color(0xFF595959)),
  (Icons.eco, Color(0xFF777777)),
  (Icons.emoji_food_beverage, Color(0xFF2B2B2B)),
  (Icons.ramen_dining, Color(0xFF4A4A4A)),
  (Icons.cake, Color(0xFF686868)),
  (Icons.local_drink, Color(0xFF858585)),
];

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double radius;
  const UserAvatar(this.user, {this.radius = 32, super.key});

  @override
  Widget build(BuildContext context) => avatarFor(user.name, user.avatar, radius);
}

Widget avatarFor(String name, int avatar, double radius) {
  if (avatar >= 0 && avatar < kAvatars.length) {
    final a = kAvatars[avatar];
    return CircleAvatar(
        radius: radius,
        backgroundColor: a.$2,
        child: Icon(a.$1, color: Brand.white, size: radius));
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: Brand.primary,
    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
            color: Brand.white, fontSize: radius * 0.85, fontWeight: FontWeight.w800)),
  );
}

// ---------------------------------------------------------------- Edit profile
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AppUser _u = context.read<AppState>().user!;
  late final _name = TextEditingController(text: _u.name);
  late final _phone = TextEditingController(text: _u.phone);
  late String _birthday = _u.birthday;
  late bool _public = _u.birthdayPublic;
  late int _avatar = _u.avatar;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final v = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Choose your avatar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Wrap(spacing: 16, runSpacing: 16, children: [
            InkResponse(
                onTap: () => Navigator.pop(ctx, -1),
                child: avatarFor(_name.text, -1, 30)),
            for (var i = 0; i < kAvatars.length; i++)
              InkResponse(onTap: () => Navigator.pop(ctx, i), child: avatarFor('', i, 30)),
          ]),
        ]),
      ),
    );
    if (v != null) setState(() => _avatar = v);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final init = DateTime.tryParse(_birthday) ?? DateTime(now.year - 20, 1, 1);
    final d = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: DateTime(1940),
        lastDate: now);
    if (d != null) setState(() => _birthday = DateFormat('yyyy-MM-dd').format(d));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return toast(context, 'Enter your name');
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9 \-]{8,15}$').hasMatch(phone)) {
      return toast(context, 'Enter a valid phone number');
    }
    setState(() => _saving = true);
    final err = await context.read<AppState>().updateProfile(
        name: name,
        phone: phone,
        birthday: _birthday,
        birthdayPublic: _public,
        avatar: _avatar);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) return toast(context, err);
    toast(context, 'Profile saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: Stack(clipBehavior: Clip.none, children: [
              avatarFor(_name.text, _avatar, 52),
              Positioned(
                right: -4,
                bottom: -4,
                child: InkResponse(
                  onTap: _pickAvatar,
                  child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Brand.white,
                      child: Icon(Icons.edit, size: 18, color: Brand.primary)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Center(
              child: TextButton(
                  onPressed: _pickAvatar, child: const Text('Choose your avatar'))),
          const SizedBox(height: 12),
          TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 14),
          TextField(
              controller: TextEditingController(text: _u.email),
              enabled: false,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickBirthday,
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Birthday', prefixIcon: Icon(Icons.cake_outlined)),
              child: Row(children: [
                Expanded(child: Text(_birthday.isEmpty ? 'Tap to choose' : _birthday)),
                Text(_public ? 'Public' : 'Private',
                    style: const TextStyle(
                        color: Brand.primary, fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _public = !_public),
              child: Text(_public
                  ? 'Who can see your birthday: staff (tap to hide)'
                  : 'Who can see your birthday: only you (tap to share)'),
            ),
          ),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone number', prefixIcon: Icon(Icons.phone_android_outlined))),
          const SizedBox(height: 28),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Help centre
class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  static const _answers = <String, String>{
    'How do I pay?':
        'Pay at the counter with cash or QR when you collect your order. There is no online or card payment.',
    'Do you offer delivery?': 'No delivery. Choose Pickup or Dine-in when you check out.',
    'Pickup or dine-in?':
        'Pickup: collect at the counter. Dine-in: enjoy it at the cafe. Pick one in the cart.',
    'What sizes are there?':
        'Most drinks are Regular or Large (Large is RM2.00 more, Frappe RM1.00 more). Beverages can be Hot or Cold (Cold is RM0.50 more). Air Balang is Small RM2.50, Medium RM3.00 or Big RM5.00, and 2 Big cups get 20% off.',
    "What's hot right now?": 'See the Hot Selling row on the Home tab.',
    "What's sold out?": 'Sold out items are marked on the Menu tab.',
  };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Help Centre'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            color: Brand.primarySoft,
            outlined: false,
            child: Text(kServicesInfo,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          const Text('Common questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          for (final e in _answers.entries)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(e.value, style: const TextStyle(color: Brand.grey))],
            ),
          const SizedBox(height: 12),
          const Text('Still need help?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Ask the Assistant tab, or message the manager directly.',
              style: TextStyle(color: Brand.grey)),
          const SizedBox(height: 12),
          if (s.user?.role == Role.customer)
            FilledButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ThreadScreen(customerId: s.user!.id))),
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Message the manager'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Feedback
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _stars = 0;
  String _topic = 'Drinks';
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (_stars == 0) return toast(context, 'Tap the stars to rate us');
    final body = _text.text.trim();
    final msg = 'Feedback ($_topic) - $_stars/5 stars${body.isEmpty ? '' : '\n$body'}';
    final err = context.read<AppState>().sendCustomerMessage(msg);
    if (err != null) return toast(context, err);
    toast(context, 'Thank you for your feedback!');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('How was your experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => setState(() => _stars = i),
                icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 38, color: Brand.star),
              ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final t in ['Drinks', 'Food', 'Service', 'App', 'Other'])
              Pill(label: t, selected: _topic == t, onTap: () => setState(() => _topic = t)),
          ]),
          const SizedBox(height: 16),
          TextField(
              controller: _text,
              maxLines: 5,
              maxLength: 400,
              decoration: const InputDecoration(
                  labelText: 'Tell us more (optional)', alignLabelWithHint: true)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _send, child: const Text('Send feedback')),
          const SizedBox(height: 8),
          const Text('Your feedback goes to the manager\'s inbox.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Brand.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Settings
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (u != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_reset, color: Brand.primary),
              title: const Text('Change password',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('We email a reset link to ${u.email}'),
              onTap: () async {
                final err = await s.sendPasswordReset(u.email);
                if (context.mounted) {
                  toast(context, err ?? 'Reset link sent. Check your email.');
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: Brand.primary),
              title: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            const Divider(),
          ],
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: Brand.primary),
            title: Text("THE MINUM'S", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Version $kAppVersion'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Terms / Privacy
class LegalScreen extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;
  const LegalScreen({required this.title, required this.sections, super.key});

  static const terms = LegalScreen(title: 'Terms & Conditions', sections: [
    ('Using the app',
        "THE MINUM'S app lets you browse the menu, place pickup or dine-in orders and message the shop. You must give true details when you sign up and keep your password private."),
    ('Orders and payment',
        'Orders are made in the app and paid at the counter by cash or QR. There is no delivery and no online or card payment. An order is confirmed once the shop accepts it.'),
    ('Prices and stock',
        'Prices are in RM and may change. Items can sell out. If an item is no longer available when you order, it will be removed from your cart.'),
    ('Cancelling',
        'You can cancel an order while it is still pending. Once the shop starts preparing it, please speak to the staff.'),
    ('Special deals',
        'Deals such as 20% off every 2 BIG Air Balang cups are applied automatically at checkout and may be changed or ended at any time.'),
    ('Changes',
        'We may update these terms. Continuing to use the app means you accept the latest version.'),
  ]);

  static const privacy = LegalScreen(title: 'Privacy Notice', sections: [
    ('What we collect',
        'Your name, email and phone number, your optional birthday and avatar, your orders, ratings, feedback and messages to the shop.'),
    ('Why we collect it',
        'To run your account, prepare your orders, show your order history, reply to your messages and improve the menu.'),
    ('Where it is kept',
        'Your account and orders are stored with Google Firebase. Menu and event photos and videos are stored with Cloudinary. Your password is handled by Firebase Authentication and is never visible to the shop.'),
    ('AI assistant',
        'Questions you type in the Assistant tab are sent to Google AI Studio (Gemini) to write a reply. Do not share personal or sensitive information there.'),
    ('Who can see it',
        'Staff and the manager see your name and orders to serve you. Your birthday is shown to staff only if set to Public.'),
    ('Your choices',
        'You can edit your details in Edit Profile, or ask the manager to remove your account.'),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (h, b) in sections) ...[
            Text(h, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(b, style: const TextStyle(color: Brand.grey, height: 1.4)),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
