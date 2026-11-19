# THE MINUM'S Management System (v1.2)

Flutter app: ordering, inventory, attendance, AI assistant. Black, grey and white theme, Firebase backend.

1. Read **FIREBASE_SETUP_GUIDE.md** (Auth, Firestore, Cloudinary photos, Google AI Studio key - all free).
2. `flutter pub get` then `flutter run` (Android 10+).
3. Put menu photos in `assets/menu/` (see the README.txt there).

Roles: guest (browse only) / customer / staff (needs Petrus's approval) / manager (created by hand in Firebase).
One login page; the role is read from the database.
