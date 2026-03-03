import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/image_utils.dart';
import '../core/constants/firestore_paths.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload post image and return download URL
  Future<String> uploadPostImage(String postId, XFile file, int index) async {
    final bytes = await file.readAsBytes();
    final compressed = await ImageUtils.compressImage(bytes);
    final data = compressed ?? bytes;

    final ref = _storage
        .ref()
        .child(FirestorePaths.postImages(postId))
        .child('image_$index.jpg');

    final uploadTask = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload multiple post images
  Future<List<String>> uploadPostImages(String postId, List<XFile> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final url = await uploadPostImage(postId, files[i], i);
      urls.add(url);
    }
    return urls;
  }

  /// Upload user avatar
  Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final compressed = await ImageUtils.compressImage(bytes);
    final data = compressed ?? bytes;

    final ref = _storage
        .ref()
        .child(FirestorePaths.userAvatar(uid))
        .child('avatar.jpg');

    final uploadTask = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete all images for a post
  Future<void> deletePostImages(String postId) async {
    try {
      final ref = _storage.ref().child(FirestorePaths.postImages(postId));
      final listResult = await ref.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {
      // Ignore if folder doesn't exist
    }
  }

  /// Upload brand image and return download URL
  Future<String> uploadBrandImage(String brandId, XFile file) async {
    final bytes = await file.readAsBytes();
    final compressed = await ImageUtils.compressImage(bytes);
    final data = compressed ?? bytes;

    final ref = _storage
        .ref()
        .child(FirestorePaths.brandImage(brandId))
        .child('logo.jpg');

    final uploadTask = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload banner image and return download URL
  Future<String> uploadBannerImage(String bannerId, XFile file) async {
    final bytes = await file.readAsBytes();
    final compressed = await ImageUtils.compressImage(bytes);
    final data = compressed ?? bytes;

    final ref = _storage
        .ref()
        .child(FirestorePaths.bannerImage(bannerId))
        .child('image.jpg');

    final uploadTask = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload section item image and return download URL
  Future<String> uploadSectionItemImage(String sectionId, int index, XFile file) async {
    final bytes = await file.readAsBytes();
    final compressed = await ImageUtils.compressImage(bytes);
    final data = compressed ?? bytes;

    final ref = _storage
        .ref()
        .child(FirestorePaths.sectionItemImage(sectionId, index))
        .child('image.jpg');

    final uploadTask = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete banner image
  Future<void> deleteBannerImage(String bannerId) async {
    try {
      final ref = _storage.ref().child(FirestorePaths.bannerImage(bannerId));
      final listResult = await ref.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (_) {
      // Ignore if folder doesn't exist
    }
  }
}
