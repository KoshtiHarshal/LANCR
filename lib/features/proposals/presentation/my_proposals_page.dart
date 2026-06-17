// lib/features/proposals/presentation/my_proposals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'my_proposals_provider.dart';

class MyProposalsPage extends ConsumerWidget {
  const MyProposalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(myProposalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Proposals')),
      body: proposalsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myProposalsProvider),
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
                  Icon(Icons.send_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No proposals yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse projects and submit\nyour first proposal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/projects/browse'),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Browse Projects'),
                  ),
                ],
              ),
            );
          }

          final stats = ref.watch(myProposalStatsProvider);

          return Column(
            children: [
              // ── Stats Strip ──────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.shadow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatPill(
                        label: 'Total',
                        value: '${stats['total']}',
                        color: AppColors.primary),
                    _StatPill(
                        label: 'Pending',
                        value: '${stats['pending']}',
                        color: const Color(0xFFF59E0B)),
                    _StatPill(
                        label: 'Active',
                        value: '${stats['accepted']}',
                        color: const Color(0xFF1565C0)),
                    _StatPill(
                        label: 'Done',
                        value: '${stats['completed']}',
                        color: const Color(0xFF2E7D32)),
                  ],
                ),
              ),

              // ── Proposal List ────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: proposals.length,
                  separatorBuilder: (_, _) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _ProposalCard(proposal: proposals[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat Pill
// ─────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Proposal Card
// ─────────────────────────────────────────────────────────────
class _ProposalCard extends StatefulWidget {
  final Map<String, dynamic> proposal;
  const _ProposalCard({required this.proposal});

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.proposal['status']) {
      case 'accepted':  return const Color(0xFF1565C0);
      case 'completed': return const Color(0xFF2E7D32);
      case 'rejected':  return const Color(0xFFD94F4F);
      default:          return const Color(0xFFF59E0B);
    }
  }

  IconData get _statusIcon {
    switch (widget.proposal['status']) {
      case 'accepted':  return Icons.timelapse;
      case 'completed': return Icons.check_circle_outline;
      case 'rejected':  return Icons.cancel_outlined;
      default:          return Icons.hourglass_top_outlined;
    }
  }

  String get _statusLabel {
    switch (widget.proposal['status']) {
      case 'accepted':  return 'In Progress';
      case 'completed': return 'Completed';
      case 'rejected':  return 'Rejected';
      default:          return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.proposal['project'] as Map?;
    final title = project?['title'] ?? 'Project';
    final description = project?['description'] ?? '';
    final bidAmount = widget.proposal['bid_amount'];
    final coverLetter = widget.proposal['cover_letter'] ?? '';
    final status = widget.proposal['status'] ?? 'pending';
    final projectId = widget.proposal['project_id'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'completed'
              ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
              : status == 'accepted'
              ? const Color(0xFF1565C0).withValues(alpha: 0.2)
              : status == 'rejected'
              ? const Color(0xFFD94F4F).withValues(alpha: 0.2)
              : AppColors.shadow,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + Status badge ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: projectId != null
                        ? () => context.push('/projects/$projectId')
                        : null,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, size: 12, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Description preview ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 10),

          // ── Bid amount ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Your bid: \$${bidAmount ?? '—'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Cover Letter (expandable) ─────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Cover Letter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      coverLetter,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}