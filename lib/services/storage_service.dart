// lib/services/storage_service.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {

  final String _cloudName = "dpwh49fxd";
  final String _uploadPreset = "z1rvuhsd";

  late final CloudinaryPublic _cloudinary;

  StorageService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// --- NEW FUNCTION: Picks ONLY images for profile pictures ---
  Future<File?> pickProfileImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, // This automatically restricts to common image formats
        // You could also use: type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg']
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      } else {
        // User canceled the picker
        return null;
      }
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  /// Uploads any file (image, pdf, etc.) and returns the secure URL
  Future<String> uploadFile(File file) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Auto),
      );

      return response.secureUrl;

    } catch (e) {
      print("Error uploading file: $e");
      rethrow;
    }
  }
}