import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gereklidir';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) {
      return 'Geçerli bir e-posta adresi giriniz';
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      if (success && authProvider.currentUserProfile != null) {
        // Trigger haptic feedback
        HapticFeedback.lightImpact();

        // Navigate based on role
        final role = authProvider.currentUserProfile!.role;
        if (role == UserRole.selector) {
          Navigator.pushReplacementNamed(
              context, AppRoutes.enhancedSelectorHomeScreen);
        } else if (role == UserRole.candidate) {
          Navigator.pushReplacementNamed(
              context, AppRoutes.candidateHomeScreen);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
        }
      } else {
        _showErrorMessage(authProvider.errorMessage ??
            'Giriş başarısız. Lütfen tekrar deneyiniz.');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Şifre Sıfırlama',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Şifre sıfırlama bağlantısı e-posta adresinize gönderilecektir.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.w),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_emailController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider
                    .resetPassword(_emailController.text.trim());

                if (mounted) {
                  if (success) {
                    _showErrorMessage('Şifre sıfırlama bağlantısı gönderildi.');
                  } else {
                    _showErrorMessage(authProvider.errorMessage ??
                        'Şifre sıfırlama başarısız.');
                  }
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 8.h),

                    // App Logo with Turkish Motifs
                    _buildAppLogo(),

                    SizedBox(height: 6.h),

                    // Welcome Text
                    _buildWelcomeText(),

                    SizedBox(height: 4.h),

                    // Email Field
                    _buildEmailField(),

                    SizedBox(height: 3.h),

                    // Password Field
                    _buildPasswordField(),

                    SizedBox(height: 2.h),

                    // Remember Me & Forgot Password
                    _buildRememberAndForgot(),

                    SizedBox(height: 4.h),

                    // Login Button
                    _buildLoginButton(authProvider),

                    SizedBox(height: 3.h),

                    // Sign Up Link
                    _buildSignUpLink(),

                    SizedBox(height: 4.h),

                    // Mock Credentials Info (only in debug mode)
                    if (kDebugMode) _buildMockCredentialsInfo(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Center(
      child: Container(
        width: 25.w,
        height: 25.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.primaryColor,
          borderRadius: BorderRadius.circular(4.w),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'favorite',
              color: Colors.white,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              'Görücü',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Hoş Geldiniz',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.lightTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Hesabınıza giriş yapın',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: _validateEmail,
      decoration: InputDecoration(
        labelText: 'E-posta',
        hintText: 'ornek@email.com',
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: 'email',
            color: AppTheme.textSecondaryLight,
            size: 5.w,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide:
              BorderSide(color: AppTheme.lightTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      validator: _validatePassword,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Şifre',
        hintText: 'Şifrenizi giriniz',
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: 'lock',
            color: AppTheme.textSecondaryLight,
            size: 5.w,
          ),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          icon: CustomIconWidget(
            iconName: _isPasswordVisible ? 'visibility_off' : 'visibility',
            color: AppTheme.textSecondaryLight,
            size: 5.w,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide:
              BorderSide(color: AppTheme.lightTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.w),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              activeColor: AppTheme.lightTheme.primaryColor,
            ),
            Text(
              'Beni hatırla',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
        TextButton(
          onPressed: _handleForgotPassword,
          child: Text(
            'Şifremi unuttum?',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    return SizedBox(
      height: 6.h,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 2,
        ),
        child: authProvider.isLoading
            ? SizedBox(
                width: 5.w,
                height: 5.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Giriş Yap',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabınız yok mu? ',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/role-selection-screen');
          },
          child: Text(
            'Kayıt Ol',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockCredentialsInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Hesapları:',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          _buildCredentialRow('Seçici:', 'selector@goricu.com', 'selector123'),
          SizedBox(height: 1.h),
          _buildCredentialRow('Aday:', 'candidate@goricu.com', 'candidate123'),
          SizedBox(height: 1.h),
          _buildCredentialRow('Admin:', 'admin@goricu.com', 'admin123'),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String role, String email, String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'E-posta: $email',
          style: AppTheme.lightTheme.textTheme.bodySmall,
        ),
        Text(
          'Şifre: $password',
          style: AppTheme.lightTheme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
