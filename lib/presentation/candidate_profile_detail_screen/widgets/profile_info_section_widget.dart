import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileInfoSectionWidget extends StatelessWidget {
  final Map<String, dynamic> candidateData;

  const ProfileInfoSectionWidget({
    super.key,
    required this.candidateData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Age
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  candidateData["name"] as String,
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '${candidateData["age"]}',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Location
          Row(
            children: [
              CustomIconWidget(
                iconName: 'location_on',
                color: AppTheme.textSecondaryLight,
                size: 4.w,
              ),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  candidateData["location"] as String,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Bio Section
          if (candidateData["bio"] != null &&
              (candidateData["bio"] as String).isNotEmpty) ...[
            Text(
              'Hakkında',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              candidateData["bio"] as String,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimaryLight,
                height: 1.5,
              ),
            ),
            SizedBox(height: 3.h),
          ],

          // Additional Information
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final List<Map<String, String>> infoItems = [
      {
        'icon': 'school',
        'label': 'Eğitim',
        'value': candidateData["education"] as String? ?? 'Belirtilmemiş',
      },
      {
        'icon': 'work',
        'label': 'Meslek',
        'value': candidateData["profession"] as String? ?? 'Belirtilmemiş',
      },
      {
        'icon': 'height',
        'label': 'Boy',
        'value': candidateData["height"] as String? ?? 'Belirtilmemiş',
      },
      {
        'icon': 'favorite',
        'label': 'Din',
        'value': candidateData["religion"] as String? ?? 'Belirtilmemiş',
      },
      {
        'icon': 'smoke_free',
        'label': 'Sigara',
        'value': candidateData["smoking"] as String? ?? 'Belirtilmemiş',
      },
      {
        'icon': 'local_bar',
        'label': 'Alkol',
        'value': candidateData["drinking"] as String? ?? 'Belirtilmemiş',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kişisel Bilgiler',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...infoItems.map((item) => _buildInfoItem(
              icon: item['icon']!,
              label: item['label']!,
              value: item['value']!,
            )),
      ],
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight,
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.primaryLight,
                size: 5.w,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
