import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChatHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> matchPartner;
  final VoidCallback onBackPressed;
  final VoidCallback onMorePressed;

  const ChatHeaderWidget({
    super.key,
    required this.matchPartner,
    required this.onBackPressed,
    required this.onMorePressed,
  });

  String _getLastSeenText() {
    if (matchPartner['isOnline'] == true) {
      return 'Çevrimiçi';
    }

    final DateTime lastSeen = matchPartner['lastSeen'] as DateTime;
    final Duration difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Az önce görüldü';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce görüldü';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce görüldü';
    } else {
      return '${difference.inDays} gün önce görüldü';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: onBackPressed,
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'arrow_back',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),

          SizedBox(width: 2.w),

          // Profile Image with Online Status
          Stack(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: matchPartner['profileImage'] ?? '',
                    width: 12.w,
                    height: 12.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (matchPartner['isOnline'] == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(width: 3.w),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchPartner['name'] ?? 'Bilinmeyen Kullanıcı',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _getLastSeenText(),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: matchPartner['isOnline'] == true
                        ? AppTheme.successColor
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // More Options Button
          GestureDetector(
            onTap: onMorePressed,
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'more_vert',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
