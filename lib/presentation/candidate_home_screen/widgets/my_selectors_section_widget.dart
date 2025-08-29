import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MySelectorsSection extends StatelessWidget {
  final List<UserProfile> selectors;
  final UserProfile? selectedSelector;
  final Function(UserProfile) onSelectorSelected;
  final Map<String, int> pendingCounts;
  final bool showRelationshipDegree;
  final Function(UserProfile)? onRemoveSelector;

  const MySelectorsSection({
    super.key,
    required this.selectors,
    required this.selectedSelector,
    required this.onSelectorSelected,
    required this.pendingCounts,
    this.showRelationshipDegree = false,
    this.onRemoveSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppTheme.lightTheme.primaryColor.withAlpha(8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.primaryColor.withAlpha(18),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 3.h),
            if (selectors.isEmpty)
              _buildEmptySelectorsState()
            else
              _buildSelectorsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.5.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.lightTheme.primaryColor,
                AppTheme.lightTheme.primaryColor.withAlpha(200),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.primaryColor.withAlpha(51),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: CustomIconWidget(
            iconName: 'people',
            color: Colors.white,
            size: 5.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Benim Görücülerim',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                '${selectors.length} aktif görücü',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorsList() {
    return SizedBox(
      height: 30.w,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemCount: selectors.length,
        itemBuilder: (context, index) {
          final selector = selectors[index];
          final isSelected = selectedSelector?.id == selector.id;
          final pendingCount = pendingCounts[selector.id] ?? 0;

          return _buildSelectorCard(
            selector: selector,
            isSelected: isSelected,
            pendingCount: pendingCount,
            onTap: () => onSelectorSelected(selector),
            onLongPress: onRemoveSelector != null ? () => _showRemoveDialog(context, selector) : null,
          );
        },
      ),
    );
  }

  Widget _buildSelectorCard({
    required UserProfile selector,
    required bool isSelected,
    required int pendingCount,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.only(right: 3.w),
      width: 20.w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.lightTheme.primaryColor.withAlpha(26),
          highlightColor: AppTheme.lightTheme.primaryColor.withAlpha(13),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.lightTheme.primaryColor.withAlpha(26),
                        AppTheme.lightTheme.primaryColor.withAlpha(13),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : LinearGradient(
                      colors: [Colors.white, Colors.grey[50]!],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor.withAlpha(26)
                      : Colors.black.withAlpha(8),
                  blurRadius: isSelected ? 12 : 4,
                  offset: Offset(0, isSelected ? 4 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: isSelected ? 6.w : 5.w,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: selector.imageUrl != null
                            ? NetworkImage(selector.imageUrl!)
                            : null,
                        child: selector.imageUrl == null
                            ? Icon(
                                Icons.person,
                                size: isSelected ? 6.w : 5.w,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          constraints:
                              BoxConstraints(minWidth: 4.w, minHeight: 4.w),
                          child: Text(
                            pendingCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  showRelationshipDegree && selector.relationshipType != null && selector.relationshipType!.isNotEmpty 
                    ? selector.relationshipType! 
                    : selector.fullName,
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  SizedBox(height: 0.5.h),
                  Container(
                    width: 3.w,
                    height: 0.4.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySelectorsState() {
    return Container(
      height: 30.w,
      padding: EdgeInsets.all(4.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'person_search',
                color: AppTheme.lightTheme.primaryColor,
                size: 8.w,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Henüz görücünüz yok',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, UserProfile selector) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Görücüyü Kaldır'),
          content: Text('${selector.fullName} adlı görücüyü listenizden kaldırmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRemoveSelector?.call(selector);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaldır'),
            ),
          ],
        );
      },
    );
  }
}
