# Firebase setup guide (free Spark plan) - THE MINUM'S

Your Firebase project `the-minum-s` already exists and is linked to the app
(`firebase_options.dart`, `google-services.json`). You still need to switch on three things.

## IMPORTANT: what is free in 2026
| Product | Free on Spark (no card)? | Used for |
|---|---|---|
| Authentication (email + password) | Yes | Login, sign-up, password security |
| Cloud Firestore (database) | Yes (daily free quota) | User profiles + roles, check-in / check-out |
| Google AI Studio (Gemini API key) | Yes (free tier, separate from Firebase) | The AI chatbox |
| **Cloud Storage for Firebase** | **No - needs the Blaze plan (card)** since 3 Feb 2026 | Photo uploads |

**So the app does NOT use Firebase Storage.** Menu photos are bundled in the app
(`assets/menu/m1.jpg ... m15.jpg`), or the manager pastes a web link in "Photo link".
Also: the Gemini *free* tier only works while the project stays on **Spark**. If you ever
upgrade to Blaze, AI becomes pay-as-you-go. Stay on Spark.

---
## Step 1 - Authentication
1. Firebase console -> your project -> **Build -> Authentication -> Get started**.
2. **Sign-in method** tab -> **Email/Password** -> Enable -> Save.
3. (Password rules) **Settings -> Password policy**: minimum length 8, require a symbol and a number (matches the app).

## Step 2 - Firestore database
1. **Build -> Firestore Database -> Create database**.
2. Edition: Standard. Location: pick the closest (e.g. `asia-southeast1` Singapore). Start in **production mode**.
3. **Rules** tab: paste the whole file `firestore.rules` from this project -> **Publish**.
4. If the app logs a message about a missing index, open the link in the message and press Create index.

## Step 3 - Create the manager account (Petrus)
Nobody can register as manager in the app, so do this by hand:
1. **Authentication -> Users -> Add user**: email `petrus@minums.com`, a strong password. Copy the **User UID**.
2. **Firestore -> Start collection** `users` -> Document ID = that **UID** (paste it) -> fields (all string):
   - `name` = Petrus Anak Jinai
   - `email` = petrus@minums.com
   - `role` = manager
   - `status` = approved
   - `phone` = (anything)
3. Staff (Emma, Raimi): they open the app -> Log in page -> **Create an account** -> switch on
   "I work at THE MINUM'S" -> Send request. Petrus approves them under **Staff** in his app.
   (Or create them like the manager with `role` = staff, `status` = approved.)

## Step 4 - AI chatbox (Google AI Studio)
The chatbox uses the Gemini API with a key from Google AI Studio. Follow the section
**"Google AI Studio - step by step"** at the end of this guide. Firebase AI Logic and App Check are no longer used.

## Step 5 - Run it
```bash
cd minums_app
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key_here   # Android phone/emulator (Android 10+)
```
Check: guest browsing works -> sign up as a customer (password rules) -> log in as Petrus -> he lands on the manager screens.
Staff: Check in turns green, Check out is red; Petrus sees the record live in **Staff**.
`flutter test` runs the logic tests (no Firebase needed).

## Menu, stock, orders - now all online (v1.2)
Everything is stored in Firestore, so every phone sees the same menu, stock and orders:
`menu`, `orders`, `stockTxns`, `reviews`, `messages`, `events`, `attendance`, `users`, `meta/counters`.
- **First login as Petrus**: if the `menu` collection is empty the app loads the starting menu (15 items,
  stock 10 or more) into Firestore automatically. After that, Petrus edits everything in the app.
- **Restock / stock out**: Staff -> Inventory. The new number appears on every phone straight away and a line is
  added to Stock history.
- **Orders** take stock in one database transaction, so two customers cannot buy the last item at once.
  Cancelling an order puts the stock back.
- **Campus events**: Petrus -> Account -> Campus events -> Add event (shown on the customer home page until finished).
- **Every time `firestore.rules` changes you must paste it again in Firestore -> Rules -> Publish.**
- Free-plan note: Firestore Spark allows about 50,000 reads and 20,000 writes per day, plenty for one kiosk.
- Known limit: to work without paid Cloud Functions, a signed-in customer is allowed to change only the
  `stock` / `sold` counters of a menu item (up to +20 per change, never below 0). If you ever open the app to
  the public, move the order logic to Cloud Functions (needs the Blaze plan).

