import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import './supabase_service.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService();

  // Storage buckets
  static const String profileImagesBucket = 'profile-images';
  static const String chatImagesBucket = 'chat-images';
  static const String galleryImagesBucket = 'gallery-images';

  /// Initialize storage buckets (call this once during app setup)
  Future<void> initializeStorage() async {
    try {
      final client = await _supabaseService.client;
      final storage = client.storage;

      // Create buckets if they don't exist
      final buckets = [
        profileImagesBucket,
        chatImagesBucket,
        galleryImagesBucket,
      ];

      for (final bucketName in buckets) {
        try {
          // Try to get bucket info, if fails then create it
          await storage.getBucket(bucketName);
        } catch (e) {
          // Bucket doesn't exist, create it
          await storage.createBucket(bucketName);
          print('Created storage bucket: $bucketName');
        }
      }
    } catch (e) {
      print('Error initializing storage: $e');
    }
  }

  /// Request camera and gallery permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      // Web doesn't need explicit permissions
      return true;
    }

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      
      // Request photos/storage permission based on platform
      PermissionStatus storageStatus;
      if (Platform.isAndroid) {
        // Android 13+ uses different permissions
        if (await _isAndroid13OrHigher()) {
          storageStatus = await Permission.photos.request();
        } else {
          storageStatus = await Permission.storage.request();
        }
      } else {
        // iOS
        storageStatus = await Permission.photos.request();
      }

      return cameraStatus.isGranted && storageStatus.isGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Simple check - if photos permission exists, we're on Android 13+
      final status = await Permission.photos.status;
      return status != PermissionStatus.permanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Wrap(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Resim Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: Colors.blue),
                  title: Text('Kamera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green),
                  title: Text('Galeri'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('İptal'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pick image from camera or gallery
  Future<XFile?> pickImage({
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    bool requestFullMetadata = false,
  }) async {
    try {
      // Check permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Kamera ve galeri izinleri gerekli');
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? 85,
        requestFullMetadata: requestFullMetadata,
      );

      return pickedFile;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>?> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = false,
  }) async {
    try {
      // Check permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Galeri izni gerekli');
      }

      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? 85,
        requestFullMetadata: requestFullMetadata,
        limit: limit,
      );

      return pickedFiles;
    } catch (e) {
      print('Error picking multiple images: $e');
      rethrow;
    }
  }

  /// Upload image to Supabase storage
  Future<String> uploadImage({
    required XFile imageFile,
    required String bucketName,
    required String fileName,
    String? userId,
    Function(double)? onProgress,
  }) async {
    try {
      final client = await _supabaseService.client;
      final storage = client.storage.from(bucketName);

      // Create file path with user ID if provided
      final filePath = userId != null 
          ? '$userId/$fileName'
          : fileName;

      Uint8List imageBytes;
      
      if (kIsWeb) {
        // For web, read as bytes
        imageBytes = await imageFile.readAsBytes();
      } else {
        // For mobile, read from file
        final file = File(imageFile.path);
        imageBytes = await file.readAsBytes();
      }

      // Upload with progress tracking
      final uploadResult = await storage.uploadBinary(
        filePath,
        imageBytes,
      );

      // Get public URL
      final publicUrl = storage.getPublicUrl(filePath);
      
      print('Image uploaded successfully: $publicUrl');
      return publicUrl;

    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage({
    required XFile imageFile,
    required String userId,
    Function(double)? onProgress,
  }) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    return await uploadImage(
      imageFile: imageFile,
      bucketName: profileImagesBucket,
      fileName: fileName,
      userId: userId,
      onProgress: onProgress,
    );
  }

  /// Upload chat image
  Future<String> uploadChatImage({
    required XFile imageFile,
    required String userId,
    required String chatId,
    Function(double)? onProgress,
  }) async {
    final fileName = 'chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    return await uploadImage(
      imageFile: imageFile,
      bucketName: chatImagesBucket,
      fileName: fileName,
      userId: userId,
      onProgress: onProgress,
    );
  }

  /// Upload gallery image
  Future<String> uploadGalleryImage({
    required XFile imageFile,
    required String userId,
    Function(double)? onProgress,
  }) async {
    final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    return await uploadImage(
      imageFile: imageFile,
      bucketName: galleryImagesBucket,
      fileName: fileName,
      userId: userId,
      onProgress: onProgress,
    );
  }

  /// Upload multiple gallery images
  Future<List<String>> uploadMultipleGalleryImages({
    required List<XFile> imageFiles,
    required String userId,
    Function(double)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadGalleryImage(
          imageFile: imageFiles[i],
          userId: userId,
          onProgress: onProgress != null 
              ? (progress) => onProgress((i + progress) / imageFiles.length)
              : null,
        );
        uploadedUrls.add(url);
      } catch (e) {
        print('Error uploading image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }
    
    return uploadedUrls;
  }

  /// Delete image from storage
  Future<void> deleteImage({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      final client = await _supabaseService.client;
      final storage = client.storage.from(bucketName);

      await storage.remove([filePath]);
      print('Image deleted successfully: $filePath');
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }

  /// Delete user's profile image
  Future<void> deleteProfileImage({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the file path after the bucket name
      final bucketIndex = pathSegments.indexOf(profileImagesBucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await deleteImage(
          bucketName: profileImagesBucket,
          filePath: filePath,
        );
      }
    } catch (e) {
      print('Error deleting profile image: $e');
      rethrow;
    }
  }

  /// Get image file size
  Future<int> getImageSize(XFile imageFile) async {
    try {
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        return bytes.length;
      } else {
        final file = File(imageFile.path);
        return await file.length();
      }
    } catch (e) {
      print('Error getting image size: $e');
      return 0;
    }
  }

  /// Validate image file
  Future<bool> validateImage(XFile imageFile) async {
    try {
      // Check file size (5MB limit)
      const maxSizeBytes = 5 * 1024 * 1024; // 5MB
      final fileSize = await getImageSize(imageFile);
      
      if (fileSize > maxSizeBytes) {
        throw Exception('Dosya boyutu 5MB\'dan büyük olamaz');
      }

      // Check file type
      final fileName = imageFile.name.toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      
      final hasValidExtension = allowedExtensions.any(
        (ext) => fileName.endsWith(ext),
      );
      
      if (!hasValidExtension) {
        throw Exception('Sadece JPG, PNG ve WebP formatları desteklenmektedir');
      }

      return true;
    } catch (e) {
      print('Image validation failed: $e');
      rethrow;
    }
  }

  /// Compress image if needed
  Future<XFile?> compressImage(XFile imageFile) async {
    try {
      // For now, we'll use the image picker's built-in compression
      // You can integrate with packages like flutter_image_compress for more control
      
      final fileSize = await getImageSize(imageFile);
      const targetSize = 1 * 1024 * 1024; // 1MB target
      
      if (fileSize <= targetSize) {
        return imageFile; // No compression needed
      }

      // Calculate quality based on file size
      int quality = ((targetSize / fileSize) * 100).round();
      quality = quality.clamp(10, 85); // Ensure reasonable quality range

      // Re-pick with lower quality
      final source = imageFile.path.contains('camera') 
          ? ImageSource.camera 
          : ImageSource.gallery;

      return await _imagePicker.pickImage(
        source: source,
        imageQuality: quality,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      print('Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Update user profile image in database
  Future<void> updateUserProfileImage({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      final client = await _supabaseService.client;
      
      await client
          .from('user_profiles')
          .update({'image_url': imageUrl})
          .eq('id', userId);
          
      print('User profile image updated in database');
    } catch (e) {
      print('Error updating user profile image: $e');
      rethrow;
    }
  }

  /// Add image to user gallery
  Future<void> addToUserGallery({
    required String userId,
    required String imageUrl,
    String? caption,
  }) async {
    try {
      final client = await _supabaseService.client;
      
      await client.from('user_gallery').insert({
        'user_id': userId,
        'image_url': imageUrl,
        'caption': caption,
        'created_at': DateTime.now().toIso8601String(),
      });
          
      print('Image added to user gallery');
    } catch (e) {
      print('Error adding image to gallery: $e');
      rethrow;
    }
  }

  /// Get user gallery images
  Future<List<Map<String, dynamic>>> getUserGallery(String userId) async {
    try {
      final client = await _supabaseService.client;
      
      final response = await client
          .from('user_gallery')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user gallery: $e');
      return [];
    }
  }

  /// Remove image from user gallery
  Future<void> removeFromUserGallery({
    required String userId,
    required String imageId,
  }) async {
    try {
      final client = await _supabaseService.client;
      
      await client
          .from('user_gallery')
          .delete()
          .eq('id', imageId)
          .eq('user_id', userId);
          
      print('Image removed from user gallery');
    } catch (e) {
      print('Error removing image from gallery: $e');
      rethrow;
    }
  }
}