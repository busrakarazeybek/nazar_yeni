import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ContactInfoWidget extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onDataChanged;

  const ContactInfoWidget({
    super.key,
    required this.userData,
    required this.onDataChanged,
  });

  @override
  State<ContactInfoWidget> createState() => _ContactInfoWidgetState();
}

class _ContactInfoWidgetState extends State<ContactInfoWidget> {
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _professionController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.userData["email"] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData["phone"] as String? ?? '',
    );
    _locationController = TextEditingController(
      text: widget.userData["location"] as String? ?? '',
    );
    _professionController = TextEditingController(
      text: widget.userData["profession"] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  void _updateUserData() {
    widget.userData["email"] = _emailController.text;
    widget.userData["phone"] = _phoneController.text;
    widget.userData["location"] = _locationController.text;
    widget.userData["profession"] = _professionController.text;
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
                iconName: 'contact_phone',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'İletişim Bilgileri',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Email Field
          _buildInfoField(
            label: 'E-posta',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: true, // Email usually shouldn't be editable
          ),
          
          SizedBox(height: 2.h),

          // Phone Field
          _buildInfoField(
            label: 'Telefon',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          
          SizedBox(height: 2.h),

          // Location Field
          _buildInfoField(
            label: 'Şehir',
            controller: _locationController,
            icon: Icons.location_city_outlined,
            keyboardType: TextInputType.text,
          ),
          
          SizedBox(height: 2.h),

          // Profession Field
          _buildInfoField(
            label: 'Meslek',
            controller: _professionController,
            icon: Icons.work_outline,
            keyboardType: TextInputType.text,
          ),

          SizedBox(height: 2.h),

          // Gender Display (Read-only)
          _buildDisplayField(
            label: 'Cinsiyet',
            value: widget.userData["gender"] as String? ?? '',
            icon: Icons.person_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelMedium,
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: readOnly ? 'Değiştirilemez' : '$label girin',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: Icon(
                icon,
                color: readOnly 
                    ? AppTheme.lightTheme.colorScheme.onSurfaceVariant 
                    : AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: readOnly
                ? AppTheme.lightTheme.colorScheme.surfaceVariant.withOpacity(0.5)
                : AppTheme.lightTheme.colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.lightTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 2.h,
            ),
          ),
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: readOnly 
                ? AppTheme.lightTheme.colorScheme.onSurfaceVariant 
                : AppTheme.lightTheme.colorScheme.onSurface,
          ),
          onChanged: readOnly ? null : (value) => _updateUserData(),
        ),
      ],
    );
  }

  Widget _buildDisplayField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelMedium,
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : 'Belirtilmemiş',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: value.isNotEmpty 
                        ? AppTheme.lightTheme.colorScheme.onSurfaceVariant 
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant.withOpacity(0.6),
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