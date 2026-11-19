/// Google AI Studio (Gemini API) settings for the AI chatbox.
///
/// Get a free key at https://aistudio.google.com/apikey (see FIREBASE_SETUP_GUIDE.md, "Google AI Studio").
///
/// Two ways to give the app the key (use ONE):
///  A) Recommended - keep it out of your files and pass it when you run / build:
///       flutter run --dart-define=GEMINI_API_KEY=your_key_here
///       flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
///  B) Quick start - paste it below between the quotes (do NOT upload this file to GitHub).
///
/// Anything inside an app can be extracted by a determined person, so ALWAYS restrict the key to
/// your Android app in Google Cloud (guide, Part 3) and keep the project on the free tier.
const String kGeminiApiKey =
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyBbQ5K3N2YV2vK5qXK4IcGn9-eQPOYwjSg');// there is an AI limit respond per day (10)

/// Model name. If it stops working (Google retires models), choose another Flash / Flash-Lite
/// name in AI Studio and change it here, or run with --dart-define=GEMINI_MODEL=name.
const String kGeminiModel =
    String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.5-flash-lite');

/// OPTIONAL (advanced): if you restrict the key to your Android app in Google Cloud, Google only
/// accepts requests that say which app they come from. Fill in the SHA-1 of the key you build with
/// (no colons, e.g. AB12CD...) or pass --dart-define=GEMINI_ANDROID_CERT=AB12.... Leave empty if you
/// only restrict the key to the Generative Language API.
const String kGeminiAndroidPackage = 'com.example.minums_app';
const String kGeminiAndroidCertSha1 = String.fromEnvironment('GEMINI_ANDROID_CERT', defaultValue: '');
