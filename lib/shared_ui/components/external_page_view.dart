import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalPageWithFallback(
  BuildContext context, {
  required String title,
  required String url,
}) async {
  final uri = Uri.parse(url);
  for (final mode in const [
    LaunchMode.externalApplication,
    LaunchMode.platformDefault,
  ]) {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (launched) {
        return;
      }
    } catch (_) {
      // Some Android builds throw instead of returning false when no handler is available.
    }
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Could not open $title in a browser.')),
  );
}
