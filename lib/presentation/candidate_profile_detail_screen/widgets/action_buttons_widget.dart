import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onPassPressed;
  final VoidCallback onSendMatchRequest;

  const ActionButtonsWidget({
    super.key,
    required this.onPassPressed,
    required this.onSendMatchRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Pass Button
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: onPassPressed,
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.errorColor,
                  size: 5.w,
                ),
                label: Text(
                  'Geç',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(color: AppTheme.errorColor, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
              ),
            ),

            SizedBox(width: 3.w),

            // Send Match Request Button
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: onSendMatchRequest,
                icon: CustomIconWidget(
                  iconName: 'favorite',
                  color: Colors.white,
                  size: 5.w,
                ),
                label: Text(
                  'Eşleşme İsteği Gönder',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
