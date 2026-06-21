// lib/features/legal/presentation/legal_page.dart
//
// Renders a bundled Markdown document (privacy policy / terms) in-app, so users
// can read it without leaving the app. The same files are hosted publicly for
// the Play Store listing. Minimal Markdown support: # / ## headings, **bold**,
// and "- " bullets — enough for our documents (no extra dependency).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/theme/app_colors.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalPage({super.key, required this.title, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text('Could not load document',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          if (!snap.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: _render(snap.data!),
          );
        },
      ),
    );
  }

  List<Widget> _render(String markdown) {
    final widgets = <Widget>[];
    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            line.substring(2),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line.substring(3),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ',
                  style: TextStyle(
                      color: AppColors.textSecondary, height: 1.6)),
              Expanded(child: _rich(line.substring(2))),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _rich(line),
        ));
      }
    }
    return widgets;
  }

  // Renders a line, bolding text wrapped in **double asterisks**.
  Widget _rich(String text) {
    final parts = text.split('**');
    final spans = <TextSpan>[
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
            color: i.isOdd ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
    ];
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
        children: spans,
      ),
    );
  }
}
