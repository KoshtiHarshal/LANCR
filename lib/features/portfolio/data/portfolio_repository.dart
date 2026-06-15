// lib/features/portfolio/data/portfolio_repository.dart
// All portfolio-related Supabase calls (table + storage).

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart';

class PortfolioRepository {
  /// All portfolio items for a freelancer, newest first.
  Future<List<Map<String, dynamic>>> fetchPortfolio(String userId) async {
    final rows = await supabase
        .from('portfolio_items')
        .select('id, title, description, image_url, link_url, created_at')
        .eq('freelancer_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Uploads a cover image to portfolio/{userId}/{timestamp}.ext and returns
  /// its public URL.
  Future<String> _uploadImage({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final ext = extension.toLowerCase() == 'png' ? 'png' : 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await supabase.storage.from('portfolio').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

    final url = supabase.storage.from('portfolio').getPublicUrl(path);
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> addItem({
    required String userId,
    required String title,
    String? description,
    String? linkUrl,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    String? imageUrl;
    if (imageBytes != null) {
      imageUrl = await _uploadImage(
        userId: userId,
        bytes: imageBytes,
        extension: imageExtension ?? 'jpg',
      );
    }

    final desc = description?.trim();
    final link = linkUrl?.trim();
    await supabase.from('portfolio_items').insert({
      'freelancer_id': userId,
      'title': title.trim(),
      if (desc != null && desc.isNotEmpty) 'description': desc,
      if (link != null && link.isNotEmpty) 'link_url': link,
      'image_url': ?imageUrl,
    });
  }

  Future<void> updateItem({
    required String itemId,
    required String userId,
    required String title,
    String? description,
    String? linkUrl,
    Uint8List? newImageBytes,
    String? imageExtension,
    String? existingImageUrl,
  }) async {
    String? imageUrl = existingImageUrl;
    if (newImageBytes != null) {
      imageUrl = await _uploadImage(
        userId: userId,
        bytes: newImageBytes,
        extension: imageExtension ?? 'jpg',
      );
    }

    final desc = description?.trim();
    final link = linkUrl?.trim();
    await supabase.from('portfolio_items').update({
      'title': title.trim(),
      'description': (desc != null && desc.isNotEmpty) ? desc : null,
      'link_url': (link != null && link.isNotEmpty) ? link : null,
      'image_url': imageUrl,
    }).eq('id', itemId);
  }

  /// Deletes the row and best-effort removes its storage object.
  Future<void> deleteItem({required String itemId, String? imageUrl}) async {
    await supabase.from('portfolio_items').delete().eq('id', itemId);

    if (imageUrl != null && imageUrl.contains('/portfolio/')) {
      final path = imageUrl.split('/portfolio/').last.split('?').first;
      try {
        await supabase.storage.from('portfolio').remove([path]);
      } catch (_) {
        // Object cleanup is best-effort; the row is already gone.
      }
    }
  }
}

final portfolioRepository = PortfolioRepository();
