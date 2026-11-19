/// Cloudinary settings (free plan, no credit card).
///
/// 1. Cloud name: Cloudinary dashboard (top left, or Settings -> Account / "Product environment").
/// 2. Upload preset: Settings -> Upload -> Upload presets -> Add. Signing mode MUST be "Unsigned".
///    See FIREBASE_SETUP_GUIDE.md ("Cloudinary") for every field.
///
/// These two values are NOT secrets. NEVER put the Cloudinary API Secret in the app.
/// While they still say YOUR_..., the app saves picked photos inside Firestore instead.
const String kCloudinaryCloudName = 'YOUR_CLOUD_NAME';
const String kCloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET';
