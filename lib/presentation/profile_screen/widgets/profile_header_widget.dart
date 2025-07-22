import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onImageChanged;

  const ProfileHeaderWidget({
    super.key,
    required this.userData,
    required this.onImageChanged,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        await _uploadImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Kamera erişiminde hata: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        print('DEBUG: Selected image: ${image.name}, path: ${image.path}');
        await _uploadImage(image);
      } else {
        print('DEBUG: No image selected');
      }
    } catch (e) {
      print('DEBUG: Gallery picker error: $e');
      _showErrorSnackBar('${kIsWeb ? 'Dosya' : 'Galeri'} seçiminde hata: $e');
    }
  }

  Future<void> _uploadImage(XFile imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser == null) {
        _showErrorSnackBar('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Upload to Supabase Storage
      final supabase = await SupabaseService().client;
      final fileName = '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Get bytes differently for web and mobile
      late Uint8List bytes;
      if (kIsWeb) {
        // For web platform
        final webBytes = await imageFile.readAsBytes();
        bytes = Uint8List.fromList(webBytes);
      } else {
        // For mobile platforms
        final file = File(imageFile.path);
        final mobileBytes = await file.readAsBytes();
        bytes = Uint8List.fromList(mobileBytes);
      }
      
      final storageResponse = await supabase.storage
          .from('profile-images')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final imageUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      // Update user profile in database
      await supabase
          .from('user_profiles')
          .update({'image_url': imageUrl})
          .eq('id', currentUser.id);

      // Update local data
      setState(() {
        widget.userData['profileImage'] = imageUrl;
      });

      // Refresh auth provider
      await authProvider.refreshUserProfile();
      
      widget.onImageChanged();
      _showSuccessSnackBar('Profil fotoğrafı başarıyla güncellendi');
      
    } catch (e) {
      _showErrorSnackBar('Fotoğraf yüklenemedi: $e');
      print('DEBUG: Upload error: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser == null) {
        _showErrorSnackBar('Kullanıcı oturumu bulunamadı');
        return;
      }

      // Update user profile in database (remove image URL)
      final supabase = await SupabaseService().client;
      await supabase
          .from('user_profiles')
          .update({'image_url': null})
          .eq('id', currentUser.id);

      // Update local data
      setState(() {
        widget.userData['profileImage'] = null;
      });

      // Refresh auth provider
      await authProvider.refreshUserProfile();
      
      widget.onImageChanged();
      _showSuccessSnackBar('Profil fotoğrafı kaldırıldı');
      
    } catch (e) {
      _showErrorSnackBar('Fotoğraf kaldırılamadı: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Profil Fotoğrafını Değiştir',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Only show camera option on mobile
                  if (!kIsWeb)
                    _buildImageOption(
                      context,
                      'Kamera',
                      'camera_alt',
                      () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                  _buildImageOption(
                    context,
                    kIsWeb ? 'Dosya Seç' : 'Galeri',
                    'photo_library',
                    () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  _buildImageOption(
                    context,
                    'Kaldır',
                    'delete',
                    () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
                ],
              ),
              SizedBox(height: 4.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption(
    BuildContext context,
    String title,
    String iconName,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.primaryColor,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: widget.userData["profileImage"] != null
                      ? CustomImageWidget(
                          imageUrl: widget.userData["profileImage"] as String,
                          width: 30.w,
                          height: 30.w,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.secondaryLight,
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'person',
                              color: AppTheme.textSecondaryLight,
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : () => _showImagePickerOptions(context),
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: _isUploading ? Colors.grey : AppTheme.lightTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.cardColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: _isUploading
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.lightTheme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : CustomIconWidget(
                              iconName: 'edit',
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              size: 16,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.userData["name"] as String? ?? 'İsim Belirtilmemiş',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${widget.userData["age"] ?? 0} yaşında',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
