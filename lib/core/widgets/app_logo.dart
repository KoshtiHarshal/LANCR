// lib/core/widgets/app_logo.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Theme-aware LANCR logo, used everywhere in the app (auth, splash, headers).
///
/// Shows the pre-bordered brand artwork — `splash_light.png` in light mode and
/// `splash_dark.png` in dark mode. The mint border and rounded corners are
/// baked into the PNGs, so this widget just renders the correct one. The same
/// artwork (padded variant) is used for the native splash screen.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final asset = AppColors.isDark
        ? 'assets/branding/splash_dark.png'
        : 'assets/branding/splash_light.png';

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
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
