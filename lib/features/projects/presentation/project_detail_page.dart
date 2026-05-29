// lib/features/projects/presentation/project_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../profiles/presentation/profile_provider.dart';
import 'project_detail_provider.dart';

class ProjectDetailPage extends ConsumerWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  String _formatDuration(String? raw) {
    switch (raw) {
      case 'less_1_month':  return 'Less than 1 month';
      case '1_3_months':    return '1–3 months';
      case '3_6_months':    return '3–6 months';
      case 'more_6_months': return '6+ months';
      default:              return raw ?? 'Not specified';
    }
  }

  String _formatBudget(Map p) {
    final min = p['budget_min'];
    final max = p['budget_max'];
    if (min == null && max == null) return 'Negotiable';
    if (min != null && max != null) return '\$$min – \$$max';
    if (min != null) return 'From \$$min';
    return 'Up to \$$max';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync  = ref.watch(projectDetailProvider(projectId));
    final profileAsync  = ref.watch(profileProvider);
    final existingAsync = ref.watch(existingProposalProvider(projectId));

    final role     = profileAsync.asData?.value?['role'] ?? 'freelancer';
    final isClient = role == 'client';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Project Detail')),
      body: projectAsync.when(
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
                  style:
                  const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(projectDetailProvider(projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (project) {
          final skills = (project['skills'] as List? ?? [])
              .map((s) => s.toString())
              .toList();
          final clientProfile  = project['profiles'] as Map?;
          final clientName     = clientProfile?['name'] ?? 'Client';
          final clientLocation = clientProfile?['location'] as String?;
          final clientCompany  = clientProfile?['company'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Title + status badge ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        project['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (project['status'] ?? 'open').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Client info ───────────────────────────
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person_outline,
                          color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if ((clientCompany != null &&
                              clientCompany.isNotEmpty) ||
                              (clientLocation != null &&
                                  clientLocation.isNotEmpty))
                            Text(
                              [
                                if (clientCompany != null &&
                                    clientCompany.isNotEmpty)
                                  clientCompany,
                                if (clientLocation != null &&
                                    clientLocation.isNotEmpty)
                                  clientLocation,
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Budget + Duration ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.attach_money,
                        label: 'Budget',
                        value: _formatBudget(project),
                        bgColor: AppColors.primaryLight,
                        valueColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailChip(
                        icon: Icons.schedule_outlined,
                        label: 'Duration',
                        value: _formatDuration(
                            project['duration'] as String?),
                        bgColor: AppColors.surface,
                        valueColor: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Description ───────────────────────────
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  project['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Skills required ───────────────────────
                if (skills.isNotEmpty) ...[
                  const Text(
                    'Skills Required',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (skill) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border:
                          Border.all(color: AppColors.shadow),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── CTA — Freelancer ──────────────────────
                if (!isClient)
                  existingAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e,s) => const SizedBox.shrink(),
                    data: (existing) {
                      if (existing != null) {
                        return _ProposalStatusBanner(
                          bidAmount: existing['bid_amount'],
                          status: existing['status'] ?? 'pending',
                        );
                      }
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                              '/projects/$projectId/submit-proposal'),
                          icon: const Icon(Icons.send_outlined,
                              size: 18),
                          label: const Text('Submit Proposal'),
                        ),
                      );
                    },
                  ),

                // ── CTA — Client ──────────────────────────
                if (isClient)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context
                          .push('/projects/$projectId/proposals'),
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text('View Proposals'),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Detail Info Chip
// ─────────────────────────────────────────────────────────────
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color bgColor;
  final Color valueColor;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.bgColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Proposal Status Banner
// ─────────────────────────────────────────────────────────────
class _ProposalStatusBanner extends StatelessWidget {
  final dynamic bidAmount;
  final String status;

  const _ProposalStatusBanner({
    required this.bidAmount,
    required this.status,
  });

  Color get _color {
    switch (status) {
      case 'accepted': return const Color(0xFF2E7D32);
      case 'rejected': return const Color(0xFFD94F4F);
      default:         return const Color(0xFFF59E0B);
    }
  }

  IconData get _icon {
    switch (status) {
      case 'accepted': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default:         return Icons.hourglass_top_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Accepted ─────────────────────────────────────
    if (status == 'accepted') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF2E7D32)
                      .withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.celebration_outlined,
                    color: Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎉 You\'re Hired!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your bid of \$$bidAmount was accepted.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Pending / Rejected ────────────────────────────
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proposal ${status[0].toUpperCase()}${status.substring(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Your bid: \$$bidAmount',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}