## Forgot password (v1.3)
"Forgot password?" on the login page emails a reset link through Firebase Authentication (works on the free plan).
Security built in:
- The link is created and checked by Firebase: one-time, expires in about 1 hour. The app never sees the new password.
- The app always shows the same message, whether or not the email has an account (no account guessing).
- Limits: 60 seconds between requests and 5 per hour per device.
Do these once in the Firebase console:
1. **Authentication -> Settings -> User actions**: switch **Email enumeration protection** ON.
2. **Authentication -> Settings -> Password policy**: set minimum length 8 and require a special character and a number,
   so the same rules apply on the reset page as in the app. Click Save.
3. **Authentication -> Templates -> Password reset**: you can rename the sender and edit the wording.
4. Petrus's email must be a real inbox you can open (petrus@minums.com must receive mail), otherwise he can only reset
   the password from **Authentication -> Users -> (menu) -> Reset password** in the console.

## Menu photos and stock monitoring (v1.5)
### A. Add or change a photo (no Firebase Storage needed)
Firebase Storage is paid since Feb 2026, so the photo is shrunk to about 560 px and saved as text inside the
menu item in Firestore (free plan).
1. Log in as Petrus -> **Menu** tab -> tap an item (or **Add item**).
2. At the top tap **Gallery** (pick a photo) or **Camera** (take one). The preview updates at once.
3. Tap **Save changes**. Every phone shows the new photo within seconds.
4. To remove it, tap the red bin next to Camera. Then the link, `assets/menu/<id>.jpg`, or a coloured icon is used.
Tips: use your own square photos; very large photos are refused (try another one). Keep to about 30 items,
because every customer's phone downloads the photos with the menu.
(Other ways, if you prefer: paste a photo link, or put `m1.jpg ... m15.jpg` in `assets/menu/` and rebuild.)

### B. Default stock = 10 and the "Low stock" label
- New items and the starting menu begin at **10** (`kDefaultStock` in `lib/seed.dart`).
- At **5 or fewer** an item is labelled **Low stock** (amber); at **0** it is **Out of stock** (red);
  otherwise the number is green. The low limit is `lowStockAt = 5` in `lib/models.dart`.
- Customers see "Only N left" on low items and "Sold out" at zero.

### C. Monitor stock (staff and Petrus)
1. **Inventory** tab: the red banner counts low/out items. Use the chips **Low stock (n)** and **Out of stock (n)**
   to see just those, plus the category chips and search.
2. Tap an item -> choose +10 / +20 / +50 (or type a number) -> Confirm. It saves to Firestore and to **Stock history**
   (clock icon) with who did it and when.
3. Items you already had in Firestore keep their old numbers. To bring everything up to 10 in one go,
   tap the box icon at the top right of Inventory -> **Top up**. Items below 10 are raised to 10 and logged.
4. Petrus's **Dashboard** also lists the low-stock items.
5. In the Firebase console you can watch it live: **Firestore -> Data -> menu -> (item)** shows `stock` and `sold`;
   **stockTxns** is the history.
No new rules are needed: publish the `firestore.rules` from v1.3 if you have not yet.

## Cloudinary photos (v1.6) - step by step
Cloudinary's free plan needs no credit card (about 25 credits a month: 1 credit = 1 GB storage or downloads).
The app uploads with an **unsigned upload preset**, so no secret is stored in the app.

### 1. Create the account
1. Go to cloudinary.com -> **Sign up for free** (email or Google). Choose "Developer" / any answer, then continue.
2. Open the **Dashboard**. Copy your **Cloud name** (a short word like `dxyz12abc`).
   Do NOT copy or share the API Secret.

### 2. Create the upload preset
1. Click the gear icon (**Settings**) -> **Upload** tab -> scroll to **Upload presets** -> **Add upload preset**.
2. **Preset name**: `minums_menu`
3. **Signing mode**: **Unsigned**  (very important)
4. **Asset folder** (or Folder): `minums/menu`
5. **Allowed formats**: `jpg,png,webp`
6. **Incoming transformation** (in Transform / Upload manipulations): Edit -> Crop `limit`, Width `1000`, Height `1000`.
   This stops huge files from using up your free space.
7. **Save**.

