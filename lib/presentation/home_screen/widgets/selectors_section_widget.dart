import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SelectorsSectionWidget extends StatelessWidget {
  final List<UserProfile> selectors;
  final VoidCallback onAddSelector;

  const SelectorsSectionWidget({
    super.key,
    required this.selectors,
    required this.onAddSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Seçicilerim',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectors.isNotEmpty) ...[
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        borderRadius: BorderRadius.circular(10.w),
                      ),
                      child: Text(
                        '${selectors.length}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton.icon(
                onPressed: onAddSelector,
                icon: CustomIconWidget(
                  iconName: 'add',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 16.w,
                ),
                label: Text(
                  'Ekle',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (selectors.isEmpty) _buildEmptyState() else _buildSelectorsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'people_outline',
            color: AppTheme.lightTheme.colorScheme.outline,
            size: 48.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Henüz Seçici Yok',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Size uygun adayları bulmanıza yardımcı olacak seçiciler ekleyin',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.w),
                topRight: Radius.circular(16.w),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'supervisor_account',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Aktif Seçiciler',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Selectors list
          ...selectors.asMap().entries.map((entry) {
            final index = entry.key;
            final selector = entry.value;
            final isLast = index == selectors.length - 1;

            return Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.1),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  // Selector avatar
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.w),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.w),
                      child: selector.imageUrl != null
                          ? CustomImageWidget(
                              imageUrl: selector.imageUrl,
                              width: 12.w,
                              height: 12.w,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Center(
                                child: CustomIconWidget(
                                  iconName: 'person',
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size: 6.w,
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selector.fullName,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          selector.email,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.w),
                                border: Border.all(
                                  color: AppTheme.successColor
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Aktif',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (selector.profession != null) ...[
                              SizedBox(width: 2.w),
                              Text(
                                '• ${selector.profession}',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: AppTheme.lightTheme.colorScheme.outline,
                    size: 12.w,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
