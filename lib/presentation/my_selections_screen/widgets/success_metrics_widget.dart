import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/match_proposal.dart';

class SuccessMetricsWidget extends StatelessWidget {
  final List<MatchProposal> proposals;

  const SuccessMetricsWidget({
    super.key,
    required this.proposals,
  });

  @override
  Widget build(BuildContext context) {
    final totalProposals = proposals.length;
    final successfulMatches = proposals.where((p) => p.isCompleted).length;
    final pendingMatches = proposals.where((p) => p.isPending).length;
    final successRate =
        totalProposals > 0 ? (successfulMatches / totalProposals) * 100 : 0.0;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.primaryColor.withAlpha(77),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Başarı İstatistikleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              _buildMetricCard(
                icon: 'favorite',
                title: 'Toplam Öneri',
                value: totalProposals.toString(),
              ),
              SizedBox(width: 4.w),
              _buildMetricCard(
                icon: 'check_circle',
                title: 'Başarılı Eşleşme',
                value: successfulMatches.toString(),
              ),
              SizedBox(width: 4.w),
              _buildMetricCard(
                icon: 'schedule',
                title: 'Beklemede',
                value: pendingMatches.toString(),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildSuccessRateIndicator(successRate),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: Colors.white,
              size: 24.w,
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 9.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateIndicator(double successRate) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'trending_up',
            color: Colors.white,
            size: 24.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Başarı Oranı',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: successRate / 100,
                        backgroundColor: Colors.white.withAlpha(77),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '${successRate.toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
