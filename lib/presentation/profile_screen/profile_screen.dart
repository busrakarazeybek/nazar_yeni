import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../models/match_proposal.dart';
import '../../services/match_proposal_service.dart';
import './widgets/interests_section_widget.dart';
import './widgets/personal_info_section_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/role_specific_settings_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/contact_info_widget.dart';
import './widgets/preferences_widget.dart';
import './widgets/photo_gallery_widget.dart';

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
  int _newMatchesCount = 0;
  Map<String, dynamic> userData = {};

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

  @override
  void initState() {
    super.initState();
    _loadMatchesCount();
  }

  Future<void> _loadMatchesCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null && currentUser.role == UserRole.candidate) {
        final prefs = await SharedPreferences.getInstance();
        final hasViewedMatches = prefs.getBool('hasViewedMatches_${currentUser.id}') ?? false;
        
        if (!hasViewedMatches) {
          final matchProposalService = MatchProposalService();
          final proposals = await matchProposalService.getProposalsForCandidate(currentUser.id);
          
          final matchedCount = proposals.where((p) => 
            p.status == AcceptanceStatus.accepted && 
            p.targetStatus == AcceptanceStatus.accepted
          ).length;
          
          setState(() {
            _newMatchesCount = matchedCount;
          });
        }
      }
    } catch (e) {
      print('Error loading matches count: $e');
    }
  }

  Future<void> _markMatchesAsViewed() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasViewedMatches_${currentUser.id}', true);
        
        setState(() {
          _newMatchesCount = 0;
        });
      }
    } catch (e) {
      print('Error marking matches as viewed: $e');
    }
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.currentUserProfile;
    final isSelector = userProfile?.role == UserRole.selector;
    print(
        'DEBUG Profile Screen: User role: ${userProfile?.role}, isSelector: $isSelector');

    return [
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
        icon: Stack(
          children: [
            CustomIconWidget(
              iconName: isSelector ? 'list' : 'favorite',
              color: _currentIndex == 1
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.textSecondaryLight,
              size: 24,
            ),
            if (!isSelector && _newMatchesCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_newMatchesCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: isSelector ? 'Önerilerim' : 'Eşleşmeler',
      ),
      BottomNavigationBarItem(
        icon: CustomIconWidget(
          iconName: 'people',
          color: _currentIndex == 2
              ? AppTheme.lightTheme.primaryColor
              : AppTheme.textSecondaryLight,
          size: 24,
        ),
        label: isSelector ? 'Adaylarım' : 'Seçicilerim',
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
    ];
  }

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
        // Role-based navigation for second tab
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userProfile = authProvider.currentUserProfile;
        if (userProfile?.role == UserRole.selector) {
          Navigator.pushReplacementNamed(context, '/my-selections-screen');
        } else {
          // Badge'i kalıcı olarak sıfırla ve matches screen'e git
          _markMatchesAsViewed();
          Navigator.pushReplacementNamed(context, '/matches-screen');
        }
        break;
      case 2:
        // Role-based navigation for third tab
        final authProvider2 = Provider.of<AuthProvider>(context, listen: false);
        final userProfile2 = authProvider2.currentUserProfile;
        if (userProfile2?.role == UserRole.selector) {
          Navigator.pushReplacementNamed(context, '/my-selectors-screen');
        } else {
          Navigator.pushReplacementNamed(context, '/my-selectors-screen');
        }
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUserProfile;
      
      if (currentUser != null) {
        final authService = AuthService();
        
        // Yaş validasyonu
        int? ageMin = userData['preferredAgeMin'] as int?;
        int? ageMax = userData['preferredAgeMax'] as int?;
        
        // Geçersiz yaş değerlerini null yap
        if (ageMin != null && (ageMin < 18 || ageMin > 100)) {
          ageMin = null;
        }
        if (ageMax != null && (ageMax < 18 || ageMax > 100)) {
          ageMax = null;
        }
        
        // MinAge > MaxAge durumunu kontrol et
        if (ageMin != null && ageMax != null && ageMin > ageMax) {
          // Swap values
          final temp = ageMin;
          ageMin = ageMax;
          ageMax = temp;
        }
        
        // userData Map'inden değerleri al ve updateUserProfile'a gönder
        await authService.updateUserProfile(
          userId: currentUser.id,
          fullName: userData['name'] as String?,
          age: userData['age'] as int?,
          bio: userData['bio'] as String?,
          interests: (userData['interests'] as List?)?.cast<String>(),
          location: currentUser.location, // mevcut location'ı koru
          profession: currentUser.profession, // mevcut profession'ı koru
          imageUrl: userData['profileImage'] as String?,
          phone: currentUser.phone, // mevcut phone'u koru
          preferredAgeMin: ageMin,
          preferredAgeMax: ageMax,
          preferredCities: (userData['preferredCities'] as List?)?.cast<String>(),
          preferredInterests: (userData['preferredInterests'] as List?)?.cast<String>(),
          preferredGenders: (userData['preferredGenders'] as List?)?.cast<String>(),
        );
        
        // AuthProvider'ı yenile
        await authProvider.refreshUserProfile();
      }

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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncelleme hatası: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    print("ProfileScreen build called");
    try {
      final authProvider = Provider.of<AuthProvider>(context);
      final userProfile = authProvider.currentUserProfile;
      print("AuthProvider loaded, userProfile: ${userProfile?.id}");

      if (authProvider.isLoading) {
        print("AuthProvider is loading");
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (userProfile == null) {
        print("UserProfile is null");
        return Scaffold(
          body: Center(
            child: Text('Kullanıcı profili bulunamadı.'),
          ), // veya giriş ekranına yönlendir
        );
      }

      // userData'yı sadece boşsa initialize et
      if (userData.isEmpty) {
        print("Initializing userData for user: ${userProfile.id}");
        try {
          print("DEBUG: Loading preferences from userProfile:");
          print("DEBUG: preferredGenders from database: ${userProfile.preferredGenders}");
          
          userData = {
            "id": userProfile.id,
            "name": userProfile.fullName,
            "age": userProfile.age,
            "bio": userProfile.bio ?? '',
            "profileImage": userProfile.imageUrl,
            "interests": userProfile.interests ?? [],
            // Kişisel bilgiler
            "email": userProfile.email,
            "phone": userProfile.phone ?? '',
            "location": userProfile.location ?? '',
            "profession": userProfile.profession ?? '',
            "gender": userProfile.gender?.displayName ?? 'Belirtilmemiş',
            // Fotoğraf galerisi
            "profileImages": userProfile.imageUrls ?? [userProfile.imageUrl].where((url) => url != null).toList(),
            // Eşleşme tercihleri - database'den çek
            "preferredAgeMin": userProfile.preferredAgeMin,
            "preferredAgeMax": userProfile.preferredAgeMax,
            "preferredCities": userProfile.preferredCities ?? [],
            "preferredInterests": userProfile.preferredInterests ?? [],
            "preferredGenders": userProfile.preferredGenders ?? [],
            "notificationsEnabled": true, // örnek
            "language": "Türkçe", // örnek
            "searchRadius": 50, // örnek
            "privacyLevel": "Orta", // örnek
            // ProfileHeaderWidget için gerekli alanlar
            "role": userProfile.role.toString().split('.').last,
            "matchCount": 0, // Gerçek değer gerekirse service'den çekilebilir
            "photoCount": (userProfile.imageUrls?.length ?? 0),
            "rating": 5.0, // Gerçek değer gerekirse service'den çekilebilir
          };
          
          print("DEBUG: userData preferredGenders after initialization: ${userData["preferredGenders"]}");
          print("userData initialized successfully");
        } catch (e) {
          print("Error initializing userData: $e");
          return Scaffold(
            body: Center(
              child: Text('Profil verileri hazırlanamadı: $e'),
            ),
          );
        }
      }

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
              Builder(
                builder: (context) {
                  try {
                    print("Building ProfileHeaderWidget with userData keys: ${userData.keys}");
                    return ProfileHeaderWidget(
                      userData: userData,
                      onImageChanged: _onDataChanged,
                    );
                  } catch (e) {
                    print("Error building ProfileHeaderWidget: $e");
                    return Container(
                      height: 200,
                      color: Colors.red,
                      child: Center(
                        child: Text('Header Error: $e', style: TextStyle(color: Colors.white)),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 2.h),
              
              // Photo Gallery - Temporarily Removed
              Container(
                height: 100,
                color: Colors.grey[200],
                child: Center(
                  child: Text('Fotoğraf galerisi geçici olarak devre dışı'),
                ),
              ),
              SizedBox(height: 2.h),
              
              PersonalInfoSectionWidget(
                userData: userData,
                onDataChanged: _onDataChanged,
              ),
              SizedBox(height: 2.h),
              
              // Contact Information
              ContactInfoWidget(
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
              
              // Preferences (only for candidates)
              if (userProfile.role == UserRole.candidate) ...[
                PreferencesWidget(
                  userData: userData,
                  onDataChanged: _onDataChanged,
                ),
                SizedBox(height: 2.h),
              ],
              
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
          items: _buildBottomNavItems(),
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
    } catch (e, stackTrace) {
      print("Error in ProfileScreen build: $e");
      print("StackTrace: $stackTrace");
      return Scaffold(
        body: Center(
          child: Text('Profil yüklenemedi: $e'),
        ),
      );
    }
  }
}
