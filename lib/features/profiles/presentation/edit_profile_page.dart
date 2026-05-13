// lib/features/profiles/presentation/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

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
  // _existingProfile removed — data is written directly to controllers

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
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

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
      });
    } catch (_) {
      // Profile doesn't exist yet — use empty controllers
    }
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

      await supabase.from('profiles').update({
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
        'profile_completed': true,
      }).eq('id', user.id);

      if (!mounted) return;
      context.go('/home');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                decoration: const InputDecoration(
                  labelText: 'Portfolio URL',
                  prefixIcon: Icon(Icons.link_outlined),
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
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
                    : ElevatedButton(
                  onPressed: _saveProfile,
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