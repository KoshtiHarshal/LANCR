// lib/features/proposals/presentation/view_proposals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../projects/presentation/proposals_provider.dart';
import '../../projects/presentation/project_detail_provider.dart';
import '../../proposals//presentation/my_proposals_provider.dart';
import '../../profiles/presentation/profile_provider.dart';
import '../../projects/presentation/client_home_page.dart'; // for clientProjectsCountProvider etc.

class ViewProposalsPage extends ConsumerWidget {
  final String projectId;
  const ViewProposalsPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(projectProposalsProvider(projectId));

    // BUG 1 + 2 + 3 FIX: invalidate ALL stale providers after any action
    void invalidateAll() {
      // Proposals list on this page
      ref.invalidate(projectProposalsProvider(projectId));
      // Bug 1: freelancer's proposal status card on ProjectDetailPage
      ref.invalidate(existingProposalProvider(projectId));
      // Bug 1: project status badge on ProjectDetailPage
      ref.invalidate(projectDetailProvider(projectId));
      // Bug 2: freelancer home stats + my proposals list
      ref.invalidate(myProposalsProvider);
      ref.invalidate(freelancerStatsProvider);
      // Bug 3: client home dashboard counts
      ref.invalidate(clientProjectsCountProvider);
      ref.invalidate(clientProposalsCountProvider);
      ref.invalidate(clientCompletedCountProvider);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Proposals')),
      body: proposalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(projectProposalsProvider(projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (proposals) {
          if (proposals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No proposals yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Proposals will appear here\nonce freelancers apply.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: proposals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final proposal = proposals[index];
              return _ProposalCard(
                proposal: proposal,
                projectId: projectId,
                // Pass the full invalidation callback
                onAction: invalidateAll,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Proposal Card (unchanged except _complete snack text)
// ─────────────────────────────────────────────────────────────
class _ProposalCard extends StatefulWidget {
  final Map<String, dynamic> proposal;
  final String projectId;
  final VoidCallback onAction;

  const _ProposalCard({
    required this.proposal,
    required this.projectId,
    required this.onAction,
  });

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  bool _loading = false;
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.proposal['status']) {
      case 'accepted':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFD94F4F);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get _statusLabel {
    switch (widget.proposal['status']) {
      case 'accepted':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Future<void> _accept() async {
    final confirm = await _showConfirmDialog(
      context,
      title: 'Accept Proposal?',
      message:
      'This will accept this freelancer and close the project to other proposals.',
      confirmLabel: 'Accept',
      confirmColor: const Color(0xFF2E7D32),
    );
    if (!confirm) return;

    setState(() => _loading = true);
    try {
      await acceptProposal(
        proposalId: widget.proposal['id'],
        projectId: widget.projectId,
        freelancerId: widget.proposal['freelancer_id'],
      );
      if (mounted) {
        _showSnack('Proposal accepted! Project is now in progress.',
            success: true);
        widget.onAction(); // invalidates all stale providers
      }
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final confirm = await _showConfirmDialog(
      context,
      title: 'Reject Proposal?',
      message: 'This will reject this freelancer\'s proposal.',
      confirmLabel: 'Reject',
      confirmColor: const Color(0xFFD94F4F),
    );
    if (!confirm) return;

    setState(() => _loading = true);
    try {
      await rejectProposal(proposalId: widget.proposal['id']);
      if (mounted) {
        _showSnack('Proposal rejected.', success: false);
        widget.onAction();
      }
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    final confirm = await _showConfirmDialog(
      context,
      title: 'Mark as Complete?',
      message:
      'This will mark the project as completed. This action cannot be undone.',
      confirmLabel: 'Complete',
      confirmColor: const Color(0xFF2E7D32),
    );
    if (!confirm) return;

    setState(() => _loading = true);
    try {
      await completeProject(
        projectId: widget.projectId,
        proposalId: widget.proposal['id'],
      );
      if (mounted) {
        _showSnack('Project marked as completed! 🎉', success: true);
        widget.onAction(); // invalidates all stale providers including client completed count
      }
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        success ? AppColors.primary : const Color(0xFFD94F4F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmLabel,
        required Color confirmColor,
      }) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final freelancer = widget.proposal['freelancer'] as Map?;
    final freelancerId = widget.proposal['freelancer_id'] as String?;
    final name = freelancer?['name'] ?? 'Freelancer';
    final headline = freelancer?['headline'] as String?;
    final location = freelancer?['location'] as String?;
    final expYears = freelancer?['experience_years'];
    final skills = (freelancer?['skills'] as List? ?? [])
        .map((s) => s.toString())
        .toList();
    final bidAmount = widget.proposal['bid_amount'];
    final coverLetter = widget.proposal['cover_letter'] ?? '';
    final status = widget.proposal['status'] ?? 'pending';
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: freelancerId != null
                      ? () => context.push('/profile/$freelancerId')
                      : null,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'F',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: freelancerId != null
                        ? () => context.push('/profile/$freelancerId')
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new,
                                size: 13, color: AppColors.primary),
                          ],
                        ),
                        if (headline != null && headline.isNotEmpty)
                          Text(
                            headline,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        if (location != null && location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: AppColors.textSecondary),
                              Text(
                                location,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bid + Experience ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                    icon: Icons.attach_money,
                    label: '\$$bidAmount',
                    color: AppColors.primary),
                if (expYears != null)
                  _InfoPill(
                      icon: Icons.workspace_premium_outlined,
                      label: '$expYears yrs exp',
                      color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Skills ────────────────────────────────────
          if (skills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .take(4)
                    .map((s) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.shadow),
                  ),
                  child: Text(s,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),

          // ── Cover Letter (expandable) ─────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Cover Letter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coverLetter,
                    maxLines: _expanded ? null : 2,
                    overflow:
                    _expanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── View Profile Button ───────────────────────
          if (freelancerId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/profile/$freelancerId'),
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: const Text('View Full Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // ── Action Buttons ────────────────────────────
          if (isPending || isAccepted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary))
                  : isPending
                  ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFD94F4F)),
                        foregroundColor:
                        const Color(0xFFD94F4F),
                      ),
                      onPressed: _reject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF2E7D32)),
                      onPressed: _accept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12),
                  ),
                  onPressed: _complete,
                  icon: const Icon(
                      Icons.check_circle_outline,
                      size: 18),
                  label: const Text('Mark as Complete'),
                ),
              ),
            ),

          if (status == 'completed' || status == 'rejected')
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Info Pill
// ─────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}