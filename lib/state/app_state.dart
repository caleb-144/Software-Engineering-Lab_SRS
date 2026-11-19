import 'dart:async';

// Firestore also has a class named Order; hide it so our own Order model is used.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models.dart';
import '../seed.dart';
import '../utils/validators.dart';

class ThreadSummary {
  final String customerId;
  final String customerName;
  final ChatMessage last;
  final bool awaitingReply;
  ThreadSummary(this.customerId, this.customerName, this.last, this.awaitingReply);
}

/// Thrown inside the order transaction when an item cannot be sold any more.
class _OrderProblem implements Exception {
  final String message;
  _OrderProblem(this.message);
}

/// App data. EVERYTHING is stored online in Firebase, so every phone sees the same data:
///  * Accounts   -> Firebase Authentication + Firestore `users/{uid}`
///  * Menu+stock -> Firestore `menu/{id}`            (public read, staff/manager write)
///  * Orders     -> Firestore `orders/{id}`          (customer sees own, staff/manager see all)
///  * Stock log  -> Firestore `stockTxns/{id}`
///  * Reviews    -> Firestore `reviews/{id}`
///  * Messages   -> Firestore `messages/{id}`
///  * Events     -> Firestore `events/{id}`
///  * Check-ins  -> Firestore `attendance/{id}`
/// `user == null` means GUEST: can browse the menu, must log in to order or message the manager.
class AppState extends ChangeNotifier {
  bool ready = false;
  bool firebaseReady = false;

  AppUser? user; // null = guest
  List<AppUser> staffAccounts = []; // manager only
  List<MenuItem> menu = [];
  List<Order> orders = []; // newest first
  List<StockTxn> stockTxns = []; // newest first (staff + manager)
  List<AttendanceRecord> attendance = []; // newest first
  List<ChatMessage> messages = []; // oldest first
  List<Review> reviews = [];
  List<CampusEvent> events = [];
  final List<CartLine> cart = [];

  int _idCounter = 0;
  bool _menuSeedChecked = false;
  bool _menuEmptyConfirmed = false; // the SERVER (not the cache) said the menu is empty

  /// Live Firestore subscriptions. These three stay on for guests too.
  static const _publicKeys = {'menu', 'reviews', 'events'};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs = {};

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get isGuest => user == null;

  String _newId(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  /// Runs a Firestore write without waiting. Firestore shows the change on screen straight
  /// away and syncs it when online; a rejected write is logged.
  void _fire(Future<void> write) {
    write.catchError((Object e) {
      debugPrint('Firestore write failed: $e');
    });
  }

  // ------------------------------------------------------------ lifecycle
  Future<void> init({bool useFirebase = true}) async {
    firebaseReady = useFirebase;
    if (useFirebase) {
      _startPublicListeners();
      await _restoreSession();
    }
    ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }

  // ------------------------------------------------------------ auth (Firebase)
  Future<AppUser?> _loadProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromMap(doc.id, data);
  }

  /// Firebase keeps the login between launches; this picks it back up.
  Future<void> _restoreSession() async {
    try {
      final fu = await _auth.authStateChanges().first.timeout(const Duration(seconds: 6));
      if (fu == null) return;
      final profile = await _loadProfile(fu.uid);
      if (profile != null && profile.status == AccountStatus.approved) {
        user = profile;
        _startListeners();
      } else {
        await _auth.signOut();
      }
    } catch (_) {
      // Offline or Firebase unreachable: continue as a guest.
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password';
      case 'invalid-email':
        return 'Enter a valid email';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
      case 'password-does-not-meet-requirements':
        return 'That password is too weak. Use 8+ characters with a number and a special character.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection';
      case 'user-disabled':
        return 'This account has been disabled. Please speak to Petrus.';
      default:
        return 'Could not complete that (${e.code}). Please try again.';
    }
  }

  static const _offlineMsg =
      'Online sign-in is not available right now. You can keep browsing as a guest.';
  static const _genericMsg = 'Something went wrong. Check your connection and try again.';

