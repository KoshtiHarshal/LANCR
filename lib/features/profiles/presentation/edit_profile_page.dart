// lib/features/profiles/presentation/edit_profile_page.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../main.dart';
import '../data/profile_repository.dart';
import 'profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _headlineCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _skillsCtrl;
  late TextEditingController _yearsCtrl;
  late TextEditingController _portfolioCtrl;
  late TextEditingController _linkedinCtrl;

  bool _saving = false;
  bool _isFreelancer = true;
  bool _loadingProfile = true;
  Uint8List? _avatarBytes;
  String? _avatarExtension;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _headlineCtrl = TextEditingController();
    _companyCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _skillsCtrl = TextEditingController();
    _yearsCtrl = TextEditingController();
    _portfolioCtrl = TextEditingController();
    _linkedinCtrl = TextEditingController();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    try {
      final data = await profileRepository.fetchProfile(user.id);

      if (!mounted) return;
      setState(() {
        _isFreelancer = (data['role'] ?? 'freelancer') == 'freelancer';
        _nameCtrl.text = data['name'] ?? '';
        _headlineCtrl.text = data['headline'] ?? '';
        _companyCtrl.text = data['company'] ?? '';
        _locationCtrl.text = data['location'] ?? '';
        _bioCtrl.text = data['bio'] ?? '';
        _skillsCtrl.text = (data['skills'] as List? ?? []).join(', ');
        _yearsCtrl.text = data['experience_years']?.toString() ?? '';
        _portfolioCtrl.text = data['portfolio_url'] ?? '';
        _linkedinCtrl.text = data['linkedin_url'] ?? '';
        _avatarUrl = data['avatar_url'] as String?;
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _chooseAvatar(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final extension = image.name.split('.').last.toLowerCase();
    if (!mounted) return;
    setState(() {
      _avatarBytes = bytes;
      _avatarExtension = extension;
    });
  }

  Future<void> _showAvatarOptions() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose profile photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PhotoOption(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _chooseAvatar(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _chooseAvatar(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    _yearsCtrl.dispose();
    _portfolioCtrl.dispose();
    _linkedinCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      String? avatarUrl = _avatarUrl;
      if (_avatarBytes != null) {
        avatarUrl = await profileRepository.uploadAvatar(
          userId: user.id,
          bytes: _avatarBytes!,
          extension: _avatarExtension ?? 'jpg',
        );
      }

      await profileRepository.updateProfile(userId: user.id, values: {
        'name': _nameCtrl.text.trim(),
        'headline': _headlineCtrl.text.trim(),
        'company': _isFreelancer ? null : _companyCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'skills': _isFreelancer ? skills : [],
        'experience_years': _isFreelancer && _yearsCtrl.text.isNotEmpty
            ? int.tryParse(_yearsCtrl.text)
            : null,
        'portfolio_url': _portfolioCtrl.text.trim(),
        'linkedin_url': _linkedinCtrl.text.trim(),
        'avatar_url': avatarUrl,
        'profile_completed': true,
      });

      if (!mounted) return;
      ref.invalidate(profileProvider);
      ref.invalidate(publicProfileProvider(user.id));
      ref.invalidate(freelancerStatsProvider(user.id));
      ref.invalidate(clientStatsProvider(user.id));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).value?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit profile'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: _loadingProfile
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showAvatarOptions,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                              image: _avatarBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_avatarBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : _avatarUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_avatarUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: _avatarBytes == null && _avatarUrl == null
                                ? Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 46,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _showAvatarOptions,
                      child: const Text('Change profile photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _headlineCtrl,
                decoration: const InputDecoration(
                  labelText: 'Headline',
                  hintText: 'e.g. Flutter & MERN Stack Developer',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter a headline' : null,
              ),
              const SizedBox(height: 16),
              if (!_isFreelancer) ...[
                TextFormField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'City, Country',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              if (_isFreelancer) ...[
                TextFormField(
                  controller: _skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Skills',
                    hintText: 'Flutter, Node.js, MongoDB',
                    prefixIcon: Icon(Icons.code_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.bar_chart_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portfolioCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: _isFreelancer ? 'Portfolio URL' : 'Company website',
                  hintText: _isFreelancer ? null : 'https://yourcompany.com',
                  prefixIcon: Icon(
                    _isFreelancer ? Icons.link_outlined : Icons.language_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkedinCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn URL',
                  prefixIcon: Icon(Icons.person_pin_outlined),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _saving
                    ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
                    : ElevatedButton(
                  onPressed: userId == null ? null : _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
