import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SuperbaseAuth {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Registers a new user with image upload.
  /// Returns a map with 'success': bool and 'message': String
  static Future<Map<String, dynamic>> registerUser({
    required UserModel user,
    required File? imageFile,
    required String password,
  }) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        final String fileExt = imageFile.path.split('.').last;
        final String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final String storagePath = 'profile_images/$fileName';

        // Upload image to Supabase Storage
        final String uploadedPath = await _client.storage
            .from('profileimages')
            .upload(storagePath, imageFile,
                fileOptions: const FileOptions(upsert: false));

        // Get public URL
        final String publicUrl =
            _client.storage.from('profileimages').getPublicUrl(uploadedPath);
        imageUrl = publicUrl;
      }

      // Prepare user data for insertion
      final userData = user.copyWith(profileImage: imageUrl).toMap();
      // Remove id if null
      if (userData['id'] == null) userData.remove('id');

      // Insert user data into 'user' table
      final response = await _client.from('user').insert(userData);
      if (response.error != null) {
        return {
          'success': false,
          'message': 'User registration failed: ${response.error!.message}'
        };
      }
      return {'success': true, 'message': 'User registered successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
