import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PersonalInfoSectionWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onDataChanged;

  const PersonalInfoSectionWidget({
    super.key,
    required this.userData,
    required this.onDataChanged,
  });

  @override
  State<PersonalInfoSectionWidget> createState() =>
      _PersonalInfoSectionWidgetState();
}

class _PersonalInfoSectionWidgetState extends State<PersonalInfoSectionWidget> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;

  final int _maxBioLength = 500;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userData["name"] as String? ?? '');
    _ageController =
        TextEditingController(text: (widget.userData["age"] ?? 0).toString());
    _bioController =
        TextEditingController(text: widget.userData["bio"] as String? ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _updateUserData() {
    widget.userData["name"] = _nameController.text;
    widget.userData["age"] = int.tryParse(_ageController.text) ?? 0;
    widget.userData["bio"] = _bioController.text;
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              CustomIconWidget(
                iconName: 'person_outline',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Kişisel Bilgiler',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Name Field
          Text(
            'İsim',
            style: AppTheme.lightTheme.textTheme.labelMedium,
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Adınızı girin',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'badge',
                  color: AppTheme.textSecondaryLight,
                  size: 20,
                ),
              ),
            ),
            onChanged: (value) => _updateUserData(),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 2.h),

          // Age Field
          Text(
            'Yaş',
            style: AppTheme.lightTheme.textTheme.labelMedium,
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              hintText: 'Yaşınızı girin',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'cake',
                  color: AppTheme.textSecondaryLight,
                  size: 20,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _updateUserData(),
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 2.h),

          // Bio Field
          Text(
            'Hakkımda',
            style: AppTheme.lightTheme.textTheme.labelMedium,
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _bioController,
            decoration: InputDecoration(
              hintText: 'Kendinizi tanıtın...',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'edit_note',
                  color: AppTheme.textSecondaryLight,
                  size: 20,
                ),
              ),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: _maxBioLength,
            onChanged: (value) => _updateUserData(),
            textInputAction: TextInputAction.done,
            buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) {
              return Container(
                padding: EdgeInsets.only(top: 1.h),
                child: Text(
                  '$currentLength/$_maxBioLength karakter',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: currentLength > _maxBioLength * 0.9
                        ? AppTheme.warningColor
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
