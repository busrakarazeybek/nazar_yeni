import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatsSection extends StatelessWidget {
  final int totalMatches;
  final int todayMatches;
  final int pendingMatches;

  const StatsSection({
    super.key,
    required this.totalMatches,
    required this.todayMatches,
    required this.pendingMatches,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Bugün',
              '$todayMatches',
              CustomIconWidget(
                iconName: 'today',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 10.w,
              ),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'Toplam',
              '$totalMatches',
              CustomIconWidget(
                iconName: 'favorite',
                color: AppTheme.successColor,
                size: 10.w,
              ),
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              'Bekleyen',
              '$pendingMatches',
              CustomIconWidget(
                iconName: 'schedule',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 10.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Widget icon) {
    return Column(
      children: [
        icon,
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontSize: 9.sp,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 5.h,
      color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
    );
  }
}
