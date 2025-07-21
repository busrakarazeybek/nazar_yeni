import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InterestsSectionWidget extends StatefulWidget {
  final List<String> interests;
  final List<String> popularInterests;
  final Function(List<String>) onInterestsChanged;

  const InterestsSectionWidget({
    super.key,
    required this.interests,
    required this.popularInterests,
    required this.onInterestsChanged,
  });

  @override
  State<InterestsSectionWidget> createState() => _InterestsSectionWidgetState();
}

class _InterestsSectionWidgetState extends State<InterestsSectionWidget> {
  late List<String> _currentInterests;
  final TextEditingController _customInterestController =
      TextEditingController();
  bool _showAddField = false;

  @override
  void initState() {
    super.initState();
    _currentInterests = List.from(widget.interests);
  }

  @override
  void dispose() {
    _customInterestController.dispose();
    super.dispose();
  }

  void _addInterest(String interest) {
    if (interest.trim().isNotEmpty &&
        !_currentInterests.contains(interest.trim())) {
      setState(() {
        _currentInterests.add(interest.trim());
      });
      widget.onInterestsChanged(_currentInterests);
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _currentInterests.remove(interest);
    });
    widget.onInterestsChanged(_currentInterests);
  }

  void _addCustomInterest() {
    if (_customInterestController.text.trim().isNotEmpty) {
      _addInterest(_customInterestController.text.trim());
      _customInterestController.clear();
      setState(() {
        _showAddField = false;
      });
    }
  }

  Widget _buildInterestChip(String interest,
      {bool isSelected = false, bool isPopular = false}) {
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          _removeInterest(interest);
        } else {
          _addInterest(interest);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        margin: EdgeInsets.only(right: 2.w, bottom: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.primaryColor
              : AppTheme.secondaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              interest,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.onPrimary
                    : AppTheme.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 1.w),
              CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availablePopularInterests = widget.popularInterests
        .where((interest) => !_currentInterests.contains(interest))
        .toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'interests',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'İlgi Alanları',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAddField = !_showAddField;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: _showAddField ? 'close' : 'add',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Current Interests
          if (_currentInterests.isNotEmpty) ...[
            Text(
              'Seçili İlgi Alanları',
              style: AppTheme.lightTheme.textTheme.labelMedium,
            ),
            SizedBox(height: 1.h),
            Wrap(
              children: _currentInterests
                  .map((interest) =>
                      _buildInterestChip(interest, isSelected: true))
                  .toList(),
            ),
            SizedBox(height: 2.h),
          ],

          // Add Custom Interest Field
          if (_showAddField) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customInterestController,
                    decoration: const InputDecoration(
                      hintText: 'Yeni ilgi alanı ekle...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onFieldSubmitted: (value) => _addCustomInterest(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: _addCustomInterest,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(3.w),
                    minimumSize: Size(0, 0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'add',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],

          // Popular Interests
          if (availablePopularInterests.isNotEmpty) ...[
            Text(
              'Popüler İlgi Alanları',
              style: AppTheme.lightTheme.textTheme.labelMedium,
            ),
            SizedBox(height: 1.h),
            Wrap(
              children: availablePopularInterests
                  .map((interest) =>
                      _buildInterestChip(interest, isPopular: true))
                  .toList(),
            ),
          ],

          // Interest count info
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    '${_currentInterests.length} ilgi alanı seçildi. En az 3, en fazla 10 ilgi alanı seçebilirsiniz.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
