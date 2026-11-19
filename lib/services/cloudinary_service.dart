import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

/// Uploads menu photos to Cloudinary with an UNSIGNED upload preset (no secret in the app).
class CloudinaryService {
  static bool get isConfigured =>
      kCloudinaryCloudName.isNotEmpty &&
      kCloudinaryUploadPreset.isNotEmpty &&
      !kCloudinaryCloudName.startsWith('YOUR_') &&
      !kCloudinaryUploadPreset.startsWith('YOUR_');

  /// Uploads [bytes] (a JPG/PNG/WebP photo) and returns its https link.
  /// Throws a [String] message that is safe to show to the user.
  static Future<String> uploadImage(Uint8List bytes, {String filename = 'menu.jpg'}) =>
      _upload('image', bytes, filename, 45);

  /// Uploads a short video (event banners) and returns its https link.
  static Future<String> uploadVideo(Uint8List bytes, {String filename = 'event.mp4'}) =>
      _upload('video', bytes, filename, 180);

  static Future<String> _upload(
      String kind, Uint8List bytes, String filename, int timeoutSeconds) async {
    final uri = Uri.https('api.cloudinary.com', '/v1_1/$kCloudinaryCloudName/$kind/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = kCloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    try {
      final streamed = await req.send().timeout(Duration(seconds: timeoutSeconds));
      final res = await http.Response.fromStream(streamed);
      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      if (res.statusCode == 200 && body['secure_url'] is String) {
        return body['secure_url'] as String;
      }
      final msg = (body['error'] is Map ? body['error']['message'] : null) as String?;
      throw 'Cloudinary refused the upload${msg == null ? '' : ': $msg'}';
    } on TimeoutException {
      throw 'The upload took too long. Check your internet and try again.';
    } on String {
      rethrow;
    } catch (_) {
      throw 'Could not reach Cloudinary. Check your internet and try again.';
    }
  }

  /// Wide banner copy of an event photo.
  static String banner(String url) {
    const marker = '/image/upload/';
    if (!url.contains('res.cloudinary.com') || !url.contains(marker)) return url;
    if (url.contains('/upload/f_auto')) return url;
    return url.replaceFirst(marker, '${marker}f_auto,q_auto,c_fill,w_900,h_500/');
  }

  /// Phone-friendly mp4 copy of an event video (works on both Android and iPhone).
  static String videoMp4(String url) {
    const marker = '/video/upload/';
    if (!url.contains('res.cloudinary.com') || !url.contains(marker)) return url;
    if (url.contains('/upload/f_mp4')) return url;
    final out = url.replaceFirst(marker, '${marker}f_mp4,vc_h264,q_auto,w_720/');
    return out.replaceFirst(RegExp(r'\.[A-Za-z0-9]+$'), '.mp4');
  }

  /// Makes Cloudinary deliver a small, optimised copy (right size, best format) instead of the
  /// full photo. Links that are not from Cloudinary are returned unchanged.
  static String optimized(String url, {int size = 600}) {
    const marker = '/image/upload/';
    if (!url.contains('res.cloudinary.com') || !url.contains(marker)) return url;
    if (url.contains('/upload/f_auto')) return url;
    return url.replaceFirst(marker, '$marker' 'f_auto,q_auto,c_fill,w_$size,h_$size/');
  }
}
