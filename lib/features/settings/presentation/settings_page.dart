// lib/features/settings/presentation/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/notifications/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/url_launcher_util.dart';
import '../../../main.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../messages/presentation/messages_provider.dart';
import '../../profiles/presentation/profile_provider.dart';

// ── Configuration — replace these with your real values before publishing ──
const _appVersion = '1.0.0';
const _privacyUrl = 'https://lancr.app/privacy'; // TODO: host real policy
const _termsUrl = 'https://lancr.app/terms'; // TODO: host real terms
const _supportEmail = 'support@lancr.app'; // TODO: real support inbox
const _playStoreId = 'com.example.lancr_app'; // TODO: production package id

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String? _memberSince(String? raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await openExternalLink(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Future<void> _launchMailto(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'LANCR Support'},
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app found')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app found')),
        );
      }
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, String? email) async {
    if (email == null) {
      _snack(context, 'No email on file');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change password',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'We\'ll email a password reset link to $email.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (context.mounted) _snack(context, 'Reset link sent to $email');
    } catch (e) {
      if (context.mounted) _snack(context, 'Failed to send reset link: $e');
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete account?',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFFD94F4F))),
        content: Text(
          'This permanently deletes your LANCR account and all of your data — '
          'profile, projects, proposals, messages, reviews and portfolio. '
          'This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
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
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await supabase.rpc('delete_current_user');
      // Clear session — auth listener redirects to login.
      await ref.read(authNotifierProvider.notifier).logout();
      _clearUserCaches(ref);
    } catch (e) {
      if (context.mounted) _snack(context, 'Failed to delete account: $e');
    }
  }

  /// Drop cached user data so a different account signing in starts clean.
  void _clearUserCaches(WidgetRef ref) {
    ref.invalidate(profileProvider);
    ref.invalidate(currentUserRoleProvider);
    ref.invalidate(freelancerStatsProvider);
    ref.invalidate(clientStatsProvider);
    ref.invalidate(conversationsProvider);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign out?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'You will need to sign in again to access your LANCR account.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD94F4F)),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      _clearUserCaches(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: profileAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Text('Could not load settings',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (profile) {
          final p = profile ?? {};
          String? text(String k) {
            final v = p[k]?.toString().trim();
            return (v == null || v.isEmpty) ? null : v;
          }

          final isClient = (text('role') ?? 'freelancer') == 'client';
          final email = text('email');
          final location = text('location');
          final company = text('company');
          final experience = p['experience_years'];
          final memberSince = _memberSince(p['created_at'] as String?);
          final website = text('portfolio_url');
          final linkedin = text('linkedin_url');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // ── Account ─────────────────────────────────
              const _SectionHeader('Account'),
              _SettingsCard(children: [
                _SettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit profile',
                  subtitle: 'Name, photo, bio and more',
                  onTap: () async {
                    await context.push('/profile/edit');
                    ref.invalidate(profileProvider);
                  },
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Email a reset link',
                  onTap: () => _resetPassword(context, email),
                ),
              ]),
              const SizedBox(height: 18),

              // ── Personal information ────────────────────
              const _SectionHeader('Personal information'),
              _SettingsCard(children: [
                if (email != null)
                  _InfoRow(icon: Icons.mail_outline_rounded, label: 'Email', value: email),
                if (location != null)
                  _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: location),
                if (isClient && company != null)
                  _InfoRow(icon: Icons.apartment_rounded, label: 'Company', value: company),
                if (!isClient && experience != null)
                  _InfoRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Experience',
                      value: '$experience years'),
                if (memberSince != null)
                  _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Member since',
                      value: memberSince),
                _InfoRow(
                    icon: isClient
                        ? Icons.business_center_outlined
                        : Icons.work_outline_rounded,
                    label: 'Role',
                    value: isClient ? 'Client' : 'Freelancer'),
              ]),
              const SizedBox(height: 18),

              // ── Professional links ──────────────────────
              if (website != null || linkedin != null) ...[
                const _SectionHeader('Professional links'),
                _SettingsCard(children: [
                  if (website != null)
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: isClient ? 'Website' : 'Portfolio',
                      subtitle: website,
                      trailing: Icon(Icons.open_in_new_rounded,
                          size: 16, color: AppColors.primary),
                      onTap: () => _open(context, website),
                    ),
                  if (linkedin != null)
                    _SettingsTile(
                      icon: Icons.badge_outlined,
                      title: 'LinkedIn',
                      subtitle: linkedin,
                      trailing: Icon(Icons.open_in_new_rounded,
                          size: 16, color: AppColors.primary),
                      onTap: () => _open(context, linkedin),
                    ),
                ]),
                const SizedBox(height: 18),
              ],

              // ── Appearance ──────────────────────────────
              const _SectionHeader('Appearance'),
              const _SettingsCard(children: [_ThemeModeSelector()]),
              const SizedBox(height: 18),

              // ── Notifications ───────────────────────────
              const _SectionHeader('Notifications'),
              const _SettingsCard(children: [_NotificationPrefTile()]),
              const SizedBox(height: 18),

              // ── About & legal ───────────────────────────
              const _SectionHeader('About & legal'),
              _SettingsCard(children: [
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate LANCR',
                  onTap: () => _open(context,
                      'https://play.google.com/store/apps/details?id=$_playStoreId'),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _open(context, _privacyUrl),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _open(context, _termsUrl),
                ),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  subtitle: _supportEmail,
                  onTap: () => _launchMailto(context),
                ),
                const _InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Version',
                    value: _appVersion),
              ]),
              const SizedBox(height: 24),

              // ── Sign out ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD94F4F),
                    side: const BorderSide(color: Color(0xFFD94F4F)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Danger zone ─────────────────────────────
              const _SectionHeader('Danger zone'),
              _SettingsCard(children: [
                _SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete account',
                  subtitle: 'Permanently remove your account and data',
                  destructive: true,
                  onTap: () => _deleteAccount(context, ref),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shadow),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: AppColors.shadow),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool destructive;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFD94F4F);
    final accent = destructive ? danger : AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: destructive ? danger : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: destructive
                        ? danger.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                    size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Local push-notification preference (persists the user's choice; it will be
/// honoured once push notifications are wired up).
class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    const options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (final (m, icon, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => ref.read(themeModeProvider.notifier).setMode(m),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: mode == m
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: mode == m ? AppColors.primary : AppColors.shadow,
                      width: mode == m ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icon,
                          size: 22,
                          color: mode == m
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              mode == m ? FontWeight.w700 : FontWeight.w500,
                          color: mode == m
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationPrefTile extends StatefulWidget {
  const _NotificationPrefTile();

  @override
  State<_NotificationPrefTile> createState() => _NotificationPrefTileState();
}

class _NotificationPrefTileState extends State<_NotificationPrefTile> {
  bool _enabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PushService.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loaded = true;
    });
  }

  Future<void> _set(bool value) async {
    setState(() => _enabled = value);
    // Persists the pref AND clears/registers the device token so it actually
    // takes effect server-side.
    await PushService.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _enabled,
      onChanged: _loaded ? _set : null,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      secondary: Icon(Icons.notifications_none_rounded,
          color: AppColors.primary, size: 20),
      title: Text(
        'Push notifications',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        'Proposals, messages and project updates',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}
