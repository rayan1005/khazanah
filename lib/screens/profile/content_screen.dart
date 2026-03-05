import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_settings_provider.dart';

/// Reusable screen for terms & conditions and privacy policy
class ContentScreen extends ConsumerWidget {
  final String title;
  final String Function(dynamic settings) contentSelector;

  const ContentScreen({
    super.key,
    required this.title,
    required this.contentSelector,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (settings) {
          final content = contentSelector(settings);
          if (content.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text(
                    'لا يوجد محتوى حالياً',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                color: AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}