  /// ONE login for everyone. The role comes from the user's profile in the database
  /// (Firestore `users/{uid}.role`), so the app opens the right screen automatically.
  /// Returns an error message, or null on success.
  Future<String?> login(String email, String password) async {
    if (!firebaseReady) return _offlineMsg;
    final emailError = Validators.email(email);
    if (emailError != null) return emailError;
    if (password.isEmpty) return 'Enter your password';
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(), password: password);
      final profile = await _loadProfile(cred.user!.uid);
      if (profile == null) {
        await _auth.signOut();
        return 'This account has no profile yet. Please speak to Petrus.';
      }
      if (profile.status == AccountStatus.pending) {
        await _auth.signOut();
        return 'Your staff account is waiting for Petrus to approve it.';
      }
      if (profile.status == AccountStatus.rejected) {
        await _auth.signOut();
        return 'Your staff request was not approved. Please speak to Petrus.';
      }
      user = profile;
      _startListeners();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } on FirebaseException catch (e) {
      // Signed in fine, but the database step failed. Sign out so nobody is half logged in.
      await _auth.signOut();
      return _dbMessage(e);
    } catch (e) {
      debugPrint('Login failed: $e');
      return 'Login failed: $e';
    }
  }

  String _dbMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Signed in, but the database refused access (permission-denied). '
            'Publish firestore.rules in Firebase > Firestore > Rules.';
      case 'not-found':
      case 'failed-precondition':
        return 'The Firestore database has not been created yet (${e.code}). '
            'Create it in Firebase > Firestore Database.';
      case 'unavailable':
        return 'Cannot reach the database. Check your internet connection.';
      default:
        return 'Database error (${e.code}). Please try again.';
    }
  }

  /// Customers are signed in straight away. Staff accounts are created as `pending` and the
  /// person is signed out again until the manager approves.
  Future<({String? error, bool pendingApproval})> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool asStaff,
  }) async {
    ({String? error, bool pendingApproval}) fail(String m) => (error: m, pendingApproval: false);
    if (!firebaseReady) return fail(_offlineMsg);
    if (name.trim().isEmpty) return fail('Please enter your name');
    final emailError = Validators.email(email);
    if (emailError != null) return fail(emailError);
    final pwError = Validators.password(password);
    if (pwError != null) return fail(pwError);

    final e = email.trim().toLowerCase();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: e, password: password);
      final profile = AppUser(
        id: cred.user!.uid,
        name: name.trim(),
        email: e,
        role: asStaff ? Role.staff : Role.customer,
        phone: phone.trim(),
        status: asStaff ? AccountStatus.pending : AccountStatus.approved,
      );
      try {
        await _db.collection('users').doc(profile.id).set({
          ...profile.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        await cred.user!.delete(); // never leave a login without a profile
        return fail('Could not save your profile. Please try again.');
      }
      if (asStaff) {
        await _auth.signOut();
        return (error: null, pendingApproval: true);
      }
      user = profile;
      _startListeners();
      notifyListeners();
      return (error: null, pendingApproval: false);
    } on FirebaseAuthException catch (ex) {
      return fail(_authMessage(ex));
    } catch (_) {
      return fail(_genericMsg);
    }
  }

  // ---- password reset (Firebase sends a one-time link that expires in about 1 hour)
  final List<DateTime> _resetRequests = [];
  static const Duration resetCooldown = Duration(seconds: 60);
  static const int maxResetsPerHour = 5;

  /// Seconds the person must still wait before asking for another reset email (0 = now).
  int get resetWaitSeconds {
    if (_resetRequests.isEmpty) return 0;
    final left = resetCooldown - DateTime.now().difference(_resetRequests.last);
    return left.isNegative ? 0 : left.inSeconds + 1;
  }

  /// Emails a password-reset link. SECURITY: the answer is the same whether or not the email
  /// belongs to an account, so nobody can use this to find out who has an account.
  /// Returns an error message, or null when the request was accepted.
  Future<String?> sendPasswordReset(String email) async {
    if (!firebaseReady) return _offlineMsg;
    final emailError = Validators.email(email);
    if (emailError != null) return emailError;
    final now = DateTime.now();
    _resetRequests.removeWhere((t) => now.difference(t) > const Duration(hours: 1));
    if (resetWaitSeconds > 0) {
      return 'Please wait ${resetWaitSeconds}s before asking again.';
    }
    if (_resetRequests.length >= maxResetsPerHour) {
      return 'Too many requests. Please try again in an hour.';
    }
    _resetRequests.add(now);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found': // do not reveal that the account does not exist
        case 'invalid-credential':
          return null;
        case 'invalid-email':
          return 'Enter a valid email';
        case 'network-request-failed':
          _resetRequests.removeLast();
          return 'No internet connection';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        default:
          return 'Could not send the email (${e.code}). Please try again.';
      }
    } catch (_) {
      return _genericMsg;
    }
  }

  Future<void> logout() async {
    _stopListeners();
    user = null;
    cart.clear();
    staffAccounts = [];
    attendance = [];
    orders = [];
    stockTxns = [];
    messages = [];
    notifyListeners();
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  // ------------------------------------------------------------ live Firestore data
  void _listen(String key, Query<Map<String, dynamic>> query,
      void Function(QuerySnapshot<Map<String, dynamic>> snap) onData) {
    _subs.remove(key)?.cancel();
    _subs[key] = query.snapshots().listen((snap) {
      onData(snap);
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Listener "$key" failed: $e');
    });
  }

  List<T> _parse<T>(QuerySnapshot<Map<String, dynamic>> snap, T Function(Map<String, dynamic>) f) {
    final out = <T>[];
    for (final d in snap.docs) {
      try {
        out.add(f({...d.data(), 'id': d.id}));
      } catch (e) {
        debugPrint('Skipped bad document ${d.reference.path}: $e');
      }
    }
    return out;
  }

  void _startPublicListeners() {
    _listen('menu', _db.collection('menu'), (snap) {
      // grouped like the printed menu (category order), then A-Z
      int rank(MenuItem m) {
        final i = kCategories.indexOf(m.category);
        return i < 0 ? kCategories.length : i;
      }

      menu = _parse(snap, MenuItem.fromJson)
        ..sort((a, b) {
          final c = rank(a).compareTo(rank(b));
          return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      _menuEmptyConfirmed = snap.docs.isEmpty && !snap.metadata.isFromCache;
      if (_menuEmptyConfirmed) _maybeSeedMenu();
    });
    _listen('reviews', _db.collection('reviews'), (snap) {
      reviews = _parse(snap, Review.fromJson)..sort((a, b) => b.at.compareTo(a.at));
    });
    _listen('events', _db.collection('events'), (snap) {
      events = _parse(snap, CampusEvent.fromJson);
    });
  }

  /// The very first time the manager logs in and the menu is empty, load the starting menu.
  void _maybeSeedMenu() {
    if (_menuSeedChecked || !_isManager || !_menuEmptyConfirmed) return;
    _menuSeedChecked = true;
    final batch = _db.batch();
    for (final m in seedMenu()) {
      batch.set(_db.collection('menu').doc(m.id), m.toJson());
    }
    _fire(batch.commit());
  }

  void _startListeners() {
    _stopListeners();
    final u = user;
    if (u == null) return;
    if (u.role == Role.customer) {
      _listen('orders', _db.collection('orders').where('customerId', isEqualTo: u.id), (snap) {
        orders = _parse(snap, Order.fromJson)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
      _listen('messages', _db.collection('messages').where('customerId', isEqualTo: u.id),
          (snap) {
        messages = _parse(snap, ChatMessage.fromJson)..sort((a, b) => a.at.compareTo(b.at));
      });
      return;
    }
    // staff and manager
    _listen('orders', _db.collection('orders').orderBy('createdAt', descending: true).limit(300),
        (snap) {
      orders = _parse(snap, Order.fromJson);
    });
    _listen('stockTxns', _db.collection('stockTxns').orderBy('at', descending: true).limit(200),
        (snap) {
      stockTxns = _parse(snap, StockTxn.fromJson);
    });
    if (u.role == Role.manager) {
      _maybeSeedMenu();
      _listen('messages', _db.collection('messages'), (snap) {
        messages = _parse(snap, ChatMessage.fromJson)..sort((a, b) => a.at.compareTo(b.at));
      });
      _listen('staff', _db.collection('users').where('role', isEqualTo: 'staff'), (snap) {
        staffAccounts = snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
      _listen('attendance',
          _db.collection('attendance').orderBy('checkIn', descending: true).limit(300),
          _onAttendance);
    } else {
      _listen('attendance', _db.collection('attendance').where('staffId', isEqualTo: u.id),
          _onAttendance);
    }
  }

  /// Stops everything except the public menu / reviews / events.
  void _stopListeners() {
    for (final k in _subs.keys.where((k) => !_publicKeys.contains(k)).toList()) {
      _subs.remove(k)?.cancel();
    }
  }

  DateTime _ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

  void _onAttendance(QuerySnapshot<Map<String, dynamic>> snap) {
    attendance = snap.docs.map((d) {
      final j = d.data();
      return AttendanceRecord(
        id: d.id,
        staffId: (j['staffId'] ?? '') as String,
        staffName: (j['staffName'] ?? '') as String,
        checkIn: _ts(j['checkIn']),
        checkOut: j['checkOut'] == null ? null : _ts(j['checkOut']),
      );
    }).toList()
      ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
    notifyListeners();
  }

  // ------------------------------------------------------------ staff approval (manager only)
  bool get _isManager => user?.role == Role.manager;

  List<AppUser> get pendingStaff =>
      staffAccounts.where((u) => u.status == AccountStatus.pending).toList();

  List<AppUser> get staffUsers =>
      staffAccounts.where((u) => u.status == AccountStatus.approved).toList();

  Future<String?> approveStaff(String id) => _setStaffStatus(id, AccountStatus.approved);
  Future<String?> rejectStaff(String id) => _setStaffStatus(id, AccountStatus.rejected);

  Future<String?> _setStaffStatus(String id, AccountStatus status) async {
    if (!_isManager) return 'Only the manager can do this';
    try {
      await _db.collection('users').doc(id).update({'status': status.name});
      return null;
    } catch (_) {
      return 'Could not update the account. Check your connection.';
    }
  }

  /// Customer/staff/manager: change your own profile (name, phone, birthday, avatar).
  Future<String?> updateProfile(
      {required String name,
      required String phone,
      required String birthday,
      required bool birthdayPublic,
      required int avatar}) async {
    final u = user;
    if (u == null) return 'Please log in first';
    try {
      await _db.collection('users').doc(u.id).update({
        'name': name,
        'phone': phone,
        'birthday': birthday,
        'birthdayPublic': birthdayPublic,
        'avatar': avatar,
      });
      u
        ..name = name
        ..phone = phone
        ..birthday = birthday
        ..birthdayPublic = birthdayPublic
        ..avatar = avatar;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Could not save your profile. Check your connection and try again.';
    }
  }

  // ------------------------------------------------------------ attendance (Firestore)
  AttendanceRecord? openShiftFor(String staffId) {
    for (final r in attendance) {
      if (r.staffId == staffId && r.isOpen) return r;
    }
    return null;
  }

  Future<String?> checkIn() async {
    final u = user;
    if (u == null) return 'Please log in';
    if (openShiftFor(u.id) != null) return 'You are already checked in';
    try {
      await _db.collection('attendance').add({
        'staffId': u.id,
        'staffName': u.name,
        'checkIn': Timestamp.now(),
        'checkOut': null,
      }).timeout(const Duration(seconds: 10));
      return null;
    } on TimeoutException {
      return 'No connection. Your check-in is saved and will sync when you are back online.';
    } catch (_) {
      return 'Could not check in. Please try again.';
    }
  }

  Future<String?> checkOut() async {
    final u = user;
    if (u == null) return 'Please log in';
    final r = openShiftFor(u.id);
    if (r == null) return 'You are not checked in';
    try {
      await _db
          .collection('attendance')
          .doc(r.id)
          .update({'checkOut': Timestamp.now()}).timeout(const Duration(seconds: 10));
      return null;
    } on TimeoutException {
      return 'No connection. Your check-out is saved and will sync when you are back online.';
    } catch (_) {
      return 'Could not check out. Please try again.';
    }
  }

  List<AttendanceRecord> recordsFor(String staffId) =>
      attendance.where((r) => r.staffId == staffId).toList();

  Duration hoursThisWeek(String staffId) {
    final now = DateTime.now();
    final start =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return recordsFor(staffId)
        .where((r) => !r.checkIn.isBefore(start))
        .fold(Duration.zero, (s, r) => s + r.duration);
  }

  // ------------------------------------------------------------ menu (FR-03)
  MenuItem? itemById(String id) {
    for (final m in menu) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<MenuItem> itemsIn(String category) =>
      menu.where((m) => m.category == category).toList();

  /// Edits name, price, photo, category, availability. (Stock changes only through
  /// [recordStock] so the stock history stays correct.)
  void saveItem(MenuItem item) {
    _fire(_db.collection('menu').doc(item.id).set(item.toDoc(), SetOptions(merge: true)));
  }

  /// Adds a brand-new menu item with its opening stock.
  void createItem(MenuItem item) {
    final u = user;
    final batch = _db.batch();
    batch.set(_db.collection('menu').doc(item.id), item.toJson());
    if (item.stock > 0) {
      final t = StockTxn(
        id: _newId('t'),
        itemId: item.id,
        itemName: item.name,
        isIn: true,
        qty: item.stock,
        reason: 'Opening stock',
        byName: u?.name ?? 'Manager',
        at: DateTime.now(),
      );
      batch.set(_db.collection('stockTxns').doc(t.id), t.toJson());
    }
    _fire(batch.commit());
  }

  String newItemId() => _newId('m');

  void deleteItem(String id) {
    cart.removeWhere((l) => l.itemId == id);
    _fire(_db.collection('menu').doc(id).delete());
    notifyListeners();
  }

  void setAvailable(String id, bool value) {
    final m = itemById(id);
    if (m == null) return;
    m.available = value;
    notifyListeners();
    _fire(_db.collection('menu').doc(id).update({'available': value}));
  }

  /// Brings every item that has fewer than [kDefaultStock] (10) units up to 10 and logs it in the
  /// stock history. Returns how many items were topped up.
  int topUpToDefault() {
    final u = user;
    if (u == null || u.role == Role.customer) return 0;
    final batch = _db.batch();
    var n = 0;
    for (final m in menu) {
      if (m.stock >= kDefaultStock) continue;
      final add = kDefaultStock - m.stock;
      batch.update(_db.collection('menu').doc(m.id), {'stock': FieldValue.increment(add)});
      final t = StockTxn(
        id: _newId('t'),
        itemId: m.id,
        itemName: m.name,
        isIn: true,
        qty: add,
        reason: 'Top up to $kDefaultStock',
        byName: u.name,
        at: DateTime.now(),
      );
      batch.set(_db.collection('stockTxns').doc(t.id), t.toJson());
      m.stock = kDefaultStock;
      n++;
    }
    if (n == 0) return 0;
    notifyListeners();
    _fire(batch.commit());
    return n;
  }

  /// Manager: brings the database in line with THE MINUM'S 2026 menu.
  ///  * adds items that are missing (stock starts at 10),
  ///  * updates name, category, price and options of items that already exist, but KEEPS their stock,
  ///    sold count, photos and "listed" switch,
  ///  * removes old starter items that are no longer on the menu.
  /// Items you created yourself in the app are never touched.
  /// Returns how many items were (added, updated, removed).
  ({int added, int updated, int removed}) loadOfficialMenu() {
    if (user?.role != Role.manager) return (added: 0, updated: 0, removed: 0);
    final have = {for (final m in menu) m.id: m};
    final wanted = seedMenu();
    final wantedIds = {for (final m in wanted) m.id};
    final batch = _db.batch();
    var added = 0, updated = 0, removed = 0;
    for (final m in wanted) {
      final ref = _db.collection('menu').doc(m.id);
      if (have.containsKey(m.id)) {
        batch.set(
            ref,
            {
              'name': m.name,
              'category': m.category,
              'price': m.price,
              'description': m.description,
              'groups': m.groups.map((g) => g.toJson()).toList(),
              'sizes': FieldValue.delete(),
            },
            SetOptions(merge: true));
        updated++;
      } else {
        batch.set(ref, m.toJson());
        added++;
      }
    }
    final starter = RegExp(r'^(m\d{1,2}|[a-z]{2}\d{2})$');
    for (final id in have.keys) {
      if (starter.hasMatch(id) && !wantedIds.contains(id)) {
        batch.delete(_db.collection('menu').doc(id));
        removed++;
      }
    }
    _fire(batch.commit());
    return (added: added, updated: updated, removed: removed);
  }

  List<MenuItem> get lowStockItems =>
      menu.where((m) => m.isLow || m.stock == 0).toList();

  // ------------------------------------------------------------ cart + orders (FR-06)
  double unitPrice(CartLine l) {
    final m = itemById(l.itemId);
    if (m == null) return 0;
    return m.priceFor(l.picks);
  }

  double get cartSubtotal => cart.fold(0.0, (s, l) => s + unitPrice(l) * l.qty);

  /// Special deal: every 2 BIG Air Balang cups in the cart get 20% off (2 x RM5.00 = RM8.00).
  /// 3 big cups = one pair discounted, 4 = two pairs, and so on.
  static const double bigPairDiscount = 0.20;

  /// How many Big Air Balang cups are in the cart.
  int get bigBalangCount {
    var n = 0;
    for (final l in cart) {
      final m = itemById(l.itemId);
      if (m != null && m.category == 'Air Balang' && l.picks.contains('Big')) n += l.qty;
    }
    return n;
  }

  double get cartDiscount {
    final prices = <double>[];
    for (final l in cart) {
      final m = itemById(l.itemId);
      if (m != null && m.category == 'Air Balang' && l.picks.contains('Big')) {
        for (var i = 0; i < l.qty; i++) {
          prices.add(unitPrice(l));
        }
      }
    }
    prices.sort((a, b) => b.compareTo(a));
    final pairs = prices.length ~/ 2;
    var sum = 0.0;
    for (var i = 0; i < pairs * 2; i++) {
      sum += prices[i];
    }
    return double.parse((sum * bigPairDiscount).toStringAsFixed(2));
  }

  double get cartTotal => cartSubtotal - cartDiscount;
  int get cartCount => cart.fold(0, (s, l) => s + l.qty);

  int _inCart(String itemId, {CartLine? except}) => cart
      .where((l) => l.itemId == itemId && l != except)
      .fold(0, (s, l) => s + l.qty);

  String? addToCart(String itemId, List<String> rawPicks, int qty) {
    final m = itemById(itemId);
    if (m == null || !m.isAvailable) return 'This item is currently unavailable';
    if (_inCart(itemId) + qty > m.stock) {
      return 'Only ${m.stock} left in stock';
    }
    final picks = m.normalizePicks(rawPicks);
    final size = m.describePicks(picks);
    for (final l in cart) {
      if (l.itemId == itemId && l.size == size) {
        l.qty += qty;
        notifyListeners();
        return null;
      }
    }
    cart.add(CartLine(itemId: itemId, picks: picks, size: size, qty: qty));
    notifyListeners();
    return null;
  }

  String? changeQty(CartLine line, int delta) {
    final m = itemById(line.itemId);
    final next = line.qty + delta;
    if (next <= 0) {
      cart.remove(line);
    } else {
      if (m != null && _inCart(line.itemId, except: line) + next > m.stock) {
        return 'Only ${m.stock} left in stock';
      }
      line.qty = next;
    }
    notifyListeners();
    return null;
  }

  /// Puts the lines of a past order back in the cart (items that are sold out are skipped).
  ({int added, int skipped}) reorder(Order o) {
    var added = 0, skipped = 0;
    for (final l in o.lines) {
      final m = itemById(l.itemId);
      if (m == null || !m.isAvailable) {
        skipped++;
        continue;
      }
      final picks = [
        for (final p in l.size.split(','))
          if (p.trim().isNotEmpty) p.trim().replaceFirst(RegExp(r'^\+'), '')
      ];
      final err = addToCart(m.id, picks, l.qty);
      err == null ? added++ : skipped++;
    }
    return (added: added, skipped: skipped);
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  /// Places the order and takes the stock in ONE database transaction, so two customers can
  /// never buy the last item at the same time.
  Future<({Order? order, String? error})> placeOrder({
    required String type,
    required String payment,
    String note = '',
  }) async {
    final u = user;
    if (u == null) return (order: null, error: 'Please log in to place your order');
    if (cart.isEmpty) return (order: null, error: 'Your cart is empty');
    if (!firebaseReady) return (order: null, error: _offlineMsg);

    final need = <String, int>{};
    for (final l in cart) {
      need[l.itemId] = (need[l.itemId] ?? 0) + l.qty;
    }
    for (final e in need.entries) {
      final m = itemById(e.key);
      if (m == null || !m.isAvailable) {
        return (order: null, error: '${m?.name ?? 'An item'} is no longer available');
      }
      if (m.stock < e.value) {
        return (order: null, error: 'Only ${m.stock} left for ${m.name}');
      }
    }

    final lines = <OrderLine>[];
    for (final l in cart) {
      final m = itemById(l.itemId)!;
      lines.add(OrderLine(
        itemId: m.id,
        name: m.name,
        size: l.size,
        qty: l.qty,
        unitPrice: unitPrice(l),
      ));
    }

    final discount = cartDiscount;
    final orderRef = _db.collection('orders').doc();
    final counterRef = _db.collection('meta').doc('counters');
    final now = DateTime.now();
    try {
      final number = await _db.runTransaction<int>((tx) async {
        // all reads first
        final counter = await tx.get(counterRef);
        final fresh = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final id in need.keys) {
          fresh[id] = await tx.get(_db.collection('menu').doc(id));
        }
        for (final e in need.entries) {
          final d = fresh[e.key]!;
          final data = d.data();
          if (!d.exists || data == null || data['available'] == false) {
            throw _OrderProblem('${itemById(e.key)?.name ?? 'An item'} is no longer available');
          }
          final stock = (data['stock'] as num?)?.toInt() ?? 0;
          if (stock < e.value) {
            throw _OrderProblem(stock <= 0
                ? '${data['name']} just sold out'
                : 'Only $stock left for ${data['name']}');
          }
        }
        // then writes
        final next = ((counter.data()?['orderSeq'] as num?)?.toInt() ?? 1000) + 1;
        if (counter.exists) {
          tx.update(counterRef, {'orderSeq': next});
        } else {
          tx.set(counterRef, {'orderSeq': next});
        }
        for (final e in need.entries) {
          tx.update(_db.collection('menu').doc(e.key), {
            'stock': FieldValue.increment(-e.value),
            'sold': FieldValue.increment(e.value),
          });
          final t = StockTxn(
            id: _newId('t'),
            itemId: e.key,
            itemName: itemById(e.key)?.name ?? '',
            isIn: false,
            qty: e.value,
            reason: 'Order #$next',
            byName: 'System',
            at: now,
          );
          tx.set(_db.collection('stockTxns').doc(t.id), t.toJson());
        }
        final order = Order(
          id: orderRef.id,
          number: next,
          customerId: u.id,
          customerName: u.name,
          lines: lines,
          type: type,
          payment: payment,
          note: note.trim(),
          discount: discount,
          createdAt: now,
        );
        tx.set(orderRef, order.toJson());
        return next;
      }).timeout(const Duration(seconds: 15));

      cart.clear();
      final order = Order(
        id: orderRef.id,
        number: number,
        customerId: u.id,
        customerName: u.name,
        lines: lines,
        type: type,
        payment: payment,
        note: note.trim(),
        discount: discount,
        createdAt: now,
      );
      // show it immediately; the live listener replaces it with the stored copy
      if (orderById(order.id) == null) orders.insert(0, order);
      notifyListeners();
      return (order: order, error: null);
    } on _OrderProblem catch (e) {
      return (order: null, error: e.message);
    } on TimeoutException {
      return (order: null, error: 'No connection. Your order was not placed. Please try again.');
    } on FirebaseException catch (e) {
      debugPrint('Order failed: ${e.code} ${e.message}');
      return (order: null, error: _dbMessage(e));
    } catch (e) {
      debugPrint('Order failed: $e');
      return (order: null, error: 'Could not place the order. Please try again.');
    }
  }

  Order? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<Order> get myOrders =>
      orders.where((o) => o.customerId == user?.id).toList();

  void advanceOrder(String id) {
    final o = orderById(id);
    final next = o?.status.next;
    if (o == null || next == null) return;
    o.status = next;
    notifyListeners();
    _fire(_db.collection('orders').doc(id).update({'status': next.name}));
  }

  /// Cancels an order and returns the reserved stock (one atomic batch).
  String? cancelOrder(String id) {
    final o = orderById(id);
    if (o == null) return 'Order not found';
    if (!o.status.isActive || o.status == OrderStatus.ready && o.paid) {
      return 'This order can no longer be cancelled';
    }
    o.status = OrderStatus.cancelled;
    final batch = _db.batch();
    batch.update(_db.collection('orders').doc(id), {'status': OrderStatus.cancelled.name});
    final back = <String, int>{};
    for (final l in o.lines) {
      back[l.itemId] = (back[l.itemId] ?? 0) + l.qty;
    }
    for (final e in back.entries) {
      final m = itemById(e.key);
      if (m == null) continue; // item was deleted from the menu
      batch.update(_db.collection('menu').doc(e.key), {
        'stock': FieldValue.increment(e.value),
        'sold': FieldValue.increment(-e.value),
      });
      final t = StockTxn(
        id: _newId('t'),
        itemId: e.key,
        itemName: m.name,
        isIn: true,
        qty: e.value,
        reason: 'Cancelled order #${o.number}',
        byName: user?.name ?? 'System',
        at: DateTime.now(),
      );
      batch.set(_db.collection('stockTxns').doc(t.id), t.toJson());
    }
    notifyListeners();
    _fire(batch.commit());
    return null;
  }

  void markPaid(String id) {
    final o = orderById(id);
    if (o == null || o.paid || o.status == OrderStatus.cancelled) return;
    o.paid = true;
    o.paidAt = DateTime.now();
    notifyListeners();
    _fire(_db.collection('orders').doc(id).update({
      'paid': true,
      'paidAt': o.paidAt!.toIso8601String(),
    }));
  }

  // ------------------------------------------------------------ inventory (FR-07)
  String? recordStock(String itemId, bool isIn, int qty, String reason) {
    final u = user;
    if (u == null) return 'Please log in';
    final m = itemById(itemId);
    if (m == null) return 'Item not found';
    if (qty <= 0) return 'Enter a quantity above 0';
    if (!isIn && qty > m.stock) return 'Only ${m.stock} in stock';
    final t = StockTxn(
      id: _newId('t'),
      itemId: m.id,
      itemName: m.name,
      isIn: isIn,
      qty: qty,
      reason: reason.trim().isEmpty ? (isIn ? 'Restock' : 'Stock out') : reason.trim(),
      byName: u.name,
      at: DateTime.now(),
    );
    final batch = _db.batch();
    batch.update(_db.collection('menu').doc(m.id), {
      'stock': FieldValue.increment(isIn ? qty : -qty),
    });
    batch.set(_db.collection('stockTxns').doc(t.id), t.toJson());
    m.stock += isIn ? qty : -qty; // show it at once; the live listener confirms it
    notifyListeners();
    _fire(batch.commit());
    return null;
  }

  // ------------------------------------------------------------ manager communication (FR-05)
  List<ChatMessage> thread(String customerId) =>
      messages.where((m) => m.customerId == customerId).toList();

  /// Sends a message to the manager's inbox. [viaBot] marks questions the AI assistant
  /// could not answer. Guests must log in first.
  String? sendCustomerMessage(String text, {bool viaBot = false}) {
    final u = user;
    if (u == null) return 'Please log in to message the manager';
    if (text.trim().isEmpty) return 'Type your message first';
    final msg = ChatMessage(
      id: _newId('c'),
      customerId: u.id,
      customerName: u.name,
      text: text.trim(),
      fromManager: false,
      viaBot: viaBot,
      at: DateTime.now(),
    );
    messages.add(msg);
    notifyListeners();
    _fire(_db.collection('messages').doc(msg.id).set(msg.toJson()));
    return null;
  }

  void sendManagerReply(String customerId, String text) {
    if (text.trim().isEmpty) return;
    var name = 'Customer';
    for (final m in messages) {
      if (m.customerId == customerId && !m.fromManager) name = m.customerName;
    }
    final msg = ChatMessage(
      id: _newId('c'),
      customerId: customerId,
      customerName: name,
      text: text.trim(),
      fromManager: true,
      at: DateTime.now(),
    );
    messages.add(msg);
    notifyListeners();
    _fire(_db.collection('messages').doc(msg.id).set(msg.toJson()));
  }

  List<ThreadSummary> get threads {
    final map = <String, ChatMessage>{};
    for (final m in messages) {
      map[m.customerId] = m; // later messages overwrite earlier ones
    }
    final list = map.entries
        .map((e) => ThreadSummary(
            e.key, e.value.customerName, e.value, !e.value.fromManager))
        .toList();
    list.sort((a, b) => b.last.at.compareTo(a.last.at));
    return list;
  }

  int get threadsAwaitingReply => threads.where((t) => t.awaitingReply).length;

  // ------------------------------------------------------------ reviews + Hot Selling
  Review? reviewFor(String orderId, String itemId) {
    for (final r in reviews) {
      if (r.orderId == orderId && r.itemId == itemId) return r;
    }
    return null;
  }

  /// A customer rates one item of one of their completed orders (once per item per order).
  String? addReview({
    required String orderId,
    required String itemId,
    required int rating,
    String comment = '',
  }) {
    final u = user;
    if (u == null) return 'Please log in';
    final o = orderById(orderId);
    if (o == null || o.customerId != u.id) return 'Order not found';
    if (o.status != OrderStatus.completed) return 'You can rate an order once it is completed';
    if (rating < 1 || rating > 5) return 'Choose 1 to 5 stars';
    if (reviewFor(orderId, itemId) != null) return 'You already rated this item';
    final line = o.lines.where((l) => l.itemId == itemId).toList();
    if (line.isEmpty) return 'Item not found in this order';
    final review = Review(
      id: _newId('r'),
      orderId: orderId,
      itemId: itemId,
      itemName: line.first.name,
      userId: u.id,
      userName: u.name,
      rating: rating,
      comment: comment.trim(),
      at: DateTime.now(),
    );
    reviews.add(review);
    notifyListeners();
    _fire(_db.collection('reviews').doc(review.id).set(review.toJson()));
    return null;
  }

  /// Units ordered so far (kept on the menu item by the order transaction).
  int orderCountFor(String itemId) => itemById(itemId)?.sold ?? 0;

  ({double avg, int count}) ratingFor(String itemId) {
    var sum = 0;
    var count = 0;
    for (final r in reviews) {
      if (r.itemId == itemId) {
        sum += r.rating;
        count++;
      }
    }
    return (avg: count == 0 ? 0.0 : sum / count, count: count);
  }

  /// "Hot Selling" ranking from order counts AND reviews:
  ///   score = units ordered + (average stars - 3) x number of reviews
  /// Each order adds 1 point, a 5-star review adds 2, a 1-star review subtracts 2.
  /// Only items that can be ordered right now are listed. Ties (a brand-new install)
  /// put "Best seller" items first.
  List<HotItem> hotSelling([int n = 6]) {
    final list = <HotItem>[];
    for (final m in menu) {
      if (!m.isAvailable) continue;
      final sold = orderCountFor(m.id);
      final r = ratingFor(m.id);
      final score = sold + (r.count == 0 ? 0.0 : (r.avg - 3) * r.count);
      list.add(HotItem(m, sold, r.avg, r.count, score));
    }
    list.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      final ta = a.item.tag == 'Best seller' ? 0 : 1;
      final tb = b.item.tag == 'Best seller' ? 0 : 1;
      if (ta != tb) return ta.compareTo(tb);
      return a.item.name.compareTo(b.item.name);
    });
    return list.take(n).toList();
  }

  /// Manager: add or change a campus event (shown in "Coming up on campus").
  void saveEvent(CampusEvent e) {
    _fire(_db.collection('events').doc(e.id).set(e.toJson()));
  }

  void deleteEvent(String id) {
    _fire(_db.collection('events').doc(id).delete());
  }

  String newEventId() => _newId('e');

  List<CampusEvent> get upcomingEvents {
    final cutoff = DateTime.now().subtract(const Duration(hours: 3));
    return events.where((e) => e.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // ------------------------------------------------------------ reports
  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  double get todaySales => orders
      .where((o) => o.paid && o.paidAt != null && _isToday(o.paidAt!))
      .fold(0.0, (s, o) => s + o.total);

  double get allTimeSales =>
      orders.where((o) => o.paid).fold(0.0, (s, o) => s + o.total);

  int get todayOrderCount => orders
      .where((o) => _isToday(o.createdAt) && o.status != OrderStatus.cancelled)
      .length;

  List<Order> get activeOrders =>
      orders.where((o) => o.status.isActive).toList();

  List<MapEntry<String, int>> topSellers([int n = 5]) {
    final counts = <String, int>{};
    for (final o in orders) {
      if (o.status == OrderStatus.cancelled) continue;
      for (final l in o.lines) {
        counts[l.name] = (counts[l.name] ?? 0) + l.qty;
      }
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(n).toList();
  }

  List<AttendanceRecord> get onShiftNow =>
      attendance.where((r) => r.isOpen).toList();
}
