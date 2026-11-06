import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final imageCaptureServiceProvider = Provider<ImageCaptureService>((ref) => ImageCaptureService(ImagePicker()));

/// Camera and gallery access. Images are resized and compressed to JPEG
/// because the backend's upload URLs are created for `image/jpeg`.
class ImageCaptureService {
  ImageCaptureService(this._picker);

  final ImagePicker _picker;

  Future<Uint8List?> takeSelfie() => _pick(ImageSource.camera, front: true);

  Future<Uint8List?> takePhoto() => _pick(ImageSource.camera);

  Future<Uint8List?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<Uint8List?> _pick(ImageSource source, {bool front = false}) async {
    final file = await _picker.pickImage(
      source: source,
      preferredCameraDevice: front ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    return file?.readAsBytes();
  }
}
