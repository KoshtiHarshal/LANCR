// lib/core/widgets/app_logo.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Theme-aware LANCR logo/illustration. Shows the dark-background artwork in
/// dark mode and the light-background artwork in light mode. Falls back to a
/// styled wordmark if the asset hasn't been added yet.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final asset = AppColors.isDark
        ? 'assets/branding/lancr_dark.png'
        : 'assets/branding/lancr_light.png';

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _Wordmark(size: size),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double size;
  const _Wordmark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'LANCR',
          style: TextStyle(
            fontSize: size * 0.22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}