### 3. Put the two values in the app
Open `lib/config/cloudinary_config.dart` and replace:
```dart
const String kCloudinaryCloudName = 'dxyz12abc';      // your cloud name
const String kCloudinaryUploadPreset = 'minums_menu'; // the preset name
```
Then run `flutter pub get` and `flutter run` (the app now needs the `http` package).

### 4. Use it
Petrus -> Menu -> tap an item -> **Gallery** or **Camera** -> wait for "Photo uploaded" -> **Save changes**.
The link is saved in the item (`image` field in Firestore) and every phone loads a small optimised copy.
You can also upload in the Cloudinary website (Media Library) and paste the link into "Or a photo link".

### Good to know
- Until you edit the config file, the app keeps saving photos inside Firestore (V1.5 behaviour).
- Removing a photo in the app does not delete it from Cloudinary; delete old ones in the Media Library.
- Someone could in theory upload to your preset if they dig the name out of the app. The format and size limits above
  and the free plan's fixed quota keep this harmless (no card, so no surprise bill). You can switch the preset
  to Disabled at any time.
- Videos: Cloudinary free allows videos up to 100 MB, but the app has no video player yet.

## Google AI Studio - step by step (v1.7)
The AI chatbox now talks straight to Google's Gemini API using a free **AI Studio** key. No Firebase AI Logic and no App Check.
Without a key the chatbox still works with the offline menu matcher, so nothing breaks while you set this up.

### Part 1 - Create the key (free, no card)
1. Open **aistudio.google.com/apikey** and sign in with your Google account.
2. Click **Create API key**. If asked, choose **Create API key in new project** (a Google Cloud project is made for you).
3. Copy the key (it starts with `AIza...`). Keep it private, like a password.
4. Do NOT add billing to that project. The free tier needs no card; adding billing turns on paid use.
Free tier limits (per project, checked in 2026): about 10 requests per minute and 500 per day for Gemini 3.5 Flash-Lite.
All customers share this, so if it runs out the chatbox quietly uses the offline menu answers until the next day.
Note: on the free tier Google may use prompts and answers to improve its products, so tell customers not to type
personal details in the chatbox.

### Part 2 - Give the key to the app (choose ONE way)
**A. Recommended - pass it when you run (nothing saved in your files):**
```bash
flutter run --dart-define=GEMINI_API_KEY=AIza...your_key
flutter build apk --dart-define=GEMINI_API_KEY=AIza...your_key
```
In VS Code: create `.vscode/launch.json` with
```json
{ "version": "0.2.0", "configurations": [ { "name": "Minums", "request": "launch", "type": "dart",
  "toolArgs": ["--dart-define=GEMINI_API_KEY=AIza...your_key"] } ] }
```
In Android Studio: **Run -> Edit Configurations -> Additional run args** -> `--dart-define=GEMINI_API_KEY=AIza...your_key`.

**B. Quick start - paste it in the file:** open `lib/config/gemini_config.dart` and replace `PASTE_YOUR_AI_STUDIO_KEY_HERE`
with your key. Never upload that file to GitHub or send it to anyone.

Then run the app and open the **Assistant** tab. Ask "recommend something sweet" and also a general question like
"what is 15% of 80?". If you see normal answers, it works. If you only get menu-style answers, see Troubleshooting.

### Part 3 - Protect the key (do this before you publish the app)
A key inside an app can be pulled out by someone determined, so lock it down:
1. Go to **console.cloud.google.com** -> pick the project AI Studio created (top bar).
2. **APIs & Services -> Credentials** -> click your API key.
3. **API restrictions -> Restrict key -> tick "Generative Language API"** -> **Save**. Now the key cannot be used for anything else.
4. (Advanced, optional) **Application restrictions -> Android apps -> Add** the package name `com.example.minums_app` and the SHA-1
   of your signing key (`cd android && ./gradlew signingReport`). Then give the app the same SHA-1 without colons:
   `--dart-define=GEMINI_ANDROID_CERT=AB12CD...`. Debug and release builds have different SHA-1s, so add both
   in the console and pass the one you build with. Skip this if it feels complicated; step 3 plus the free-tier cap is a safe minimum.
5. Never turn on billing for this project. The free daily limit then also caps any misuse.
6. If the key ever leaks: Credentials -> the key -> **Regenerate/Delete**, create a new one and update the app.
(Want the key completely hidden from the app? That needs a small server such as Firebase Cloud Functions, which needs the paid Blaze plan.
The earlier Firebase AI Logic version was the free way to hide it; tell me if you want to switch back.)

