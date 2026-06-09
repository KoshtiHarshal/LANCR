// lib/features/projects/presentation/post_project_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

class PostProjectPage extends ConsumerStatefulWidget {
  final String? projectId; // null = create, non-null = edit
  const PostProjectPage({super.key, this.projectId});

  @override
  ConsumerState<PostProjectPage> createState() => _PostProjectPageState();
}

class _PostProjectPageState extends ConsumerState<PostProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _skillsController = TextEditingController();

  String _duration = 'less_1_month';
  bool _isLoading = false;
  bool _isLoadingData = false; // for prefill fetch in edit mode

  bool get _isEditMode => widget.projectId != null;

  final _durations = const [
    ('less_1_month', 'Less than 1 month'),
    ('1_3_months', '1 – 3 months'),
    ('3_6_months', '3 – 6 months'),
    ('more_6_months', 'More than 6 months'),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) _loadExistingProject();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  // ── Pre-fill form when editing ──────────────────────────────
  Future<void> _loadExistingProject() async {
    setState(() => _isLoadingData = true);
    try {
      final data = await supabase
          .from('projects')
          .select(
          'title, description, budget_min, budget_max, skills, duration')
          .eq('id', widget.projectId!)
          .single();

      _titleController.text = data['title'] as String? ?? '';
      _descController.text = data['description'] as String? ?? '';
      _budgetMinController.text =
          data['budget_min']?.toString() ?? '';
      _budgetMaxController.text =
          data['budget_max']?.toString() ?? '';

      final rawSkills = data['skills'];
      if (rawSkills is List) {
        _skillsController.text = rawSkills.join(', ');
      }

      final rawDuration = data['duration'] as String?;
      if (rawDuration != null &&
          _durations.any((d) => d.$1 == rawDuration)) {
        _duration = rawDuration;
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load project data.'),
            backgroundColor: const Color(0xFFD94F4F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('budget_max') || raw.contains('PGRST204')) {
      return 'Database schema error — please contact support.';
    }
    if (raw.contains('JWT') || raw.contains('auth')) {
      return 'Session expired. Please log in again.';
    }
    if (raw.contains('violates row-level security')) {
      return 'Permission denied. Are you logged in as a client?';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser!;
      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final payload = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'budget_min': int.tryParse(_budgetMinController.text.trim()),
        'budget_max': int.tryParse(_budgetMaxController.text.trim()),
        'skills': skills,
        'duration': _duration,
      };

      if (_isEditMode) {
        // ── Edit mode: update existing row ──────────────
        await supabase
            .from('projects')
            .update(payload)
            .eq('id', widget.projectId!)
            .eq('client_id', user.id); // RLS-safe guard
      } else {
        // ── Create mode: insert new row ─────────────────
        await supabase.from('projects').insert({
          ...payload,
          'client_id': user.id,
          'status': 'open',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  _isEditMode
                      ? 'Project updated successfully!'
                      : 'Project posted successfully!',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _friendlyError(e.toString()),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD94F4F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Project' : 'Post a Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingData
          ? const Center(
        child:
        CircularProgressIndicator(color: AppColors.primary),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Section header ──────────────────────
              Text(
                _isEditMode
                    ? 'Update Project Details'
                    : 'Project Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEditMode
                    ? 'Update your project info. Changes are visible immediately.'
                    : 'Describe your project clearly to attract the right freelancers.',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // ── Title ────────────────────────────────
              _label('Project Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText:
                  'e.g. Build a React dashboard for my SaaS',
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Description ──────────────────────────
              _label('Description *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                  'Describe the project scope, deliverables, and any technical requirements...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                (v == null || v.trim().length < 30)
                    ? 'Please write at least 30 characters'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Budget ───────────────────────────────
              _label('Budget Range (USD)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Min',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  const Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: 12),
                    child: Text('–',
                        style: TextStyle(fontSize: 18)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Max',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Duration ─────────────────────────────
              _label('Project Duration'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: AppColors.shadow),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _duration,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _duration = val);
                      }
                    },
                    items: _durations
                        .map((d) => DropdownMenuItem(
                      value: d.$1,
                      child: Text(d.$2),
                    ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Skills ───────────────────────────────
              _label('Skills Required'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  hintText:
                  'React, Node.js, Firebase (comma-separated)',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Separate skills with commas.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary),
              ),

              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(_isEditMode
                      ? 'Save Changes'
                      : 'Post Project'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}