import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CandidateSelectionCarousel extends StatelessWidget {
  final List<UserProfile> candidates;
  final UserProfile? selectedCandidate;
  final Function(UserProfile) onCandidateSelected;

  const CandidateSelectionCarousel({
    super.key,
    required this.candidates,
    required this.selectedCandidate,
    required this.onCandidateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
        height: 12.h,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              final isSelected = selectedCandidate?.id == candidate.id;

              return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCandidateSelected(candidate);
                  },
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: 3.w),
                      child: Column(children: [
                        Container(
                            height: 8.h,
                            width: 8.h,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSelected
                                        ? AppTheme.lightTheme.primaryColor
                                        : AppTheme
                                            .lightTheme.colorScheme.outline
                                            .withValues(alpha: 0.3),
                                    width: isSelected ? 3 : 1),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: AppTheme
                                                .lightTheme.primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2)),
                                      ]
                                    : null),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.h),
                                child: CustomImageWidget(
                                    imageUrl: candidate.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                        color: AppTheme
                                            .lightTheme.colorScheme.surface,
                                        child: CustomIconWidget(
                                            iconName: 'person',
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                            size: 3.h))))),
                        SizedBox(height: 1.h),
                        SizedBox(
                            width: 8.h,
                            child: Text(candidate.fullName.split(' ').first,
                                style: AppTheme.lightTheme.textTheme.labelSmall
                                    ?.copyWith(
                                        color: isSelected
                                            ? AppTheme.lightTheme.primaryColor
                                            : AppTheme.lightTheme.colorScheme
                                                .onSurfaceVariant,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        if (candidate.age != null)
                          Text('${candidate.age}',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 9.sp)),
                      ])));
            }));
  }

  Widget _buildEmptyState() {
    return Container(
        height: 12.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                style: BorderStyle.solid)),
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CustomIconWidget(
              iconName: 'person_add',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24.w),
          SizedBox(height: 1.h),
          Text('Henüz aday eklenmemiş',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
        ])));
  }
}
