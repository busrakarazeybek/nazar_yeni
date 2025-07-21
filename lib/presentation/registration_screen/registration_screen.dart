import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/form_fields_widget.dart';
import './widgets/interests_section_widget.dart';
import './widgets/profile_photo_section_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bioController = TextEditingController();

  // Form state
  String _selectedRole = 'Candidate';
  int _selectedAge = 25;
  String _selectedGender = '';
  String? _profileImagePath;
  List<String> _selectedInterests = [];
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Validation state
  bool _isFormValid = false;

  int? _preferredAgeMin;
  int? _preferredAgeMax;
  final List<String> _preferredCities = [];
  final List<String> _preferredGenders = [];

  // Mock data for interests
  final List<String> _availableInterests = [
    'Müzik',
    'Kitap Okuma',
    'Spor',
    'Seyahat',
    'Yemek Pişirme',
    'Fotoğrafçılık',
    'Sinema',
    'Doğa Yürüyüşü',
    'Sanat',
    'Teknoloji',
    'Bahçıvanlık',
    'Dans',
    'Yoga',
    'Bisiklet',
    'Resim',
    'Yazılım',
    'Müze Gezisi',
    'Kamp',
    'Balık Tutma',
    'El Sanatları',
  ];

  @override
  void initState() {
    super.initState();
    _getSelectedRole();
    _addFormListeners();
  }

  void _getSelectedRole() {
    // Get role from navigation arguments or default to Candidate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['role'] != null) {
        setState(() {
          _selectedRole = args['role'] as String;
        });
      }
    });
  }

  void _addFormListeners() {
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    final isCandidate = _selectedRole.toLowerCase() == 'candidate';
    final isValid = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _isValidEmail(_emailController.text.trim()) &&
        _passwordController.text.length >= 6 &&
        _confirmPasswordController.text == _passwordController.text &&
        _selectedGender.isNotEmpty &&
        _termsAccepted &&
        (!isCandidate ||
            (_preferredAgeMin != null &&
                _preferredAgeMax != null &&
                _preferredAgeMin! <= _preferredAgeMax! &&
                _preferredCities.isNotEmpty &&
                _selectedInterests.isNotEmpty &&
                _preferredGenders.isNotEmpty));
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

  void _onInterestsChanged(List<String> interests) {
    setState(() {
      _selectedInterests = interests;
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

      // Prepare additional data for candidate profile
      final additionalData = <String, dynamic>{
        'age': _selectedAge,
        'gender': gender.toString().split('.').last,
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : 'Merhaba! ${_nameController.text.trim()} isimli aday.',
        'interests': _selectedInterests,
        'profession': 'Aday',
      };

      if (_selectedRole.toLowerCase() == 'candidate') {
        additionalData['preferred_age_min'] = _preferredAgeMin;
        additionalData['preferred_age_max'] = _preferredAgeMax;
        additionalData['preferred_cities'] = _preferredCities;
        additionalData['preferred_genders'] = _preferredGenders;
      }

      // If profile image is selected, add it to additional data
      if (_profileImagePath != null) {
        additionalData['image_url'] = _profileImagePath;
      }

      // Call the actual sign up method
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: UserRole.candidate,
        additionalData: additionalData,
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap başarıyla oluşturuldu!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate based on role - candidates go to home screen which shows matches & suggestions
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home-screen',
          (route) => false,
        );
      } else if (mounted) {
        // Show error message from auth provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ??
                  'Kayıt sırasında hata oluştu. Lütfen tekrar deneyin.',
            ),
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
    _bioController.dispose();
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
          'Kayıt Ol',
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
                    color: AppTheme.lightTheme.colorScheme.outline.withValues(
                      alpha: 0.2,
                    ),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: _selectedRole == 'Selector' ? 'people' : 'person',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _selectedRole == 'Selector'
                        ? 'Seçici Olarak Kayıt'
                        : 'Aday Olarak Kayıt',
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
                      // Profile photo section
                      ProfilePhotoSectionWidget(
                        imagePath: _profileImagePath,
                        onImageSelected: _onProfileImageSelected,
                      ),

                      SizedBox(height: 3.h),

                      // Form fields
                      FormFieldsWidget(
                        nameController: _nameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        bioController: _bioController,
                        selectedAge: _selectedAge,
                        selectedGender: _selectedGender,
                        obscurePassword: _obscurePassword,
                        obscureConfirmPassword: _obscureConfirmPassword,
                        onAgeChanged: _onAgeChanged,
                        onGenderChanged: _onGenderChanged,
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

                      // Interests section
                      InterestsSectionWidget(
                        availableInterests: _availableInterests,
                        selectedInterests: _selectedInterests,
                        onInterestsChanged: (interests) {
                          _onInterestsChanged(interests);
                          _validateForm();
                        },
                      ),

                      if (_selectedRole.toLowerCase() == 'candidate') ...[
                        SizedBox(height: 2.h),
                        Text(
                          'Tercih Edilen Yaş Aralığı',
                          style: AppTheme.lightTheme.textTheme.labelLarge,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Min Yaş',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    _preferredAgeMin = int.tryParse(val);
                                  });
                                  _validateForm();
                                },
                                validator: (val) {
                                  if (_selectedRole.toLowerCase() !=
                                      'candidate') {
                                    return null;
                                  }
                                  if (val == null || val.isEmpty) {
                                    return 'Gerekli';
                                  }
                                  final v = int.tryParse(val);
                                  if (v == null) return 'Geçersiz';
                                  if (_preferredAgeMax != null &&
                                      v > _preferredAgeMax!) {
                                    return 'Min, max yaştan büyük olamaz';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Max Yaş',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    _preferredAgeMax = int.tryParse(val);
                                  });
                                  _validateForm();
                                },
                                validator: (val) {
                                  if (_selectedRole.toLowerCase() !=
                                      'candidate') {
                                    return null;
                                  }
                                  if (val == null || val.isEmpty) {
                                    return 'Gerekli';
                                  }
                                  final v = int.tryParse(val);
                                  if (v == null) return 'Geçersiz';
                                  if (_preferredAgeMin != null &&
                                      v < _preferredAgeMin!) {
                                    return 'Max, min yaştan küçük olamaz';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tercih Edilen Cinsiyetler',
                          style: AppTheme.lightTheme.textTheme.labelLarge,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final gender in ['Kadın', 'Erkek', 'Diğer'])
                              FilterChip(
                                label: Text(gender),
                                selected: _preferredGenders.contains(gender),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _preferredGenders.add(gender);
                                    } else {
                                      _preferredGenders.remove(gender);
                                    }
                                  });
                                  _validateForm();
                                },
                              ),
                          ],
                        ),
                        if (_preferredGenders.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              'En az bir cinsiyet seçmelisiniz',
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tercih Edilen Şehirler',
                          style: AppTheme.lightTheme.textTheme.labelLarge,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final city in [
                              'İstanbul',
                              'Ankara',
                              'İzmir',
                              'Bursa',
                              'Antalya',
                            ])
                              FilterChip(
                                label: Text(city),
                                selected: _preferredCities.contains(city),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _preferredCities.add(city);
                                    } else {
                                      _preferredCities.remove(city);
                                    }
                                  });
                                  _validateForm();
                                },
                              ),
                          ],
                        ),
                        if (_preferredCities.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              'En az bir şehir seçmelisiniz',
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],

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
                                      const TextSpan(text: 'Kayıt olarak '),
                                      TextSpan(
                                        text: 'Kullanım Şartları',
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
                                        text: '\'nı kabul etmiş olursunuz.',
                                      ),
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
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Hesap Oluştur',
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
                                  text: 'Zaten hesabınız var mı? ',
                                ),
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
