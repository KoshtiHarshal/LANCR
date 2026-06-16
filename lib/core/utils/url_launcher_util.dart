// lib/core/utils/url_launcher_util.dart

import 'package:url_launcher/url_launcher.dart';

/// Opens [raw] in an external browser, prepending https:// when no scheme is
/// present. Returns false if it couldn't be launched.
Future<bool> openExternalLink(String raw) async {
  var value = raw.trim();
  if (value.isEmpty) return false;
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'https://$value';
  }
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
