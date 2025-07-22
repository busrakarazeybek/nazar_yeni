import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/user_profile.dart';

class EnhancedCandidateSelectionCarousel extends StatefulWidget {
  final List<UserProfile> candidates;
  final UserProfile? selectedCandidate;
  final ValueChanged<UserProfile> onCandidateSelected;
  final ValueChanged<UserProfile> onRemoveCandidate;

  const EnhancedCandidateSelectionCarousel({
    super.key,
    required this.candidates,
    required this.selectedCandidate,
    required this.onCandidateSelected,
    required this.onRemoveCandidate,
  });

  @override
  State<EnhancedCandidateSelectionCarousel> createState() =>
      _EnhancedCandidateSelectionCarouselState();
}

class _EnhancedCandidateSelectionCarouselState
    extends State<EnhancedCandidateSelectionCarousel> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 15.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: widget.candidates.length,
        itemBuilder: (context, index) {
          final candidate = widget.candidates[index];
          final isSelected = widget.selectedCandidate?.id == candidate.id;
          
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            child: GestureDetector(
              onTap: () => widget.onCandidateSelected(candidate),
              onLongPress: () => _showRemoveDialog(candidate),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: isSelected ? 22.w : 20.w,
                    height: isSelected ? 22.w : 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.primaryColor
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: candidate.imageUrl != null
                          ? Image.network(
                              candidate.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  _buildDefaultAvatar(candidate, isSelected),
                            )
                          : _buildDefaultAvatar(candidate, isSelected),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 300),
                    style: AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: isSelected ? 12.sp : 11.sp,
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    child: Text(
                      candidate.fullName.split(' ').first,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar(UserProfile candidate, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.primaryColor.withOpacity(0.8),
            AppTheme.lightTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          candidate.fullName.isNotEmpty
              ? candidate.fullName.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSelected ? 18.sp : 16.sp,
          ),
        ),
      ),
    );
  }

  Future<void> _showRemoveDialog(UserProfile candidate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Adayı Kaldır',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${candidate.fullName} listesinden kaldırılsın mı?',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Kaldır'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      widget.onRemoveCandidate(candidate);
    }
  }
}
