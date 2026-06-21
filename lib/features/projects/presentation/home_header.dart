// lib/features/projects/presentation/home_header.dart
//
// Shared hero header for both the freelancer and client home pages.
// Logo + greeting on the left, notifications bell + avatar/name on the right.
// Drag the header down (or tap the avatar) to open the user's profile.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/widgets/app_logo.dart';
import '../../notifications/presentation/notifications_page.dart';

class HomeHeader extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final VoidCallback onProfileOpen;
  final String fallbackName;

  const HomeHeader({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.onProfileOpen,
    this.fallbackName = 'there',
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  bool _dragging = false;
  double _dragStartY = 0;
  double _dragProgress = 0; // 0.0 → 1.0 as user drags down 60px

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
    final avatarUrl = widget.avatarUrl;
    final glowOpacity = (0.2 + _dragProgress * 0.3).clamp(0.0, 0.5);
    final gradientDark = _dragging;

    return GestureDetector(
      onVerticalDragStart: (d) {
        _dragStartY = d.globalPosition.dy;
        setState(() {
          _dragging = true;
          _dragProgress = 0;
        });
      },
      onVerticalDragUpdate: (d) {
        final delta = d.globalPosition.dy - _dragStartY;
        if (delta > 0) {
          setState(() {
            _dragProgress = (delta / 60).clamp(0.0, 1.0);
          });
        }
      },
      onVerticalDragEnd: (d) {
        final totalDelta = d.globalPosition.dy - _dragStartY;
        setState(() {
          _dragging = false;
          _dragProgress = 0;
        });
        if (totalDelta >= 30) {
          widget.onProfileOpen();
        }
      },
      onVerticalDragCancel: () {
        setState(() {
          _dragging = false;
          _dragProgress = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientDark
                ? [const Color(0xFF007B76), const Color(0xFF005F5B)]
                : [const Color(0xFF00A19B), const Color(0xFF007B76)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A19B).withValues(alpha: glowOpacity),
              blurRadius: 16 + _dragProgress * 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── LEFT: Logo + greeting ──────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      AppLogo(size: 46),
                      SizedBox(width: 10),
                      Text(
                        'Lancr',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      color: Color(0xFFB2DFDB),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // ── Notifications bell ─────────────────────
            const NotificationBell(color: Colors.white),
            const SizedBox(width: 4),

            // ── RIGHT: Avatar + name (tap or drag to profile) ─
            GestureDetector(
              onTap: widget.onProfileOpen,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.name.isNotEmpty ? widget.name : widget.fallbackName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, -_bounceAnim.value),
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: _dragging ? 0.35 : 0.2),
                        shape: BoxShape.circle,
                        image: avatarUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: _dragging ? 1.0 : 0.5),
                          width: 2,
                        ),
                        boxShadow: _dragging
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                )
                              ]
                            : [],
                      ),
                      child: avatarUrl != null
                          ? null
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
