// lib/features/proposals/presentation/my_proposals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../messages/presentation/messages_provider.dart';
import 'my_proposals_provider.dart';

class MyProposalsPage extends ConsumerStatefulWidget {
  const MyProposalsPage({super.key});

  @override
  ConsumerState<MyProposalsPage> createState() => _MyProposalsPageState();
}

class _MyProposalsPageState extends ConsumerState<MyProposalsPage> {
  // 'all' | 'pending' | 'accepted' | 'completed'
  String _tab = 'all';

  @override
  Widget build(BuildContext context) {
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
        data: (allProposals) {
          // Hide archived proposals from every tab (stats still count them),
          // and order active (accepted) + pending first.
          int rank(String s) => switch (s) {
                'accepted' => 0,
                'pending' => 1,
                'completed' => 2,
                'rejected' => 3,
                _ => 4,
              };
          final visible = allProposals
              .where((p) => p['archived'] != true)
              .toList()
            ..sort((a, b) {
              final r = rank(a['status'] ?? 'pending')
                  .compareTo(rank(b['status'] ?? 'pending'));
              if (r != 0) return r;
              final da = a['created_at'] as String? ?? '';
              final db = b['created_at'] as String? ?? '';
              return db.compareTo(da);
            });

          if (visible.isEmpty) {
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

          // Counts come from the stats provider (counts archived too) so the
          // numbers stay stable even after a completed proposal is removed.
          final stats = ref.watch(myProposalStatsProvider);

          final filtered = _tab == 'all'
              ? visible
              : visible
                  .where((p) => (p['status'] ?? 'pending') == _tab)
                  .toList();

          return Column(
            children: [
              // ── Stats Strip (tappable tabs) ──────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.shadow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatTab(
                      label: 'Total',
                      value: '${stats['total']}',
                      color: AppColors.primary,
                      selected: _tab == 'all',
                      onTap: () => setState(() => _tab = 'all'),
                    ),
                    _StatTab(
                      label: 'Pending',
                      value: '${stats['pending']}',
                      color: const Color(0xFFF59E0B),
                      selected: _tab == 'pending',
                      onTap: () => setState(() => _tab = 'pending'),
                    ),
                    _StatTab(
                      label: 'Active',
                      value: '${stats['accepted']}',
                      color: const Color(0xFF1565C0),
                      selected: _tab == 'accepted',
                      onTap: () => setState(() => _tab = 'accepted'),
                    ),
                    _StatTab(
                      label: 'Done',
                      value: '${stats['completed']}',
                      color: const Color(0xFF2E7D32),
                      selected: _tab == 'completed',
                      onTap: () => setState(() => _tab = 'completed'),
                    ),
                  ],
                ),
              ),

              // ── Proposal List ────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyTab(tab: _tab)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async =>
                            ref.invalidate(myProposalsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _ProposalCard(proposal: filtered[index]),
                        ),
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
// Empty state for a filtered tab
// ─────────────────────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  final String tab;
  const _EmptyTab({required this.tab});

  String get _label {
    switch (tab) {
      case 'pending':
        return 'pending';
      case 'accepted':
        return 'active';
      case 'completed':
        return 'completed';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No $_label proposals',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat Tab — tappable filter pill
// ─────────────────────────────────────────────────────────────
class _StatTab extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatTab({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Proposal Card
// ─────────────────────────────────────────────────────────────
class _ProposalCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> proposal;
  const _ProposalCard({required this.proposal});

  @override
  ConsumerState<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<_ProposalCard> {
  bool _expanded = false;

  Future<void> _confirmRemove() async {
    final id = widget.proposal['id'] as String?;
    if (id == null) return;
    final title =
        (widget.proposal['project'] as Map?)?['title'] as String? ?? 'this proposal';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove proposal?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'This removes "$title" from your My Proposals list. '
          'Your stats are not affected.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await archiveProposal(proposalId: id);
      ref.invalidate(myProposalsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from your proposals.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

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

  Future<void> _openChat() async {
    final project = widget.proposal['project'] as Map?;
    final clientId = project?['client_id'] as String?;
    final clientName = (project?['client'] as Map?)?['name'] as String? ?? 'Client';
    final projectId = widget.proposal['project_id'] as String?;
    final me = supabase.auth.currentUser?.id;
    if (clientId == null || projectId == null || me == null) return;
    try {
      final convId = await openConversation(
        projectId: projectId,
        clientId: clientId,
        freelancerId: me,
      );
      if (!mounted) return;
      context.push('/messages/$convId', extra: {
        'otherPersonName': clientName,
        'otherPersonId': clientId,
        'projectTitle': project?['title'] ?? '',
        'projectId': projectId,
        'proposalId': widget.proposal['id'],
        'isClient': false,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: $e')),
        );
      }
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
    // Only active (accepted) proposals get the quick-chat button.
    final canChat = status == 'accepted';

    return Stack(
      children: [
        GestureDetector(
          onLongPress: _confirmRemove,
          child: Container(
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
          ),
        ),
        if (canChat)
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openChat,
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
