// lib/features/projects/presentation/project_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _formatBudget(Map<String, dynamic> p) {
    final min = p['budget_min'];
    final max = p['budget_max'];
    if (min == null && max == null) return 'Negotiable';
    if (min != null && max != null) return '\$$min – \$$max';
    if (min != null) return 'From \$$min';
    return 'Up to \$$max';
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final projectAsync = ref.watch(projectDetailProvider(projectId));
    final profileAsync = ref.watch(profileProvider);
    final existingAsync = ref.watch(existingProposalProvider(projectId));

    if (!profileAsync.hasValue) return const _DetailSkeleton();
    final role = profileAsync.asData?.value?['role'] ?? 'freelancer';
    final isClient = role == 'client';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: projectAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(projectDetailProvider(projectId)),
        ),
        data: (project) {
          final skills = (project['skills'] as List? ?? [])
              .map((s) => s.toString())
              .toList();
          final rawClientProfile = project['profiles'];
          final clientProfile = rawClientProfile != null
              ? Map<String, dynamic>.from(rawClientProfile as Map)
              : null;
          final clientName = clientProfile?['name'] as String? ?? 'Client';
          final clientLocation = clientProfile?['location'] as String?;
          final clientCompany = clientProfile?['company'] as String?;
          final clientBio = clientProfile?['bio'] as String?;
          final clientId = project['client_id'] as String?;
          final proposalCount =
              project['proposal_count'] as int? ?? 0;
          final status = project['status'] as String? ?? 'open';

          return CustomScrollView(
            slivers: [

              // ── Gradient Header ──────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00A19B), Color(0xFF007B76)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 14,
                    20,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back + share row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.2),
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: status == 'open'
                                  ? Colors.white
                                  : Colors.white
                                  .withValues(alpha: 0.2),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: status == 'open'
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        project['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stats row
                      Row(
                        children: [
                          Flexible(
                            child: _HeaderStat(
                              icon: Icons.attach_money_rounded,
                              label: _formatBudget(project),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: _HeaderStat(
                              icon: Icons.schedule_outlined,
                              label: _formatDuration(project['duration'] as String?),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: _HeaderStat(
                              icon: Icons.people_outline_rounded,
                              label: '$proposalCount proposal${proposalCount == 1 ? '' : 's'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Posted time
                      Text(
                        'Posted ${_timeAgo(project['created_at'] as String?)}',
                        style: const TextStyle(
                          color: Color(0xFFB2DFDB),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────
              SliverPadding(
                padding:
                const EdgeInsets.fromLTRB(20, 24, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Client card ─────────────────────
                    GestureDetector(
                      onTap: clientId != null
                          ? () => context
                          .push('/profile/$clientId')
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.shadow),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                              AppColors.primaryLight,
                              backgroundImage: clientProfile?[
                              'avatar_url'] !=
                                  null
                                  ? NetworkImage(clientProfile![
                              'avatar_url'] as String)
                                  : null,
                              child:
                              clientProfile?['avatar_url'] ==
                                  null
                                  ? const Icon(
                                Icons
                                    .person_outline_rounded,
                                color: AppColors.primary,
                                size: 24,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (clientCompany != null &&
                                      clientCompany.isNotEmpty)
                                    Text(
                                      clientCompany,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                        AppColors.textSecondary,
                                      ),
                                    ),
                                  if (clientLocation != null &&
                                      clientLocation.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .location_on_outlined,
                                          size: 11,
                                          color: AppColors
                                              .textSecondary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          clientLocation,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors
                                                .textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (clientId != null)
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (clientBio != null &&
                        clientBio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child: Text(
                          clientBio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Description ──────────────────────
                    const _SectionHeader(label: 'Description'),
                    const SizedBox(height: 10),
                    Text(
                      project['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Skills ───────────────────────────
                    if (skills.isNotEmpty) ...[
                      const _SectionHeader(
                          label: 'Skills Required'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills
                            .map(
                              (skill) => Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.shadow),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Budget + Duration cards ───────────
                    const _SectionHeader(label: 'Project Details'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailChip(
                            icon: Icons.attach_money_rounded,
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
                    const SizedBox(height: 32),

                    // ── CTA — Freelancer ─────────────────
                    if (!isClient)
                      existingAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) => const SizedBox.shrink(),
                        data: (existing) {
                          if (existing != null) {
                            return _ProposalStatusBanner(
                              bidAmount: existing['bid_amount'],
                              status: existing['status'] ??
                                  'pending',
                              coverLetter: existing[
                              'cover_letter']
                              as String?,
                              submittedAt: existing['created_at']
                              as String?,
                            );
                          }
                          // Project closed — disable button
                          if (status != 'open') {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.shadow),
                              ),
                              child: const Center(
                                child: Text(
                                  'This project is no longer accepting proposals',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(
                                  '/projects/$projectId/submit-proposal'),
                              icon: const Icon(
                                  Icons.send_outlined,
                                  size: 18),
                              label:
                              const Text('Submit Proposal'),
                            ),
                          );
                        },
                      ),

                    // ── CTA — Client ─────────────────────
                    if (isClient) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                              '/projects/$projectId/proposals'),
                          icon: const Icon(
                              Icons.people_outline_rounded,
                              size: 18),
                          label: Text(
                              'View Proposals ($proposalCount)'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                              '/projects/$projectId/edit'),
                          icon: const Icon(Icons.edit_outlined,
                              size: 18),
                          label: const Text('Edit Project'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ]),
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
// Header stat pill
// ─────────────────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFB2DFDB)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
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
              Icon(icon, size: 12, color: AppColors.textSecondary),
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
  final String? coverLetter;
  final String? submittedAt;

  const _ProposalStatusBanner({
    required this.bidAmount,
    required this.status,
    this.coverLetter,
    this.submittedAt,
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

  String get _title {
    switch (status) {
      case 'accepted': return '🎉 You\'re Hired!';
      case 'rejected': return 'Proposal Not Selected';
      default:         return 'Proposal Pending';
    }
  }

  String get _subtitle {
    switch (status) {
      case 'accepted':
        return 'Your bid of \$$bidAmount was accepted. Check messages!';
      case 'rejected':
        return 'Your bid of \$$bidAmount was not selected this time.';
      default:
        return 'Your bid of \$$bidAmount is under review.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _color,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
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
          if (coverLetter != null && coverLetter!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.shadow, height: 1),
            const SizedBox(height: 10),
            const Text(
              'Your Cover Letter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              coverLetter!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Skeleton Loader
// ─────────────────────────────────────────────────────────────
class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bone(double w, double h, {double r = 10}) =>
      AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Opacity(
          opacity: _anim.value,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: AppColors.shadow,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Color(0xFF00A19B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(double.infinity, 80, r: 16),
                const SizedBox(height: 16),
                _bone(double.infinity, 16),
                const SizedBox(height: 8),
                _bone(300, 16),
                const SizedBox(height: 8),
                _bone(250, 16),
                const SizedBox(height: 24),
                Row(children: [
                  _bone(120, 60, r: 14),
                  const SizedBox(width: 12),
                  _bone(120, 60, r: 14),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  _bone(80, 30, r: 20),
                  const SizedBox(width: 8),
                  _bone(100, 30, r: 20),
                  const SizedBox(width: 8),
                  _bone(70, 30, r: 20),
                ]),
                const SizedBox(height: 32),
                _bone(double.infinity, 50, r: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Could not load project',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}