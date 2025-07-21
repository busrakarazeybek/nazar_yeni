import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FormFieldsWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController bioController;
  final int selectedAge;
  final String selectedGender;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final Function(int) onAgeChanged;
  final Function(String) onGenderChanged;
  final VoidCallback onPasswordVisibilityToggled;
  final VoidCallback onConfirmPasswordVisibilityToggled;

  const FormFieldsWidget({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.bioController,
    required this.selectedAge,
    required this.selectedGender,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.onPasswordVisibilityToggled,
    required this.onConfirmPasswordVisibilityToggled,
  });

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad Soyad gereklidir';
    }
    if (value.trim().length < 2) {
      return 'Ad Soyad en az 2 karakter olmalıdır';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta gereklidir';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gereklidir';
    }
    if (value != passwordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  void _showAgePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        title: Text(
          'Yaşınızı Seçin',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 70.w,
          height: 30.h,
          child: ListView.builder(
            itemCount: 24, // Ages 22-45
            itemBuilder: (context, index) {
              final age = 22 + index;
              final isSelected = age == selectedAge;

              return ListTile(
                title: Text(
                  '$age yaş',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? CustomIconWidget(
                        iconName: 'check',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  onAgeChanged(age);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showGenderPickerDialog(BuildContext context) {
    final genders = ['Erkek', 'Kadın'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        title: Text(
          'Cinsiyetinizi Seçin',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: genders.map((gender) {
            final isSelected = gender == selectedGender;

            return ListTile(
              title: Text(
                gender,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              trailing: isSelected
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    )
                  : null,
              onTap: () {
                onGenderChanged(gender);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
        Text(
          'Ad Soyad *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Adınızı ve soyadınızı girin',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'person',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          validator: _validateName,
          textCapitalization: TextCapitalization.words,
        ),

        SizedBox(height: 2.h),

        // Age and Gender row
        Row(
          children: [
            // Age field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yaş *',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  GestureDetector(
                    onTap: () => _showAgePickerDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'cake',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '$selectedAge yaş',
                            style: AppTheme.lightTheme.textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 4.w),

            // Gender field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cinsiyet *',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  GestureDetector(
                    onTap: () => _showGenderPickerDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedGender.isEmpty
                              ? AppTheme.errorColor.withValues(alpha: 0.5)
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: selectedGender == 'Erkek'
                                ? 'male'
                                : selectedGender == 'Kadın'
                                    ? 'female'
                                    : 'person',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            selectedGender.isEmpty ? 'Seçin' : selectedGender,
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                              color: selectedGender.isEmpty
                                  ? AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant
                                  : AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Email field
        Text(
          'E-posta *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'ornek@email.com',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'email',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 2.h),

        // Password field
        Text(
          'Şifre *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: passwordController,
          decoration: InputDecoration(
            hintText: 'En az 6 karakter',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onPasswordVisibilityToggled,
              icon: CustomIconWidget(
                iconName: obscurePassword ? 'visibility' : 'visibility_off',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          validator: _validatePassword,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 2.h),

        // Confirm password field
        Text(
          'Şifre Tekrarı *',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: confirmPasswordController,
          decoration: InputDecoration(
            hintText: 'Şifrenizi tekrar girin',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              onPressed: onConfirmPasswordVisibilityToggled,
              icon: CustomIconWidget(
                iconName:
                    obscureConfirmPassword ? 'visibility' : 'visibility_off',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          validator: _validateConfirmPassword,
          obscureText: obscureConfirmPassword,
          textInputAction: TextInputAction.next,
        ),

        SizedBox(height: 2.h),

        // Bio field
        Text(
          'Hakkımda',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Kendinizi kısaca tanıtın (isteğe bağlı)',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            counterText: '${bioController.text.length}/200',
          ),
          maxLines: 3,
          maxLength: 200,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
