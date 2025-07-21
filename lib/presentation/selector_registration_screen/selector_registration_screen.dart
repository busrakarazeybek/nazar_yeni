import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/selector_form_fields_widget.dart';
import './widgets/selector_profile_photo_section_widget.dart';

class SelectorRegistrationScreen extends StatefulWidget {
  const SelectorRegistrationScreen({super.key});

  @override
  State<SelectorRegistrationScreen> createState() =>
      _SelectorRegistrationScreenState();
}

class _SelectorRegistrationScreenState
    extends State<SelectorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();

  // Form state
  int _selectedAge = 40;
  String _selectedGender = '';
  String? _profileImagePath;
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedExperience = 'Yeni';

  // Validation state
  bool _isFormValid = false;

  final List<String> _experienceOptions = [
    'Yeni',
    '1-3 Yıl',
    '3-5 Yıl',
    '5-10 Yıl',
    '10+ Yıl'
  ];

  @override
  void initState() {
    super.initState();
    _addFormListeners();
  }

  void _addFormListeners() {
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _isValidEmail(_emailController.text.trim()) &&
        _passwordController.text.length >= 6 &&
        _confirmPasswordController.text == _passwordController.text &&
        _phoneController.text.trim().isNotEmpty &&
        _selectedGender.isNotEmpty &&
        _termsAccepted;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _onProfileImageSelected(String? imagePath) {
    setState(() {
      _profileImagePath = imagePath;
    });
  }

  void _onAgeChanged(int age) {
    setState(() {
      _selectedAge = age;
    });
  }

  void _onGenderChanged(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    _validateForm();
  }

  void _onExperienceChanged(String experience) {
    setState(() {
      _selectedExperience = experience;
    });
  }

  Future<void> _handleRegistration() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Map gender string to GenderType enum
      GenderType? gender;
      switch (_selectedGender.toLowerCase()) {
        case 'erkek':
        case 'male':
          gender = GenderType.male;
          break;
        case 'kadın':
        case 'female':
          gender = GenderType.female;
          break;
        case 'diğer':
        case 'other':
          gender = GenderType.other;
          break;
        default:
          gender = GenderType.preferNotToSay;
      }

      // Prepare additional data for selector profile
      final additionalData = <String, dynamic>{
        'age': _selectedAge,
        'gender': gender.toString().split('.').last,
        'phone': _phoneController.text.trim(),
        'bio': 'Deneyimli seçici - $_selectedExperience tecrübe',
        'profession': 'Seçici',
      };

      // If profile image is selected, add it to additional data
      if (_profileImagePath != null) {
        additionalData['image_url'] = _profileImagePath;
      }

      // Call the actual sign up method
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: UserRole.selector,
        additionalData: additionalData,
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seçici hesabınız başarıyla oluşturuldu!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to home screen which will show selector home view
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home-screen',
          (route) => false,
        );
      } else if (mounted) {
        // Show error message from auth provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ??
                'Kayıt sırasında hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen bir hata oluştu: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Text(
          'Seçici Kayıt',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Role indicator
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'people',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Seçici Olarak Kayıt Oluyorsunuz',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information banner
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppTheme
                              .lightTheme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'info',
                                  color:
                                      AppTheme.lightTheme.colorScheme.secondary,
                                  size: 20,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Seçici Hakkında',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleSmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Seçici olarak adaylar arasında eşleşme yapabilir, aday profillerini inceleyebilir ve uygun görülen adayları birbirleri ile tanıştırabilirsiniz.',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Profile photo section
                      SelectorProfilePhotoSectionWidget(
                        imagePath: _profileImagePath,
                        onImageSelected: _onProfileImageSelected,
                      ),

                      SizedBox(height: 3.h),

                      // Form fields
                      SelectorFormFieldsWidget(
                        nameController: _nameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        phoneController: _phoneController,
                        experienceController: _experienceController,
                        selectedAge: _selectedAge,
                        selectedGender: _selectedGender,
                        selectedExperience: _selectedExperience,
                        experienceOptions: _experienceOptions,
                        obscurePassword: _obscurePassword,
                        obscureConfirmPassword: _obscureConfirmPassword,
                        onAgeChanged: _onAgeChanged,
                        onGenderChanged: _onGenderChanged,
                        onExperienceChanged: _onExperienceChanged,
                        onPasswordVisibilityToggled: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        onConfirmPasswordVisibilityToggled: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Terms and conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _termsAccepted,
                            onChanged: (value) {
                              setState(() {
                                _termsAccepted = value ?? false;
                              });
                              _validateForm();
                            },
                            activeColor:
                                AppTheme.lightTheme.colorScheme.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _termsAccepted = !_termsAccepted;
                                });
                                _validateForm();
                              },
                              child: Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: RichText(
                                  text: TextSpan(
                                    style:
                                        AppTheme.lightTheme.textTheme.bodySmall,
                                    children: [
                                      const TextSpan(
                                          text: 'Seçici olarak kayıt olarak '),
                                      TextSpan(
                                        text: 'Seçici Kullanım Şartları',
                                        style: TextStyle(
                                          color: AppTheme
                                              .lightTheme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(text: ' ve '),
                                      TextSpan(
                                        text: 'Gizlilik Politikası',
                                        style: TextStyle(
                                          color: AppTheme
                                              .lightTheme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(
                                          text: '\'nı kabul etmiş olursunuz.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 6.h,
                        child: ElevatedButton(
                          onPressed: _isFormValid && !_isLoading
                              ? _handleRegistration
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormValid
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.outline,
                            foregroundColor: Colors.white,
                            elevation: _isFormValid ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Seçici Hesabı Oluştur',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Login link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login-screen');
                          },
                          child: RichText(
                            text: TextSpan(
                              style: AppTheme.lightTheme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(
                                    text: 'Zaten hesabınız var mı? '),
                                TextSpan(
                                  text: 'Giriş Yapın',
                                  style: TextStyle(
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
