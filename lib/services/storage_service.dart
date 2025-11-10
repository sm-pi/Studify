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

  /// Picks ONLY images for profile pictures
  Future<File?> pickProfileImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      } else {
        return null;
      }
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  /// --- NEW FUNCTION ---
  /// Picks an image or PDF for a post.
  /// Returns the File, File Name, and File Type
  Future<Map<String, dynamic>?> pickPostAttachment(bool pickImage) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: pickImage ? FileType.image : FileType.custom,
        allowedExtensions: pickImage ? null : ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return {
          'file': File(result.files.single.path!),
          'fileName': result.files.single.name,
          'fileType': pickImage ? 'image' : 'pdf',
        };
      } else {
        return null;
      }
    } catch (e) {
      print("Error picking attachment: $e");
      return null;
    }
  }

  /// Uploads any file and returns the secure URL
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