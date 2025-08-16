import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/app_export.dart';
import '../../widgets/app_logo_widget.dart';
import '../../services/auth_service.dart';

enum RegistrationStep {
  welcome,
  name,
  email,
  password,
  phone, // Telefon numarası adımı eklendi
  age,
  gender,
  location,
  profession,
  profilePhoto,
  bio,
  interests,
  experience, // Seçici için deneyim
  preferences,
  terms,
  loading,
  complete
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  RegistrationStep _currentStep = RegistrationStep.welcome;
  int _currentStepIndex = 0;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(); // Telefon controller eklendi
  final _bioController = TextEditingController();
  final _customCityController = TextEditingController(); // Manuel şehir girişi için

  // Form state
  String _selectedRole = 'Candidate';
  int _selectedAge = 25;
  String _selectedGender = '';
  String _selectedLocation = '';
  String _selectedProfession = '';
  String? _profileImagePath;
  List<String> _selectedInterests = [];
  bool _termsAccepted = false;
  bool _isLoading = false;

  // Selector specific
  String _selectedExperience = '';

  // Preferences
  int? _preferredAgeMin;
  int? _preferredAgeMax;
  final List<String> _preferredCities = [];
  final List<String> _preferredGenders = [];

  // Mock data for interests
  final List<String> _availableInterests = [
    'Müzik', 'Kitap Okuma', 'Spor', 'Seyahat', 'Yemek Pişirme', 
    'Fotoğrafçılık', 'Sinema', 'Doğa Yürüyüşü', 'Sanat', 'Teknoloji',
    'Bahçıvanlık', 'Dans', 'Yoga', 'Bisiklet', 'Resim', 'Yazılım',
    'Müze Gezisi', 'Kamp', 'Balık Tutma', 'El Sanatları',
  ];

  List<RegistrationStep> get _steps {
    final baseSteps = [
      RegistrationStep.welcome,
      RegistrationStep.name,
      RegistrationStep.email,
      RegistrationStep.password,
      RegistrationStep.phone, // Telefon adımı eklendi
      RegistrationStep.age,
      RegistrationStep.gender,
      RegistrationStep.location,
      RegistrationStep.profession,
      RegistrationStep.profilePhoto,
      RegistrationStep.bio,
    ];

    if (_selectedRole.toLowerCase() == 'candidate') {
      baseSteps.addAll([
        RegistrationStep.interests,
        RegistrationStep.preferences,
      ]);
    } else {
      baseSteps.addAll([
        RegistrationStep.experience,
      ]);
    }

    baseSteps.add(RegistrationStep.terms);
    return baseSteps;
  }

