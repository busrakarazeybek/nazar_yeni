import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/message.dart';

class ModernMessageBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String? partnerImageUrl;
  final VoidCallback? onLongPress;

  const ModernMessageBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
    this.partnerImageUrl,
    this.onLongPress,
  });

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAvatar() {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.grey[300],
        backgroundImage: partnerImageUrl?.isNotEmpty == true
            ? NetworkImage(partnerImageUrl!)
            : null,
        child: partnerImageUrl?.isEmpty ?? true
            ? Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 4.w,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 3.w,
          vertical: 0.5.h,
        ),
        child: Row(
          mainAxisAlignment: isMe 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              if (showAvatar)
                _buildAvatar()
              else
                SizedBox(width: 10.w), // Spacing for non-avatar messages
              SizedBox(width: 2.w),
              _buildReceivedMessage(),
            ],
            if (isMe) _buildSentMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage() {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(maxWidth: 65.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[50]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.senderName != null) ...[
                    Text(
                      message.senderName!,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 0.3.h),
            Padding(
              padding: EdgeInsets.only(left: 1.w),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 8.sp,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentMessage() {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(maxWidth: 65.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF5A52F5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C63FF).withAlpha(38),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 0.3.h),
            Padding(
              padding: EdgeInsets.only(right: 1.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 0.5.w),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12.sp,
                    color: message.isRead 
                        ? Colors.blue[600] 
                        : Colors.grey[500],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}