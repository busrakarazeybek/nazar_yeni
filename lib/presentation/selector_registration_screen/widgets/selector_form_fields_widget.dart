import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SelectorFormFieldsWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final TextEditingController experienceController;
  final int selectedAge;
  final String selectedGender;
  final String selectedExperience;
  final List<String> experienceOptions;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final Function(int) onAgeChanged;
  final Function(String) onGenderChanged;
  final Function(String) onExperienceChanged;
  final VoidCallback onPasswordVisibilityToggled;
  final VoidCallback onConfirmPasswordVisibilityToggled;

  const SelectorFormFieldsWidget({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.experienceController,
    required this.selectedAge,
    required this.selectedGender,
    required this.selectedExperience,
    required this.experienceOptions,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.onExperienceChanged,
    required this.onPasswordVisibilityToggled,
    required this.onConfirmPasswordVisibilityToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kişisel Bilgiler',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Name field
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Ad Soyad *',
            hintText: 'Ahmet Yılmaz',
            prefixIcon: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 3.h),

        // Email field
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'E-posta *',
            hintText: 'ahmet@example.com',
            prefixIcon: CustomIconWidget(
              iconName: 'email',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 3.h),

        // Phone field
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Telefon Numarası *',
            hintText: '+90 555 123 45 67',
            prefixIcon: CustomIconWidget(
              iconName: 'phone',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 3.h),

        // Password field
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Şifre *',
            hintText: 'En az 6 karakter',
            prefixIcon: CustomIconWidget(
              iconName: 'lock',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: onPasswordVisibilityToggled,
              icon: CustomIconWidget(
                iconName: obscurePassword ? 'visibility_off' : 'visibility',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 3.h),

        // Confirm password field
        TextFormField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Şifre Tekrarı *',
            hintText: 'Şifrenizi tekrar girin',
            prefixIcon: CustomIconWidget(
              iconName: 'lock',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: onConfirmPasswordVisibilityToggled,
              icon: CustomIconWidget(
                iconName:
                    obscureConfirmPassword ? 'visibility_off' : 'visibility',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textInputAction: TextInputAction.done,
        ),

        SizedBox(height: 4.h),

        Text(
          'Demografik Bilgiler',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Age selector
        Text(
          'Yaş: $selectedAge',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
            inactiveTrackColor:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            thumbColor: AppTheme.lightTheme.colorScheme.primary,
            overlayColor:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
            valueIndicatorColor: AppTheme.lightTheme.colorScheme.primary,
            valueIndicatorTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Slider(
            value: selectedAge.toDouble(),
            min: 25.0,
            max: 70.0,
            divisions: 45,
            label: selectedAge.toString(),
            onChanged: (value) => onAgeChanged(value.round()),
          ),
        ),

        SizedBox(height: 3.h),

        // Gender selection
        Text(
          'Cinsiyet *',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                'Erkek',
                'male',
                selectedGender == 'Erkek',
                onGenderChanged,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildGenderOption(
                'Kadın',
                'female',
                selectedGender == 'Kadın',
                onGenderChanged,
              ),
            ),
          ],
        ),

        SizedBox(height: 3.h),

        // Experience selection
        Text(
          'Görücülük Deneyimi',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedExperience,
              hint: Text('Deneyim seçin'),
              isExpanded: true,
              items: experienceOptions.map((String experience) {
                return DropdownMenuItem<String>(
                  value: experience,
                  child: Text(experience),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onExperienceChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    String label,
    String value,
    bool isSelected,
    Function(String) onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primaryContainer
              : AppTheme.lightTheme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: value == 'male' ? 'male' : 'female',
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
