import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CandidateProfileSummaryWidget extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback onEditProfile;

  const CandidateProfileSummaryWidget({
    super.key,
    required this.userProfile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Profiliniz',
                style: AppTheme.lightTheme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
                onPressed: onEditProfile,
                icon: CustomIconWidget(
                    iconName: 'edit',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16.w),
                label: Text('Düzenle',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary))),
          ]),
          SizedBox(height: 3.h),
          Row(children: [
            // Profile Image
            Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.w),
                    border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        width: 2)),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.w),
                    child: userProfile.imageUrl != null
                        ? CustomImageWidget(
                            imageUrl: userProfile.imageUrl,
                            width: 20.w,
                            height: 20.w,
                            fit: BoxFit.cover)
                        : Container(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            child: Center(
                                child: CustomIconWidget(
                                    iconName: 'person',
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    size: 10.w))))),
            SizedBox(width: 4.w),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(userProfile.fullName,
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 0.5.h),
                  if (userProfile.age != null)
                    Text('${userProfile.age} yaşında',
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant)),
                  if (userProfile.profession != null)
                    Text(userProfile.profession!,
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w500)),
                  if (userProfile.location != null)
                    Row(children: [
                      CustomIconWidget(
                          iconName: 'location_on',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 12.w),
                      SizedBox(width: 1.w),
                      Text(userProfile.location!,
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme
                                      .onSurfaceVariant)),
                    ]),
                ])),
          ]),
          if (userProfile.bio != null && userProfile.bio!.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                    color: AppTheme
                        .lightTheme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.w)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CustomIconWidget(
                            iconName: 'article',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 16.w),
                        SizedBox(width: 2.w),
                        Text('Hakkımda',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme
                                        .lightTheme.colorScheme.primary)),
                      ]),
                      SizedBox(height: 1.h),
                      Text(userProfile.bio!,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(height: 1.5)),
                    ])),
          ],
          if (userProfile.interests != null &&
              userProfile.interests!.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text('İlgi Alanlarım',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.primary)),
            SizedBox(height: 1.h),
            Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: userProfile.interests!.map((interest) {
                  return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                          color:
                              AppTheme.lightTheme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.3))),
                      child: Text('#$interest',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w500)));
                }).toList()),
          ],
          if (!userProfile.isProfileComplete) ...[
            SizedBox(height: 3.h),
            Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3))),
                child: Row(children: [
                  CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.warningColor,
                      size: 20.w),
                  SizedBox(width: 3.w),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Profil Eksik',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                                    color: AppTheme.warningColor,
                                    fontWeight: FontWeight.w600)),
                        Text('Daha iyi eşleşmeler için profilinizi tamamlayın',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(color: AppTheme.warningColor)),
                      ])),
                ])),
          ],
        ]));
  }
}
