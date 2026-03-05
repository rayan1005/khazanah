import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/boutique_provider.dart';
import '../../models/user_model.dart';

class BoutiquesScreen extends ConsumerWidget {
  const BoutiquesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boutiquesAsync = ref.watch(boutiquesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.boutiques),
      ),
      body: boutiquesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (boutiques) {
          if (boutiques.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.noBoutiques,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: boutiques.length,
            itemBuilder: (context, index) {
              return _BoutiqueFullWidthCard(boutique: boutiques[index]);
            },
          );
        },
      ),
    );
  }
}

class _BoutiqueFullWidthCard extends StatelessWidget {
  final UserModel boutique;
  const _BoutiqueFullWidthCard({required this.boutique});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/boutique/${boutique.uid}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    boutique.boutiqueCover != null
                        ? CachedNetworkImage(
                            imageUrl: boutique.boutiqueCover!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.storefront,
                                  color: AppColors.primary, size: 48),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.15),
                                  AppColors.primary.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(Icons.storefront,
                                color: AppColors.primary, size: 48),
                          ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Verified badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'معتمد',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Visit store button
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.visitStore,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_back_ios,
                                size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Logo
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: boutique.boutiqueLogo != null
                          ? CachedNetworkImageProvider(boutique.boutiqueLogo!)
                          : null,
                      child: boutique.boutiqueLogo == null
                          ? Icon(Icons.store,
                              size: 22, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Name + Description + City
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  boutique.boutiqueName ?? boutique.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.verified,
                                  size: 16, color: AppColors.info),
                            ],
                          ),
                          if (boutique.boutiqueDescription != null &&
                              boutique.boutiqueDescription!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                boutique.boutiqueDescription!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          if (boutique.city.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 12, color: AppColors.textHint),
                                  const SizedBox(width: 2),
                                  Text(
                                    boutique.city,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Social icons preview
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (boutique.showInstagram &&
                            boutique.instagramUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.camera_alt,
                                size: 16,
                                color: const Color(0xFFE1306C)
                                    .withValues(alpha: 0.6)),
                          ),
                        if (boutique.showMaaroof && boutique.maaroofUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_user,
                                size: 16,
                                color: const Color(0xFF2E7D32)
                                    .withValues(alpha: 0.6)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
