import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/interests_section_widget.dart';
import './widgets/personal_info_section_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/role_specific_settings_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3; // Profile tab is active
  bool _hasUnsavedChanges = false;
  bool _isLoading = false;
  final String _userRole =
      'Candidate'; // Mock role - can be 'Selector' or 'Candidate'

  // Mock user data
  final Map<String, dynamic> _userData = {
    "id": 1,
    "name": "Ayşe Demir",
    "age": 28,
    "bio":
        "İstanbul'da yaşayan, kitap okumayı ve seyahat etmeyi seven bir öğretmenim. Hayatımda anlamlı bağlantılar kurmak istiyorum.",
    "profileImage":
        "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    "interests": [
      "Kitap Okuma",
      "Seyahat",
      "Yemek Pişirme",
      "Müzik",
      "Doğa Yürüyüşü",
    ],
    "notificationsEnabled": true,
    "language": "Türkçe",
    "searchRadius": 50,
    "privacyLevel": "Orta",
  };

  final List<String> _popularInterests = [
    "Spor",
    "Sinema",
    "Sanat",
    "Teknoloji",
    "Fotoğrafçılık",
    "Dans",
    "Yoga",
    "Bahçıvanlık",
    "Oyun",
    "Tarih",
  ];

  void _onBottomNavTap(int index) {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog(() {
        _navigateToTab(index);
      });
    } else {
      _navigateToTab(index);
    }
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.currentUserProfile;

    switch (index) {
      case 0:
        if (userProfile != null) {
          if (userProfile.role.toString().contains('candidate')) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.candidateHomeScreen,
            );
          } else if (userProfile.role.toString().contains('selector')) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.enhancedSelectorHomeScreen,
            );
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
          }
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
        }
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/matches-screen');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/my-selectors-screen');
        break;
      case 3:
        // Already on profile screen
        break;
    }
  }

  void _showUnsavedChangesDialog(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Kaydedilmemiş Değişiklikler',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Değişiklikleriniz kaydedilmedi. Çıkmak istediğinizden emin misiniz?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Çık'),
            ),
          ],
        );
      },
    );
  }

  void _onDataChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil başarıyla güncellendi'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAccountDeletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hesabı Sil',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu işlem geri alınamaz. Hesabınız ve tüm verileriniz kalıcı olarak silinecektir.',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              Text(
                'Verilerinizi dışa aktarmak ister misiniz?',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle data export
              },
              child: const Text('Verileri Dışa Aktar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle account deletion
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Hesabı Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.currentUserProfile;

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userProfile == null) {
      return Scaffold(
        body: Center(
          child: Text('Kullanıcı profili bulunamadı.'),
        ), // veya giriş ekranına yönlendir
      );
    }

    final userData = {
      "id": userProfile.id,
      "name": userProfile.fullName,
      "age": userProfile.age,
      "bio": userProfile.bio ?? '',
      "profileImage": userProfile.imageUrl,
      "interests": userProfile.interests ?? [],
      "notificationsEnabled": true, // örnek
      "language": "Türkçe", // örnek
      "searchRadius": 50, // örnek
      "privacyLevel": "Orta", // örnek
    };

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          _showUnsavedChangesDialog(() {
            Navigator.of(context).pop();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Profil',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
          elevation: 0,
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                onPressed: _isLoading ? null : _saveChanges,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightTheme.primaryColor,
                          ),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'check',
                        color: AppTheme.successColor,
                        size: 24,
                      ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              ProfileHeaderWidget(
                userData: userData,
                onImageChanged: _onDataChanged,
              ),
              SizedBox(height: 2.h),
              PersonalInfoSectionWidget(
                userData: userData,
                onDataChanged: _onDataChanged,
              ),
              SizedBox(height: 2.h),
              InterestsSectionWidget(
                interests: (userData["interests"] as List).cast<String>(),
                popularInterests: _popularInterests,
                onInterestsChanged: (List<String> newInterests) {
                  setState(() {
                    userData["interests"] = newInterests;
                  });
                  _onDataChanged();
                },
              ),
              SizedBox(height: 2.h),
              RoleSpecificSettingsWidget(
                userRole: userProfile.role.toString().split('.').last,
                userData: userData,
                onDataChanged: _onDataChanged,
              ),
              SizedBox(height: 2.h),
              SettingsSectionWidget(
                userData: userData,
                onDataChanged: _onDataChanged,
                onAccountDeletion: _showAccountDeletionDialog,
              ),
              SizedBox(height: 10.h), // Bottom padding for FAB
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor:
              AppTheme.lightTheme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor:
              AppTheme.lightTheme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor:
              AppTheme.lightTheme.bottomNavigationBarTheme.unselectedItemColor,
          items: [
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'home',
                color: _currentIndex == 0
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.textSecondaryLight,
                size: 24,
              ),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'favorite',
                color: _currentIndex == 1
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.textSecondaryLight,
                size: 24,
              ),
              label: 'Eşleşmeler',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'people',
                color: _currentIndex == 2
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.textSecondaryLight,
                size: 24,
              ),
              label: 'Seçicilerim',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'person',
                color: _currentIndex == 3
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.textSecondaryLight,
                size: 24,
              ),
              label: 'Profil',
            ),
          ],
        ),
        floatingActionButton: _hasUnsavedChanges
            ? FloatingActionButton(
                onPressed: _isLoading ? null : _saveChanges,
                backgroundColor: AppTheme.successColor,
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightTheme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: 'save',
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        size: 24,
                      ),
              )
            : null,
      ),
    );
  }
}
