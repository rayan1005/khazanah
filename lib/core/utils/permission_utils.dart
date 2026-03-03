import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

class PermissionUtils {
  PermissionUtils._();

  /// Request camera permission with Arabic explanation dialog
  static Future<bool> requestCamera(BuildContext context) async {
    if (kIsWeb) return true;
    return _requestPermission(
      context,
      Permission.camera,
      AppStrings.cameraPermissionTitle,
      AppStrings.cameraPermissionMessage,
      Icons.camera_alt_rounded,
    );
  }

  /// Request photo library permission with Arabic explanation dialog
  static Future<bool> requestPhotos(BuildContext context) async {
    if (kIsWeb) return true;
    final permission = Platform.isAndroid
        ? Permission.photos
        : Permission.photos;
    return _requestPermission(
      context,
      permission,
      AppStrings.galleryPermissionTitle,
      AppStrings.galleryPermissionMessage,
      Icons.photo_library_rounded,
    );
  }

  /// Request location permission with Arabic explanation dialog
  static Future<bool> requestLocation(BuildContext context) async {
    if (kIsWeb) return true;
    return _requestPermission(
      context,
      Permission.locationWhenInUse,
      AppStrings.locationPermissionTitle,
      AppStrings.locationPermissionMessage,
      Icons.location_on_rounded,
    );
  }

  /// Request notification permission with Arabic explanation dialog
  static Future<bool> requestNotification(BuildContext context) async {
    if (kIsWeb) return true;
    return _requestPermission(
      context,
      Permission.notification,
      AppStrings.notificationPermissionTitle,
      AppStrings.notificationPermissionMessage,
      Icons.notifications_rounded,
    );
  }

  /// Generic permission request with Arabic explanation dialog shown first
  static Future<bool> _requestPermission(
    BuildContext context,
    Permission permission,
    String title,
    String message,
    IconData icon,
  ) async {
    final status = await permission.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context);
      }
      return false;
    }

    // Show Arabic explanation dialog BEFORE system prompt
    if (context.mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(AppStrings.ok),
              ),
            ],
          ),
        ),
      );

      if (shouldRequest != true) return false;
    }

    final result = await permission.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied && context.mounted) {
      _showSettingsDialog(context);
    }
    return false;
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(AppStrings.permissionDenied),
          content: const Text(
            'يمكنك تفعيل الإذن من إعدادات التطبيق',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text(AppStrings.openSettings),
            ),
          ],
        ),
      ),
    );
  }
}
