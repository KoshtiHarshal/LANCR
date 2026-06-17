// lib/features/portfolio/presentation/manage_portfolio_page.dart
//
// Owner-facing screen to add / edit / delete portfolio items.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../data/portfolio_repository.dart';
import 'portfolio_provider.dart';
import 'portfolio_widgets.dart';

class ManagePortfolioPage extends ConsumerWidget {
  const ManagePortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Portfolio'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      floatingActionButton: userId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () async {
                final changed = await showPortfolioForm(context, userId: userId);
                if (changed == true) ref.invalidate(portfolioProvider(userId));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add item'),
            ),
      body: userId == null
          ? const Center(child: Text('Not signed in'))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(portfolioProvider(userId)),
              child: ref.watch(portfolioProvider(userId)).when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (e, _) => ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text('Could not load portfolio.\n$e',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                    data: (items) {
                      if (items.isEmpty) return const _EmptyPortfolio();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ManageTile(
                          item: items[i],
                          userId: userId,
                          onChanged: () =>
                              ref.invalidate(portfolioProvider(userId)),
                        ),
                      );
                    },
                  ),
            ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  const _EmptyPortfolio();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.work_outline_rounded,
            size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No portfolio items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Showcase your best work. Tap "Add item" to upload a project with an image, description and link.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManageTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String userId;
  final VoidCallback onChanged;

  const _ManageTile({
    required this.item,
    required this.userId,
    required this.onChanged,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete item?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'This portfolio item will be permanently removed.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD94F4F)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await portfolioRepository.deleteItem(
        itemId: item['id'] as String,
        imageUrl: item['image_url'] as String?,
      );
      onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] as String?) ?? 'Untitled';
    final description = (item['description'] as String?)?.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shadow),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: PortfolioImage(url: item['image_url'] as String?),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              final changed = await showPortfolioForm(context,
                  userId: userId, existing: item);
              if (changed == true) onChanged();
            },
            icon: Icon(Icons.edit_outlined,
                size: 20, color: AppColors.primary),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Color(0xFFD94F4F)),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add / edit form (modal bottom sheet). Returns true if saved.
// ─────────────────────────────────────────────────────────────
Future<bool?> showPortfolioForm(
  BuildContext context, {
  required String userId,
  Map<String, dynamic>? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PortfolioFormSheet(userId: userId, existing: existing),
  );
}

class _PortfolioFormSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? existing;

  const _PortfolioFormSheet({required this.userId, this.existing});

  @override
  State<_PortfolioFormSheet> createState() => _PortfolioFormSheetState();
}

class _PortfolioFormSheetState extends State<_PortfolioFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _linkCtrl;

  Uint8List? _imageBytes;
  String? _imageExtension;
  String? _existingImageUrl;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?['title'] as String? ?? '');
    _descCtrl = TextEditingController(text: e?['description'] as String? ?? '');
    _linkCtrl = TextEditingController(text: e?['link_url'] as String? ?? '');
    _existingImageUrl = e?['image_url'] as String?;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageExtension = image.name.split('.').last.toLowerCase();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && (_existingImageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a cover image.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await portfolioRepository.updateItem(
          itemId: widget.existing!['id'] as String,
          userId: widget.userId,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          linkUrl: _linkCtrl.text,
          newImageBytes: _imageBytes,
          imageExtension: _imageExtension,
          existingImageUrl: _existingImageUrl,
        );
      } else {
        await portfolioRepository.addItem(
          userId: widget.userId,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          linkUrl: _linkCtrl.text,
          imageBytes: _imageBytes,
          imageExtension: _imageExtension,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Edit portfolio item' : 'Add portfolio item',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : PortfolioImage(url: _existingImageUrl),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _saving ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. E-commerce app UI',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _linkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Add to portfolio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
