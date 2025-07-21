import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InterestsSectionWidget extends StatelessWidget {
  final List<String> availableInterests;
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;

  const InterestsSectionWidget({
    super.key,
    required this.availableInterests,
    required this.selectedInterests,
    required this.onInterestsChanged,
  });

  void _toggleInterest(String interest) {
    List<String> updatedInterests = List.from(selectedInterests);

    if (updatedInterests.contains(interest)) {
      updatedInterests.remove(interest);
    } else {
      if (updatedInterests.length < 10) {
        updatedInterests.add(interest);
      }
    }

    onInterestsChanged(updatedInterests);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'İlgi Alanları',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '(${selectedInterests.length}/10)',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Size uygun eşleşmeler bulmak için ilgi alanlarınızı seçin',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 25.h),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: availableInterests.map((interest) {
                final isSelected = selectedInterests.contains(interest);
                final canSelect = selectedInterests.length < 10 || isSelected;

                return GestureDetector(
                  onTap: canSelect ? () => _toggleInterest(interest) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : canSelect
                              ? AppTheme.lightTheme.colorScheme.surface
                              : AppTheme.lightTheme.colorScheme.surface
                                  .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : canSelect
                                ? AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.3)
                                : AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          CustomIconWidget(
                            iconName: 'check',
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                        ],
                        Text(
                          interest,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : canSelect
                                    ? AppTheme.lightTheme.colorScheme.onSurface
                                    : AppTheme.lightTheme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (selectedInterests.length >= 10)
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.warningColor,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Maksimum 10 ilgi alanı seçebilirsiniz',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
