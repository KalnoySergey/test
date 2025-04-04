import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class CameraUseCase {
  Future<XFile?> pickImageFromGallery() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }

  Future<void> savePhoto(XFile image) async {
    try {
      final newPath = "/storage/emulated/0/DCIM/Camera/${DateTime.now().millisecondsSinceEpoch}.jpg";
      final newFile = await File(image.path).copy(newPath);
      final intent = AndroidIntent(
        action: 'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        data: Uri.file(newFile.path).toString(),
        flags: <int>[Flag.FLAG_GRANT_READ_URI_PERMISSION],
      );
      await intent.launch();
      print("Photo saved to MediaStore: ${newFile.path}");
    } catch (e) {
      print("Error saving photo to MediaStore: $e");
    }
  }

  Future<void> saveVideo(XFile video) async {
    try {
      final newPath = "/storage/emulated/0/DCIM/Camera/${DateTime.now().millisecondsSinceEpoch}.mp4";
      final newFile = await File(video.path).copy(newPath);
      print("Video saved to MediaStore: ${newFile.path}");
    } catch (e) {
      print("Error saving video to MediaStore: $e");
    }
  }
}
