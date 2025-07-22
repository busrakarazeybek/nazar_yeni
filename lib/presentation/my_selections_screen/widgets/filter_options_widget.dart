import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterOptionsWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const FilterOptionsWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchField(),
          SizedBox(height: 1.5.h),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Aday ismi ile ara...',
        prefixIcon: Padding(
          padding: EdgeInsets.all(2.w),
          child: CustomIconWidget(
            iconName: 'search',
            color: Colors.grey[400]!,
            size: 16,
          ),
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
                icon: CustomIconWidget(
                  iconName: 'clear',
                  color: Colors.grey[400]!,
                  size: 16,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.lightTheme.primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Tümü', 'color': Colors.grey},
      {'key': 'pending', 'label': 'Beklemede', 'color': Colors.orange},
      {'key': 'accepted', 'label': 'Eşleşti', 'color': Colors.green},
      {'key': 'rejected', 'label': 'Reddedildi', 'color': Colors.red},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter['key'];
          final color = filter['color'] as Color;

          return Container(
            margin: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: color.withAlpha(26),
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter['key'] as String);
                }
              },
              side: BorderSide(
                color: isSelected ? color : color.withAlpha(77),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
