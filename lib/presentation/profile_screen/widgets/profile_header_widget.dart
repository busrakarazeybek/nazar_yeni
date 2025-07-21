import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onImageChanged;

  const ProfileHeaderWidget({
    super.key,
    required this.userData,
    required this.onImageChanged,
  });

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
                  _buildImageOption(
                    context,
                    'Kamera',
                    'camera_alt',
                    () {
                      Navigator.pop(context);
                      onImageChanged();
                    },
                  ),
                  _buildImageOption(
                    context,
                    'Galeri',
                    'photo_library',
                    () {
                      Navigator.pop(context);
                      onImageChanged();
                    },
                  ),
                  _buildImageOption(
                    context,
                    'Kaldır',
                    'delete',
                    () {
                      Navigator.pop(context);
                      onImageChanged();
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
                  child: userData["profileImage"] != null
                      ? CustomImageWidget(
                          imageUrl: userData["profileImage"] as String,
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
                  onTap: () => _showImagePickerOptions(context),
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.cardColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
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
            userData["name"] as String? ?? 'İsim Belirtilmemiş',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${userData["age"] ?? 0} yaşında',
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
