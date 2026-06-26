// lib/features/moderation/presentation/moderation_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'moderation_provider.dart';

const _reasons = <String>[
  'Spam or misleading',
  'Inappropriate content',
  'Harassment or abuse',
  'Scam or fraud',
  'Other',
];

/// Report dialog — pick a reason + optional details. Returns true if submitted.
Future<bool?> showReportDialog(
  BuildContext context, {
  String? reportedUserId,
  String? reportedProjectId,
  String targetName = 'this',
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(
      reportedUserId: reportedUserId,
      reportedProjectId: reportedProjectId,
      targetName: targetName,
    ),
  );
}

class _ReportDialog extends StatefulWidget {
  final String? reportedUserId;
  final String? reportedProjectId;
  final String targetName;

  const _ReportDialog({
    this.reportedUserId,
    this.reportedProjectId,
    required this.targetName,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _reason;
  final _details = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _submitting = true);
    try {
      await submitReport(
        reportedUserId: widget.reportedUserId,
        reportedProjectId: widget.reportedProjectId,
        reason: _reason!,
        details: _details.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Report ${widget.targetName}',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you reporting this?',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            for (final r in _reasons)
              InkWell(
                onTap: _submitting ? null : () => setState(() => _reason = r),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _reason == r
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: _reason == r
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r,
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add details (optional)',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.shadow),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.shadow),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD94F4F)),
          onPressed: (_reason == null || _submitting) ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

/// Confirm + block a user, then invalidate the blocked-ids provider.
/// Returns true if the user was blocked.
Future<bool> confirmAndBlockUser(
  BuildContext context,
  WidgetRef ref,
  String userId,
  String name,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Block $name?',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      content: Text(
        "You won't see $name's projects or conversations, and they won't be "
        'able to reach you. You can unblock them later.',
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
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (confirm != true) return false;
  try {
    await blockUser(userId);
    ref.invalidate(blockedUserIdsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name blocked.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not block: $e')),
      );
    }
    return false;
  }
}
