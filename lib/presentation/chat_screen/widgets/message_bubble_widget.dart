import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onLongPress;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.onLongPress,
  });

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSent = message['isSent'] as bool;
    final bool isRead = message['isRead'] as bool;
    final DateTime timestamp = message['timestamp'] as DateTime;
    final String messageText = message['message'] as String;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 0.5.h),
        child: Row(
          mainAxisAlignment:
              isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSent) ...[
              // Receiver's message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 75.w),
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: const Radius.circular(4),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _formatTime(timestamp),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Sender's message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 75.w),
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        messageText,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(timestamp),
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary
                                  .withValues(alpha: 0.8),
                              fontSize: 10.sp,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          CustomIconWidget(
                            iconName: isRead ? 'done_all' : 'done',
                            color: isRead
                                ? AppTheme.successColor
                                : AppTheme.lightTheme.colorScheme.onPrimary
                                    .withValues(alpha: 0.8),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
