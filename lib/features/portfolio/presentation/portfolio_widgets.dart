// lib/features/portfolio/presentation/portfolio_widgets.dart
//
// Read-only portfolio UI used on profile pages:
//  - PortfolioGallery     : horizontal scroller of portfolio cards
//  - showPortfolioDetail()  : bottom sheet with the full item

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_launcher_util.dart';
import 'portfolio_provider.dart';

class PortfolioGallery extends ConsumerWidget {
  final String userId;

  /// When false, renders nothing while empty (used where an outer widget
  /// already provides an empty state / CTA).
  final bool showEmptyHint;

  const PortfolioGallery({
    super.key,
    required this.userId,
    this.showEmptyHint = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(portfolioProvider(userId));

    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, _) => const Text(
        'Could not load portfolio.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      data: (items) {
        if (items.isEmpty) {
          return showEmptyHint
              ? const Text(
                  'No portfolio items yet.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : const SizedBox.shrink();
        }
        return SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => PortfolioCard(
              item: items[i],
              onTap: () => showPortfolioDetail(context, items[i]),
            ),
          ),
        );
      },
    );
  }
}

class PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const PortfolioCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] as String?) ?? 'Untitled';
    final imageUrl = item['image_url'] as String?;
    final hasLink = (item['link_url'] as String?)?.trim().isNotEmpty ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.shadow),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: PortfolioImage(url: imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        hasLink ? Icons.link_rounded : Icons.image_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasLink ? 'Has link' : 'Project',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Network image with graceful loading + fallback for portfolio covers.
class PortfolioImage extends StatelessWidget {
  final String? url;
  const PortfolioImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.image_outlined,
            color: AppColors.primary, size: 30),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.primaryLight,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.broken_image_outlined,
            color: AppColors.primary, size: 28),
      ),
    );
  }
}

/// Bottom sheet showing the full portfolio item.
Future<void> showPortfolioDetail(
  BuildContext context,
  Map<String, dynamic> item,
) {
  final title = (item['title'] as String?) ?? 'Untitled';
  final description = (item['description'] as String?)?.trim();
  final link = (item['link_url'] as String?)?.trim();
  final imageUrl = item['image_url'] as String?;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: PortfolioImage(url: imageUrl),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
              if (link != null && link.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () async {
                      final ok = await openExternalLink(link);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open link')),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Visit link'),
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  link,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
