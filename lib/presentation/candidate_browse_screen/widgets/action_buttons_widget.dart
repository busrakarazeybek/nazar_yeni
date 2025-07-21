import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onLike;
  final bool isEnabled;

  const ActionButtonsWidget({
    super.key,
    required this.onPass,
    required this.onLike,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          GestureDetector(
            onTap: isEnabled ? onPass : null,
            child: Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'close',
                  color: isEnabled
                      ? AppTheme.errorColor
                      : AppTheme.errorColor.withValues(alpha: 0.5),
                  size: 7.w,
                ),
              ),
            ),
          ),

          // Super like button (optional)
          GestureDetector(
            onTap: isEnabled
                ? () {
                    // Handle super like
                    onLike();
                  }
                : null,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'star',
                  color: isEnabled
                      ? AppTheme.accentColor
                      : AppTheme.accentColor.withValues(alpha: 0.5),
                  size: 5.w,
                ),
              ),
            ),
          ),

          // Like button
          GestureDetector(
            onTap: isEnabled ? onLike : null,
            child: Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'favorite',
                  color: isEnabled
                      ? AppTheme.successColor
                      : AppTheme.successColor.withValues(alpha: 0.5),
                  size: 7.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
