import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SelectorProfilePhotoSectionWidget extends StatelessWidget {
  final String? imagePath;
  final Function(String?) onImageSelected;

  const SelectorProfilePhotoSectionWidget({
    super.key,
    this.imagePath,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Fotoğrafı',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Seçici olarak güven oluşturmak için profil fotoğrafınızı ekleyin (isteğe bağlı)',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        Center(
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Stack(
              children: [
                Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.w),
                          child: Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'photo_camera',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 32.w,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Fotoğraf\nEkle',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
                if (imagePath != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onImageSelected(null),
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: CustomIconWidget(
                          iconName: 'close',
                          color: Colors.white,
                          size: 12.w,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    // For now, simulate selecting a default selector image
    // In a real app, this would show camera/gallery options
    final defaultImages = [
      'assets/images/no-image.jpg',
      'assets/images/no-image.jpg',
      'assets/images/no-image.jpg',
    ];

    // Simulate selecting first default image
    onImageSelected(defaultImages.first);
  }
}
