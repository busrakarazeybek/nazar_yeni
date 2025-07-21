import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/candidate_home_widget.dart';
import './widgets/selector_home_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  UserProfile? _currentUserProfile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      _currentUserProfile = authProvider.currentUserProfile;

      if (_currentUserProfile == null) {
        setState(() {
          _errorMessage = 'Kullanıcı profili bulunamadı';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Profil yüklenirken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_currentUserProfile == null) {
      return _buildNoProfileScreen();
    }

    // Rol bazlı ekran seçimi
    switch (_currentUserProfile!.role) {
      case UserRole.selector:
        return SelectorHomeWidget(userProfile: _currentUserProfile!);
      case UserRole.candidate:
        return CandidateHomeWidget(userProfile: _currentUserProfile!);
      case UserRole.admin:
        return SelectorHomeWidget(userProfile: _currentUserProfile!);
      default:
        return _buildUnsupportedRoleScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.primaryColor,
            ),
            SizedBox(height: 2.h),
            Text(
              'Profil yükleniyor...',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'error_outline',
                color: AppTheme.errorColor,
                size: 64.w,
              ),
              SizedBox(height: 3.h),
              Text(
                'Hata',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _errorMessage ?? 'Bilinmeyen hata',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: _loadUserProfile,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: Colors.white,
                  size: 20.w,
                ),
                label: Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProfileScreen() {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'account_circle',
                color: AppTheme.lightTheme.colorScheme.outline,
                size: 64.w,
              ),
              SizedBox(height: 3.h),
              Text(
                'Profil Bulunamadı',
                style: AppTheme.lightTheme.textTheme.headlineSmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Lütfen profilinizi tamamlayın',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile-screen');
                },
                child: Text('Profile Git'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedRoleScreen() {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: AppTheme.warningColor,
                size: 64.w,
              ),
              SizedBox(height: 3.h),
              Text(
                'Desteklenmeyen Rol',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.warningColor,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Kullanıcı rolünüz henüz desteklenmiyor',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile-screen');
                },
                child: Text('Profile Git'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
