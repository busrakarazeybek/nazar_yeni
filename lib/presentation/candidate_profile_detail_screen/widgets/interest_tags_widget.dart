import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InterestTagsWidget extends StatelessWidget {
  final List<String> interests;

  const InterestTagsWidget({
    super.key,
    required this.interests,
  });

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlgi Alanları',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: interests
                .map((interest) => _buildInterestTag(context, interest))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestTag(BuildContext context, String interest) {
    return GestureDetector(
      onLongPress: () => _showRelatedCandidates(context, interest),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 4.w,
          vertical: 1.5.h,
        ),
        decoration: BoxDecoration(
          color: AppTheme.secondaryLight,
          borderRadius: BorderRadius.circular(6.w),
          border: Border.all(
            color: AppTheme.primaryLight.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: _getIconForInterest(interest),
              color: AppTheme.primaryLight,
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                interest,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIconForInterest(String interest) {
    switch (interest.toLowerCase()) {
      case 'kitap okuma':
        return 'menu_book';
      case 'doğa yürüyüşü':
        return 'hiking';
      case 'seyahat':
        return 'flight';
      case 'müzik':
        return 'music_note';
      case 'yemek pişirme':
        return 'restaurant';
      case 'fotoğrafçılık':
        return 'camera_alt';
      case 'yoga':
        return 'self_improvement';
      case 'sinema':
        return 'movie';
      case 'spor':
        return 'fitness_center';
      case 'sanat':
        return 'palette';
      case 'teknoloji':
        return 'computer';
      case 'dans':
        return 'music_note';
      case 'bahçıvanlık':
        return 'local_florist';
      case 'oyun':
        return 'sports_esports';
      default:
        return 'favorite';
    }
  }

  void _showRelatedCandidates(BuildContext context, String interest) {
    // Mock related candidates data
    final List<Map<String, dynamic>> relatedCandidates = [
      {
        "name": "Elif Kaya",
        "age": 26,
        "image":
            "https://images.pexels.com/photos/1036623/pexels-photo-1036623.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
      {
        "name": "Zeynep Özkan",
        "age": 29,
        "image":
            "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
      {
        "name": "Selin Yılmaz",
        "age": 27,
        "image":
            "https://images.pexels.com/photos/1181424/pexels-photo-1181424.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(0.5.h),
                  ),
                ),
              ),
              SizedBox(height: 3.h),

              // Title
              Text(
                '$interest ile İlgilenen Diğer Adaylar',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 2.h),

              // Related candidates list
              ...relatedCandidates
                  .map((candidate) => _buildRelatedCandidateItem(candidate)),

              SizedBox(height: 2.h),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelatedCandidateItem(Map<String, dynamic> candidate) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2.w),
            child: CustomImageWidget(
              imageUrl: candidate["image"] as String,
              width: 12.w,
              height: 12.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate["name"] as String,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${candidate["age"]} yaşında',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'arrow_forward_ios',
            color: AppTheme.textSecondaryLight,
            size: 4.w,
          ),
        ],
      ),
    );
  }
}
