import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  ImageUtils._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick a single image from gallery
  static Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
  }

  /// Pick image from camera
  static Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
  }

  /// Pick multiple images from gallery
  static Future<List<XFile>> pickMultipleFromGallery({int maxImages = 5}) async {
    final images = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (images.length > maxImages) {
      return images.sublist(0, maxImages);
    }
    return images;
  }

  /// Compress image bytes
  static Future<Uint8List?> compressImage(Uint8List imageBytes) async {
    final result = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 800,
      minHeight: 800,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// Compress image file
  static Future<XFile?> compressImageFile(String path) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      '${path}_compressed.jpg',
      minWidth: 800,
      minHeight: 800,
      quality: 75,
    );
    return result;
  }
}
