import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart';

class ProfileRepository {
  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final data =
        await supabase.from('profiles').select().eq('id', userId).single();
    return Map<String, dynamic>.from(data);
  }

  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> values,
  }) async {
    await supabase.from('profiles').update(values).eq('id', userId);
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final normalizedExtension = extension.toLowerCase() == 'png' ? 'png' : 'jpg';
    final path = '$userId/avatar.$normalizedExtension';

    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: normalizedExtension == 'png'
                ? 'image/png'
                : 'image/jpeg',
          ),
        );

    final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}

final profileRepository = ProfileRepository();
