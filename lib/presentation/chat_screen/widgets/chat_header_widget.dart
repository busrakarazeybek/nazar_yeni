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
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: onBackPressed,
            child: Container(
              padding: EdgeInsets.all(1.5.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'arrow_back',
                color: Colors.grey[700]!,
                size: 18,
              ),
            ),
          ),

          SizedBox(width: 1.5.w),

          // Profile Image with Online Status
          Stack(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF9C27B0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6C63FF).withAlpha(51),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(0.5.w),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: matchPartner['profileImage'] ?? '',
                      width: 11.w,
                      height: 11.w,
                      fit: BoxFit.cover,
                    ),
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
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00E676).withAlpha(77),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(width: 2.w),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchPartner['name'] ?? 'Bilinmeyen Kullanıcı',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Container(
                      width: 1.5.w,
                      height: 1.5.w,
                      decoration: BoxDecoration(
                        color: matchPartner['isOnline'] == true
                            ? Color(0xFF00E676)
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      _getLastSeenText(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: matchPartner['isOnline'] == true
                            ? Color(0xFF00E676)
                            : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // More Options Button
          GestureDetector(
            onTap: onMorePressed,
            child: Container(
              padding: EdgeInsets.all(1.5.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'more_vert',
                color: Colors.grey[700]!,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
