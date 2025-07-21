import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfilePhotoSectionWidget extends StatelessWidget {
  final String? imagePath;
  final Function(String?) onImageSelected;

  const ProfilePhotoSectionWidget({
    super.key,
    this.imagePath,
    required this.onImageSelected,
  });

  void _showImagePickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 2.h),

            Text(
              'Profil Fotoğrafı Seç',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 3.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera option
                _buildImageSourceOption(
                  context: context,
                  icon: 'camera_alt',
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    // Simulate camera capture
                    onImageSelected('camera_image_path');
                  },
                ),

                // Gallery option
                _buildImageSourceOption(
                  context: context,
                  icon: 'photo_library',
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    // Simulate gallery selection
                    onImageSelected(
                        'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png');
                  },
                ),
              ],
            ),

            SizedBox(height: 2.h),

            if (imagePath != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onImageSelected(null);
                },
                child: Text(
                  'Fotoğrafı Kaldır',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 25.w,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Profil Fotoğrafı',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: () => _showImagePickerBottomSheet(context),
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: imagePath != null
                ? ClipOval(
                    child: imagePath!.startsWith('http')
                        ? CustomImageWidget(
                            imageUrl: imagePath!,
                            width: 30.w,
                            height: 30.w,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 30.w,
                            height: 30.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                            ),
                            child: CustomIconWidget(
                              iconName: 'person',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 40,
                            ),
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'add_a_photo',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 32,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Fotoğraf\nEkle',
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Profil fotoğrafınızı eklemek için dokunun',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
