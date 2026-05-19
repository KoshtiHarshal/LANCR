// lib/features/projects/presentation/submit_proposal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import 'project_detail_provider.dart';

class SubmitProposalPage extends ConsumerStatefulWidget {
  final String projectId;
  const SubmitProposalPage({super.key, required this.projectId});

  @override
  ConsumerState<SubmitProposalPage> createState() =>
      _SubmitProposalPageState();
}

class _SubmitProposalPageState extends ConsumerState<SubmitProposalPage> {
  final _formKey        = GlobalKey<FormState>();
  final _coverLetterCtrl = TextEditingController();
  final _bidAmountCtrl  = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _coverLetterCtrl.dispose();
    _bidAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await supabase.from('proposals').insert({
        'project_id':    widget.projectId,
        'freelancer_id': user.id,
        'cover_letter':  _coverLetterCtrl.text.trim(),
        'bid_amount':    double.parse(_bidAmountCtrl.text.trim()),
        'status':        'pending',
      });

      if (!mounted) return;

      ref.invalidate(existingProposalProvider(widget.projectId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Proposal submitted successfully!'),
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
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('unique')
          ? 'You already submitted a proposal for this project.'
          : 'Failed to submit: ${e.toString().replaceFirst('Exception: ', '')}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: const Color(0xFFD94F4F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Submit Proposal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Project title preview ─────────────────
              projectAsync.maybeWhen(
                data: (p) => Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.shadow),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // ── Bid Amount ────────────────────────────
              const Text(
                'Your Bid (USD)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bidAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'e.g. 500',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your bid amount';
                  if (double.tryParse(v) == null)
                    return 'Enter a valid number';
                  if (double.parse(v) <= 0)
                    return 'Bid must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Cover Letter ──────────────────────────
              const Text(
                'Cover Letter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Explain why you're the best fit for this project.",
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _coverLetterCtrl,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText:
                  "Hi, I'm interested in this project because...",
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please write a cover letter';
                  if (v.trim().length < 30)
                    return 'Cover letter too short (min 30 characters)';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── Submit Button ─────────────────────────
              SizedBox(
                width: double.infinity,
                child: _submitting
                    ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                )
                    : ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Submit Proposal'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}