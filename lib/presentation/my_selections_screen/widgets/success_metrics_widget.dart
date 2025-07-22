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
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor.withAlpha(230),
            AppTheme.lightTheme.primaryColor.withAlpha(180),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withAlpha(100),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.primaryColor.withAlpha(30),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Başarı İstatistikleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildMetricCard(
                icon: 'favorite',
                title: 'Toplam Öneri',
                value: totalProposals.toString(),
              ),
              SizedBox(width: 2.w),
              _buildMetricCard(
                icon: 'check_circle',
                title: 'Başarılı Eşleşme',
                value: successfulMatches.toString(),
              ),
              SizedBox(width: 2.w),
              _buildMetricCard(
                icon: 'schedule',
                title: 'Beklemede',
                value: pendingMatches.toString(),
              ),
            ],
          ),
          SizedBox(height: 2.h),
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
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 1.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(77),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha(128),
            width: 0.3,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 0.3.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 8.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateIndicator(double successRate) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(128),
          width: 0.3,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'trending_up',
            color: Colors.white,
            size: 16,
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
                    fontSize: 9.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: successRate / 100,
                        backgroundColor: Colors.white.withAlpha(102),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 5,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${successRate.toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
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
