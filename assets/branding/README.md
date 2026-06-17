# Branding assets

Drop your two theme logo/illustration PNGs here with these **exact** names:

- `lancr_light.png` — used in **light** theme (your light/cream-background artwork)
- `lancr_dark.png` — used in **dark** theme (your dark/black-background artwork)

They are shown on the splash screen and the login/register headers via
`AppLogo` (lib/core/widgets/app_logo.dart), which picks the right one for the
active theme. Until the files exist, a styled "LANCR" text fallback is shown.

Recommended: square-ish PNG, ≥1024px, transparent or theme-matching background.