  @override
  void initState() {
    super.initState();
    _getSelectedRole();
    _initializeAnimations();
    _pageController = PageController();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _getSelectedRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['role'] != null) {
        setState(() {
          _selectedRole = args['role'] as String;
        });
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidTurkishPhone(String phone) {
    // Remove spaces and special characters
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Turkish phone numbers: 05xx xxx xx xx (11 digits starting with 05)
    return cleanPhone.length == 11 && cleanPhone.startsWith('05');
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      HapticFeedback.lightImpact();
      _slideController.reset();
      setState(() {
        _currentStepIndex++;
        _currentStep = _steps[_currentStepIndex];
      });
      _slideController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleRegistration();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      HapticFeedback.lightImpact();
      _slideController.reset();
      setState(() {
        _currentStepIndex--;
        _currentStep = _steps[_currentStepIndex];
      });
      _slideController.forward();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case RegistrationStep.welcome:
        return true;
      case RegistrationStep.name:
        return _nameController.text.trim().length >= 2;
      case RegistrationStep.email:
        return _isValidEmail(_emailController.text.trim());
      case RegistrationStep.password:
        return _passwordController.text.length >= 6;
      case RegistrationStep.phone:
        return _isValidTurkishPhone(_phoneController.text.trim());
      case RegistrationStep.age:
        return _selectedAge >= 18 && _selectedAge <= 80;
      case RegistrationStep.gender:
        return _selectedGender.isNotEmpty;
      case RegistrationStep.location:
        return _selectedLocation.isNotEmpty;
      case RegistrationStep.profession:
        return _selectedProfession.isNotEmpty;
      case RegistrationStep.profilePhoto:
        return true; // Optional
      case RegistrationStep.bio:
        return true; // Optional
      case RegistrationStep.interests:
        return _selectedInterests.length >= 3;
      case RegistrationStep.experience:
        return _selectedExperience.isNotEmpty;
      case RegistrationStep.preferences:
        return _selectedRole.toLowerCase() != 'candidate' || 
               (_preferredAgeMin != null && _preferredAgeMax != null && 
                _preferredCities.isNotEmpty && _preferredGenders.isNotEmpty);
      case RegistrationStep.terms:
        return _termsAccepted;
      default:
        return false;
    }
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _isLoading = true;
      _currentStep = RegistrationStep.loading;
    });

    try {
      // Check if email or phone already exists
      final authService = AuthService();
      final existingData = await authService.checkExistingEmailAndPhone(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (existingData['emailExists'] == true) {
        setState(() {
          _isLoading = false;
          _currentStep = RegistrationStep.email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu email adresi zaten kayıtlı. Lütfen farklı bir email adresi kullanın.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (existingData['phoneExists'] == true) {
        setState(() {
          _isLoading = false;
          _currentStep = RegistrationStep.phone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu telefon numarası zaten kayıtlı. Lütfen farklı bir numara kullanın.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

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

      final additionalData = <String, dynamic>{
        'age': _selectedAge,
        'gender': gender.toString().split('.').last,
        'location': _selectedLocation,
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : (_selectedRole.toLowerCase() == 'candidate' 
                ? 'Merhaba! ${_nameController.text.trim()} isimli aday.'
                : 'Merhaba! ${_nameController.text.trim()} isimli profesyonel görücü.'),
        'profession': _selectedProfession,
      };

      if (_selectedRole.toLowerCase() == 'candidate') {
        additionalData['interests'] = _selectedInterests;
        additionalData['preferred_age_min'] = _preferredAgeMin;
        additionalData['preferred_age_max'] = _preferredAgeMax;
        additionalData['preferred_cities'] = _preferredCities;
        additionalData['preferred_genders'] = _preferredGenders;
      } else {
        additionalData['experience'] = _selectedExperience;
      }

      if (_profileImagePath != null) {
        additionalData['image_url'] = _profileImagePath;
      }

      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole.toLowerCase() == 'candidate' ? UserRole.candidate : UserRole.selector,
        additionalData: additionalData,
      );

      if (success && mounted) {
        setState(() {
          _currentStep = RegistrationStep.complete;
        });
        
        await Future.delayed(const Duration(seconds: 2));
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home-screen',
          (route) => false,
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = RegistrationStep.terms;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Kayıt sırasında hata oluştu.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = RegistrationStep.terms;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _customCityController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  BoxDecoration _buildTurkishOrnateBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1a365d),
          Color(0xFF2c5282),
          Color(0xFF3182ce),
          Color(0xFF4299e1),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
      image: DecorationImage(
        image: NetworkImage('https://images.unsplash.com/photo-1578662996442-48f60103fc96?q=80&w=1920&h=1080&fit=crop&ixlib=rb-4.0.3'),
        fit: BoxFit.cover,
        opacity: 0.15,
        colorFilter: ColorFilter.mode(
          Color(0xFF1a365d).withOpacity(0.8),
          BlendMode.overlay,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStepIndex + 1) / _steps.length;
    return Container(
      height: 4,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Colors.white.withOpacity(0.2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStepIndex > 0)
                  GestureDetector(
                    onTap: _previousStep,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'arrow_back_ios',
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                else
                  SizedBox(width: 32),
                
                Text(
                  '${_currentStepIndex + 1} / ${_steps.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(RegistrationStep step) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.all(6.w),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildStepWidget(step),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepWidget(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.welcome:
        return _buildWelcomeStep();
      case RegistrationStep.name:
        return _buildNameStep();
      case RegistrationStep.email:
        return _buildEmailStep();
      case RegistrationStep.password:
        return _buildPasswordStep();
      case RegistrationStep.phone:
        return _buildPhoneStep();
      case RegistrationStep.age:
        return _buildAgeStep();
      case RegistrationStep.gender:
        return _buildGenderStep();
      case RegistrationStep.location:
        return _buildLocationStep();
      case RegistrationStep.profession:
        return _buildProfessionStep();
      case RegistrationStep.profilePhoto:
        return _buildProfilePhotoStep();
      case RegistrationStep.bio:
        return _buildBioStep();
      case RegistrationStep.interests:
        return _buildInterestsStep();
      case RegistrationStep.experience:
        return _buildExperienceStep();
      case RegistrationStep.preferences:
        return _buildPreferencesStep();
      case RegistrationStep.terms:
        return _buildTermsStep();
      default:
        return Container();
    }
  }

  Widget _buildContinueButton() {
    final canProceed = _canProceed();
    return Container(
      width: double.infinity,
      height: 6.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canProceed ? [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ] : [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: canProceed ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: canProceed ? _nextStep : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: canProceed ? Color(0xFF1a365d) : Colors.white.withOpacity(0.5),
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _currentStepIndex == _steps.length - 1 ? 'Hesap Oluştur' : 'Devam Et',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: canProceed ? Color(0xFF1a365d) : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          SizedBox(height: 4.h),
          Text(
            'Hesabınız oluşturuluyor...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 48,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Hesap Başarıyla Oluşturuldu!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final isSelector = _selectedRole.toLowerCase() == 'selector';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppLogoWidget(size: 20.w),
        SizedBox(height: 4.h),
        Text(
          'Görücü\'ye Hoş Geldiniz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelector ? Icons.people : Icons.person,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                isSelector ? 'Seçici Olarak Kayıt' : 'Aday Olarak Kayıt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          isSelector 
            ? 'Profesyonel görücü olarak aileler için ideal eşleştirmeler yapın. Deneyiminizi paylaşın ve güvenilir bir hizmet sunun.'
            : 'Geleneksel görücülük geleneğini modern teknoloji ile buluşturan uygulamaya adım atın.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16.sp,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Adınız ve soyadınız nedir?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Profilinizde görünecek gerçek adınızı girin',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
          decoration: InputDecoration(
            hintText: 'Adınız ve soyadınız',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: EdgeInsets.all(4.w),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'E-posta adresiniz nedir?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Hesap doğrulama için kullanılacak',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: _emailController,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
          decoration: InputDecoration(
            hintText: 'ornek@email.com',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: EdgeInsets.all(4.w),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Telefon numaranız nedir?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'İletişim için kullanılacak',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: _phoneController,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
          decoration: InputDecoration(
            hintText: '05xx xxx xx xx',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: EdgeInsets.all(4.w),
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Telefon numaranız sadece eşleşen kişilerle paylaşılacak',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Güvenli bir şifre oluşturun',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'En az 6 karakter uzunluğunda olmalı',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: _passwordController,
          onChanged: (_) => setState(() {}),
          obscureText: true,
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: EdgeInsets.all(4.w),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Yaşınız kaç?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '18-80 yaş aralığında olmalıdır',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '$_selectedAge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'yaşında',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _selectedAge.toDouble(),
            min: 18,
            max: 80,
            divisions: 62,
            onChanged: (value) {
              setState(() {
                _selectedAge = value.round();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    final genders = ['Erkek', 'Kadın', 'Diğer'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Cinsiyetiniz nedir?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Profil eşleştirmelerinde kullanılacak',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        ...genders.map((gender) => Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedGender = gender;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: _selectedGender == gender 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedGender == gender 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.3),
                  width: _selectedGender == gender ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: _selectedGender == gender 
                          ? Colors.white 
                          : Colors.transparent,
                    ),
                    child: _selectedGender == gender 
                        ? Icon(Icons.check, size: 14, color: Color(0xFF1a365d))
                        : null,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    gender,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: _selectedGender == gender 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildLocationStep() {
    final cities = [
      'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana',
      'Konya', 'Gaziantep', 'Mersin', 'Kayseri', 'Diyarbakır', 'Samsun',
      'Denizli', 'Şanlıurfa', 'Adapazarı', 'Malatya', 'Kahramanmaraş', 'Van',
      'Batman', 'Elazığ', 'Erzurum', 'Trabzon', 'Manisa', 'Balıkesir'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Hangi şehirde yaşıyorsunuz?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Lokasyon bazlı eşleştirmeler için kullanılacak',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        
        // Search/filter field
        TextField(
          onChanged: (value) => setState(() {}),
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: 'Şehir ara...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: EdgeInsets.all(4.w),
          ),
        ),
        
        SizedBox(height: 3.h),
        
        Text(
          'Popüler şehirler:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // Cities grid
        SizedBox(
          height: 40.h,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: cities.map((city) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLocation = city;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: _selectedLocation == city 
                        ? Colors.white.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedLocation == city 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.3),
                      width: _selectedLocation == city ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedLocation == city)
                        Padding(
                          padding: EdgeInsets.only(right: 1.w),
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                      Text(
                        city,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: _selectedLocation == city 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionStep() {
    final professions = [
      'Mühendis', 'Doktor', 'Öğretmen', 'Avukat', 'Hemşire', 
      'Muhasebeci', 'Pazarlama', 'Yazılım', 'Öğrenci', 'Diğer'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6.h),
        Text(
          'Mesleğiniz nedir?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Mesleğinizi yazın veya listeden seçin',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        
        // Manuel meslek girişi
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Mesleğinizi yazın...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            ),
            onChanged: (value) {
              setState(() {
                _selectedProfession = value.trim();
              });
            },
          ),
        ),
        
        SizedBox(height: 3.h),
        
        Text(
          'Veya hızlı seçim yapın:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14.sp,
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // Hazır seçenekler (azaltılmış)
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: professions.map((profession) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedProfession = profession;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: _selectedProfession == profession 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedProfession == profession 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.3),
                  width: _selectedProfession == profession ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedProfession == profession)
                    Padding(
                      padding: EdgeInsets.only(right: 1.w),
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  Text(
                    profession,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: _selectedProfession == profession 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 6.h),
        Text(
          'Profil fotoğrafı ekleyin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        Text(
          'İsteğe bağlı - daha sonra da ekleyebilirsiniz',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        
        // Profile photo display
        Center(
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: _profileImagePath != null 
                ? ClipOval(
                    child: Image.file(
                      File(_profileImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.camera_alt, color: Colors.white, size: 48),
                    ),
                  )
                : Icon(Icons.camera_alt, color: Colors.white, size: 48),
          ),
        ),
        
        SizedBox(height: 4.h),
        
        // Photo selection buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery button
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library, color: Colors.white, size: 32),
                    SizedBox(height: 1.h),
                    Text(
                      'Galeriden\nSeç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Camera button
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 32),
                    SizedBox(height: 1.h),
                    Text(
                      'Kameradan\nÇek',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        if (_profileImagePath != null) ...[
          SizedBox(height: 3.h),
          GestureDetector(
            onTap: () {
              setState(() {
                _profileImagePath = null;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 16),
                  SizedBox(width: 2.w),
                  Text(
                    'Fotoğrafı Kaldır',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Kendinizden bahsedin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'İsteğe bağlı - kısa bir tanıtım yazısı',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: _bioController,
          onChanged: (_) => setState(() {}),
          maxLines: 4,
          maxLength: 150,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: 'Hobileriniz, ilgi alanlarınız, kişiliğiniz hakkında...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: EdgeInsets.all(4.w),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsStep() {
    final _customInterestController = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6.h),
        Text(
          'İlgi alanlarınızı seçin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'En az 3 tane seçmeniz gerekiyor (${_selectedInterests.length}/3)',
          style: TextStyle(
            color: _selectedInterests.length >= 3 
                ? Colors.green.withOpacity(0.8)
                : Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 3.h),
        
        // Custom interest input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customInterestController,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Kendi ilgi alanınızı yazın...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: () {
                final customInterest = _customInterestController.text.trim();
                if (customInterest.isNotEmpty && !_selectedInterests.contains(customInterest)) {
                  setState(() {
                    _selectedInterests.add(customInterest);
                    _customInterestController.clear();
                  });
                  HapticFeedback.selectionClick();
                }
              },
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 3.h),
        
        // Pre-defined interests
        Text(
          'Hazır seçenekler:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _availableInterests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        // Selected interests display
        if (_selectedInterests.isNotEmpty) ...[
          SizedBox(height: 3.h),
          Text(
            'Seçilen ilgi alanları:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _selectedInterests.map((interest) => Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    interest,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedInterests.remove(interest);
                      });
                      HapticFeedback.selectionClick();
                    },
                    child: Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPreferencesStep() {
    if (_selectedRole.toLowerCase() != 'candidate') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 64),
          SizedBox(height: 2.h),
          Text(
            'Tercihler tamamlandı!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 6.h),
        Text(
          'Tercihlerinizi belirtin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Eşleştirmeler için kullanılacak',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 3.h),
        
        // Age preferences
        Text(
          'Tercih edilen yaş aralığı',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Min',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (val) => setState(() => _preferredAgeMin = int.tryParse(val)),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Max',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (val) => setState(() => _preferredAgeMax = int.tryParse(val)),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 3.h),
        
        // Gender preferences
        Text(
          'Tercih edilen cinsiyetler',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          children: [
            {'key': 'female', 'label': 'Kadın'},
            {'key': 'male', 'label': 'Erkek'},
            {'key': 'other', 'label': 'Diğer'}
          ].map((genderData) => 
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_preferredGenders.contains(genderData['key'])) {
                    _preferredGenders.remove(genderData['key']);
                  } else {
                    _preferredGenders.add(genderData['key']!);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _preferredGenders.contains(genderData['key']) 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _preferredGenders.contains(genderData['key']) 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(genderData['label']!, style: TextStyle(color: Colors.white)),
              ),
            )
          ).toList(),
        ),
        
        SizedBox(height: 3.h),
        
        // City preferences
        Text(
          'Tercih edilen şehirler',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        
        // Manual city input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customCityController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Şehir adı yazın...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: () {
                final cityName = _customCityController.text.trim();
                if (cityName.isNotEmpty && !_preferredCities.contains(cityName)) {
                  setState(() {
                    _preferredCities.add(cityName);
                    _customCityController.clear();
                  });
                  HapticFeedback.selectionClick();
                }
              },
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 2.h),
        
        // Predefined cities
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana', 'Konya', 'Gaziantep'].map((city) => 
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_preferredCities.contains(city)) {
                    _preferredCities.remove(city);
                  } else {
                    _preferredCities.add(city);
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _preferredCities.contains(city) 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _preferredCities.contains(city) 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(city, style: TextStyle(color: Colors.white)),
              ),
            )
          ).toList(),
        ),
        
        // Display selected cities with remove option
        if (_preferredCities.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            'Seçilen şehirler:',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14.sp),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _preferredCities.map((city) => 
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      city, 
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                    SizedBox(width: 1.w),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _preferredCities.remove(city);
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              )
            ).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildExperienceStep() {
    final experiences = [
      '0-1 yıl (Yeni başlayan)',
      '1-3 yıl (Tecrübeli)',
      '3-5 yıl (Uzman)',
      '5-10 yıl (Profesyonel)',
      '10+ yıl (Usta)',
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Görücülük deneyiminiz nedir?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Bu bilgi, aileler için güven oluşturur',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        ...experiences.map((experience) => Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedExperience = experience;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: _selectedExperience == experience 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedExperience == experience 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.3),
                  width: _selectedExperience == experience ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: _selectedExperience == experience 
                          ? Colors.white 
                          : Colors.transparent,
                    ),
                    child: _selectedExperience == experience 
                        ? Icon(Icons.check, size: 14, color: Color(0xFF1a365d))
                        : null,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      experience,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: _selectedExperience == experience 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }


  Widget _buildTermsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'Kullanım şartları',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Devam etmek için şartları kabul etmelisiniz',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        GestureDetector(
          onTap: () {
            setState(() {
              _termsAccepted = !_termsAccepted;
            });
            HapticFeedback.selectionClick();
          },
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _termsAccepted 
                  ? Colors.white.withOpacity(0.2) 
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _termsAccepted 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.3),
                width: _termsAccepted ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: _termsAccepted ? Colors.white : Colors.transparent,
                  ),
                  child: _termsAccepted 
                      ? Icon(Icons.check, size: 16, color: Color(0xFF1a365d))
                      : null,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: 'Kayıt olarak '),
                        TextSpan(
                          text: 'Kullanım Şartları',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' ve '),
                        TextSpan(
                          text: 'Gizlilik Politikası',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '\'nı kabul ediyorum.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildTurkishOrnateBackground(),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _steps.length + 2,
                itemBuilder: (context, index) {
                  if (index < _steps.length) {
                    return _buildStepContent(_steps[index]);
                  } else if (index == _steps.length) {
                    return _buildLoadingStep();
                  } else {
                    return _buildCompleteStep();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