### Part 4 - Choose or change the model
Default is `gemini-3.5-flash-lite` (fast and cheap, best for the free tier). Change it in `lib/config/gemini_config.dart`
or with `--dart-define=GEMINI_MODEL=model_name`. In AI Studio, the model list shows the current names.
Google retires old models over time; if the chatbox stops using AI, check the model name first.

### Troubleshooting (run with `flutter run` and watch the console)
| Console says | Meaning | Fix |
|---|---|---|
| nothing, answers look like a menu list | no key found | Redo Part 2, restart the app fully |
| `Gemini API 400` | wrong key or model name | Re-copy the key; check the model name |
| `Gemini API 403` | key restricted or API blocked | Part 3: allow "Generative Language API"; if Android-restricted, check package and SHA-1 |
| `Gemini API 429` | free limit reached (per minute or per day) | Wait; the offline answers are used meanwhile |
| `Gemini request failed: ... SocketException` | no internet | Check the phone's connection |

## Menu categories and customisation (v1.8)
The menu follows THE MINUM'S 2026 menu: Beverages, Soft Drinks, Frappe, Matcha, Cocoa, Taro, Latte, Red Velvet, Sprite,
Thai Tea, Air Balang, Other Drinks, Dip & Drizzle, Seoul Bites, Additional (126 items). Customisation rules:

| Category | Options |
|---|---|
| Beverages | Regular / Large (+RM2.00) and Hot (free) / Cold (+RM0.50) |
| Frappe | Regular / Large (+RM1.00) and add-on Milk Foam (+RM2.00) |
| Matcha, Cocoa, Taro, Latte, Red Velvet, Sprite, Thai Tea | Regular / Large (+RM2.00) |
| Air Balang | Small RM2.50 / Medium RM3.00 / Big RM5.00. **2 Big cups = 20% off** (every pair) |
| Seoul Bites | Add-ons: Mee, Telur Mata, Sosej, Fishball, Fishcake (RM1.50 each), Cili Api (RM0.50) |
| Additional | Ice Cup: Regular RM0.50 / Large RM0.70 |
| Soft Drinks, Other Drinks, Dip & Drizzle | No options |

- **Update an existing database:** log in as Petrus -> **Menu & stock** -> list-add icon -> **Load menu**. It adds new items, updates
  names, prices and options of existing ones, and removes old starter items. Stock, sold counts, photos and availability are kept.
- **Change options in the app:** Menu & stock -> tap the item -> **Customisation**. One line per group:
  - `Size*: Regular=0, Large=2` - `*` means the customer must pick one; numbers are extra charges.
  - `Add-ons: Milk Foam=2` - no `*` means optional, any number can be ticked.
  - `Size*@: Small=2.50, Big=5` - `@` means the numbers are the full price, not extra.
- **Assumptions to check:** Mee add-on price (RM1.50) is a placeholder because the menu prints none; Fishball and Fishcake are
  two separate add-ons; Beverage Large +RM2.00 and Frappe Large +RM1.00 follow the printed prices; where the two printed pages
  disagree (Taro, Red Velvet) the first spread was used.

## What's new in v1.9 (events banner, reorder, account)
- **Republish the Firestore rules** (Firestore -> Rules -> paste `firestore.rules` -> Publish). Customers may now edit their own
  name, phone, birthday and avatar, so *Edit Profile* works.
- **Run `flutter pub get`** - the app now uses `video_player` for event video banners.
- **Customisation editor:** in Menu & stock -> item, tap the chips **Size**, **Hot / Cold**, **Add-ons** or **Own prices**, then
  change the names and prices. No special symbols are needed any more.
- **Event banners:** Account -> Campus events -> Add event -> **Banner photo** or **Banner video** (max 30 seconds). Needs
  Cloudinary (the same unsigned preset works for photos and videos). The Home page slides through upcoming events automatically.
- **Reorder:** Home -> *Your last order* -> Reorder puts the same items and options back in the cart (sold-out items are skipped).
- **Account:** Edit Profile, Orders, Help Centre, Feedback (goes to the manager inbox), Settings (password reset email),
  Terms & Conditions and Privacy Notice (sample text - please review with the shop owner).
