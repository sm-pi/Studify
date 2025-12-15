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
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  /// Picks an image or PDF
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
      }
      return null;
    } catch (e) {
      print("Error picking attachment: $e");
      return null;
    }
  }

  /// --- THE FIX: Force everything to be 'Image' type ---
  Future<String> uploadFile(File file, String fileType) async {
    try {
      // TRICK: We set resourceType to 'Image' even for PDFs.
      // This tells Cloudinary to treat the PDF as a visual document (Public).
      // If we use 'Raw', it becomes Private (401 Error).
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
            file.path,
            resourceType: CloudinaryResourceType.Image, // <--- FORCE IMAGE TYPE
            folder: "studify_files"
        ),
      );

      // FORCE HTTPS (Android requires this)
      String secureUrl = response.secureUrl;
      if (secureUrl.startsWith("http://")) {
        secureUrl = secureUrl.replaceFirst("http://", "https://");
      }

      print("✅ Cloudinary Upload Success ($fileType): $secureUrl");
      return secureUrl;

    } catch (e) {
      print("❌ Cloudinary Upload Error: $e");
      // Fallback: If 'Image' type fails for some PDF (rare), try 'Auto'
      try {
        print("⚠️ Retrying with Auto type...");
        CloudinaryResponse response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
              file.path,
              resourceType: CloudinaryResourceType.Auto,
              folder: "studify_files"
          ),
        );
        return response.secureUrl;
      } catch (retryError) {
        print("❌ Retry failed: $retryError");
        rethrow;
      }
    }
  }
}