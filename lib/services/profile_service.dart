import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Picks an avatar, uploads it to the `avatars` bucket and saves the public
  /// URL in `profiles.avatar_url`. Returns the URL, or null if cancelled/failed.
  Future<String?> uploadProfilePicture(String userId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return null;

      // Bytes work on web (no file paths) and on native.
      final Uint8List imageBytes = await image.readAsBytes();
      final fileExt = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      final contentType = 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}';

      // Unique name avoids stale browser/CDN caching after an update.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp.$fileExt';

      await _client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);

      await _client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile picture: $e');
      return null;
    }
  }
}
