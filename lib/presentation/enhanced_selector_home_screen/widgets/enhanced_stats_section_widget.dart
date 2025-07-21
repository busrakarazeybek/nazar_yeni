import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EnhancedStatsSection extends StatelessWidget {
  final int totalMatches;
  final int todayMatches;
  final int pendingMatches;
  final int proposalCounter;

  const EnhancedStatsSection({
    super.key,
    required this.totalMatches,
    required this.todayMatches,
    required this.pendingMatches,
    required this.proposalCounter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.w),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 2.w),
              Text(
                'Eşleştirme İstatistikleri',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 1.5.h,
            children: [
              _buildStatCard(
                emoji: '💕',
                title: 'Toplam Eşleşme',
                value: totalMatches.toString(),
                color: Colors.pink,
              ),
              _buildStatCard(
                emoji: '🌟',
                title: 'Bugünkü',
                value: todayMatches.toString(),
                color: Colors.orange,
              ),
              _buildStatCard(
                emoji: '⏳',
                title: 'Bekleyen',
                value: pendingMatches.toString(),
                color: Colors.blue,
              ),
              _buildStatCard(
                emoji: '🎯',
                title: 'Önerilerim',
                value: proposalCounter.toString(),
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16.sp)),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
