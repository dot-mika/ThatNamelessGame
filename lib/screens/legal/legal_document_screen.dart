import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/audio_controller.dart';
import '../../config/app_language.dart';
import '../../config/config.dart';
import '../../settings/settings_notifier.dart';

/// An in-app reader for legal documents bundled with the application.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({
    super.key,
    required this.documentBaseName,
  });

  final String documentBaseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appSettingsProvider).language;
    final asset = documentBaseName == 'license'
        ? language == AppLanguage.jp
              ? 'LICENSE.ja.md'
              : 'LICENSE'
        : 'docs/${documentBaseName}_${language.name}.md';
    final title = documentBaseName == 'privacy_policy'
        ? AppStrings.privacyPolicy(language)
        : AppStrings.license(language);

    return Scaffold(
      key: Key('${documentBaseName}Screen'),
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 22, 24, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.settingsBlack,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: TextButton.icon(
                      key: const Key('legalBackButton'),
                      onPressed: () {
                        ref.playTapSound();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back, size: 22),
                      label: Text(AppStrings.settingsTitle(language)),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerRight,
                        foregroundColor: AppColors.settingsBlack,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 22, height: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.settingsBlack),
            Expanded(
              child: FutureBuilder<String>(
                future: rootBundle.loadString(asset),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        language == AppLanguage.jp
                            ? '文書を読み込めませんでした。'
                            : 'The document could not be loaded.',
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _MarkdownDocument(markdown: snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownDocument extends StatelessWidget {
  const _MarkdownDocument({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split('\n');
    return Scrollbar(
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'sans-serif'),
        child: ListView.builder(
          key: const Key('legalDocumentScrollView'),
          padding: const EdgeInsets.fromLTRB(52, 28, 52, 42),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final line = lines[index];
            if (line.isEmpty) return const SizedBox(height: 12);
            final isTitle = line.startsWith('# ');
            final isHeading = line.startsWith('## ');
            final isBullet = line.startsWith('- ');
            final text = isTitle || isHeading
                ? line.substring(isTitle ? 2 : 3)
                : isBullet
                ? '• ${line.substring(2)}'
                : line;
            return Padding(
              padding: EdgeInsets.only(bottom: isHeading ? 10 : 4),
              child: Text(
                text,
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontSize: isTitle ? 34 : isHeading ? 25 : 20,
                  fontWeight: isTitle || isHeading
                      ? FontWeight.bold
                      : FontWeight.normal,
                  height: 1.45,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
