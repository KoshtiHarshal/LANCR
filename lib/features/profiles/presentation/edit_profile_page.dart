import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_providers.dart';
import '../../auth/presentation/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    final p = user?.profile;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _headlineCtrl = TextEditingController(text: p?.headline ?? '');
    _companyCtrl = TextEditingController(text: p?.company ?? '');
    _locationCtrl = TextEditingController(text: p?.location ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _skillsCtrl = TextEditingController(
      text: (p?.skills ?? []).join(', '),
    );
    _yearsCtrl = TextEditingController(
      text: p?.experienceYears?.toString() ?? '',
    );
    _portfolioCtrl = TextEditingController(text: p?.portfolioUrl ?? '');
    _linkedinCtrl = TextEditingController(text: p?.linkedinUrl ?? '');
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
      final user = ref.read(authProvider).value!;
      final isFreelancer = user.role == 'freelancer';

      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final profile = {
        'name': _nameCtrl.text.trim(),
        'headline': _headlineCtrl.text.trim(),
        'company': isFreelancer ? null : _companyCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'skills': isFreelancer ? skills : [],
        'experienceYears':
        isFreelancer && _yearsCtrl.text.isNotEmpty ? int.parse(_yearsCtrl.text) : null,
        'portfolioUrl': _portfolioCtrl.text.trim(),
        'linkedinUrl': _linkedinCtrl.text.trim(),
      };

      final api = ref.read(apiServiceProvider);
      final res = await api.put('/users/me/profile', data: {
        'profile': profile,
        'profileCompleted': true,
      });

      final updatedUser = User.fromJson(res.data['user']);
      ref.read(authProvider.notifier).setUser(updatedUser);

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
    final user = ref.watch(authProvider).value;
    final isFreelancer = user?.role == 'freelancer';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _headlineCtrl,
                decoration: const InputDecoration(
                  labelText: 'Headline',
                  hintText: 'e.g. Flutter & MERN Stack Developer',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter headline' : null,
              ),
              const SizedBox(height: 16),
              if (!isFreelancer)
                Column(
                  children: [
                    TextFormField(
                      controller: _companyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Company',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'City, Country',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (isFreelancer) ...[
                TextFormField(
                  controller: _skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Skills',
                    hintText: 'Flutter, Node.js, MongoDB',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Years of experience',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portfolioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Portfolio URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkedinCtrl,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _saving
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}