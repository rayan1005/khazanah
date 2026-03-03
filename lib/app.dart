import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';

class KhazanahApp extends ConsumerWidget {
  const KhazanahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeColor = ref.watch(themeColorProvider);

    return MaterialApp.router(
      title: 'خزانة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(themeColor),
      routerConfig: router,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
